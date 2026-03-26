/*******************************************************************
* @Class Name        :  IC_API_PolicyService_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 31-Oct-2023, Jira Tickets: ICS-225
* @Version           :  1.0
*
*******************************************************************/

@IsTest
public class IC_API_PolicyService_TEST {
    @testSetup
    static void setup() {
        IC_TestDataFactory.createSingleCase();
        IC_TestDataFactory.createSingleCase_CL_Disability();
    }
    
    @isTest 
    static void test_makePolicyCallout() {
        
        Case insertedCase = [SELECT Subject, CaseNumber, CIF_Number__c, Event_Date__c, Product_Type__c, IC_Type__c, Sub_Type__c, Last_Working_Date__c, IC_Duration_of_Condition__c FROM Case WHERE Subject = 'Test Case - ICS-225' LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockPolicyCallout());
        
        IC_API_PolicyService.FlowRequest req = new IC_API_PolicyService.FlowRequest();
        req.caseNumber = insertedCase.CaseNumber;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = Date.today();
        req.productType = insertedCase.Product_Type__c;
        req.caseType = insertedCase.IC_Type__c;
        req.caseSubType = insertedCase.Sub_Type__c;
        req.lastWorkingDate = Date.today();
        req.eventApproved = true;
        
        List<IC_API_PolicyService.FlowRequest> reqList = new List<IC_API_PolicyService.FlowRequest>{ req };
            Test.startTest();
        List<String> results = IC_API_PolicyService.makePolicyCallout(reqList);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
    }
    
   
    
    @isTest 
    static void test_makePolicyCallout_ccsStatus_J() {
        
        Case insertedCase = [SELECT Subject, CaseNumber, CIF_Number__c, Event_Date__c, Product_Type__c, IC_Type__c, Sub_Type__c, Last_Working_Date__c FROM Case WHERE Subject = 'Test Case - ICS-225' LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockPolicyCallout_ccsStatus_J());
        
        IC_API_PolicyService.FlowRequest req = new IC_API_PolicyService.FlowRequest();
        req.caseNumber = insertedCase.CaseNumber;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = Date.today();
        req.productType = insertedCase.Product_Type__c;
        req.caseType = insertedCase.IC_Type__c;
        req.caseSubType = insertedCase.Sub_Type__c;
        req.lastWorkingDate = Date.today();
        req.eventApproved = true;
        
        List<IC_API_PolicyService.FlowRequest> reqList = new List<IC_API_PolicyService.FlowRequest>{ req };
            Test.startTest();
        List<String> results = IC_API_PolicyService.makePolicyCallout(reqList);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        
    }
    
    // Mock for HTTP callout
    public class MockPolicyCallout implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"count":1,"items":[{"policyNumber":"PN12345", "insurerUnderWriterAtEventDate":"CapitecLife", "creditProductType":"Test Product", "policyVersion":"1.0", "productDescription":"Test Description", "dateOpened":"2023-10-31", "ccsStatusAtEventDate":"A", "balanceOutstandingAtEventDate":"1000", "installmentAmountAtEventDate":"100", "remainingTermAtEventDate":1, "remainingTermAtLastWorkingDate":12, "firstPaymentDueDate":"2023-11-30", "paymentFrequency":"Monthly", "recommendedNumberOfPayments":1, "numberOfCatchupPayments":0, "inForceOnEventDate":true, "inwaitingPeriod":false, "recommendedOutcome":"Proceed", "recommendedReason":"Valid","groupOfInsuranceContracts":"TEST"}]}');
            res.setStatusCode(200);
            //return res;
            //system.debug('TESTRESPONSE:::' +JSON.deserialize(res));        
            //System.assertEquals(recommendedNumberOfPayments, insertedCase.IC_Duration_of_Condition__c, 'IC_Recommended_Number_of_Payments__c should be equal to IC_Duration_of_Condition__c');
            return res;
        }
    }
    
    // Mock for HTTP callout
    public class MockPolicyCallout_weekly implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"count":1,"items":[{"policyNumber":"PN12345", "insurerUnderWriterAtEventDate":"CapitecLife", "creditProductType":"Test Product", "policyVersion":"1.0", "productDescription":"Test Description", "dateOpened":"2023-10-31", "ccsStatusAtEventDate":"A", "balanceOutstandingAtEventDate":"1000", "installmentAmountAtEventDate":"100", "remainingTermAtEventDate":1, "remainingTermAtLastWorkingDate":12, "firstPaymentDueDate":"2023-11-30", "paymentFrequency":"Weekly", "recommendedNumberOfPayments":21, "numberOfCatchupPayments":0, "inForceOnEventDate":true, "inwaitingPeriod":false, "recommendedOutcome":"Proceed", "recommendedReason":"Valid","groupOfInsuranceContracts":"TEST"}]}');
            res.setStatusCode(200);
            //return res;
            //system.debug('TESTRESPONSE:::' +JSON.deserialize(res));        
            //System.assertEquals(recommendedNumberOfPayments, insertedCase.IC_Duration_of_Condition__c, 'IC_Recommended_Number_of_Payments__c should be equal to IC_Duration_of_Condition__c');
            return res;
        }
    }
    
    // Mock for HTTP callout
    public class MockPolicyCallout_fortnightly implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"count":1,"items":[{"policyNumber":"PN12345", "insurerUnderWriterAtEventDate":"CapitecLife", "creditProductType":"Test Product", "policyVersion":"1.0", "productDescription":"Test Description", "dateOpened":"2023-10-31", "ccsStatusAtEventDate":"A", "balanceOutstandingAtEventDate":"1000", "installmentAmountAtEventDate":"100", "remainingTermAtEventDate":1, "remainingTermAtLastWorkingDate":12, "firstPaymentDueDate":"2023-11-30", "paymentFrequency":"FORTNIGHTLY", "recommendedNumberOfPayments":21, "numberOfCatchupPayments":0, "inForceOnEventDate":true, "inwaitingPeriod":false, "recommendedOutcome":"Proceed", "recommendedReason":"Valid","groupOfInsuranceContracts":"TEST"}]}');
            res.setStatusCode(200);
            //return res;
            //system.debug('TESTRESPONSE:::' +JSON.deserialize(res));        
            //System.assertEquals(recommendedNumberOfPayments, insertedCase.IC_Duration_of_Condition__c, 'IC_Recommended_Number_of_Payments__c should be equal to IC_Duration_of_Condition__c');
            return res;
        }
    }
    
    // Mock for HTTP callout
    public class MockPolicyCallout_daily implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"count":1,"items":[{"policyNumber":"PN12345", "insurerUnderWriterAtEventDate":"CapitecLife", "creditProductType":"Test Product", "policyVersion":"1.0", "productDescription":"Test Description", "dateOpened":"2023-10-31", "ccsStatusAtEventDate":"A", "balanceOutstandingAtEventDate":"1000", "installmentAmountAtEventDate":"100", "remainingTermAtEventDate":1, "remainingTermAtLastWorkingDate":12, "firstPaymentDueDate":"2023-11-30", "paymentFrequency":"Daily", "recommendedNumberOfPayments":21, "numberOfCatchupPayments":0, "inForceOnEventDate":true, "inwaitingPeriod":false, "recommendedOutcome":"Proceed", "recommendedReason":"Valid","groupOfInsuranceContracts":"TEST"}]}');
            res.setStatusCode(200);
            //return res;
            //system.debug('TESTRESPONSE:::' +JSON.deserialize(res));        
            //System.assertEquals(recommendedNumberOfPayments, insertedCase.IC_Duration_of_Condition__c, 'IC_Recommended_Number_of_Payments__c should be equal to IC_Duration_of_Condition__c');
            return res;
        }
    }
    
    
    
    public class MockPolicyCallout_ccsStatus_J implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"count":1,"items":[{"policyNumber":"PN12345", "insurerUnderWriterAtEventDate":"Test Insurer", "creditProductType":"Test Product", "policyVersion":"1.0", "productDescription":"Test Description", "accountConsolidated":true, "dateOpened":"2023-10-31", "ccsStatusAtEventDate":"J", "balanceOutstandingAtEventDate":"1000", "installmentAmountAtEventDate":"100", "remainingTermAtEventDate":12, "remainingTermAtLastWorkingDate":12, "firstPaymentDueDate":"2023-11-30", "paymentFrequency":"Monthly", "recommendedNumberOfPayments":12, "numberOfCatchupPayments":0, "inForceOnEventDate":true, "inwaitingPeriod":false, "recommendedOutcome":"Proceed", "recommendedReason":"Valid","groupOfInsuranceContracts":"TEST"}]}');
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
        Case insertedCase = [SELECT Subject, CaseNumber, CIF_Number__c, Event_Date__c, Product_Type__c, IC_Type__c, Sub_Type__c, Last_Working_Date__c FROM Case WHERE Subject = 'Test Case - ICS-225' LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse for an error scenario using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockPolicyCalloutError());
        
        // Create a new FlowRequest with data from the test case
        IC_API_PolicyService.FlowRequest req = new IC_API_PolicyService.FlowRequest();
        req.caseNumber = insertedCase.CaseNumber;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = insertedCase.Event_Date__c;
        req.productType = insertedCase.Product_Type__c;
        req.caseType = insertedCase.IC_Type__c;
        req.caseSubType = insertedCase.Sub_Type__c;
        req.lastWorkingDate = insertedCase.Last_Working_Date__c;
        req.eventApproved = true;
        
        // Wrap in a list as expected by the method being tested
        List<IC_API_PolicyService.FlowRequest> reqList = new List<IC_API_PolicyService.FlowRequest>{ req };
            
            // Make the callout within test context
            Test.startTest();
        List<String> results = IC_API_PolicyService.makePolicyCallout(reqList);
        Test.stopTest();
        
        // Assert that the results contain the expected error messages
        //System.debug('Message: ' + results[0]);
        System.assertEquals(2, results.size(), 'There should be two entries in results - one for the detail error message and one for the HTTP status error.');
        System.assert(results[0].contains('Error: CifNumber - \'Cif Number\' must not be empty.'), 'The property name and error message should match the mock response');
        System.assert(results[1].startsWith('HTTP Error: 400'), 'The results should contain the HTTP error message.');
    }   
    
    
    @isTest 
    static void test_makePolicyCallout_weekly() {//ICS-812, ICS-1234
        
        Case insertedCase = [SELECT Subject, CaseNumber, CIF_Number__c, Event_Date__c, Product_Type__c, IC_Type__c, Sub_Type__c, Last_Working_Date__c, IC_Duration_of_Condition__c FROM Case WHERE Subject = 'Test Case - ICS-840' LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockPolicyCallout_weekly());
        
        IC_API_PolicyService.FlowRequest req = new IC_API_PolicyService.FlowRequest();
        req.caseNumber = insertedCase.CaseNumber;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = Date.today();
        req.productType = insertedCase.Product_Type__c;
        req.caseType = insertedCase.IC_Type__c;
        req.caseSubType = insertedCase.Sub_Type__c;
        req.lastWorkingDate = Date.today();
        req.eventApproved = true;
        
        List<IC_API_PolicyService.FlowRequest> reqList = new List<IC_API_PolicyService.FlowRequest>{ req };
            Test.startTest();
        List<String> results = IC_API_PolicyService.makePolicyCallout(reqList);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        
        // Verify the calculation
        Case childCase = [SELECT IC_Recommended_Number_of_Payments__c, IC_Claim_Number_of_Payments__c FROM Case WHERE parentId = :insertedCase.Id];
        
        Integer expectedPayments = (Integer) Math.ceil(insertedCase.IC_Duration_of_Condition__c * 4.33);
        System.assertEquals(expectedPayments, childCase.IC_Recommended_Number_of_Payments__c, 'The recommended number of payments should be calculated correctly.');
        System.assertEquals(expectedPayments, childCase.IC_Claim_Number_of_Payments__c, 'The claim number of payments should be calculated correctly.');
        
    }
    
    @isTest 
    static void test_makePolicyCallout_fortnightly() {//ICS-812, ICS-1234
        
        Case insertedCase = [SELECT Subject, CaseNumber, CIF_Number__c, Event_Date__c, Product_Type__c, IC_Type__c, Sub_Type__c, Last_Working_Date__c, IC_Duration_of_Condition__c FROM Case WHERE Subject = 'Test Case - ICS-840' LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockPolicyCallout_fortnightly());
        
        IC_API_PolicyService.FlowRequest req = new IC_API_PolicyService.FlowRequest();
        req.caseNumber = insertedCase.CaseNumber;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = Date.today();
        req.productType = insertedCase.Product_Type__c;
        req.caseType = insertedCase.IC_Type__c;
        req.caseSubType = insertedCase.Sub_Type__c;
        req.lastWorkingDate = Date.today();
        req.eventApproved = true;
        
        List<IC_API_PolicyService.FlowRequest> reqList = new List<IC_API_PolicyService.FlowRequest>{ req };
            Test.startTest();
        List<String> results = IC_API_PolicyService.makePolicyCallout(reqList);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        
        // Verify the calculation
        Case childCase = [SELECT IC_Recommended_Number_of_Payments__c, IC_Claim_Number_of_Payments__c FROM Case WHERE parentId = :insertedCase.Id];
        
        Integer expectedPayments = (Integer) (insertedCase.IC_Duration_of_Condition__c * 2);
        System.assertEquals(expectedPayments, childCase.IC_Recommended_Number_of_Payments__c, 'The recommended number of payments should be calculated correctly.');
        System.assertEquals(expectedPayments, childCase.IC_Claim_Number_of_Payments__c, 'The claim number of payments should be calculated correctly.');
        
    }
    
    @isTest 
    static void test_makePolicyCallout_daily() {//ICS-812, ICS-1234
        
        Case insertedCase = [SELECT Subject, CaseNumber, CIF_Number__c, Event_Date__c, Product_Type__c, IC_Type__c, Sub_Type__c, Last_Working_Date__c, IC_Duration_of_Condition__c FROM Case WHERE Subject = 'Test Case - ICS-840' LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockPolicyCallout_daily());
        
        IC_API_PolicyService.FlowRequest req = new IC_API_PolicyService.FlowRequest();
        req.caseNumber = insertedCase.CaseNumber;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = Date.today();
        req.productType = insertedCase.Product_Type__c;
        req.caseType = insertedCase.IC_Type__c;
        req.caseSubType = insertedCase.Sub_Type__c;
        req.lastWorkingDate = Date.today();
        req.eventApproved = true;
        
        List<IC_API_PolicyService.FlowRequest> reqList = new List<IC_API_PolicyService.FlowRequest>{ req };
            Test.startTest();
        List<String> results = IC_API_PolicyService.makePolicyCallout(reqList);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        
        // Verify the calculation
        Case childCase = [SELECT IC_Recommended_Number_of_Payments__c, IC_Claim_Number_of_Payments__c FROM Case WHERE parentId = :insertedCase.Id];
        
        Integer expectedPayments = (Integer) insertedCase.IC_Duration_of_Condition__c;
        System.assertEquals(expectedPayments, childCase.IC_Recommended_Number_of_Payments__c, 'The recommended number of payments should be calculated correctly.');
        System.assertEquals(expectedPayments, childCase.IC_Claim_Number_of_Payments__c, 'The claim number of payments should be calculated correctly.');
        
    }
    
    
    
}