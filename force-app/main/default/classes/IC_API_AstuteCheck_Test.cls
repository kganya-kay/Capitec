@isTest
private class IC_API_AstuteCheck_Test {
    
    @testSetup
    static void setup() {
        IC_TestDataFactory.createSingleAstuteCase();
    }
    
    @isTest
    static void test_MakeDHAServiceCallout() {
        
        Case caseRecord = [SELECT Id, CaseNumber, IC_Deceased_Identity_Number__c, Product_Type__c, Sub_Type__c, Sub_Type_Reason__c, IC_DHA_Cause_of_Death__c, IC_DHA_Date_of_Birth__c, IC_DHA_Name__c, 
                           IC_DHA_Surname__c, IC_DHA_Date_of_Death__c, IC_DHA_Deceased_Indicator__c, IC_DHA_Gender__c, IC_DHA_ID_Number__c, 
                           IC_DHA_Marital_Status__c, IC_DHA_Place_of_Death__c, IC_DHA_Request_Date_Time__c, IC_DHA_Response_Code__c, 
                           IC_DHA_Response_Message__c, IC_DHA_Transaction_Reference__c, IC_DHA_Under_Investigation__c, IC_DHA_Verified__c           
                           FROM Case 
                           /*WHERE CaseNumber = :request.caseNumber*/ 
                           LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse using HttpCalloutMock interface
        //Test.setMock(HttpCalloutMock.class, new MockPolicyCallout());
        
        // Create a test DHAServiceRequest
        IC_API_AstuteCheck.DHAServiceRequest testRequest = new IC_API_AstuteCheck.DHAServiceRequest();
        //testRequest.caseNumber = '00061113';       
        //testRequest.idReferenceNo = '8408030030081';
        //testRequest.transRefGuid = '9ef7a029-3b5d-4b8b-93d3-0c050cb2951a';
        //testRequest.trackingReference ='00061113';
        testRequest.caseNumber = caseRecord.CaseNumber;
        testRequest.idReferenceNo = caseRecord.IC_Deceased_Identity_Number__c; 
        
        //IC_API_AstuteCheck.VopdRequestDetails vopdTestRequest = new IC_API_AstuteCheck.VopdRequestDetails();
        //vopdTestRequest.vopdVerificationType = 2;
        //vopdTestRequest.messageID = '00061113';
        //vopdTestRequest.vopdIdType = 4;
        //vopdTestRequest.idReferenceNo = '';
        
        
        /*IC_API_AstuteCheck.DHAServiceRequest testRequest = new IC_API_AstuteCheck.DHAServiceRequest();
testRequest.caseNumber = 'TESTCASE123';
testRequest.DHAServiceRequest = new List<IC_API_AstuteCheck.DHAServiceRequest>();
IC_API_AstuteCheck.DHAServiceRequest requestDetails = new IC_API_AstuteCheck.DHAServiceRequest();
requestDetails.caseNumber = 'TESTCASE123';
requestDetails.IdReferenceNo = '1234567890';  // Replace with a valid ID
testRequest.DHAServiceRequest.add(requestDetails);*/
        
        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Test the main method
        Test.startTest();
        List<String> results = IC_API_AstuteCheck.makeDHAServiceCallout(new List<IC_API_AstuteCheck.DHAServiceRequest>{testRequest});
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(2, results.size()); // Assuming success and debug messages are added
        System.assertEquals('Success:', results[0].substring(0, 8));
        //System.assertEquals('00061113', results[0].IC_DHA_Name__c);
    }
    
    
    @IsTest
    static void test_makePolicyCallout_HttpError() {
        // Setup test data
        Case caseRecord = [SELECT Id, Product_Type__c, Sub_Type__c, Sub_Type_Reason__c, IC_DHA_Cause_of_Death__c, IC_DHA_Date_of_Birth__c, IC_DHA_Name__c, IC_DHA_Surname__c, IC_DHA_Date_of_Death__c, IC_DHA_Deceased_Indicator__c, IC_DHA_Gender__c, IC_DHA_ID_Number__c, IC_DHA_Marital_Status__c, IC_DHA_Place_of_Death__c, IC_DHA_Request_Date_Time__c, IC_DHA_Response_Code__c, IC_DHA_Response_Message__c, IC_DHA_Transaction_Reference__c, IC_DHA_Under_Investigation__c, IC_DHA_Verified__c           
                           FROM Case 
                           /*WHERE CaseNumber = :request.caseNumber*/ 
                           LIMIT 1];        
        // Mock the HttpRequest and HttpResponse for an error scenario using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockPolicyCalloutError());
        
        // Create a new FlowRequest with data from the test case
        IC_API_AstuteCheck.DHAServiceRequest req  = new IC_API_AstuteCheck.DHAServiceRequest();
        req.caseNumber = '00061113';       
        req.idReferenceNo = '8408030030081';
        req.transRefGuid = '9ef7a029-3b5d-4b8b-93d3-0c050cb2951a';
        req.trackingReference ='00061113';
        
        // Wrap in a list as expected by the method being tested
        List<IC_API_AstuteCheck.DHAServiceRequest> reqList = new List<IC_API_AstuteCheck.DHAServiceRequest>{ req };
            
            // Make the callout within test context
            Test.startTest();
        List<String> results = IC_API_AstuteCheck.makeDHAServiceCallout(reqList);
        Test.stopTest();
        
        // Assert that the results contain the expected error messages
        //System.debug('Message: ' + results[0]);
        System.assertEquals(2, results.size(), 'There should be two entries in results - one for the detail error message and one for the HTTP status error.');
        System.assert(results[0].contains('Error: CifNumber - \'Cif Number\' must not be empty.'), 'The property name and error message should match the mock response');
        System.assert(results[1].startsWith('HTTP Error: 400'), 'The results should contain the HTTP error message.');
    } 
    
    
    // Create a mock HTTP response for testing callouts
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            // Create a mock response with a success status code
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(200);
            // Mock response body (adjust based on your actual response structure)
            response.setBody('{"successful": true, "responseData": {"transRefGuid": "4fadc869-b094-4b91-9c64-f9301fe15c46", "trackingReference": "voploopbaccktest", "requestDateTime": "2024-02-20T13:43:19.923+00:00", "vopdRequestStatus": 4, "vopdRequestSource": 5, "verificationDetails": [{"gender": "F", "maritalStatus": "SINGLE", "dateOfDeath": "2022-11-01T00:00:00+00:00", "dateOfBirth": "1958-08-20T00:00:00+00:00", "placeOfDeath": "Mankweng", "causeOfDeath": "NATURAL CAUSES", "deathUnderInvestigation": false, "vopdVerificationType": 2, "idNumber": "5808203983086", "errorMessage": "null", "smartId": "null", "surname": "Doe", "forename": "John", "deceasedStatus": "Deceased", "requestMessageId": "voploopbaccktest"}]}}');
            return response;
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
}