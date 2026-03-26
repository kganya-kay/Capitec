/**
 * @description Mock implementation of HttpCalloutMock for simulating HTTP responses.
 */
public with sharing class Capitec_GetProactiveSkillsMock implements HttpCalloutMock {

    /**
     * @description The body of the mock HTTP response.
     */
    public String responseBody;

    /**
     * @description The status code of the mock HTTP response.
     */
    public Integer statusCode;

    /**
     * @description Constructor to initialize the mock response body and status code.
     * 
     * @param responseBody The body of the mock HTTP response.
     * @param statusCode The status code of the mock HTTP response.
     */
    public Capitec_GetProactiveSkillsMock(String responseBody, Integer statusCode) {
        this.responseBody = responseBody;
        this.statusCode = statusCode;
    }

    /**
     * @description Responds to the HTTP request with the mock response.
     * 
     * @param httpRequest The HTTP request to respond to.
     * @return The mock HTTP response.
     */
    public HttpResponse respond(HttpRequest httpRequest) {
        return response(responseBody, statusCode);
    }

    /**
     * @description Creates a mock HTTP response with the given body and status code.
     * 
     * @param body The body of the mock HTTP response.
     * @param statusCode The status code of the mock HTTP response.
     * @return The mock HTTP response.
     */
    private static HttpResponse response(String body, Integer statusCode) {
        HttpResponse response = new HttpResponse();
        response.setBody(body);
        response.setStatusCode(statusCode);
        return response;
    }
}