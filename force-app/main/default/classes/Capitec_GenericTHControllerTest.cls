/*
********************************************************************************************
Apex Class Name    : Capitec_GenericTHControllerTest
Created Date       : November 03, 2024
@description       : Cloned and updated from capitec_FraudTHControllerTest, by Dawid Kuczer
                     Test class for Capitec_GenericTHController
@author            : Cornelia Smit
Modification Log:
Ver   Date         Author                 Modification
1.0   18-11-2024   Cornelia Smit         Initial Version
********************************************************************************************
*/
@IsTest
private class Capitec_GenericTHControllerTest {
    private static final String CIF = '103226141';
    private static final String CP = 'CP340378';
    private static final String START_DATE = String.valueOf(System.today()-31);
    private static final String END_DATE = String.valueOf(System.today());
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    private static final String FIRST_NAME = 'Jordan';
    private static final String LAST_NAME = 'Hal';
    private static final String IDENTITY_NUMBER1 = '8806110477082';
    private static final String IDENTITY_NUMBER2 = '9505240053081';
    private static final String GENDER = 'M';
    private static final Date DATE_OF_BIRTH1 = Date.valueOf('1988-06-11');
    private static final Date DATE_OF_BIRTH2 = Date.valueOf('1995-05-24');
 
    @TestSetup
    static void dataSetup(){
 
        String uniqueUserName = 'testuser2' + DateTime.now().getTime() + '@testorg1.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'usert1', Email='testUser1@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles',
                Username=uniqueUserName, EmployeeNumber=CP);
 
        String uniqueUserNameNoCode = 'testuser1' + DateTime.now().getTime() + '@testorg2.com';
        User userNoCode = new User(Alias = 'usert2', Email='testUser2@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles',
                Username=uniqueUserNameNoCode);
 
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
        Id clientCareRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('Client_Care').getRecordTypeId();
 
        Id amlRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('AML_Record_Type').getRecordTypeId();
 
        Account acc = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
                'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                'LastName' => FIRST_NAME,
                'CIF_Number__c' => CIF,
                'Identity_Number__c' => IDENTITY_NUMBER1,
                'LastName' => LAST_NAME,
                'Gender__c' => GENDER,
                'Birthdate__c' => DATE_OF_BIRTH1
        }, true);
 
        Account accNoCif = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
                'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                'LastName' => FIRST_NAME,
                'Identity_Number__c' => IDENTITY_NUMBER2,
                'LastName' => LAST_NAME,
                'Gender__c' => GENDER,
                'Birthdate__c' => DATE_OF_BIRTH2
        }, true);
 
        Entitlement entit = (Entitlement)TestDataFactory.createSObject('Entitlement', new Map<String, Object> {
                'StartDate' => Date.today(),
                'EndDate' => Date.today().addYears(90),
                'Name' => 'AML Full Case SLA',
                'BusinessHoursId' => bh.Id,
                'AccountId' => acc.Id
        }, true);
 
        System.runAs(u) {
            // The following code runs as user 'u'
            Case newCase = (Case) TestDataFactory.createSObject('Case', new Map<String, Object>{
                    'Account_CIF_Number__c' => CIF,
                    'RecordTypeId' => clientCareRecordTypeId,
                    'capitec_Employee_Code__c' => CP,
                    'BusinessHoursId' => bh.Id,
                    'AccountId' => acc.Id
            }, true);
        }
 
        System.runAs(userNoCode) {
            // The following code runs as user 'userNoCode'
            Case caseNoCif = (Case)TestDataFactory.createSObject('Case', new Map<String, Object>{
                    'BusinessHoursId' => bh.Id,
                    'RecordTypeId' => amlRecordTypeId,
                    'AccountId' => accNoCif.Id
            }, true);
        }

        WebServiceSettings__c settingProduct = new WebServiceSettings__c();
        settingProduct.Name = 'GenericProductService';
        settingProduct.Endpoint_URL__c = '/test/url?';
        settingProduct.Named_Credential__c = 'test';
        settingProduct.Scheme__c = 'callout:';
        insert settingProduct;

        WebServiceSettings__c settingTH = new WebServiceSettings__c();
        settingTH.Name = 'GenericTransactionHistoryService';
        settingTH.Endpoint_URL__c = '/test/url?';
        settingTH.Named_Credential__c = 'test';
        settingTH.Scheme__c = 'callout:';
        insert settingTH;

        FinServ__FinancialAccount__c testFinancialAccount = new FinServ__FinancialAccount__c(
            FinServ__FinancialAccountNumber__c = '00000001575095813',
            FinServ__PrimaryOwner__c = acc.Id,
            FinServ__JointOwner__c = accNoCif.Id,
            Capitec_Integration_CIF__c = '103226141'
        );
        insert testFinancialAccount;
    }
 
    @IsTest
    static void testGetCaseDataCorrect() {
 
        String CP = 'CP340378';
        Case tempCase = [SELECT Id, Account_CIF_Number__c,CIF_Number__c, capitec_Employee_Code__c FROM Case WHERE Account_CIF_Number__c != '' LIMIT 1];
        String employeeCode;
        String cifNumber;
        Date startDate;
        Test.startTest();
 
        employeeCode = Capitec_GenericTHController.getConsultantCP(tempCase.Id);
        cifNumber = Capitec_CaseUtils.getCIFByRecordId(tempCase.Id);
        startDate = Capitec_GenericTHController.getDateRange(tempCase.Id);
 
 
        Test.stopTest();
 
        System.assert(employeeCode == CP, 'Employ code does not match');
        System.assert(cifNumber == tempCase.Account_CIF_Number__c, 'CIF does not match');
        System.assert(startDate == (System.today().addMonths(-3)), 'Date does not match');
    }
 
    @IsTest
    static void testGetCaseDataFailed() {
        String employeeCode;
        String cifNumber;
        Date startDate;
 
        String employeeCode2;
        String cifNumber2;
        Date startDate2;
 
        Case tempCase = [SELECT Id, Account_CIF_Number__c,CIF_Number__c, capitec_Employee_Code__c FROM Case WHERE Account_CIF_Number__c = '' LIMIT 1];
 
        Test.startTest();
 
        employeeCode = Capitec_GenericTHController.getConsultantCP(tempCase.Id);
        cifNumber = Capitec_CaseUtils.getCIFByRecordId(tempCase.Id);
        startDate = Capitec_GenericTHController.getDateRange(tempCase.Id);
 
        employeeCode2 = Capitec_GenericTHController.getConsultantCP('not an id');
        cifNumber2 = Capitec_CaseUtils.getCIFByRecordId('not an id');
 
        Test.stopTest();
 
        System.assert(employeeCode == null, 'Employ code should be null');
        System.assert(cifNumber == null, 'CIF should be null');
        System.assert(startDate == (System.today().addMonths(-3)), 'Date does not match');
 
        System.assert(employeeCode2 == null, 'Employ code should be null');
        System.assert(cifNumber2 == null, 'CIF should be null');
 
    }

    @IsTest
    static void testGetTHCorrect() {
 
        Test.setMock(HttpCalloutMock.class, new Capitec_GenericTHMockResponses.CorrectGetTHResponse());
        String responseJSON;
 
        Test.startTest();
        responseJSON = Capitec_GenericTHController.getTransactionHistory('accNumber', START_DATE, END_DATE);
        Test.stopTest();

        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);
        Boolean errorResponse = (Boolean) jsonMap.get('error');
 
        System.assertEquals(false, errorResponse, 'Transaction history retrieval failed');
    }

    @IsTest
    static void testGetTHFailed() {
 
        Test.setMock(HttpCalloutMock.class, new Capitec_GenericTHMockResponses.FailedGetTHResponse());
        String responseJSON;
 
        Test.startTest();
        responseJSON = Capitec_GenericTHController.getTransactionHistory('accNumber', START_DATE, END_DATE);
        Test.stopTest();

        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);
        Boolean errorResponse = (Boolean) jsonMap.get('error');
 
        System.assertEquals(errorResponse, true, 'Expected failure response');
    }
    @IsTest
    static void testGetTHEmpty() {
 
        Test.setMock(HttpCalloutMock.class, new Capitec_GenericTHMockResponses.EmptyGetTHResponse());
        String responseJSON;
 
        Test.startTest();
        responseJSON = Capitec_GenericTHController.getTransactionHistory('accNumber', START_DATE, END_DATE);
        Test.stopTest();

        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);
        List<Object> rawTransactions = (List<Object>) jsonMap.get('transactions');

        List<Map<String, Object>> transactions = new List<Map<String, Object>>();
        for (Object item : rawTransactions) {
            transactions.add((Map<String, Object>) item);
        }
 
        System.assertEquals(transactions.size(), 0, 'Empty transaction test failed');
    }
 
    @IsTest
    static void testGetProducts(){

        Test.setMock(HttpCalloutMock.class, new Capitec_GenericTHMockResponses.CorrectGetProductsResponse());
        String responseJSON;
        Case tempCase = [SELECT Id, Account_CIF_Number__c,CIF_Number__c, capitec_Employee_Code__c FROM Case WHERE Account_CIF_Number__c != '' LIMIT 1];
 
        Test.startTest();
        responseJSON = Capitec_GenericTHController.getProductsByCase(tempCase.Id);
        Test.stopTest();
 
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);
        Boolean errorResponse = (Boolean) jsonMap.get('error');
 
        System.assertEquals(false, errorResponse, 'Product retrieval failed');
    }

    @IsTest
    static void testGetProductsFailed(){

        Test.setMock(HttpCalloutMock.class, new Capitec_GenericTHMockResponses.FailedGetProductsResponse());
        String responseJSON;
        Case tempCase = [SELECT Id, Account_CIF_Number__c,CIF_Number__c, capitec_Employee_Code__c FROM Case WHERE Account_CIF_Number__c != '' LIMIT 1];
 
        Test.startTest();
        responseJSON = Capitec_GenericTHController.getProductsByCase(tempCase.Id);
        Test.stopTest();
 
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);
        Boolean errorResponse = (Boolean) jsonMap.get('error');
 
        System.assertEquals(errorResponse, true, 'Expected failure response');
    }

    @IsTest
    static void testFlagToCaseCorrect() {
        
        Test.setMock(HttpCalloutMock.class, new Capitec_GenericTHMockResponses.CorrectGetTHResponse());
        String responseJSON;
        String flagResponse;

        Case tempCase = [SELECT Id, Account_CIF_Number__c,CIF_Number__c, capitec_Employee_Code__c FROM Case WHERE Account_CIF_Number__c != '' LIMIT 1];
 
        Test.startTest();
        responseJSON = Capitec_GenericTHController.getTransactionHistory('accNumber', START_DATE, END_DATE);

        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);
        List<Object> rawTransactions = (List<Object>) jsonMap.get('transactions');

        List<Map<String, Object>> transactions = new List<Map<String, Object>>();
        for (Object item : rawTransactions) {
            transactions.add((Map<String, Object>) item);
        }

        List<Map<String, Object>> selectedItems = new List<Map<String, Object>>();
        selectedItems.add(transactions[0]);

        flagResponse = Capitec_GenericTHController.getHandleFlagToCase(tempCase.Id, selectedItems);
        Test.stopTest();

        System.assertEquals('success', flagResponse, 'Flagging unsuccessful');
    }

    @IsTest
    static void testFlagToCaseDuplicate() {

        Test.setMock(HttpCalloutMock.class, new Capitec_GenericTHMockResponses.CorrectGetTHResponse());
        String responseJSON;
        String flagResponse;

        Case tempCase = [SELECT Id, Account_CIF_Number__c,CIF_Number__c, capitec_Employee_Code__c FROM Case WHERE Account_CIF_Number__c != '' LIMIT 1];
 
        Test.startTest();
        responseJSON = Capitec_GenericTHController.getTransactionHistory('accNumber', START_DATE, END_DATE);

        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);
        List<Object> rawTransactions = (List<Object>) jsonMap.get('transactions');

        List<Map<String, Object>> transactions = new List<Map<String, Object>>();
        for (Object item : rawTransactions) {
            transactions.add((Map<String, Object>) item);
        }

        List<Map<String, Object>> selectedItems = new List<Map<String, Object>>();
        selectedItems.add(transactions[0]);

        flagResponse = Capitec_GenericTHController.getHandleFlagToCase(tempCase.Id, selectedItems);
        //Run flagging on same record a second time
        flagResponse = Capitec_GenericTHController.getHandleFlagToCase(tempCase.Id, selectedItems);
        Test.stopTest();

        System.assertEquals('duplicateTransactionId', flagResponse, 'TH flagging duplicate check failed');

    }
}