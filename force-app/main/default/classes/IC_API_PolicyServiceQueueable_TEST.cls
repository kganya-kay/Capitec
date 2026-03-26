@IsTest
public class IC_API_PolicyServiceQueueable_TEST {
    @IsTest
    static void testExecute() {
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account a = new Account(
            LastName = 'Test Case - ICS-426',
            CIF_Number__c = '123456',
            RecordTypeId = personAccountRTId
        );
        insert a;
        
        // Create test data
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case testCase = new Case(
            AccountId = a.Id,
            IC_Data_Wash_Service__c = true,
            Event_Date__c = Date.today(),
            IC_Type__c = 'Death',
            Product_Type__c = 'Funeral',
            Sub_Type__c = 'Natural',
            Last_Working_Date__c = Date.today(),
            RecordTypeId = insuranceClaimsRTId,
            Origin = 'Data Wash'
            
        );
        insert testCase;
        
        // Create test data for FlowRequest
        IC_API_PolicyService.FlowRequest request = new IC_API_PolicyService.FlowRequest();
        request.caseNumber = testCase.CaseNumber;
        request.cifNumber = testCase.CIF_Number__c;
        request.eventDate = Date.today();
        request.productType = testCase.Product_Type__c;
        request.caseType = testCase.IC_Type__c;
        request.caseSubType = testCase.Sub_Type__c;
        request.lastWorkingDate = Date.today();
        request.eventApproved = true;
        
        List<IC_API_PolicyService.FlowRequest> flowRequests = new List<IC_API_PolicyService.FlowRequest>{request};
            
            // Instantiate the Queueable class
            IC_API_PolicyServiceQueueable queueable = new IC_API_PolicyServiceQueueable(flowRequests);
        
        // Execute the Queueable class
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
        
    }
    
    // Mock class for HTTP callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"count":1,"items":[{"policyNumber":"PN12345", "insurerUnderWriterAtEventDate":"Test Insurer", "creditProductType":"Test Product", "policyVersion":"1.0", "productDescription":"Test Description", "dateOpened":"2023-10-31", "ccsStatusAtEventDate":"J", "balanceOutstandingAtEventDate":"1000", "installmentAmountAtEventDate":"100", "remainingTermAtEventDate":12, "remainingTermAtLastWorkingDate":12, "firstPaymentDueDate":"2023-11-30", "paymentFrequency":"Monthly", "recommendedNumberOfPayments":12, "numberOfCatchupPayments":0, "inForceOnEventDate":true, "inwaitingPeriod":false, "recommendedOutcome":"Proceed", "recommendedReason":"Valid","groupOfInsuranceContracts":"TEST"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
}