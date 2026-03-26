@isTest
public class capitec_ConManGetImageMock implements HttpCalloutMock {
    
    // Implement the respond method
    public HttpResponse respond(HttpRequest req) {
        // Create a new HttpResponse
        HttpResponse res = new HttpResponse();
        
        // Set the status and status code to simulate a successful response
        res.setStatusCode(200);
        res.setStatus('OK');
        
        // Mock binary data representing the image content.
        // Note: For a real test, you may use an actual base64 or binary string.
        Blob imageBlob = Blob.valueOf('SampleBinaryContent');
        res.setBodyAsBlob(imageBlob);

        return res;
    }
}