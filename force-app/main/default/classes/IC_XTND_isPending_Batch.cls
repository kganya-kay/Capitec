/********************************\
    @ Func Area     : IC Funeral - XTND Pending Results
    @ Author        : Gerhard de Klerk
    @ Date          : 31 Oct 2024
    @ Description   : Check for XNTD results on cases in the relevant queue
    @ Related files :
    @ Test File     : IC_XTND_isPending_Batch_TEST
                    :
===================================
    @ Last Modified By  : Jason Folding
    @ Last Modified On  : 04 Nov 2024
    @ Modification Description : Insert InsuranceFinancialCrimesRecord from the flow.
	@ -
	@ -
===================================
**********************************/
global class IC_XTND_isPending_Batch implements Database.Batchable<sObject>,Database.AllowsCallouts, Schedulable{

    //GLOBAL VARIABLES
    public integer RecordsInserted=0;
    public integer RecordsUpdated=0;
    public integer RecordsDeleted=0;
    public string RecordInsertFailures;
    public string RecordUpdateFailures;
    public string RecordDeleteFailures;

    public Integer recordsPerBatch = null;

    global IC_XTND_isPending_Batch(){}

    global IC_XTND_isPending_Batch(Integer recordsPerBatch){
        recordsPerBatch = recordsPerBatch;
    }

    //SCHEDULE THE BATCHABLE CONTEXTS
    global void execute(SchedulableContext sc)
    {
        IC_XTND_isPending_Batch xtnd = new IC_XTND_isPending_Batch ();
        if (recordsPerBatch != null){
            database.executebatch(xtnd,recordsPerBatch);
        }else{
            database.executebatch(xtnd);
        }

    }



    // QUERY LOCATOR (USUALLY THE BIG SELECT STATEMENT)
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Total number of records retrieved by Database.getQueryLocator	10,000
        String caseOwnerName = 'XTND check in progress';//name of Queue
        String Query = 'SELECT Id, CaseNumber, OwnerId, IC_PreviousOwner__c,IC_RiskScore__c FROM Case WHERE Case_Owner_Name__c = \'' + caseOwnerName + '\' ORDER BY LastModifiedDate ASC LIMIT 150';
        System.debug('---Query -- '+ Query);
        return Database.getQueryLocator(Query);
    }

    global void execute(Database.BatchableContext BC, List<Case> scope){

        List<Case> casesToUpdate = new List<Case>();
        List<IC_Insurance_Financial_Crime__c> insuranceFinancialCrimesRecords = new List<IC_Insurance_Financial_Crime__c>();

        for (Case c: scope) {
            System.debug('Case: ' + c);


            // Prepare the Flow variables
            Map<String, Object> params = new Map<String, Object>();
            params.put('caseRecord', c);

            // Instantiate and start the Flow
            Flow.Interview.IC_XTND_Outcome_Check flowIC_XTND_Outcome_Check = new Flow.Interview.IC_XTND_Outcome_Check(params);
            flowIC_XTND_Outcome_Check.start();

            Boolean pendingResults = (Boolean)flowIC_XTND_Outcome_Check.getVariableValue('isPendingResults');
            
            //Update Case
            Case caseResult = (Case)flowIC_XTND_Outcome_Check.getVariableValue('caseRecord');
            casesToUpdate.add(caseResult);
            
            // Get Insurance Financial Crime record
            IC_Insurance_Financial_Crime__c financialCrimeRecord = (IC_Insurance_Financial_Crime__c)flowIC_XTND_Outcome_Check.getVariableValue('InsuranceFinancialCrimesRecord');
            insuranceFinancialCrimesRecords.add(financialCrimeRecord);
            

        }
        system.debug('***CASES TO UPDATE: ' + casesToUpdate);

        try{
            if(casesToUpdate.size() >0){
                database.saveresult[] ds =  Database.update(casesToUpdate,false);
                for(database.SaveResult d : ds){
                    if(d.issuccess()){
                        RecordsInserted++;
                    }
                    else
                    {
                        for (Database.Error err : d.getErrors()){
                            RecordInsertFailures += 'Error updating Case records: '+ err.getStatusCode() + ' ' + err.getMessage();
                        }
                    }
                }
                System.debug('Case Records updated.');
            }
        }
        catch (Exception e){
            System.debug(e);
        }

        try{
            if(insuranceFinancialCrimesRecords.size() >0){
                database.saveresult[] ds =  Database.insert(insuranceFinancialCrimesRecords,false);
                for(database.SaveResult d : ds){
                    if(d.issuccess()){
                        RecordsInserted++;
                    }
                    else
                    {
                        for (Database.Error err : d.getErrors()){
                            RecordInsertFailures += 'Error inserting InsuranceFinancialCrime records: '+ err.getStatusCode() + ' ' + err.getMessage();
                        }
                    }
                }
                System.debug('InsuranceFinancialCrime Records inserted.');
            }
        }
        catch (Exception e){
            System.debug(e);
        }
    }

    global void finish(Database.BatchableContext BC){
    }


    public static void scheduleBatchJob(Integer minutes){
        Integer hour = 60;
        Integer iterations = hour / minutes;
        for (integer i = 0; i< iterations; i++ ){
            String cronExpression = '0 ' + i*minutes + ' * * * ?';
            IC_XTND_isPending_Batch xtnd = new IC_XTND_isPending_Batch(1); //the 1 here allows the batch to run serially due to bulk issues in triggers
            String jobName = 'IC_XTND_isPending_Batch - Every ' + minutes + ' Minutes - iteration ' + i;
            if( Test.isRunningTest()){
                jobName = 'TEST_' + jobName;
            }
            String jobID = System.schedule(jobName, cronExpression, xtnd);
            system.debug('JobId: ' + jobId + ' - ' + jobName + ' - Cron Expression: ' + cronExpression);
        }
    }

    public static void cancelXTNDScheduledBatchJobs(){
        String jobName = 'IC_XTND_isPending_Batch%';
        if( Test.isRunningTest()){
            jobName = 'TEST_' + jobName;
        }
        List<CronTrigger> cronJobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger where CronJobDetail.Name LIKE :jobName];
        for(CronTrigger job : cronJobs )
        {
            System.debug('Aborted: ' + job.CronJobDetail.Name);
            System.abortJob(job.Id);
        }
    }

}