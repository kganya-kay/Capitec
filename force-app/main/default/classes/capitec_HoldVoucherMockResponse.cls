/**
 * Created by CalebGovender on 2023/06/23.
 */
@IsTest
public class capitec_HoldVoucherMockResponse implements HttpCalloutMock{

    public HttpResponse respond(HttpRequest request) {
        capitec_HoldCashVoucher.RequestBodyWrapper body = (capitec_HoldCashVoucher.RequestBodyWrapper)JSON.deserialize(request.getBody(),
                capitec_HoldCashVoucher.RequestBodyWrapper.class);
        if (body.orderReference == '') {
            return unSuccessfulResponse();
        }

        return successfulResponse();
    }

    private static HttpResponse successfulResponse() {
        String body = '{"id":"8639d391-d169-4d91-9cd4-e87c9947e594","responseDateTime":"2023-04-13T13:56:57.853875464+02:00","correlationId":"5afe0f07-9c14-4523-a910-b31bc16b71da","journalNumber":null,"errorCode":null,"errorDescription":null,"success":true}';
        HttpResponse response = new HttpResponse();
        response.setBody(body);
        response.setStatusCode(200);
        return response;
    }

    private static HttpResponse unSuccessfulResponse() {
        String body = '{"timestamp":"2023-05-23T08:08:41.074+00:00","status":400,"error":"BadRequest","path":"/v1/unblock-channel"}';
        HttpResponse response = new HttpResponse();
        response.setBody(body);
        response.setStatusCode(400);
        return response;
    }
}