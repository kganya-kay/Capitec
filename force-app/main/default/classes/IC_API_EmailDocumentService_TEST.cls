/*******************************************************************
* @Class Name        :  IC_API_EmailDocumentService_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 29-July-2023, Jira Tickets: ICS-1368 
* @Version           :  1.0
*
*******************************************************************/

@IsTest
public class IC_API_EmailDocumentService_TEST {
    
    @testSetup
    static void setup() {  
    IC_TestDataFactory.createSingleCase_Funeral();
    }
    
    @IsTest
    static void testSendDocumentEmail() {
        
        Case funeralCase = [SELECT Id FROM Case WHERE Subject = 'Test Case - ICS-485' LIMIT 1];
        
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        // Create a list of requests
        List<IC_API_EmailDocumentService.Request> requests = new List<IC_API_EmailDocumentService.Request>();
        IC_API_EmailDocumentService.Request req = new IC_API_EmailDocumentService.Request();
        req.documentId = '12345';
        req.recipientEmail = 'recipient@example.com';
        req.parentCaseId = funeralCase.Id;
        requests.add(req);

        Test.startTest();
        IC_API_EmailDocumentService.sendDocumentEmail(requests);
        Test.stopTest();

    }

    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"documentContent": "dGVzdA==", "metaData": {"title": "Test Title", "fileExtension": "pdf"}}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockHttpErrorResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Internal Server Error"}');
            return res;
        }
    }
}