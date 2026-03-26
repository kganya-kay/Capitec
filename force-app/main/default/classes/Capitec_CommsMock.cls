/**
 * Created by Vignesh on 28.12.2023.
 */

public class Capitec_CommsMock implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest httpRequest) {
        Capitec_CommsController.NotifyStatusChangeWrapper body = (Capitec_CommsController.NotifyStatusChangeWrapper)JSON.deserialize(httpRequest.getBody(),
                Capitec_CommsController.NotifyStatusChangeWrapper.class);

        if (body.templateID == '') {
            return unSuccessfulResponse();
        }

        return successfulResponse();
    }

    private static HttpResponse successfulResponse() {
        String body = '{"id":"8639d391-d169-4d91-9cd4-e87c9947e594","responseDateTime":"2023-04-13T13:56:57.853875464+02:00","correlationId":"5afe0f07-9c14-4523-a910-b31bc16b71da","errorCode":null,"errorDescription":null,"success":true}';
        HttpResponse response = new HttpResponse();
        response.setBody(body);
        response.setStatusCode(200);
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