/**
* Author           Ridwan Moosuddee
* Company          BlueSky
* Date             07/11/2023
* Description      Test Class for IC_API_FinaliseClaimDecline
**/
@isTest
private class IC_API_FinaliseClaimDecline_TEST {

    @testSetup
    static void setup() {
        IC_TestDataFactory.createSingleCase();
    }
    
    @isTest 
    static void test_finaliseClaimDeclineCallout() {
        
        Case insertedCase = [SELECT CaseNumber, IC_Policy_Number_child__c, CIF_Number__c, IC_Decline_Reason__c, IC_Group_of_Insurance_Contracts__c FROM Case LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockFinaliseDeclineCallout());
        
        IC_API_FinaliseClaimDecline.FlowRequestVariables req = new IC_API_FinaliseClaimDecline.FlowRequestVariables();
        req.caseNumber = insertedCase.CaseNumber;
        req.policyNumber = insertedCase.IC_Policy_Number_child__c;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = Date.today();
        req.declineReason = insertedCase.IC_Decline_Reason__c;
        req.groupOfInsuranceContracts = insertedCase.IC_Group_of_Insurance_Contracts__c;
        
        List<IC_API_FinaliseClaimDecline.FlowRequestVariables> reqList = new List<IC_API_FinaliseClaimDecline.FlowRequestVariables>{ req };
        
        Test.startTest();
        	List<String> results = IC_API_FinaliseClaimDecline.makeDeclineFinaliseClaimCallout(reqList);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
    }
    
    // Mock for HTTP callout
    public class MockFinaliseDeclineCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"count":1,"items":[{"caseNumber":"12345","policyNumber":"PolNumber12345", "cifNumber":"12345","eventDate":"2023-11-01","declineReason":"WaitingPeriod"}]}');
			res.setStatusCode(200);
            return res;
        }
    }
    
     // This mock class simulates an HTTP error response with a specific format
    private class MockPolicyCalloutError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            // Simulate an error response body in the specified format
            res.setBody('{' +
                        '"Title": "Bad Request",' +
                        '"Detail": [' +
                        '{' +
                        '"PropertyName": "CifNumber",' +
                        '"ErrorMessage": "\'Cif Number\' must not be empty."' +
                        '}' +
                        '],' +
                        '"Status": 400' +
                        '}');
            res.setStatusCode(400);
            return res;
        }
    }
    
    @IsTest
    static void test_makePolicyCallout_HttpError() {
        // Setup test data
        Case insertedCase = [SELECT CaseNumber, IC_Policy_Number_child__c, CIF_Number__c, IC_Decline_Reason__c, IC_Group_of_Insurance_Contracts__c FROM Case LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse for an error scenario using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockPolicyCalloutError());
        
        // Create a new FlowRequest with data from the test case
        IC_API_FinaliseClaimDecline.FlowRequestVariables req = new IC_API_FinaliseClaimDecline.FlowRequestVariables();
        req.caseNumber = insertedCase.CaseNumber;
        req.policyNumber = insertedCase.IC_Policy_Number_child__c;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = Date.today();
        req.declineReason = insertedCase.IC_Decline_Reason__c;
        req.groupOfInsuranceContracts = insertedCase.IC_Group_of_Insurance_Contracts__c;
        
        // Wrap in a list as expected by the method being tested
        List<IC_API_FinaliseClaimDecline.FlowRequestVariables> reqList = new List<IC_API_FinaliseClaimDecline.FlowRequestVariables>{ req };
            
            // Make the callout within test context
        Test.startTest();
        	List<String> results = IC_API_FinaliseClaimDecline.makeDeclineFinaliseClaimCallout(reqList);
        Test.stopTest();
        
        // Assert that the results contain the expected error messages
        //System.debug('Message: ' + results[0]);
        System.assertEquals(2, results.size(), 'There should be two entries in results - one for the detail error message and one for the HTTP status error.');
        System.assert(results[0].contains('Error: CifNumber - \'Cif Number\' must not be empty.'), 'The property name and error message should match the mock response');
        System.assert(results[1].startsWith('HTTP Error: 400'), 'The results should contain the HTTP error message.');
    }    
}