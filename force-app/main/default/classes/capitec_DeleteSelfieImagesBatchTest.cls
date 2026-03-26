@isTest
public class capitec_DeleteSelfieImagesBatchTest {
    @isTest
    static void testBatchProcessing() {

        //added mock due to the class Capitec_ContentVersionDMN that execute with all contentVersion
        Test.setMock(HttpCalloutMock.class, new Capitec_DocumentumMock.correctResponse());

        // Setup: Create a record type for Fraud Case if it doesn't exist
        RecordType fraudRecordType  = [SELECT Id FROM RecordType WHERE Name = 'Fraud Record Type' LIMIT 1];

        // Create Account and Case records
        Account testAccount = new Account(Name = 'Test Account', CIF_Number__c = '12345');
        insert testAccount;
        
        Case testCase = new Case(AccountId = testAccount.Id, 
                            RecordTypeId = fraudRecordType.Id,
                            Status = 'Closed',
                            IC_Trigger_Finalise_Claim__c = true,
                            FR_Repatriation_Amount__c = 99,
                            Subject = 'Test',
                            Description = 'Test',
                            Alert_Comments__c = 'Test',
                            Alert_Conclusion__c = 'Test',
                            Capitec_Category__c = 'Card',
                            Capitec_Sub_Category__c = 'Mule',
                            Modus_Operandi__c = 'SAFPS',
                            Capitec_Primary_Need__c = 'Fraud',
                            Capitec_Specific_Need__c = 'Theft',
                            FR_Decision_Tree_Completed__c = true
                           );
        insert testCase;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Selfie_image',
            PathOnClient = 'Selfie_image.jpg',
            VersionData = Blob.valueOf('Test data'),
            FirstPublishLocationId = testCase.Id
        );
        insert contentVersion;

        ContentVersion cV = [SELECT Id, ContentDocumentId, FirstPublishLocationId FROM ContentVersion
        WHERE Id = :contentVersion.Id];

        ContentDocumentLink contentLink = new ContentDocumentLink(
            LinkedEntityId = testAccount.Id,
            ContentDocumentId = cV.ContentDocumentId, 
            ShareType = 'V'
        );
        insert contentLink;

        // Run the batch process
        Test.startTest();
        capitec_DeleteSelfieImagesBatch batchInstance = new capitec_DeleteSelfieImagesBatch();
        Database.executeBatch(batchInstance, 1);
        Test.stopTest();

        // Assertions

        // Check that the ContentDocument was deleted
        List<ContentDocument> docsAfterBatch = [SELECT Id FROM ContentDocument WHERE Id = :cV.ContentDocumentId];
        System.assertEquals(0, docsAfterBatch.size(), 'ContentDocument should be deleted by the batch.');

        // Verify IC_Trigger_Finalise_Claim__c field is updated to false for the test case
        Case updatedCase = [SELECT IC_Trigger_Finalise_Claim__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(false, updatedCase.IC_Trigger_Finalise_Claim__c, 'IC_Trigger_Finalise_Claim__c should be set to false.');
    }
    
    @isTest
    static void testSelfieDeletionScheduler() {
        // Create an instance of the scheduler class
        capitec_SelfieDeletionScheduler scheduler = new capitec_SelfieDeletionScheduler();

        Test.startTest();
        // Execute the scheduled job
        scheduler.execute(null);
        Test.stopTest();

    }
}