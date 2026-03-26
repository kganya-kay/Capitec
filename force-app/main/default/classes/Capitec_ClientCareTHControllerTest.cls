/*
********************************************************************************************
Apex Class Name    : Capitec_ClientCareTHControllerTest
Created Date       : November 6, 2024
@description       : Test class for Capitec_ClientCareTHController                
@author            : Cornelia Smit
Modification Log:
Ver   Date         Author                 Modification
1.0   14-11-2024   Cornelia Smit         Initial Version
********************************************************************************************
*/
@isTest
private class Capitec_ClientCareTHControllerTest {

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
 
        Id clientCareRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('Client_Care').getRecordTypeId();

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
 
        Account acc = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
                'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                'LastName' => FIRST_NAME,
                'CIF_Number__c' => CIF,
                'Identity_Number__c' => IDENTITY_NUMBER1,
                'LastName' => LAST_NAME,
                'Gender__c' => GENDER,
                'Birthdate__c' => DATE_OF_BIRTH1
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

            Case newCase2 = (Case) TestDataFactory.createSObject('Case', new Map<String, Object>{
                    'Account_CIF_Number__c' => CIF,
                    'RecordTypeId' => clientCareRecordTypeId,
                    'capitec_Employee_Code__c' => CP,
                    'BusinessHoursId' => bh.Id,
                    'AccountId' => acc.Id
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
    }

    @IsTest
    static void testGetGenericAdditionalMapping() {
        Boolean success = getAdditionalMapping('Generic');
        System.assertEquals(true, success, 'Generic additional mapping failed');
    }

    @IsTest
    static void testGetFraudAdditionalMapping() {
        Boolean success = getAdditionalMapping('Fraud');
        System.assertEquals(true, success, 'Fraud additional mapping failed');
    }

    @IsTest
    static void testGetTHEmpty() {

        Test.setMock(HttpCalloutMock.class, new Capitec_GenericTHMockResponses.EmptyGetTHResponse());
        String responseJSON;
 
        Test.startTest();
        responseJSON = Capitec_ClientCareTHController.getTransactionHistory('accNumber', 'caseId', START_DATE, END_DATE, 'Generic');
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
    static void testGenericFlagToCaseCorrect() {
        Boolean success = verifyFlagToCase('Generic');
        System.assertEquals(true, success, 'Generic flagging failed');
    }

    @IsTest
    static void testFraudFlagToCaseCorrect() {
        Boolean success = verifyFlagToCase('Fraud');
        System.assertEquals(true, success, 'Fraud flagging failed');
    }

    @IsTest
    static void testGenericFlagToCaseDuplicate() {
        Boolean success = verifyDuplicateFlagging('Generic');
        System.assertEquals(true, success, 'Generic duplicate check failed');
    }

    @IsTest
    static void testFraudFlagToCaseDuplicate() {
        Boolean success = verifyDuplicateFlagging('Fraud');
        System.assertEquals(true, success, 'Fraud duplicate check failed');
    }

    private static Boolean getAdditionalMapping(String processType) {

        Test.startTest();
        String responseJSON = getTransactionHistoryMockResponse(processType);
        Test.stopTest();

        // Deserialize and verify the response
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);
        Boolean errorResponse = (Boolean) jsonMap.get('error');

        System.assertEquals(false, errorResponse, 'Transaction history retrieval failed');

        List<Object> rawTransactions = (List<Object>) jsonMap.get('transactions');
        List<Map<String, Object>> transactions = new List<Map<String, Object>>();
        for (Object item : rawTransactions) {
            transactions.add((Map<String, Object>) item);
        }

        // Verify transaction mapping
        Boolean hasTransactionType = false;
        for (Map<String, Object> item : transactions) {
            if (item.containsKey('transactionType') && item.get('transactionType') != '' && item.get('transactionType') != null) {
                hasTransactionType = true;
                break;
            }
        }
        System.assertEquals(true, hasTransactionType, 'Transactions should have transactionType column');
        return true;
    }

    private static String getTransactionHistoryMockResponse(String processType) {
        if (processType == 'Fraud') {
            Test.setMock(HttpCalloutMock.class, new Capitec_FraudTHMockResponses.CorrectGetTHResponse());
        } else {
            Test.setMock(HttpCalloutMock.class, new Capitec_GenericTHMockResponses.CorrectGetTHResponse());
        }
        String responseJSON = '';

        responseJSON = Capitec_ClientCareTHController.getTransactionHistory('accNumber', 'caseId', START_DATE, END_DATE, processType);

        if (processType == 'Fraud') {
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);
            List<Object> rawTransactions = (List<Object>) jsonMap.get('transactions');
            List<Map<String, Object>> transactions = new List<Map<String, Object>>();

            for (Object item : rawTransactions) {
                transactions.add((Map<String, Object>) item);
            }

            for (Map<String, Object> item : transactions) {
                if (!item.containsKey('accNumberFull')) {
                    item.put('accNumberFull', jsonMap.get('accountNumber'));
                }
            }

            Map<String, Object> newJSONMap =  new Map<String, Object>();
            newJSONMap.put('accountNumber', jsonMap.get('accountNumber'));
            newJSONMap.put('transactions', transactions);
            newJSONMap.put('error', jsonMap.get('error'));
            newJSONMap.put('statusCode', jsonMap.get('statusCode'));
            responseJSON = JSON.serialize(newJSONMap);
        }

        return responseJSON;
    }

    private static Boolean verifyFlagToCase(String processType) {

        test.startTest();

        // Retrieve processed transactions
        List<Map<String, Object>> selectedItems = getProcessedTransactions(processType);

        Case tempCase = [
            SELECT Id, Account_CIF_Number__c, CIF_Number__c, capitec_Employee_Code__c 
            FROM Case 
            LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class, new Capitec_GenericTHMockResponses.CorrectGetProductsResponse());

        // Flag transactions to the case
        String flagResponse = Capitec_ClientCareTHController.getHandleFlagToCase(tempCase.Id, selectedItems);

        Test.stopTest();

        // Verify the flagging response and transaction records
        FinServ__FinancialAccountTransaction__c finAccTransaction = [
            SELECT Id, Transaction_Type__c, CC_Account_Type__c
            FROM FinServ__FinancialAccountTransaction__c
            WHERE Case__c = :tempCase.Id
            LIMIT 1
        ];
        
        System.assertEquals('success', flagResponse, 'Flagging unsuccessful');
        System.assert(finAccTransaction.Transaction_Type__c != '', 'No transaction type populated');
        System.assert(finAccTransaction.CC_Account_Type__c != '', 'No account type populated');

        return true;
    }

    private static Boolean verifyDuplicateFlagging(String processType) {

        test.startTest();

        // Retrieve processed transactions
        List<Map<String, Object>> selectedItems = (List<Map<String, Object>>) getProcessedTransactions(processType);

         // Query sample cases
         List<Case> tempCaseList = [
            SELECT Id, Account_CIF_Number__c, CIF_Number__c, capitec_Employee_Code__c 
            FROM Case 
            LIMIT 2
        ];

        String flagResponsePass = Capitec_ClientCareTHController.getHandleFlagToCase(tempCaseList[0].Id, selectedItems);

        flagResponsePass = Capitec_ClientCareTHController.getHandleFlagToCase(tempCaseList[1].Id, selectedItems);

        String flagResponseDuplicate = Capitec_ClientCareTHController.getHandleFlagToCase(tempCaseList[0].Id, selectedItems);
        
        Test.stopTest();

        // Verify results
        System.assertEquals('success', flagResponsePass, 'TH incorrectly flagged as duplicate');
        System.assertEquals('duplicateTransactionId', flagResponseDuplicate, 'TH not flagged as duplicate');
        return true;
    }

    private static List<Map<String, Object>> getProcessedTransactions(String processType) {
        
        String responseJSON = getTransactionHistoryMockResponse(processType);

        // Deserialize and filter transactions
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(responseJSON);
        List<Object> rawTransactions = (List<Object>) jsonMap.get('transactions');
        List<Map<String, Object>> transactions = new List<Map<String, Object>>();
        for (Object item : rawTransactions) {
            transactions.add((Map<String, Object>) item);
        }

        // Filter transactions with valid transactionType
        List<Map<String, Object>> selectedItems = new List<Map<String, Object>>();
        for (Map<String, Object> item : transactions) {
            if (item.containsKey('transactionType') && item.get('transactionType') != '' && item.get('transactionType') != null) {
                selectedItems.add(item);
            }
        }
        return selectedItems;
    }
}