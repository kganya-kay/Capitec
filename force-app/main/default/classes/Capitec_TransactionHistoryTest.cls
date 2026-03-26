/**
 * Created by dawid on 20.04.2023.
 */

@IsTest
private class Capitec_TransactionHistoryTest {
    private static final String CIF = '103226141';
    private static final Date START_DATE = (System.today()-31);
    private static final Date END_DATE = System.today();
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    private static final String FIRST_NAME = 'Jordan';
    private static final String LAST_NAME = 'Hal';
    private static final String IDENTITY_NUMBER = '8806110477082';
    private static final String GENDER = 'M';
    private static final Date DATE_OF_BIRTH = Date.valueOf('1988-06-11');

    @TestSetup
    static void dataSetup(){

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];

        Account acc = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
                'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                'LastName' => FIRST_NAME,
                'CIF_Number__c' => CIF,
                'Identity_Number__c' => IDENTITY_NUMBER,
                'LastName' => LAST_NAME,
                'Gender__c' => GENDER,
                'Birthdate__c' => DATE_OF_BIRTH
        });

        Entitlement entit = (Entitlement)TestDataFactory.createSObject('Entitlement', new Map<String, Object> {
                'StartDate' => Date.today(),
                'EndDate' => Date.today().addYears(90),
                'Name' => 'AML Full Case SLA',
                'BusinessHoursId' => bh.Id,
                'AccountId' => acc.Id
        });

        Case newCase = (Case)TestDataFactory.createSObject('Case', new Map<String, Object>{
                'Account_CIF_Number__c' => CIF,
                'BusinessHoursId' => bh.Id,
                'AccountId' => acc.Id
        });

        Case caseNoCif = (Case)TestDataFactory.createSObject('Case', new Map<String, Object>{
                'BusinessHoursId' => bh.Id,
                'AccountId' => acc.Id
        });

    }

    @IsTest
    static void testGoodResponse() {
        Case tempCase = [SELECT Id, Account_CIF_Number__c FROM Case WHERE Account_CIF_Number__c != '' LIMIT 1];
        Case noCIFCase = [SELECT Id, Account_CIF_Number__c FROM Case WHERE Account_CIF_Number__c = '' LIMIT 1];
        Capitec_TransactionHistoryHelper.TransactionHistoryResponseWrapper responseWrapper;
        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceTHMockResponse());

        Test.startTest();
        responseWrapper = Capitec_TransactionHistoryController.getClientTransactionHistory('accNumber', tempCase.Id, START_DATE, END_DATE);
        responseWrapper = Capitec_TransactionHistoryController.getClientTransactionHistory('accNumber', noCIFCase.Id, START_DATE, END_DATE);
        Test.stopTest();

        System.assert(responseWrapper.statusCode == 200);

    }

    @IsTest
    static void testFailedResponse() {
        Case tempCase = [SELECT Id, Account_CIF_Number__c FROM Case WHERE Account_CIF_Number__c != '' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceTHMockResponse.failedResponse());
        Test.startTest();
        Capitec_TransactionHistoryHelper.TransactionHistoryResponseWrapper responseWrapper = Capitec_TransactionHistoryController.getClientTransactionHistory('accNumber', tempCase.Id, START_DATE, END_DATE);
        Test.stopTest();

        System.assert(responseWrapper.statusCode == 500);
    }

    @IsTest
    static void testFailedProductResponse() {
        Case tempCase = [SELECT Id, Account_CIF_Number__c FROM Case WHERE Account_CIF_Number__c != '' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceTHMockResponse.failedProductResponse());
        Test.startTest();
        List<String> accList = Capitec_TransactionHistoryController.getFinancialAccountsNumbers(tempCase.Id);
        Test.stopTest();

        System.assert(accList.size() == 0);
    }

    @IsTest
    static void testFlagging() {
        Case tempCase = [SELECT Id, Account_CIF_Number__c FROM Case WHERE Account_CIF_Number__c != '' LIMIT 1];

        List<String> transIds = new List<String>();
        transIds.add('111');
        transIds.add('222');
        transIds.add('333');


        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceTHMockResponse());
        Test.startTest();
        Capitec_TransactionHistoryHelper.CapitecResponseStatus responseWrapper = Capitec_TransactionHistoryController.flagTransactions(transIds, tempCase.Id);
        Capitec_TransactionHistoryController.updateFlaggedTransactionTotalValue(tempCase.Id, transIds);
        Test.stopTest();

        System.assert(responseWrapper.statusCode == 200);

    }
}