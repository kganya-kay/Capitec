/**
 * Created by Sebastian on 19.04.2023.
 */

public class capitec_DataSourceProductsMockResponse implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest request) {

        if (request.getEndpoint().contains('product-proxy/product/v1/account/list') &&
            request.getEndpoint().contains('?cifNumber=') &&
            request.getEndpoint().contains('&accountNumber=')) {
            return responseForOneProduct();
        }

        if (request.getEndpoint().contains('product-proxy/product/v1/account/list') &&
            request.getEndpoint().contains('?cifNumber=')) {
            return resposneForProductsFilterdByRelatedAccount();
        }

        throw new DataSourceProductsMockResponseException('No mock response for this endpoint implemented');
    }

    private static HttpResponse responseForOneProduct() {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"cifNumber":"100018459","accounts":[{"accountNumber":"00000001935459277","accountName":"LIVEBETTERSAVINGSACCOUNT","accountProduct":null,"accountType":"0210","accountStatus":"OPEN","availableBalance":1.99,"currentBalance":1.99,"creditCardArrears":null,"maturityDate":null,"fixingDate":null,"lastFinancialTransactionDate":null,"openDate":"2022-04-13","savingsAccountTerm":0,"moneyIn":true,"moneyOut":true}]}');
        res.setStatusCode(200);
        return res;
    }

    private static HttpResponse resposneForProductsFilterdByRelatedAccount() {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"cifNumber":"100018459","accounts":[{"accountNumber":"00000001935459277","accountName":"LIVEBETTERSAVINGSACCOUNT","accountProduct":null,"accountType":"0210","accountStatus":"OPEN","availableBalance":1.99,"currentBalance":1.99,"creditCardArrears":null,"maturityDate":null,"fixingDate":null,"lastFinancialTransactionDate":null,"openDate":"2022-04-13","savingsAccountTerm":0,"moneyIn":true,"moneyOut":true},{"accountNumber":"00000001887163350","accountName":"SAVINGSACCOUNT","accountProduct":null,"accountType":"0300","accountStatus":"OPEN","availableBalance":513.37,"currentBalance":543.37,"creditCardArrears":null,"maturityDate":null,"fixingDate":null,"lastFinancialTransactionDate":null,"openDate":"2022-01-27","savingsAccountTerm":0,"moneyIn":true,"moneyOut":true}]}');
        res.setStatusCode(200);
        return res;
    }

    public class DataSourceProductsMockResponseException extends Exception {}
}