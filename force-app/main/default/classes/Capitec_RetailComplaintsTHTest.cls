/**
 * Created by Pako on 20.02.2024.
 * Updated by Kevin on 12.11.2024: Added HTTPCalloutMock
 * Updated by Cornelia on 18.11.2024: CEDT-3267 & CEDT-3265 - Removed Client Care code and added new Transaction Id field
 */

 @IsTest
 private class Capitec_RetailComplaintsTHTest {
 
     private static final String CIF = '103226141';
     private static final String CP = 'CP340378';
     private static final String START_DATE = String.valueOf(System.today()-31);
     private static final String END_DATE = String.valueOf(System.today());
     static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
     private static final String FIRST_NAME = 'Jordan';
     private static final String LAST_NAME = 'Hal';
     private static final String IDENTITY_NUMBER = '8806110477082';
     private static final String IDENTITY_NUMBER_2 = '8806110477083';
     private static final String GENDER = 'M';
     private static final Date DATE_OF_BIRTH = Date.valueOf('1988-06-11');
 
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
         Id retailComplaintsRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                 .get('Retail_Complaints').getRecordTypeId();
 
         Id amlRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                 .get('AML_Record_Type').getRecordTypeId();
 
         Account acc = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
                 'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                 'LastName' => FIRST_NAME,
                 'CIF_Number__c' => CIF,
                 'Identity_Number__c' => IDENTITY_NUMBER,
                 'LastName' => LAST_NAME,
                 'Gender__c' => GENDER,
                 'Birthdate__c' => DATE_OF_BIRTH
         }, true);
 
         Account accNoCif = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
                 'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                 'LastName' => FIRST_NAME,
                 'Identity_Number__c' => IDENTITY_NUMBER_2,
                 'LastName' => LAST_NAME,
                 'Gender__c' => GENDER,
                 'Birthdate__c' => DATE_OF_BIRTH
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
             System.debug('Current User: ' + UserInfo.getUserName());
             System.debug('Current Profile: ' + UserInfo.getProfileId());
 
             Case newCase = (Case) TestDataFactory.createSObject('Case', new Map<String, Object>{
                     'Account_CIF_Number__c' => CIF,
                     'RecordTypeId' => retailComplaintsRecordTypeId,
                     'capitec_Employee_Code__c' => CP,
                     'BusinessHoursId' => bh.Id,
                     'AccountId' => acc.Id
             }, true);
             System.debug(newCase);
         }
 
         System.runAs(userNoCode) {
             // The following code runs as user 'u'
             System.debug('Current User: ' + UserInfo.getUserName());
             System.debug('Current Profile: ' + UserInfo.getProfileId());
 
             Case caseNoCif = (Case)TestDataFactory.createSObject('Case', new Map<String, Object>{
                     'BusinessHoursId' => bh.Id,
 //                'RecordTypeId' => fraudRecordTypeId,
                     'RecordTypeId' => amlRecordTypeId,
                     'AccountId' => accNoCif.Id
             }, true);
         }
 
     }
 
     @IsTest
     static void testGetCaseDataCorrect() {
 
 
 
         String CP = 'CP340378';
         Case tempCase = [SELECT Id, Account_CIF_Number__c,CIF_Number__c, capitec_Employee_Code__c FROM Case WHERE Account_CIF_Number__c != '' LIMIT 1];
         String employeeCode;
         String cifNumber;
         Date startDate;
         Test.startTest();
 
         employeeCode = Capitec_RetailComplaintsTHController.getConsultantCP(tempCase.Id);
         cifNumber = Capitec_CaseUtils.getCIFByRecordId(tempCase.Id);
         startDate = Capitec_RetailComplaintsTHController.getDateRange(tempCase.Id);
 
 
         Test.stopTest();
 
         System.assert(employeeCode == CP);
         System.assert(cifNumber == tempCase.Account_CIF_Number__c);
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
 
         employeeCode = Capitec_RetailComplaintsTHController.getConsultantCP(tempCase.Id);
         cifNumber = Capitec_CaseUtils.getCIFByRecordId(tempCase.Id);
         startDate = Capitec_RetailComplaintsTHController.getDateRange(tempCase.Id);
 
         employeeCode2 = Capitec_RetailComplaintsTHController.getConsultantCP('not an id');
         cifNumber2 = Capitec_CaseUtils.getCIFByRecordId('not an id');
         startDate2 = Capitec_RetailComplaintsTHController.getDateRange('not an id');
 
         Test.stopTest();
 
         System.assert(employeeCode == null);
         System.assert(cifNumber == null);
         System.assert(startDate == (System.today().addMonths(-3)));
 
         System.assert(employeeCode2 == null);
         System.assert(cifNumber2 == null);
         System.assert(startDate2 == null);
 
     }
     @IsTest
     static void testGetTHCorrect() {
 
         Test.setMock(HttpCalloutMock.class, new Capitec_FraudTHMockResponses.CorrectGetTHResponse());
         String responseJSON;
 
         Test.startTest();
         responseJSON = Capitec_RetailComplaintsTHController.getTransactionHistory('accNumber', 'caseId', START_DATE, END_DATE);
         Test.stopTest();
 
         System.assert(responseJSON != '');
     }
     @IsTest
     static void testGetTHFailed() {
 
         Test.setMock(HttpCalloutMock.class, new Capitec_FraudTHMockResponses.FailedGetTHResponse());
         String responseJSON;
 
         Test.startTest();
         responseJSON = Capitec_RetailComplaintsTHController.getTransactionHistory('accNumber', 'caseId', START_DATE, END_DATE);
         Test.stopTest();
 
         System.assert(responseJSON != '');
     }
     @IsTest
     static void testGetTHEmpty() {
 
         Test.setMock(HttpCalloutMock.class, new Capitec_FraudTHMockResponses.EmptyGetTHResponse());
         String responseJSON;
 
         Test.startTest();
         responseJSON = Capitec_RetailComplaintsTHController.getTransactionHistory('accNumber', 'caseId', START_DATE, END_DATE);
         Test.stopTest();
 
         System.assert(responseJSON != '');
     }
 
     @IsTest
     static void testCACorrect() {
 
         Test.setMock(HttpCalloutMock.class, new Capitec_FraudTHMockResponses.CorrectGetCAResponse());
         String responseJSON;
 
         Test.startTest();
         responseJSON = Capitec_RetailComplaintsTHController.getFlaggedTransactions('caseId');
         Test.stopTest();
 
         System.assert(responseJSON != '');
     }
     @IsTest
     static void testCAFailed() {
 
         Test.setMock(HttpCalloutMock.class, new Capitec_FraudTHMockResponses.FailedGetCAResponse());
         String responseJSON;
 
         Test.startTest();
         responseJSON = Capitec_RetailComplaintsTHController.getFlaggedTransactions('caseId');
         Test.stopTest();
 
         System.assert(responseJSON != '');
     }
     @IsTest
     static void testCAEmpty() {
 
         Test.setMock(HttpCalloutMock.class, new Capitec_FraudTHMockResponses.EmptyGetCAResponse());
         String responseJSON;
 
         Test.startTest();
         responseJSON = Capitec_RetailComplaintsTHController.getFlaggedTransactions('caseId');
         Test.stopTest();
 
         System.assert(responseJSON != '');
     }
 
     @IsTest
     static void testGetProducts(){
         Test.setMock(HttpCalloutMock.class, new Capitec_FraudTHMockResponses.CorrectGetCAResponse());
         String responseJSON;
 
         Test.startTest();
         responseJSON = Capitec_RetailComplaintsTHController.getProductsByCase('caseId');
         Test.stopTest();
 
         System.assert(responseJSON != '');
     }
 
     @IsTest
     static void testPostCallouts() {
 
         Test.setMock(HttpCalloutMock.class, new Capitec_FraudTHMockResponses.PostResponse());
         String responseJSON1;
         String responseJSON2;
         String responseJSON3;
 
         Test.startTest();
         responseJSON2 = Capitec_RetailComplaintsTHController.postApplyActions('JSONString');
 
         Test.stopTest();
 
         System.assert(responseJSON1 != '');
         System.assert(responseJSON2 != '');
         System.assert(responseJSON3 != '');
     }
     
     @isTest
     static void testGetHandleFlagToCase() {
         // Create test data
         Account primaryOwner = new Account(Name = 'Primary Owner');
         insert primaryOwner;
 
         Account jointOwner = new Account(Name = 'Joint Owner');
         insert jointOwner;
 
         FinServ__FinancialAccount__c testFinancialAccount = new FinServ__FinancialAccount__c(
             FinServ__FinancialAccountNumber__c = '1234567890',
             FinServ__PrimaryOwner__c = primaryOwner.Id,
             FinServ__JointOwner__c = jointOwner.Id,
             Capitec_Integration_CIF__c = 'CIF123456'
         );
         insert testFinancialAccount;
 
         Case testCase = new Case(Subject = 'Test Case');
         insert testCase;
 
         List<Map<String, Object>> selectedItems = new List<Map<String, Object>>();
         
         Map<String, Object> selectedItem1 = new Map<String, Object>{
             'account' => '1234567890',
             'transactionId' => 'TRANS001',
             'journalNr' => 'JRN001',
             'amount' => 100.00,
             'transactionDate' => '2024-06-01T12:00:00Z'
         };
         selectedItems.add(selectedItem1);
         
         Map<String, Object> selectedItem2 = new Map<String, Object>{
             'account' => '1234567890',
             'transactionId' => 'TRANS002',
             'journalNr' => 'JRN002',
             'amount' => 200.00,
             'transactionDate' => '2024-06-02T12:00:00Z'
         };
         selectedItems.add(selectedItem2);
         
         Test.startTest();
         String result = Capitec_RetailComplaintsTHController.gethandleFlagToCase(testCase.Id, selectedItems);
         Test.stopTest();
         System.assertEquals('success', result);
     }
 
     @isTest
     static void testGetHandleFlagToCase2() {
         // Create test data
         Account primaryOwner = new Account(Name = 'Primary Owner');
         insert primaryOwner;
 
         Account jointOwner = new Account(Name = 'Joint Owner');
         insert jointOwner;
 
         FinServ__FinancialAccount__c testFinancialAccount = new FinServ__FinancialAccount__c(
             FinServ__FinancialAccountNumber__c = '1234567890',
             FinServ__PrimaryOwner__c = primaryOwner.Id,
             FinServ__JointOwner__c = jointOwner.Id,
             Capitec_Integration_CIF__c = 'CIF123456'
         );
         insert testFinancialAccount;
 
         Case testCase = new Case(Subject = 'Test Case');
         insert testCase;
 
         List<Map<String, Object>> selectedItems = new List<Map<String, Object>>();
         
         Map<String, Object> selectedItem1 = new Map<String, Object>{
             'account' => '1234567890',
             'transactionId' => '65532444459',
             'journalNr' => 'JRN001',
             'amount' => 100.00,
             'transactionDate' => '2024-06-01T12:00:00Z'
         };
         selectedItems.add(selectedItem1);
         
         Map<String, Object> selectedItem2 = new Map<String, Object>{
             'account' => '1234567890',
             'transactionId' => '130973752737583',
             'journalNr' => 'JRN002',
             'amount' => 200.00,
             'transactionDate' => '2024-06-02T12:00:00Z'
         };
         selectedItems.add(selectedItem2);
 
         Test.startTest();
         String result = Capitec_RetailComplaintsTHController.gethandleFlagToCase(testCase.Id, selectedItems);
         Test.stopTest();
 
         List<FinServ__FinancialAccountTransaction__c> transactions = [
             SELECT Id, Transaction_Id__c, Case__c FROM FinServ__FinancialAccountTransaction__c WHERE Case__c = :testCase.Id
         ];
         System.assertEquals(2, transactions.size());
 
         // Separate the second test for duplicate transactionId into a new test method
     }
 
     @isTest
     static void testDuplicateTransactionId() {
         // Create test data
         Account primaryOwner = new Account(Name = 'Primary Owner');
         insert primaryOwner;
 
         Account jointOwner = new Account(Name = 'Joint Owner');
         insert jointOwner;
 
         FinServ__FinancialAccount__c testFinancialAccount = new FinServ__FinancialAccount__c(
             FinServ__FinancialAccountNumber__c = '1234567890',
             FinServ__PrimaryOwner__c = primaryOwner.Id,
             FinServ__JointOwner__c = jointOwner.Id,
             Capitec_Integration_CIF__c = 'CIF123456'
         );
         insert testFinancialAccount;
 
         Case testCase = new Case(Subject = 'Test Case');
         insert testCase;
 
         List<Map<String, Object>> selectedItems = new List<Map<String, Object>>();
         
         Map<String, Object> selectedItem1 = new Map<String, Object>{
             'account' => '1234567890',
             'transactionId' => 'TRANS001',
             'journalNr' => 'JRN001',
             'amount' => 100.00,
             'transactionDate' => '2024-06-01T12:00:00Z'
         };
         selectedItems.add(selectedItem1);
         
         Map<String, Object> selectedItem2 = new Map<String, Object>{
             'account' => '1234567890',
             'transactionId' => 'TRANS002',
             'journalNr' => 'JRN002',
             'amount' => 200.00,
             'transactionDate' => '2024-06-02T12:00:00Z'
         };
         selectedItems.add(selectedItem2);
 
         // Adding a duplicate transaction ID
         selectedItems.add(selectedItem1);
         
         Test.startTest();
         String duplicateResult = Capitec_RetailComplaintsTHController.gethandleFlagToCase(testCase.Id, selectedItems);
         Test.stopTest();
         System.assertEquals('duplicateTransactionId', duplicateResult);
     }
 
     @isTest
     static void testDuplicateTransactionIdInDatabase() {
         Account primaryOwner = new Account(Name = 'Primary Owner');
         insert primaryOwner;
 
         Account jointOwner = new Account(Name = 'Joint Owner');
         insert jointOwner;
 
         FinServ__FinancialAccount__c testFinancialAccount = new FinServ__FinancialAccount__c(
             FinServ__FinancialAccountNumber__c = '1234567890',
             FinServ__PrimaryOwner__c = primaryOwner.Id,
             FinServ__JointOwner__c = jointOwner.Id,
             Capitec_Integration_CIF__c = 'CIF123456'
         );
         insert testFinancialAccount;
 
         Case testCase = new Case(Subject = 'Test Case');
         insert testCase;
 
         FinServ__FinancialAccountTransaction__c existingTransaction = new FinServ__FinancialAccountTransaction__c(
            Transaction_Id__c = 'TRANS001',
             FinServ__FinancialAccount__c = testFinancialAccount.Id,
             Case__c = testCase.Id,
             FinServ__Amount__c = 100.00,
             FinServ__TransactionDate__c = DateTime.now()
         );
         insert existingTransaction;
 
         List<Map<String, Object>> selectedItems = new List<Map<String, Object>>();
         Map<String, Object> selectedItem1 = new Map<String, Object>{
             'account' => '1234567890',
             'transactionId' => 'TRANS001',
             'journalNr' => 'JRN001',
             'amount' => 100.00,
             'transactionDate' => '2024-06-01T12:00:00Z'
         };
         selectedItems.add(selectedItem1);
 
         Test.startTest();
         String result = Capitec_RetailComplaintsTHController.gethandleFlagToCase(testCase.Id, selectedItems);
         Test.stopTest();
         System.assertEquals('duplicateTransactionId', result);
     }
 
 }