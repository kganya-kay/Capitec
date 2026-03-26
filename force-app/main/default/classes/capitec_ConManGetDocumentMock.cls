@IsTest

public class capitec_ConManGetDocumentMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {

    String jsonResponse = '[{"documentId":"86e22c17-0ba1-47f7-9c1c-c474d3b777ea", ' +
                                            '"documentType":4,' +
                                            '"documentSubType":0,' +
                                            '"documentStatus":"ACCEPTED",' +
                                            '"contentType":"png",' +
                                            '"modifiedDateTime":"2024-12-04T15:09:26.568+02:00",' +
                                            '"creationDateTime":"2024-12-04T15:09:26.568+02:00"}, ' +
                                        '{"documentId":"86e22c17-0ba1-47f7-9c1c-c474d3b777ea", ' +
                                            '"documentType":1,' +
                                            '"documentSubType":0,' +
                                            '"documentStatus":"ACCEPTED",' +
                                            '"contentType":"png",' +
                                            '"modifiedDateTime":"2024-12-04T15:09:26.568+02:00",' +
                                            '"creationDateTime":"2024-12-04T15:09:26.568+02:00"}, ' +
                                        '{"documentId":"86e22c17-0ba1-47f7-9c1c-c474d3b777ea", ' +
                                            '"documentType":25,' +
                                            '"documentSubType":0,' +
                                            '"documentStatus":"ACCEPTED",' +
                                            '"contentType":"png",' +
                                            '"modifiedDateTime":"2024-12-04T15:09:26.568+02:00",' +
                                            '"creationDateTime":"2024-12-04T15:09:26.568+02:00"}]';


        // Create the HTTP response and set the body
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(jsonResponse);
        res.setStatusCode(200);

        return res;
    }

    public class failedResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest httpRequest) {
            if (httpRequest.getEndpoint().contains('/content/bc/api/v2/documents/')) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('');
                res.setStatusCode(500);
                res.setStatus('test');
                return res;
            }
            else{
                return null;
            }
        }    
    }    
}