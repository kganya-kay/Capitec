/**
 * @description: Test class for Capitec_FlowSearchAccount.
 * @author     : Johan Langenhoven
 * @created    : 2024/09/15
 */
@IsTest(SeeAllData=false)
private class Capitec_FlowSearchAccountTest {

    /**
    * @description: Constant for the Person Account Record Type Id.
    */
    private static final Id PERSON_ACCOUNT_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

    /**
    * @description: Test setup method to create test data.
    */
    @TestSetup
    static void testSetup() {
        Account personAccount = new Account();

        personAccount.FirstName = 'John';
        personAccount.LastName = 'Doe';
        personAccount.ID_Type__c = 'SA Id';
        personAccount.Identity_Number__c = '1234567890123';
        personAccount.Passport_Number__c = 'P78477';
        personAccount.CIF_Number__c = '123456789';
        personAccount.AccountNumber = 'AccNUM1234';
        personAccount.RecordTypeId = PERSON_ACCOUNT_RECORD_TYPE_ID;

        insert personAccount;
    }

    /**
    * @description: Test method to verify search by Identity Number.
    */
    @IsTest
    static void testSearchAccountWithIdentityNumber() {
        Capitec_FlowSearchAccount.Requests request = new Capitec_FlowSearchAccount.Requests();
        request.identityNumber = '1234567890123';
        request.recordTypeId = PERSON_ACCOUNT_RECORD_TYPE_ID;

        List<Capitec_FlowSearchAccount.Requests> requests = new List<Capitec_FlowSearchAccount.Requests>{
                request
        };

        Test.startTest();

        List<Capitec_FlowSearchAccount.Results> results = Capitec_FlowSearchAccount.searchAccount(requests);

        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(1, results[0].accounts.size());
    }

    /**
    * @description: Test method to verify search by CIF Number.
    * */
    @IsTest
    static void testSearchAccountWithCifNumber() {

        Capitec_FlowSearchAccount.Requests request = new Capitec_FlowSearchAccount.Requests();
        request.cifNumber = '123456789';
        request.recordTypeId = PERSON_ACCOUNT_RECORD_TYPE_ID;

        List<Capitec_FlowSearchAccount.Requests> requests = new List<Capitec_FlowSearchAccount.Requests>{
                request
        };

        Test.startTest();

        List<Capitec_FlowSearchAccount.Results> results = Capitec_FlowSearchAccount.searchAccount(requests);

        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(1, results[0].accounts.size());
    }
}