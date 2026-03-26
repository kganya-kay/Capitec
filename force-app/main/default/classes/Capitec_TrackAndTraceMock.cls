/**
 * Created by Urvashi Ragobur on 30.10.2023.
 */

@isTest
public class Capitec_TrackAndTraceMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(201);
        return response; 
    }  
}