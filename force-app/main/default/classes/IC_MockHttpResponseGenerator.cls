@isTest
public class IC_MockHttpResponseGenerator implements HttpCalloutMock {
    private HttpResponse response;

    // Constructor to set the mock response
    public IC_MockHttpResponseGenerator(HttpResponse response) {
        this.response = response;
    }

    // Implement the respond method
    public HttpResponse respond(HttpRequest req) {
        return response;
    }
}