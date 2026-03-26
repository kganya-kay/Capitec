@isTest
private class IC_API_DocumentRequests_TEST {
    @testSetup
    static void setup() {
        IC_DocumentRequests_API_Settings__mdt apiSettings = IC_DocumentRequests_API_Settings__mdt.getAll().values()[0];
    }

    @isTest
    static void testGetSanlamRequestsSuccess() {
        String mockResponseBody = '{ "summaryDetails": { "policies": [ { "claims": [ { "documentsRequired": [ { "documentCode": "DOC001", "documentName": "Document 1", "guid": "GUID1", "docStatus": "Pending", "isMandatory": null } ] } ] } ] } }';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, mockResponseBody));

        IC_API_DocumentRequests.FlowRequestVariables reqVar = new IC_API_DocumentRequests.FlowRequestVariables();
        reqVar.idNumber = '123456';
        reqVar.cifNumber = '7890';

        List<IC_API_DocumentRequests.FlowRequestVariables> reqVarList = new List<IC_API_DocumentRequests.FlowRequestVariables>();
        reqVarList.add(reqVar);

        Test.startTest();
        List<List<String>> results = IC_API_DocumentRequests.getSanlamRequests(reqVarList);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be one document request.');
    }
    
    @isTest
    static void testGetSanlamRequestsError() {
        String mockResponseBody = '{ "summaryDetails": { "policies": [ { "claims": [ { "documentsRequired": [{"docStatus":"Required", "isMandatory":null, "documentCode":"Inquest_Report", "documentName":"Inquest Report", "guid":null} ] } ] } ] } }';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(400, mockResponseBody));

        IC_API_DocumentRequests.FlowRequestVariables reqVar = new IC_API_DocumentRequests.FlowRequestVariables();
        reqVar.idNumber = '123456';
        reqVar.cifNumber = '7890';

        List<IC_API_DocumentRequests.FlowRequestVariables> reqVarList = new List<IC_API_DocumentRequests.FlowRequestVariables>();
        reqVarList.add(reqVar);

        Test.startTest();
        List<List<String>> results = IC_API_DocumentRequests.getSanlamRequests(reqVarList);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'There should be one document request.');
    }

    private class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public MockHttpResponse(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
}