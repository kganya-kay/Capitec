/*******************************************************************
* @Class Name        :  IC_API_SubmitRepudiation_TEST
* @Author            :  Ram
* @Last Modified By  :  Ram, 28-Oct-2024
* @Version           :  1.0 
*
*******************************************************************/
@IsTest
public class IC_API_SubmitRepudiation_TEST {
    @IsTest
    static void SubmitRepudiation_Success() {
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Create test data
        Account testAccount = IC_TestDataFactory.createSingleAccount();
        testAccount = [select id,CIF_Number__c,Name,PersonEmail from account where id=:testAccount.id];
        
         IC_Policy__c testPolicy = new IC_Policy__c(Name = 'PN123', IC_Date_Opened__c = Date.today(),IC_Refund_Amount__c=500);
        insert testPolicy;
        
        Case testCaseFuneral = IC_TestDataFactory.createSingleCase_Funeral();

        testCaseFuneral.AccountId = testAccount.Id;
        testCaseFuneral.IC_Deceased_Date_of_Death__c = Date.today();
        testCaseFuneral.IC_Lodge_Date__c = Date.today();
        testCaseFuneral.Description = 'Test Description';

        update testCaseFuneral;
		
        IC_Policy_Participant__c policyParticipant = new IC_Policy_Participant__c(
                IC_BenefitAmount__c = 100,
                IC_Cover_Amount__c = 200,
                IC_Policy_Number__c = testPolicy.Id,
            	IC_Calculated_Cover_Amount__c = 300,
                IC_Case__c = testCaseFuneral.Id,
            	IC_Relationship__c='Main Life'
        );
        insert policyParticipant;
        
        Case testCaseFuneralClaimant = IC_TestDataFactory.createSingleCase_Funeral_Claimant();

        testCaseFuneralClaimant.AccountId = testAccount.Id;
        testCaseFuneralClaimant.IC_Policy_Number_child__c = 'PN123';
        testCaseFuneralClaimant.IC_Claim_Number__c = 'CL123';
        testCaseFuneralClaimant.IC_Insurer_Claim_Reference__c = 'REF123';
        //testCaseFuneralClaimant.IC_RecommendedPayoutAmount__c = 5000;
        testCaseFuneralClaimant.IC_Decline_Reason__c = 'Decline Reason';
		testCaseFuneralClaimant.IC_Beneficiary__c = policyParticipant.Id;
        update testCaseFuneralClaimant;
        
		testCaseFuneralClaimant = [select id,IC_2nd_Decline_Reason__c,IC_Policy_Number_child__c,IC_Claim_Number__c,casenumber,IC_Insurer_Claim_Reference__c,IC_Decline_Reason__c,IC_RecommendedPayoutAmount__c from case where id=:testCaseFuneralClaimant.id];
       

        List<DocumentType> retrenchmentLetterDocType = [SELECT Id, MasterLabel FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];

        List<DocumentChecklistItem> docChecklistItems = IC_TestDataFactory.createDocumentChecklistItems(new Map<Case, List<DocumentType>>{
                testCaseFuneral => retrenchmentLetterDocType
        });

        // Create Requests object
        IC_API_SubmitRepudiation.Requests request = new IC_API_SubmitRepudiation.Requests();
        request.account = testAccount;
        request.childCase = testCaseFuneralClaimant;
        request.parentCase = testCaseFuneral;
        request.policy = testPolicy;
        request.documentChecklistItems = docChecklistItems;

        List<IC_API_SubmitRepudiation.Requests> requests = new List<IC_API_SubmitRepudiation.Requests>{
                request
        };

        System.debug('requests:' + requests);

        System.debug('requests:' + requests);

        Test.startTest();

        List<IC_API_SubmitRepudiation.Results> results = IC_API_SubmitRepudiation.submitRepudiationRequest(requests);

        Test.stopTest();

        System.debug('Results: ' + results);
        // Verify the results
        System.assertEquals(1, results.size());
        //System.assertEquals('Operation has completed successfully.', results[0].results[0]);
    }

    @IsTest
    static void SubmitRepudiation_Fail() {
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFail());

        // Create test data
        Account testAccount = IC_TestDataFactory.createSingleAccount();
        testAccount = [select id,CIF_Number__c,Name,PersonEmail from account where id=:testAccount.id];
        
         IC_Policy__c testPolicy = new IC_Policy__c(Name = 'PN123', IC_Date_Opened__c = Date.today(),IC_Refund_Amount__c=500);
        insert testPolicy;
        
        Case testCaseFuneral = IC_TestDataFactory.createSingleCase_Funeral();

        testCaseFuneral.AccountId = testAccount.Id;
        testCaseFuneral.IC_Deceased_Date_of_Death__c = Date.today();
        testCaseFuneral.IC_Lodge_Date__c = Date.today();
        testCaseFuneral.Description = 'Test Description';

        update testCaseFuneral;
		
        IC_Policy_Participant__c policyParticipant = new IC_Policy_Participant__c(
                IC_BenefitAmount__c = 100,
                IC_Cover_Amount__c = 200,
                IC_Policy_Number__c = testPolicy.Id,
            	IC_Calculated_Cover_Amount__c = 300,
                IC_Case__c = testCaseFuneral.Id,
            	IC_Relationship__c='Main Life'
        );
        insert policyParticipant;
        
        Case testCaseFuneralClaimant = IC_TestDataFactory.createSingleCase_Funeral_Claimant();

        testCaseFuneralClaimant.AccountId = testAccount.Id;
        testCaseFuneralClaimant.IC_Policy_Number_child__c = 'PN123';
        testCaseFuneralClaimant.IC_Claim_Number__c = 'CL123';
        testCaseFuneralClaimant.IC_Insurer_Claim_Reference__c = 'REF123';
        //testCaseFuneralClaimant.IC_RecommendedPayoutAmount__c = 5000;
        testCaseFuneralClaimant.IC_Decline_Reason__c = 'Decline Reason';
		testCaseFuneralClaimant.IC_Beneficiary__c = policyParticipant.Id;
        update testCaseFuneralClaimant;
        
		testCaseFuneralClaimant = [select id,IC_2nd_Decline_Reason__c,IC_Policy_Number_child__c,IC_Claim_Number__c,casenumber,IC_Insurer_Claim_Reference__c,IC_Decline_Reason__c,IC_RecommendedPayoutAmount__c from case where id=:testCaseFuneralClaimant.id];
       

        List<DocumentType> retrenchmentLetterDocType = [SELECT Id, MasterLabel FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];

        List<DocumentChecklistItem> docChecklistItems = IC_TestDataFactory.createDocumentChecklistItems(new Map<Case, List<DocumentType>>{
                testCaseFuneral => retrenchmentLetterDocType
        });

        // Create Requests object
        IC_API_SubmitRepudiation.Requests request = new IC_API_SubmitRepudiation.Requests();
        request.account = testAccount;
        request.childCase = testCaseFuneralClaimant;
        request.parentCase = testCaseFuneral;
        request.policy = testPolicy;
        request.documentChecklistItems = docChecklistItems;

        List<IC_API_SubmitRepudiation.Requests> requests = new List<IC_API_SubmitRepudiation.Requests>{
                request
        };

        System.debug('requests:' + requests);

        System.debug('requests:' + requests);

        Test.startTest();

        List<IC_API_SubmitRepudiation.Results> results = IC_API_SubmitRepudiation.submitRepudiationRequest(requests);

        Test.stopTest();

        System.debug('Results: ' + results);
        // Verify the results
        System.assertEquals(1, results.size());
    }
	@IsTest
    static void SubmitRepudiation_Fail1() {
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseFail());
        IC_API_SubmitRepudiation.submitRepudiationRequest(null);
    }
    @IsTest
    static void SubmitRepudiation_Fail2() {
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Create test data
        Account testAccount = IC_TestDataFactory.createSingleAccount();
        testAccount = [select id,CIF_Number__c,Name,PersonEmail from account where id=:testAccount.id];
        
         IC_Policy__c testPolicy = new IC_Policy__c(Name = 'PN123', IC_Date_Opened__c = Date.today(),IC_Refund_Amount__c=500);
        insert testPolicy;
        
        Case testCaseFuneral = IC_TestDataFactory.createSingleCase_Funeral();

        testCaseFuneral.AccountId = testAccount.Id;
        testCaseFuneral.IC_Deceased_Date_of_Death__c = Date.today();
        testCaseFuneral.IC_Lodge_Date__c = Date.today();
        testCaseFuneral.Description = 'Test Description';

        update testCaseFuneral;
		
        IC_Policy_Participant__c policyParticipant = new IC_Policy_Participant__c(
                IC_BenefitAmount__c = 100,
                IC_Cover_Amount__c = 200,
                IC_Policy_Number__c = testPolicy.Id,
            	IC_Calculated_Cover_Amount__c = 300,
                IC_Case__c = testCaseFuneral.Id,
            	IC_Relationship__c='Main Life'
        );
        insert policyParticipant;
        
        Case testCaseFuneralClaimant = IC_TestDataFactory.createSingleCase_Funeral_Claimant();

        testCaseFuneralClaimant.AccountId = testAccount.Id;
        testCaseFuneralClaimant.IC_Policy_Number_child__c = 'PN123';
        testCaseFuneralClaimant.IC_Claim_Number__c = 'CL123';
        testCaseFuneralClaimant.IC_Insurer_Claim_Reference__c = 'REF123';
        //testCaseFuneralClaimant.IC_RecommendedPayoutAmount__c = 5000;
        //testCaseFuneralClaimant.IC_Decline_Reason__c = 'Decline Reason';
		testCaseFuneralClaimant.IC_Beneficiary__c = policyParticipant.Id;
        update testCaseFuneralClaimant;
        
		testCaseFuneralClaimant = [select id,IC_2nd_Decline_Reason__c,IC_Policy_Number_child__c,IC_Claim_Number__c,casenumber,IC_Insurer_Claim_Reference__c,IC_Decline_Reason__c,IC_RecommendedPayoutAmount__c from case where id=:testCaseFuneralClaimant.id];
       

        List<DocumentType> retrenchmentLetterDocType = [SELECT Id, MasterLabel FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];

        List<DocumentChecklistItem> docChecklistItems = IC_TestDataFactory.createDocumentChecklistItems(new Map<Case, List<DocumentType>>{
                testCaseFuneral => retrenchmentLetterDocType
        });

        // Create Requests object
        IC_API_SubmitRepudiation.Requests request = new IC_API_SubmitRepudiation.Requests();
        request.account = testAccount;
        request.childCase = testCaseFuneralClaimant;
        request.parentCase = testCaseFuneral;
        request.policy = testPolicy;
        request.documentChecklistItems = docChecklistItems;

        List<IC_API_SubmitRepudiation.Requests> requests = new List<IC_API_SubmitRepudiation.Requests>{
                request
        };

        System.debug('requests:' + requests);

        System.debug('requests:' + requests);

        Test.startTest();

        List<IC_API_SubmitRepudiation.Results> results = IC_API_SubmitRepudiation.submitRepudiationRequest(requests);

        Test.stopTest();

        System.debug('Results: ' + results);
        // Verify the results
        System.assertEquals(1, results.size());
        //System.assertEquals('Operation has completed successfully.', results[0].results[0]);
    }
    private class MockHttpResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id": "12345"}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockHttpResponseFail implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": "Bad Request"}');
            res.setStatusCode(400);
            return res;
        }
    }
}