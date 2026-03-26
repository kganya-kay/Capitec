/**
* Author           Ridwan Moosuddee
* Company          BlueSky
* Date             06/11/2023
* Description      Test Class for IC_API_FinaliseClaimApprove
**/
@isTest
private class IC_API_FinaliseClaimApprove_TEST {
    
    @testSetup
    static void setup() {
        IC_TestDataFactory.createSingleCase();
    }
    
    @isTest 
    static void test_finaliseClaimapproveCallout() {
        
        Case insertedCase = [SELECT CaseNumber, IC_Policy_Number_child__c, CIF_Number__c, IC_Claim_Number_of_Payments__c, IC_Insurer_Underwriter_at_Event_Date__c, IC_Claim_Lump_Sum_Amount__c, IC_Claim_Annuity_Amount__c, IC_Remaining_Term_at_Event_Date__c, IC_Remaining_Term_at_Last_Working_Date__c, IC_Payment_Frequency__c, IC_Number_of_Catch_Up_Payments__c, IC_Group_of_Insurance_Contracts__c FROM Case LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockFinaliseApproveCallout());
        
        IC_API_FinaliseClaimApprove.FlowRequestVariables req = new IC_API_FinaliseClaimApprove.FlowRequestVariables();
        req.caseNumber = insertedCase.CaseNumber;
        req.policyNumber = insertedCase.IC_Policy_Number_child__c;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = Date.today();
        req.insurerUnderwriterAtEventDate = insertedCase.IC_Insurer_Underwriter_at_Event_Date__c;
        req.claimInstallmentPeriod = Integer.Valueof(insertedCase.IC_Claim_Number_of_Payments__c);
        req.claimLumpSumAmount = insertedCase.IC_Claim_Lump_Sum_Amount__c;
        req.claimAnnuityAmount = insertedCase.IC_Claim_Annuity_Amount__c;
        req.remainingTermAtEventDate = Integer.Valueof(insertedCase.IC_Remaining_Term_at_Event_Date__c);
        req.remainingTermAtLastWorkingDate = Integer.Valueof(insertedCase.IC_Remaining_Term_at_Last_Working_Date__c);
        req.firstPaymentDueDate = Date.today();
        req.paymentFrequency = insertedCase.IC_Payment_Frequency__c;
        req.numberOfCatchUpPayments = Integer.Valueof(insertedCase.IC_Number_of_Catch_Up_Payments__c);
        req.groupOfInsuranceContracts = insertedCase.IC_Group_of_Insurance_Contracts__c;
        
        List<IC_API_FinaliseClaimApprove.FlowRequestVariables> reqList = new List<IC_API_FinaliseClaimApprove.FlowRequestVariables>{ req };
            Test.startTest();
        List<String> results = IC_API_FinaliseClaimApprove.makeApproveFinaliseClaimCallout(reqList);
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        
    }
    
    // Mock for HTTP callout
    public class MockFinaliseApproveCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"count":1,"items":[{"caseNumber":"12345","policyNumber":"PolNumber12345", "cifNumber":"12345","eventDate":"2023-11-01","insurerUnderWriterAtEventDate":"Test Approval", "claimInstallmentPeriod":"1", "claimLumpSumAmount":"11", "claimAnnuityAmount":"1", "remainingTermAtEventDate":"12", "remainingTermAtLastWorkingDate":"12", "firstPaymentDueDate":"2023-11-01", "paymentFrequency":"OnceOff","numberOfCatchupPayments":"1"}]}');
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
                        '"Title": "Error",' +
                        '"Detail": [' +
                        '{' +
                        '"PropertyName": "CifNumber",' +
                        '"ErrorMessage": "\'Cif Number\' must not be empty."' +
                        '}' +
                        '],' +
                        '"Status": 500' +
                        '}');
            res.setStatusCode(500);
            return res;
        }
    }
    
    private class MockPolicyCalloutError_400 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{' +
                        '"Title": "External Dependency Error [TransactService]",' +
                        '"Detail": [' +
                        '"{\\"Title\\": \\"Internal Server Error\\", \\"Detail\\": [\\"Duplicate transaction found\\"], \\"Status\\": 400}"' +
                        '],' +
                        '"Status": 400' +
                        '}');
            res.setStatusCode(400);
            return res;
        }
    }
    
    private class MockPolicyCalloutError_400_SecondStructure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{' +
                        '"Title": "External Dependency Error [TransactService]",' +
                        '"Detail": [' +
                        '"{\\"Title\\": \\"Bad Request\\", \\"Detail\\": [{\\"PropertyName\\": \\"Amount\\", \\"ErrorMessage\\": \\"\'Amount\' must not be equal to \'0\'.\\"}], \\"Status\\": 400}"' +
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
        Case insertedCase = [SELECT CaseNumber, IC_Policy_Number_child__c, CIF_Number__c, IC_Claim_Number_of_Payments__c, IC_Insurer_Underwriter_at_Event_Date__c, IC_Claim_Lump_Sum_Amount__c, IC_Claim_Annuity_Amount__c, IC_Remaining_Term_at_Event_Date__c, IC_Remaining_Term_at_Last_Working_Date__c, IC_Payment_Frequency__c, IC_Number_of_Catch_Up_Payments__c, IC_Group_of_Insurance_Contracts__c FROM Case LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse for an error scenario using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockPolicyCalloutError());
        
        // Create a new FlowRequest with data from the test case
        IC_API_FinaliseClaimApprove.FlowRequestVariables req = new IC_API_FinaliseClaimApprove.FlowRequestVariables();
        req.caseNumber = insertedCase.CaseNumber;
        req.policyNumber = insertedCase.IC_Policy_Number_child__c;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = Date.today();
        req.insurerUnderwriterAtEventDate = insertedCase.IC_Insurer_Underwriter_at_Event_Date__c;
        req.claimInstallmentPeriod = Integer.Valueof(insertedCase.IC_Claim_Number_of_Payments__c);
        req.claimLumpSumAmount = insertedCase.IC_Claim_Lump_Sum_Amount__c;
        req.claimAnnuityAmount = insertedCase.IC_Claim_Annuity_Amount__c;
        req.remainingTermAtEventDate = Integer.Valueof(insertedCase.IC_Remaining_Term_at_Event_Date__c);
        req.remainingTermAtLastWorkingDate = Integer.Valueof(insertedCase.IC_Remaining_Term_at_Last_Working_Date__c);
        req.firstPaymentDueDate = Date.today();
        req.paymentFrequency = insertedCase.IC_Payment_Frequency__c;
        req.numberOfCatchUpPayments = Integer.Valueof(insertedCase.IC_Number_of_Catch_Up_Payments__c);
        req.groupOfInsuranceContracts = insertedCase.IC_Group_of_Insurance_Contracts__c;
        
        // Wrap in a list as expected by the method being tested
        List<IC_API_FinaliseClaimApprove.FlowRequestVariables> reqList = new List<IC_API_FinaliseClaimApprove.FlowRequestVariables>{ req };
            
            // Make the callout within test context
            Test.startTest();
        List<String> results = IC_API_FinaliseClaimApprove.makeApproveFinaliseClaimCallout(reqList);
        Test.stopTest();
        
        // Assert that the results contain the expected error messages
        //System.debug('Message: ' + results[0]);
        System.assertEquals(2, results.size(), 'There should be two entries in results - one for the detail error message and one for the HTTP status error.');
        System.assert(results[0].contains('Error: CifNumber - \'Cif Number\' must not be empty.'), 'The property name and error message should match the mock response');
        System.assert(results[1].startsWith('HTTP Error: 500'), 'The results should contain the HTTP error message.');
    }   
    
    
    @IsTest
    static void test_makePolicyCallout_HttpError_400() {
        // Setup test data
        Case insertedCase = [SELECT CaseNumber, IC_Policy_Number_child__c, CIF_Number__c, IC_Claim_Number_of_Payments__c, IC_Insurer_Underwriter_at_Event_Date__c, IC_Claim_Lump_Sum_Amount__c, IC_Claim_Annuity_Amount__c, IC_Remaining_Term_at_Event_Date__c, IC_Remaining_Term_at_Last_Working_Date__c, IC_Payment_Frequency__c, IC_Number_of_Catch_Up_Payments__c, IC_Group_of_Insurance_Contracts__c FROM Case LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse for an error scenario using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockPolicyCalloutError_400());
        
        // Create a new FlowRequest with data from the test case
        IC_API_FinaliseClaimApprove.FlowRequestVariables req = new IC_API_FinaliseClaimApprove.FlowRequestVariables();
        req.caseNumber = insertedCase.CaseNumber;
        req.policyNumber = insertedCase.IC_Policy_Number_child__c;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = Date.today();
        req.insurerUnderwriterAtEventDate = insertedCase.IC_Insurer_Underwriter_at_Event_Date__c;
        req.claimInstallmentPeriod = Integer.Valueof(insertedCase.IC_Claim_Number_of_Payments__c);
        req.claimLumpSumAmount = insertedCase.IC_Claim_Lump_Sum_Amount__c;
        req.claimAnnuityAmount = insertedCase.IC_Claim_Annuity_Amount__c;
        req.remainingTermAtEventDate = Integer.Valueof(insertedCase.IC_Remaining_Term_at_Event_Date__c);
        req.remainingTermAtLastWorkingDate = Integer.Valueof(insertedCase.IC_Remaining_Term_at_Last_Working_Date__c);
        req.firstPaymentDueDate = Date.today();
        req.paymentFrequency = insertedCase.IC_Payment_Frequency__c;
        req.numberOfCatchUpPayments = Integer.Valueof(insertedCase.IC_Number_of_Catch_Up_Payments__c);
        req.groupOfInsuranceContracts = insertedCase.IC_Group_of_Insurance_Contracts__c;
        
        // Wrap in a list as expected by the method being tested
        List<IC_API_FinaliseClaimApprove.FlowRequestVariables> reqList = new List<IC_API_FinaliseClaimApprove.FlowRequestVariables>{ req };
            
            // Make the callout within test context
            Test.startTest();
        List<String> results = IC_API_FinaliseClaimApprove.makeApproveFinaliseClaimCallout(reqList);
        Test.stopTest();
        
        // Assert that the results contain the expected error messages
        Boolean foundDuplicateTransactionError = false;
        for (String result : results) {
            if (result.contains('Error: This claim has already been scheduled for payment, please close this as a duplicate claim.')) {
                foundDuplicateTransactionError = true;
                break;
            }
        }
        
        System.assert(foundDuplicateTransactionError, 'The error "Duplicate transaction found" should lead to a specific result message being present in the results.');        
        
    }
    
    
    //ICS-1178
    @IsTest
    static void test_makePolicyCallout_HttpError_400_SecondStructure() {
        // Setup test data
        Case insertedCase = [SELECT CaseNumber, IC_Policy_Number_child__c, CIF_Number__c, IC_Claim_Number_of_Payments__c, IC_Insurer_Underwriter_at_Event_Date__c, IC_Claim_Lump_Sum_Amount__c, IC_Claim_Annuity_Amount__c, IC_Remaining_Term_at_Event_Date__c, IC_Remaining_Term_at_Last_Working_Date__c, IC_Payment_Frequency__c, IC_Number_of_Catch_Up_Payments__c, IC_Group_of_Insurance_Contracts__c FROM Case LIMIT 1];
        
        // Mock the HttpRequest and HttpResponse for an error scenario using HttpCalloutMock interface
        Test.setMock(HttpCalloutMock.class, new MockPolicyCalloutError_400_SecondStructure());
        
        // Create a new FlowRequest with data from the test case
        IC_API_FinaliseClaimApprove.FlowRequestVariables req = new IC_API_FinaliseClaimApprove.FlowRequestVariables();
        req.caseNumber = insertedCase.CaseNumber;
        req.policyNumber = insertedCase.IC_Policy_Number_child__c;
        req.cifNumber = insertedCase.CIF_Number__c;
        req.eventDate = Date.today();
        req.insurerUnderwriterAtEventDate = insertedCase.IC_Insurer_Underwriter_at_Event_Date__c;
        req.claimInstallmentPeriod = Integer.Valueof(insertedCase.IC_Claim_Number_of_Payments__c);
        req.claimLumpSumAmount = insertedCase.IC_Claim_Lump_Sum_Amount__c;
        req.claimAnnuityAmount = insertedCase.IC_Claim_Annuity_Amount__c;
        req.remainingTermAtEventDate = Integer.Valueof(insertedCase.IC_Remaining_Term_at_Event_Date__c);
        req.remainingTermAtLastWorkingDate = Integer.Valueof(insertedCase.IC_Remaining_Term_at_Last_Working_Date__c);
        req.firstPaymentDueDate = Date.today();
        req.paymentFrequency = insertedCase.IC_Payment_Frequency__c;
        req.numberOfCatchUpPayments = Integer.Valueof(insertedCase.IC_Number_of_Catch_Up_Payments__c);
        req.groupOfInsuranceContracts = insertedCase.IC_Group_of_Insurance_Contracts__c;
        
        // Wrap in a list as expected by the method being tested
        List<IC_API_FinaliseClaimApprove.FlowRequestVariables> reqList = new List<IC_API_FinaliseClaimApprove.FlowRequestVariables>{ req };
            
            // Make the callout within test context
            Test.startTest();
        List<String> results = IC_API_FinaliseClaimApprove.makeApproveFinaliseClaimCallout(reqList);
        Test.stopTest();
        
        // Assert that the results contain the expected error messages
        Boolean foundAmountError = false;
        for (String result : results) {
            if (result.contains('Error: \'Amount\' must not be equal to \'0\'.')) {
                foundAmountError = true;
                break;
            }
        }
        
        System.assert(foundAmountError, 'The error "\'Amount\' must not be equal to \'0\'." should lead to a specific result message being present in the results.');         
        
    }
}