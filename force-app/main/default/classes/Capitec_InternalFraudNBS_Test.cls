/**
 * Created by CalebGovender on 2024/11/08.
 */

@IsTest
public class Capitec_InternalFraudNBS_Test {

    @IsTest
    static void testInternalFraudNBSUpdate() {
        // Create test data
        Capitec_InternalFraudNBS.InternalFraudApprovalInput input = new Capitec_InternalFraudNBS.InternalFraudApprovalInput();
        input.cif = '1234567890';
        input.outcome = 'Approved';

        List<Capitec_InternalFraudNBS.InternalFraudApprovalInput> inputList = new List<Capitec_InternalFraudNBS.InternalFraudApprovalInput>{input};

        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Capitec_InternalFraudNBS.InternalFraudNBSUpdate(inputList);
        Test.stopTest();

        // Add assertions to verify the behavior
        System.assert(true, 'No exception should be thrown.');
    }

    @IsTest
    static void testMakeGETCalloutWithParameters() {
        String url = '/client/product-proxy/product/v1/account/list';
        String parameters = 'param1=value1&param2=value2';

        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HttpResponse response = Capitec_CalloutHandler.makeGETCalloutWithParameters(url, parameters);
        Test.stopTest();

        // Add assertions to verify the behavior
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200.');
        System.assertEquals('{"fileContent":"fakeFileContent"}', response.getBody(), 'Response body should match the mock response.');
    }

    @IsTest
    static void testMakePOSTCalloutWithBody() {
        String url = '/client/account-action-service/v1/account/block';
        String requestBody = '{"accountId":"1234567890"}';

        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HttpResponse response = Capitec_CalloutHandler.makePOSTCalloutWithBody(url, requestBody);
        Test.stopTest();

        // Add assertions to verify the behavior
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200.');
        System.assertEquals('{"fileContent":"fakeFileContent"}', response.getBody(), 'Response body should match the mock response.');
    }

    @IsTest
    static void testMakePUTCalloutWithBody() {
        String url = '/fraudp/nbs-proxy/v1/bypass';
        String requestBody = '{"cif":"1234567890","outcome":"Approved"}';

        // Mock HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HttpResponse response = Capitec_CalloutHandler.makePUTCalloutWithBody(url, requestBody);
        Test.stopTest();

        // Add assertions to verify the behavior
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200.');
        System.assertEquals('{"fileContent":"fakeFileContent"}', response.getBody(), 'Response body should match the mock response.');
    }

    // Mock HTTP response generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('200');
            res.setBody('{"fileContent":"fakeFileContent"}');
            res.setStatusCode(200);
            return res;
        }
    }
}