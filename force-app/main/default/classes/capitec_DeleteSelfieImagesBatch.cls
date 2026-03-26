global class capitec_DeleteSelfieImagesBatch implements Database.Batchable<SObject> {
    // Retrieve closed cases with IC_Trigger_Finalise_Claim__c = true
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id 
            FROM Case 
            WHERE recordType.Name = 'Fraud Record Type'
            AND IsClosed = true 
            AND IC_Trigger_Finalise_Claim__c = true 
        ]);
    }

    // Process each case in batches
    global void execute(Database.BatchableContext BC, List<Case> scope) {
        System.debug('capitec_DeleteSelfieImagesBatch Scope '+scope);
        // Collect Case Ids from the scope for querying ContentVersion records
        Set<Id> caseIds = new Set<Id>();
        for (Case c : scope) {
            caseIds.add(c.Id);
        }
        
        // Query ContentVersion records for these cases titled with 'Selfie' to retrieve ContentDocumentIds
        List<ContentVersion> selfieVersions = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE FirstPublishLocationId IN :caseIds AND Title LIKE 'Selfie%'
        ];

        // Collect ContentDocumentIds from the ContentVersion records
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentVersion version : selfieVersions) {
            contentDocumentIds.add(version.ContentDocumentId);
        }

        // Delete the ContentDocument records
        if (!contentDocumentIds.isEmpty()) {
            delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIds];
        }
        
        // Update IC_Trigger_Finalise_Claim__c to false for all cases in scope
        for (Case c : scope) {
            c.IC_Trigger_Finalise_Claim__c = false;
        }
        update scope;
    }

    global void finish(Database.BatchableContext BC) {
        // Optional: Add any post-processing logic here, such as logging or sending notifications
    }
}