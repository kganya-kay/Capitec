/**
 * Created by Marinus on 16.04.2024.
 */

public class Capitec_LogEmailEventMock implements HttpCalloutMock {
    
    public HttpResponse respond(HttpRequest httpRequest) {
        capitec_LogSFEmailEvent.LogEmailEventWrapper body = (capitec_LogSFEmailEvent.LogEmailEventWrapper)JSON.deserialize(httpRequest.getBody(),
                capitec_LogSFEmailEvent.LogEmailEventWrapper.class);
        
        if (body.ParentId == '') {
            return unSuccessfulResponse();
        }

        return successfulResponse();
    }
    
    private static HttpResponse successfulResponse() {
        String body = '{"id":"8639d391-d169-4d91-9cd4-e87c9947e594","responseDateTime":"2023-04-13T13:56:57.853875464+02:00","correlationId":"5afe0f07-9c14-4523-a910-b31bc16b71da","errorCode":null,"errorDescription":null,"success":true}';
        HttpResponse response = new HttpResponse();
        response.setBody(body);
        response.setStatusCode(204);
        return response;
    }

    private static HttpResponse unSuccessfulResponse() {
        String body = '{"timestamp":"2023-05-23T08:08:41.074+00:00","status":400,"error":"BadRequest","path":"/v1/notify"}';
        HttpResponse response = new HttpResponse();
        response.setBody(body);
        response.setStatusCode(400);
        return response;
    }
}