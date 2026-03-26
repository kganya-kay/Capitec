@isTest
private class IC_API_SendSMS_TEST {

    @isTest
    static void sendSMSCalloutTest() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        
        // Create a test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'Administration',
            Sub_Status__c = 'Allocated',
            IC_Template_Description__c = 'Request Document from Client',
            IC_Document_Type_required__c = 'Certificate of Service',
            IC_Type__c = 'Unemployment/ITEI',
            Sub_Type__c = 'Retrenchment',
            Sub_Type_Reason__c = 'New Technology',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Credit Life'
        );
        insert testCase;

        // Create a test FlowRequestVariables
        IC_API_SendSMS.FlowRequestVariables testFlowRequest = new IC_API_SendSMS.FlowRequestVariables();
        testFlowRequest.caseId = testCase.Id;
        testFlowRequest.templateName = 'Acknowledge Claim';
        testFlowRequest.cifNumber = '123456';
        testFlowRequest.Phone_Number = '9876543210';
        testFlowRequest.productType = 'Credit Life';
        testFlowRequest.documentType = 'Certificate of Service;Client’s ID;Medical certificates';

        // Mock the HTTP callout response
        Test.setMock(HttpCalloutMock.class, new MockPolicyCalloutError());

        // Test the sendSMSCallout method
        Test.startTest();
        List<IC_API_SendSMS.FlowRequestVariables> requestList = new List<IC_API_SendSMS.FlowRequestVariables>{testFlowRequest};
        List<String> result = IC_API_SendSMS.sendSMSCallout(requestList);
        Test.stopTest();

        // Assert the results
        //System.assert(result.size() > 0, 'Expected at least one result');
        //System.assert(result[0].contains('\'Cif Number\' must not be empty.'));
    }

    @isTest
    static void sendSMSCalloutTest2() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        
        // Create a test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'Administration',
            Sub_Status__c = 'Allocated',
            IC_Template_Description__c = 'Funeral: Request Outstanding Doc',
            IC_Document_Type_required__c = 'Certificate of Service',
            IC_Type__c = 'Death',
            Sub_Type__c = 'Natural',
            Sub_Type_Reason__c = 'Main life',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Funeral'
        );
        insert testCase;

        // Create a test FlowRequestVariables
        IC_API_SendSMS.FlowRequestVariables testFlowRequest = new IC_API_SendSMS.FlowRequestVariables();
        testFlowRequest.caseId = testCase.Id;
        testFlowRequest.templateName = 'Funeral: Request Outstanding Doc';
        testFlowRequest.cifNumber = '123456';
        testFlowRequest.Phone_Number = '9876543210';
        testFlowRequest.productType = 'Funeral';
        testFlowRequest.documentType = 'Test Document';

        // Mock the HTTP callout response
        Test.setMock(HttpCalloutMock.class, new MockPolicyCalloutError());

        // Test the sendSMSCallout method
        Test.startTest();
        List<IC_API_SendSMS.FlowRequestVariables> requestList = new List<IC_API_SendSMS.FlowRequestVariables>{testFlowRequest};
        List<String> result = IC_API_SendSMS.sendSMSCallout(requestList);
        Test.stopTest();
    }
    
    @isTest
    static void sendSMSCalloutTest3() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        
        // Create a test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'Administration',
            Sub_Status__c = 'Allocated',
            IC_Template_Description__c = 'Funeral: Claim Validation 14 day',
            IC_Document_Type_required__c = 'Certificate of Service',
            IC_Type__c = 'Death',
            Sub_Type__c = 'Natural',
            Sub_Type_Reason__c = 'Main life',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Funeral'
        );
        insert testCase;

        // Create a test FlowRequestVariables
        IC_API_SendSMS.FlowRequestVariables testFlowRequest = new IC_API_SendSMS.FlowRequestVariables();
        testFlowRequest.caseId = testCase.Id;
        testFlowRequest.templateName = 'Funeral: Claim Validation 14 day';
        testFlowRequest.cifNumber = '123456';
        testFlowRequest.Phone_Number = '9876543210';
        testFlowRequest.productType = 'Funeral';
        testFlowRequest.documentType = 'Test Document';

        // Mock the HTTP callout response
        Test.setMock(HttpCalloutMock.class, new MockPolicyCalloutError());

        // Test the sendSMSCallout method
        Test.startTest();
        List<IC_API_SendSMS.FlowRequestVariables> requestList = new List<IC_API_SendSMS.FlowRequestVariables>{testFlowRequest};
        List<String> result = IC_API_SendSMS.sendSMSCallout(requestList);
        Test.stopTest();
    }
    
    @isTest
    static void sendSMSCalloutTest4() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        
        // Create a test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'Administration',
            Sub_Status__c = 'Allocated',
            IC_Template_Description__c = 'Claim Status Updates',
            IC_Document_Type_required__c = 'Certificate of Service',
            IC_Type__c = 'Death',
            Sub_Type__c = 'Natural',
            Sub_Type_Reason__c = 'Main life',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Credit Life'
        );
        insert testCase;

        // Create a test FlowRequestVariables
        IC_API_SendSMS.FlowRequestVariables testFlowRequest = new IC_API_SendSMS.FlowRequestVariables();
        testFlowRequest.caseId = testCase.Id;
        testFlowRequest.templateName = 'Claim Status Updates';
        testFlowRequest.cifNumber = '123456';
        testFlowRequest.Phone_Number = '9876543210';
        testFlowRequest.productType = 'Credit Life';
        testFlowRequest.documentType = 'Test Document';

        // Mock the HTTP callout response
        Test.setMock(HttpCalloutMock.class, new MockPolicyCallout());

        // Test the sendSMSCallout method
        Test.startTest();
        List<IC_API_SendSMS.FlowRequestVariables> requestList = new List<IC_API_SendSMS.FlowRequestVariables>{testFlowRequest};
        List<String> result = IC_API_SendSMS.sendSMSCallout(requestList);
        Test.stopTest();
    }

    private class MockPolicyCalloutError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
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
    
    private class MockPolicyCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{' +
                        '"Title": "Success",' +
                        '"Detail": [' +
                        '{' +
                        '"PropertyName": "CifNumber",' +
                        '"ErrorMessage": "\'Cif Number\' must not be empty."' +
                        '}' +
                        '],' +
                        '"Status": 200' +
                        '}');
            res.setStatusCode(200);
            return res;
        }
    }
}