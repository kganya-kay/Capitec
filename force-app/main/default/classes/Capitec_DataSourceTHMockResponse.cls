/**
 * Created by Sebastian on 19.04.2023.
 */

public class Capitec_DataSourceTHMockResponse implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest httpRequest) {
        if(httpRequest.getEndpoint().contains('/transaction-proxy/transaction/v1/history')){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"accountNumber":"1953752983","transactions":[{"transactionId":0,"accountNumber":0,"transactionDate":"2023-04-19T08:35:00.161Z","postingDate":"2023-04-19","interestDate":"2023-04-19","originalDescription":"string","statementDescription":"string","amount":0,"balance":0,"availableBalance":0,"fee":0,"transactionCode":0,"sortId":0,"classification":"string","budgetCategoryId":0,"budgetCategoryName":"string","budgetParentCategoryId":0,"budgetParentCategoryName":"string","includesVAT":true,"journalNumber":0,"branch":0,"teller":0,"channel":"string","externalTerminalId":"string","cardAuthType":"string","cardNumber":"string","transferAccount":0,"showOnStatement":true,"moneyIn":true,"cashback":0,"processDate":"2023-04-19","merchantDescription":"string","daysToClear":0,"transTypeDesc":"string","spendGroup":"string","disputeFlag":"string","disputeReason":"string","disputeRef":"string","disputeDate":"2023-04-19T08:35:00.161Z","riskReference":"string","riskFlagged":true}]}');
            res.setStatusCode(200);
                res.setStatus('test');
            return res;
        }
        else{
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"cifNumber":"100018459","accounts":[{"accountNumber":"00000001935459277","accountName":"LIVEBETTERSAVINGSACCOUNT","accountProduct":null,"accountType":"0210","accountStatus":"OPEN","availableBalance":1.99,"currentBalance":1.99,"creditCardArrears":null,"maturityDate":null,"fixingDate":null,"lastFinancialTransactionDate":null,"openDate":"2022-04-13","savingsAccountTerm":0,"moneyIn":true,"moneyOut":true}]}');
            res.setStatusCode(200);
                res.setStatus('test');
            return res;
        }

    }


    public class failedResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest httpRequest) {
            if (httpRequest.getEndpoint().contains('/transaction-proxy/transaction/v1/history')) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('');
                res.setStatusCode(500);
                res.setStatus('test');
                return res;
            }
            else{
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"cifNumber":"100018459","accounts":[{"accountNumber":"00000001935459277","accountName":"LIVEBETTERSAVINGSACCOUNT","accountProduct":null,"accountType":"0210","accountStatus":"OPEN","availableBalance":1.99,"currentBalance":1.99,"creditCardArrears":null,"maturityDate":null,"fixingDate":null,"lastFinancialTransactionDate":null,"openDate":"2022-04-13","savingsAccountTerm":0,"moneyIn":true,"moneyOut":true}]}');
                res.setStatusCode(200);
                res.setStatus('test');
                return res;
            }
        }
    }

    public class badResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest httpRequest) {
            if (httpRequest.getEndpoint().contains('/transaction-proxy/transaction/v1/history')) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'multipart/form-data');
                res.setBody('---;"""312121024893290sdjakffd;sjkln2348u');
                res.setStatusCode(200);
                res.setStatus('test');
                return res;
            }
            else{
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"cifNumber":"100018459","accounts":[{"accountNumber":"00000001935459277","accountName":"LIVEBETTERSAVINGSACCOUNT","accountProduct":null,"accountType":"0210","accountStatus":"OPEN","availableBalance":1.99,"currentBalance":1.99,"creditCardArrears":null,"maturityDate":null,"fixingDate":null,"lastFinancialTransactionDate":null,"openDate":"2022-04-13","savingsAccountTerm":0,"moneyIn":true,"moneyOut":true}]}');
                res.setStatusCode(200);
                res.setStatus('test');
                return res;
            }
        }
    }

    public class badProductResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest httpRequest) {
            if (httpRequest.getEndpoint().contains('/transaction-proxy/transaction/v1/history')) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'multipart/form-data');
                res.setBody('---;"""312121024893290sdjakffd;sjkln2348u');
                res.setStatusCode(200);
                res.setStatus('test');
                return res;
            }
            else{
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'multipart/form-data');
                res.setBody('```!@!!~~~~~$DSFDSA ER  ewr-={nts":[{"accountNumber":"0000"LIVEBETTERSAVINGSACCOpe":"0210","accountStatus":,"currentBalance":1.99,"crediull,"fixingDate":null,"actionDate":null,"openDate":"2022-04-13","savingsAccountTerm":0,"moneyIn":true,"moneyOut":true}]}');
                res.setStatusCode(200);
                res.setStatus('test');
                return res;
            }
        }
    }

    public class failedProductResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest httpRequest) {
            if (httpRequest.getEndpoint().contains('/transaction-proxy/transaction/v1/history')) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'multipart/form-data');
                res.setBody('---;"""312121024893290sdjakffd;sjkln2348u');
                res.setStatusCode(500);
                res.setStatus('test');
                return res;
            }
            else{
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'multipart/form-data');
                res.setBody('```!@!!~~~~~$DSFDSA ER  ewr-={nts":[{"accountNumber":"0000"LIVEBETTERSAVINGSACCOpe":"0210","accountStatus":,"currentBalance":1.99,"crediull,"fixingDate":null,"actionDate":null,"openDate":"2022-04-13","savingsAccountTerm":0,"moneyIn":true,"moneyOut":true}]}');
                res.setStatusCode(500);
                res.setStatus('test');
                return res;
            }
        }
    }
}