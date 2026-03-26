global class capitec_SelfieDeletionScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Execute the batch job
        capitec_DeleteSelfieImagesBatch batchJob = new capitec_DeleteSelfieImagesBatch();
        Integer batchSize = 200; // Adjust batch size if needed
        Database.executeBatch(batchJob, batchSize);
    }
}