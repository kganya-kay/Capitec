/**
 * Created by Sebastian on 19.04.2023.
 */

public class Capitec_DataSourceCHMockResponse implements HttpCalloutMock{

    public HttpResponse respond(HttpRequest httpRequest) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"cifNumber":"00000000100590934","numberOfCards":4,"cards":[{"cardNumber":"5284973230734448","cardStatus":"01","cardType":"P","cardTypeFlag":"2","expiryDate":"06/29","fullName":"DEV","identityNumber":"6503255578087","identityType":2,"linkedCard":"0000000000000000","cardNotPresentAllowed":true,"cardPersonalized":true,"cardStopDate":null},{"cardNumber":"5054092087556438","cardStatus":"03","cardType":"P","cardTypeFlag":"3","expiryDate":"07/16","fullName":"DEV","identityNumber":"6503255578087","identityType":2,"linkedCard":"0000000000000000","cardNotPresentAllowed":false,"cardPersonalized":false,"cardStopDate":"2016-11-13"},{"cardNumber":"5054092000483256","cardStatus":"03","cardType":"P","cardTypeFlag":"3","expiryDate":"09/12","fullName":"DEV","identityNumber":"6503255578087","identityType":2,"linkedCard":"0000000000000000","cardNotPresentAllowed":false,"cardPersonalized":false,"cardStopDate":null},{"cardNumber":"6037362000235448","cardStatus":"03","cardType":"P","cardTypeFlag":"0","expiryDate":"07/12","fullName":"DEV","identityNumber":"6503255578087","identityType":2,"linkedCard":"0000000000000000","cardNotPresentAllowed":false,"cardPersonalized":false,"cardStopDate":"2004-02-13"}]}');
        res.setStatusCode(200);
        return res;
    }
}