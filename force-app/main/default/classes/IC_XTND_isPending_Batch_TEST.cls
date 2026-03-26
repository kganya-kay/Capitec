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
    @ Modification Description : Updated test to cater for changes in the flow. 
	@ - Above Threshold cases now go to the IC_Waiting_for_XTND_Response queue.
	@ - Above Threshold cases now also creates IC_Insurance_Financial_Crime__c records.
===================================
    @ Last Modified By  : Jason Folding
    @ Last Modified On  : 16 Jan 2025
    @ Modification Description : Added a test for new flow logic which routes cases to the xtnd error queue.

**********************************
* SCHEDULING NOTES
**********************************S
In order to schedule the class, execute the following Anonymous Apex:

    IC_XTND_isPending_Batch.scheduleBatchJob(5);

If any changes need to be made, you will need to remove the scheduled job first:

    IC_XTND_isPending_Batch.cancelXTNDScheduledBatchJobs();
**********************************/




@IsTest
public with sharing class IC_XTND_isPending_Batch_TEST {

    static final String QUEUE_DEVNAME_WAITING_FOR_XTND_RESPONSE = 'IC_Waiting_for_XTND_Response';
    static final String RECORDTYPE_DEVNAME_INSURANCE_CLAIMS = 'Insurance_Claims';
    static final String QUEUE_DEVNAME_XTND_CHECK_IN_PROGRESS = 'IC_XTND_check_in_progress';
    static final String QUEUE_DEVNAME_XTND_ERROR = 'IC_XTND_Error_Queue';
    private static Case generateCase(String subject, Id ownerId, Id recordTypeId){
        Case testCase = new Case(
                Status = 'New',
                Subject = subject,
                Origin = 'Email',
                RecordTypeId = recordTypeId,
                OwnerId = ownerId,
                IC_PreviousOwner__c = System.UserInfo.getUserId());
        return testCase;
    }

    @TestSetup
    static void testSetup(){
        
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_DEVNAME_INSURANCE_CLAIMS).getRecordTypeId();

        //create cases
        Group ownerQueue = [SELECT Id, Name FROM Group WHERE DeveloperName = :QUEUE_DEVNAME_XTND_CHECK_IN_PROGRESS];
        Case testCase1 = generateCase('TestCase1',ownerQueue.Id, recordTypeId);

        insert testCase1;

        Case testCase2 = generateCase('TestCase2',ownerQueue.Id, recordTypeId);
        testCase2.IC_RiskScore__c = 'XTND Pending Assessment - Requested at ' + System.now();
        insert testCase2;

    }

    /**
     * @description Check batch job with positive outcome (records to update)
     */
    @IsTest
    private static void testXTND_Batch_Positive_1PerBatch(){
        // Set HTTP callout mock to match flow's external service action invocation
        Test.setMock(HttpCalloutMock.class, new XTNDHttpCalloutMock());

        Test.startTest();
        IC_XTND_isPending_Batch xtnd = new IC_XTND_isPending_Batch (1);
        database.executebatch(xtnd);
        Test.stopTest();

        Case c = [SELECT Id, CaseNumber, OwnerId, IC_PreviousOwner__c, IC_RiskScoreAboveRiskThreshold__c, IC_RiskScore__c, Status, Sub_Status__c FROM Case WHERE Subject = 'TestCase1' LIMIT 1];
        Group waitingForXTNDQueue = [SELECT Id, Name FROM Group WHERE DeveloperName = :QUEUE_DEVNAME_WAITING_FOR_XTND_RESPONSE];
        System.assertEquals('Above Threshold', c.IC_RiskScore__c, 'Unexpected Risk Score');
        System.assertEquals(waitingForXTNDQueue.Id,c.OwnerId,'Unexpected Owner');
        System.assertEquals('Escalated For Review',c.Status,'Unexpected Status');
        System.assertEquals('Validation',c.Sub_Status__c,'Unexpected Sub Status');

    }

    /**
     * @description Check batch job with positive outcome (records to update)
     */
    @IsTest
    private static void testXTND_Batch_BelowThreshold(){
        // Set HTTP callout mock to match flow's external service action invocation
        Test.setMock(HttpCalloutMock.class, new XTNDHttpCalloutMockBelowThreshold());

        Test.startTest();
        IC_XTND_isPending_Batch xtnd = new IC_XTND_isPending_Batch ();
        database.executebatch(xtnd);
        Test.stopTest();

        Case c = [SELECT Id, CaseNumber, OwnerId, IC_PreviousOwner__c, IC_RiskScoreAboveRiskThreshold__c, IC_RiskScore__c FROM Case WHERE Subject = 'TestCase1' LIMIT 1];
        System.assertEquals('Below Threshold', c.IC_RiskScore__c, 'Unexpected Risk Score');
        System.assertEquals(System.UserInfo.getUserId(),c.OwnerId,'Unexpected Owner');

        // Check for InsuranceFinancialCrimes records
        List<IC_Insurance_Financial_Crime__c> financialCrimesRecords = [SELECT Id, IC_Case__c, IC_Status__c, IC_Source__c, IC_Message__c FROM IC_Insurance_Financial_Crime__c WHERE IC_Case__c =: c.Id];
        System.assertEquals(0,financialCrimesRecords.size(),'Did not expect Insurance Financial Crimes records to be created.');

    }

    /**
     * @description Check batch job with positive outcome (records to update)
     */
    @IsTest
    private static void testXTND_Batch_Positive(){
        
        // Set HTTP callout mock to match flow's external service action invocation
        Test.setMock(HttpCalloutMock.class, new XTNDHttpCalloutMock());

        Test.startTest();
        IC_XTND_isPending_Batch xtnd = new IC_XTND_isPending_Batch ();
        database.executebatch(xtnd);
        Test.stopTest();

        Case c = [SELECT Id, CaseNumber, OwnerId, IC_PreviousOwner__c, IC_RiskScoreAboveRiskThreshold__c, IC_RiskScore__c FROM Case WHERE Subject = 'TestCase1' LIMIT 1];
        Group waitingForXTNDQueue = [SELECT Id, Name FROM Group WHERE DeveloperName = :QUEUE_DEVNAME_WAITING_FOR_XTND_RESPONSE];

        System.assertEquals('Above Threshold', c.IC_RiskScore__c, 'Unexpected Risk Score');
        System.assertEquals(waitingForXTNDQueue.Id,c.OwnerId,'Unexpected Owner');

        // Check for InsuranceFinancialCrimes records
        List<IC_Insurance_Financial_Crime__c> financialCrimesRecords = [SELECT Id, IC_Case__c, IC_Status__c, IC_Source__c, IC_Message__c FROM IC_Insurance_Financial_Crime__c WHERE IC_Case__c =: c.Id];
        Assert.isNotNull(financialCrimesRecords, 'Expected Insurance Financial Crimes records to be created.');
        Assert.isTrue(financialCrimesRecords.size() > 0, 'Expected at least 1 Insurance Financial Crimes record to be created.');

    }

    /**
     * @description Check batch job with negative outcome (NO records to update)
     */
    @IsTest
    private static void testXTND_Batch_Negative(){
        // Set HTTP callout mock to match flow's external service action invocation
        Test.setMock(HttpCalloutMock.class, new XTNDHttpCalloutMockPending());

        Test.startTest();
        IC_XTND_isPending_Batch xtnd = new IC_XTND_isPending_Batch ();
        database.executebatch(xtnd);
        Test.stopTest();

        Case c = [SELECT Id, CaseNumber, OwnerId, IC_PreviousOwner__c, IC_RiskScoreAboveRiskThreshold__c, IC_RiskScore__c FROM Case WHERE Subject = 'TestCase1' LIMIT 1];
        System.assertEquals('XTND Pending Assessment', c.IC_RiskScore__c.left(23), 'Unexpected Risk Score');
        System.assertEquals('[Iteration: 1]', c.IC_RiskScore__c.right(14), 'Unexpected Risk Score');
        System.assertNotEquals(System.UserInfo.getUserId(),c.OwnerId,'Unexpected Owner');

        Case c2 = [SELECT Id, CaseNumber, OwnerId, IC_PreviousOwner__c, IC_RiskScoreAboveRiskThreshold__c, IC_RiskScore__c FROM Case WHERE Subject = 'TestCase2' LIMIT 1];
        System.assertEquals('XTND Pending Assessment', c2.IC_RiskScore__c.left(23), 'Unexpected Risk Score');
        System.assertEquals('[Iteration: 1]', c2.IC_RiskScore__c.right(14), 'Unexpected Risk Score');
        System.assertNotEquals(System.UserInfo.getUserId(),c2.OwnerId,'Unexpected Owner');

    }

    /**
     * @description Check batch job with claim not found outcome
     */
    @IsTest
    private static void testXTND_Batch_Claim_Not_Found(){
        // Set HTTP callout mock to match flow's external service action invocation
        Test.setMock(HttpCalloutMock.class, new XTNDHttpCalloutMockError());

        Test.startTest();
        IC_XTND_isPending_Batch xtnd = new IC_XTND_isPending_Batch ();
        database.executebatch(xtnd);
        Test.stopTest();

        Group XTND_ERROR_QUEUE = [SELECT Id, Name FROM Group WHERE DeveloperName = : QUEUE_DEVNAME_XTND_ERROR];

        Case c = [SELECT Id, CaseNumber, OwnerId, IC_PreviousOwner__c, IC_RiskScoreAboveRiskThreshold__c, IC_RiskScore__c FROM Case WHERE Subject = 'TestCase1' LIMIT 1];
        System.assertEquals(XTND_ERROR_QUEUE.Id, c.OwnerId, 'Expected the Owner to be ' + XTND_ERROR_QUEUE.Name);
    }

    /**
     * @description Check batch job with scheduler function
     */
    @IsTest
    private static void testScheduleBatchJobAndCancel(){
        // Set HTTP callout mock to match flow's external service action invocation
        Test.setMock(HttpCalloutMock.class, new XTNDHttpCalloutMock());

        Test.startTest();
        IC_XTND_isPending_Batch.scheduleBatchJob(60);
        IC_XTND_isPending_Batch.cancelXTNDScheduledBatchJobs();
        Test.stopTest();

    }

    /**
     * @description Check batch job with scheduler function
     */
    @IsTest
    private static void testXTND_Batch_scheduler(){
        // Set HTTP callout mock to match flow's external service action invocation
        Test.setMock(HttpCalloutMock.class, new XTNDHttpCalloutMock());

        Test.startTest();
        IC_XTND_isPending_Batch xtnd = new IC_XTND_isPending_Batch();
        String sch = '0 1 * * * ?';
        String jobID = System.schedule('XTND Job', sch, xtnd);
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
        FROM CronTrigger WHERE id = :jobId];
        System.assertNotEquals(NULL,ct,'Unexpected Cron Trigger');
    }




//=============================================================================================
//  HELPER METHODS - HTTP MOCKS
//=============================================================================================

    public class XTNDHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {

            // Send response test data
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{ "results_set" : true, "results" : [ { "value_set" : true, "value" : "", "reference_set" : true, "reference" : "00512588", "description_set" : true, "description" : "Above Threshold", "code_set" : true, "code" : "1" } ] }');
            response.setStatusCode(200);
            return response;
        }
    }

    public class XTNDHttpCalloutMockBelowThreshold implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {

            // Send response test data
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{ "results_set" : true, "results" : [ { "value_set" : true, "value" : "", "reference_set" : true, "reference" : "00512588", "description_set" : true, "description" : "Below Threshold", "code_set" : true, "code" : "1" } ] }');
            response.setStatusCode(200);
            return response;
        }
    }

    public class XTNDHttpCalloutMockPending implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {

            // Send response test data
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{ "results_set" : true, "results" : [ { "value_set" : true, "value" : "", "reference_set" : true, "reference" : "00512588", "description_set" : true, "description" : "Pending Assessment", "code_set" : true, "code" : "1" } ] }');
            response.setStatusCode(200);
            return response;
        }
    }

    public class XTNDHttpCalloutMockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {

            // Send response test data
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"results_set": true,"results": [{"value_set": true,"value": "","reference_set": true,"reference": "01634022","description_set": true,"description": "The claim cannot be found.","code_set": true,"code": "-102"}]}');
            response.setStatusCode(200);
            return response;
        }
    }

}