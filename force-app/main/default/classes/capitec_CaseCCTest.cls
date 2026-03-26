/**
 * @description Unit test class for the capitec_CaseCC utility class.
 * This test class verifies the validation logic to ensure cases cannot be closed 
 * unless all related disputes are resolved.
 */
@IsTest(SeeAllData=false)
private class capitec_CaseCCTest {

    /**
     * @description Record Type ID for Person Account, retrieved dynamically at runtime.
     * Used to create test Account records with the appropriate record type.
     */
    private static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID =
            Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

    /**
     * @description Test setup method to create sample data required for test execution.
     * It inserts an Account, a Capitec Pay case, associated disputes, and dispute items.
     */
    @TestSetup
    static void setup() {
        // Create a test Account record
        Account account = new Account(
                FirstName = 'John',
                LastName = 'Doe',
                RecordTypeId = PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                CIF_Number__c = '123456789',
                Identity_Number__c = '7101180046087'
        );
        insert account;

        // Create a test Case record with Capitec Pay record type
        Case capitecPayCase = new Case(
                Subject = 'Test Case',
                Description = 'Test Description',
                Status = 'New',
                Capitec_Primary_Need__c = 'CapitecPay Transaction Dispute',
                Capitec_Specific_Need__c = 'Credit not processed',
                CM_Channel__c = 'Contact Centre - voice',
                CM_Product__c = 'Credit Card',
                AccountId = account.Id,
                RecordTypeId = capitec_CaseCC.RT_CAPITEC_PAY_ID
        );
        insert capitecPayCase;

        // Create and insert test Dispute records linked to the case
        List<Dispute> disputes = new List<Dispute>();
        Dispute dispute = new Dispute(
                Status = 'In Review',
                CaseId = capitecPayCase.Id,
                RecordTypeId = capitec_DisputeCC.RT_CAPITEC_PAY_ID,
                ReceivedDate = Date.today()
        );
        disputes.add(dispute);
        insert disputes;

        // Create and insert test DisputeItem records linked to the dispute
        List<DisputeItem> disputeItems = new List<DisputeItem>();
        DisputeItem disputeItem1 = new DisputeItem(
                DisputeId = dispute.Id,
                Status = 'In Review',
                TransactionDate = Date.today()
        );
        disputeItems.add(disputeItem1);
        insert disputeItems;
    }

    /**
     * @description Test method to verify the case closure validation logic.
     * Ensures that a case cannot be closed if associated disputes remain unresolved.
     *
     * @test Expected Behavior: 
     * - The update operation should fail with an error message when attempting to close the case.
     */
    @IsTest
    static void testValidateCaseClosureWithError() {
        // Retrieve the test case with the Capitec Pay record type
        List<Case> capitecPayCases = [
                SELECT Id, Status, RecordTypeId
                FROM Case
                WHERE RecordTypeId = :capitec_CaseCC.RT_CAPITEC_PAY_ID
        ];
        Case capitecPayCase = capitecPayCases[0];

        // Attempt to update the status to 'Closed'
        capitecPayCase.Status = 'Closed';

        Test.startTest();
        // Try updating the case, expecting validation failure
        Database.SaveResult sr = Database.update(capitecPayCase, false);
        Test.stopTest();

        // Assert that the update operation failed due to unresolved disputes
        System.assertEquals(false, sr.isSuccess(), 'Expected the update to fail due to unresolved disputes.');

        // Verify that exactly one validation error is returned
        System.assertEquals(1, sr.getErrors().size(), 'Expected one validation error.');

        // Verify the correct error message is displayed
        System.assertEquals(
                'Case cannot be closed until all disputes are resolved.',
                sr.getErrors()[0].getMessage(),
                'Expected validation error message did not match.'
        );
    }
}