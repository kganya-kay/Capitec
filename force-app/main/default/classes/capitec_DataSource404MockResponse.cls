/**
 * Created by Sebastian on 19.04.2023.
 */

public class capitec_DataSource404MockResponse implements HttpCalloutMock{

    public HttpResponse respond(HttpRequest httpRequest) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"error":"404"}');
        res.setStatusCode(404);
        return res;
    }
}