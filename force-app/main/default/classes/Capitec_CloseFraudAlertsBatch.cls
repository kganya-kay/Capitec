/**
 * Created by CalebGovender on 2024/11/07.
 */
public class Capitec_CloseFraudAlertsBatch implements Database.Batchable<SObject>, Database.Stateful {
    // Define the scope of the batch
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('Starting batch processing.');
        String query = Capitec_CloseFraudBatchFunctions.buildFraudAlerts();
        return Database.getQueryLocator(query);
    }

    // Process each batch of records
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        System.debug('Scope: ' + scope.get(0));
        List<Case> casesToUpdate = new List<Case>();
        for (SObject sObj : scope) {
            Case cs = (Case)sObj;
            cs.Status = 'Not Fraud';
            cs.CM_Outcome__c = 'Auto Close';
            System.debug('Case ID: ' + cs.Id);
            casesToUpdate.add(cs);
        }

        update casesToUpdate;
    }

    // Finish method to execute after all batches are processed
    public void finish(Database.BatchableContext BC) {
        // Perform any final actions
        System.debug('Batch processing completed.');
    }
}