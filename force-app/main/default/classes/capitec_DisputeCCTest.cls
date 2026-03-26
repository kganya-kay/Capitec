/**
 * @description Unit test class for the capitec_DisputeTRH trigger handler.
 * This test class verifies the correct behavior of dispute resolution validation logic
 * to ensure disputes cannot be resolved unless all related dispute items are settled.
 */
@IsTest(SeeAllData=false)
private class capitec_DisputeCCTest {

    /**
     * @description Test setup method to create test data for Dispute and DisputeItem records.
     * This data will be used in test methods to validate business logic.
     */
    @TestSetup
    static void setup() {
        // Create a list to store test dispute records
        List<Dispute> disputes = new List<Dispute>();

        // Create and initialize a test Dispute record
        Dispute dispute = new Dispute(
                Status = 'In Review',
                RecordTypeId = capitec_DisputeCC.RT_CAPITEC_PAY_ID,
                ReceivedDate = Date.today()
        );
        disputes.add(dispute);

        // Insert the dispute records into the database
        insert disputes;

        // Create a list to store test dispute item records
        List<DisputeItem> disputeItems = new List<DisputeItem>();

        // Create and initialize a test DisputeItem record linked to the dispute
        DisputeItem disputeItem1 = new DisputeItem(
                DisputeId = dispute.Id,
                Status = 'In Review',
                TransactionDate = Date.today()
        );
        disputeItems.add(disputeItem1);

        // Insert the dispute item records into the database
        insert disputeItems;
    }

    /**
     * @description Test method to verify the validation logic when attempting to resolve a dispute
     * with unsettled dispute items.
     *
     * This test ensures that the beforeUpdate trigger prevents disputes from being resolved
     * if any related dispute items have not been settled.
     */
    @IsTest
    static void testValidateDisputeResolutionWithError() {
        // Retrieve the inserted test dispute record
        List<Dispute> disputes = [SELECT Id, Status, RecordTypeId FROM Dispute];
        Dispute dispute = disputes[0];

        // Attempt to update the status to 'Resolved'
        dispute.Status = 'Resolved';

        Test.startTest();

        // Try to update the dispute, expecting validation to prevent the update
        Database.SaveResult sr = Database.update(dispute, false);

        Test.stopTest();

        // Assert that the update operation failed as expected
        System.assertEquals(false, sr.isSuccess(), 'Expected the update to fail due to unsettled dispute items.');

        // Validate that an error was added to the record
        System.assertEquals(1, sr.getErrors().size(), 'Expected one validation error.');

        // Verify the expected error message
        System.assertEquals(
                'Dispute cannot be resolved until all dispute items are settled.',
                sr.getErrors()[0].getMessage(),
                'Expected validation error message did not match.'
        );
    }
}