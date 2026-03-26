/**
 * Created by dawid on 22.06.2023.
 */

public with sharing class Capitec_DocumentumMock {
    public class correctResponse implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest httpRequest) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('');
            res.setStatusCode(200);
            return res;
        }
    }
}