/**
 * Created 
 */

 public without sharing class Capitec_NoticeDepositsTHMockResponses{

    public class CorrectGetTHResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(correctJSON);
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }

    public class EmptyGetTHResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(emptyJSON);
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }

    public class FailedGetTHResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(failedJSON);
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    public class CorrectGetCAResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(correctCAJSON);
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }

    public class EmptyGetCAResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(emptyJSON);
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }

    public class FailedGetCAResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(failedJSON);
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    public class PostResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(failedJSON);
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }


    public static String correctJSON = '{"accountNumber":"00000002173375314","transactions":[{"account":2173375314,"amount":7.18,"balance":14572.18,"categoryId":104,"categoryName":"Interest","fee":0.0,"transactionId":64465739783,"moneyIn":true,"parentCategoryId":3000,"postingDate":"2023-10-31","sortId":64576341486,"spendGroup":"Interest","listDescription":null,"statementDescription":"Interest Received","originalDescription":null,"transactionTypeDescription":"Interest Received","transactionDate":"2023-10-31T20:12:12.393+02:00","txnCategory":"FINANCIAL","originatorId":null,"processDate":"2023-10-31T20:12:12.393+02:00","financialDate":"2023-10-31T20:12:12.393+02:00","journalNr":83408,"tranCode":730,"toAccount":0,"cifNumber":null,"fraudFlagged":false,"holdFlagged":false,"chaseFlagged":false,"holdAmount":0.0,"holdJournalNo":0,"consultantIdentifier":null,"caseId":null,"lastUpdatedAt":null,"holdLiftedAt":null},{"account":2173375314,"amount":-7.0,"balance":14565.18,"categoryId":201,"categoryName":"Fees","fee":0.0,"transactionId":64465739840,"moneyIn":false,"parentCategoryId":200,"postingDate":"2023-10-31","sortId":64576341543,"spendGroup":"Fee","listDescription":null,"statementDescription":"Monthly Account Admin Fee","originalDescription":null,"transactionTypeDescription":"Monthly Account Admin Fee","transactionDate":"2023-10-31T20:12:12.397+02:00","txnCategory":"FEE","originatorId":null,"processDate":"2023-10-31T20:12:12.397+02:00","financialDate":"2023-10-31T20:12:12.397+02:00","journalNr":83409,"tranCode":9293,"toAccount":0,"cifNumber":null,"fraudFlagged":false,"holdFlagged":false,"chaseFlagged":false,"holdAmount":0.0,"holdJournalNo":0,"consultantIdentifier":null,"caseId":null,"lastUpdatedAt":null,"holdLiftedAt":null},{"account":2173375314,"amount":-20.0,"balance":14545.18,"categoryId":2001,"categoryName":"Transfer","fee":0.0,"transactionId":64471802400,"moneyIn":false,"parentCategoryId":2000,"postingDate":"2023-11-01","sortId":64582406331,"spendGroup":"StandingOrderInternalTransfer","listDescription":"Test","statementDescription":"Recurring Transfer (16230098): Test","originalDescription":"TEST","transactionTypeDescription":"Transfer","transactionDate":"2023-10-31T23:09:29.967+02:00","txnCategory":"FINANCIAL","originatorId":null,"processDate":"2023-10-31T23:09:29.967+02:00","financialDate":"2023-10-31T23:09:29.967+02:00","journalNr":961761,"tranCode":1055,"toAccount":0,"cifNumber":null,"fraudFlagged":false,"holdFlagged":false,"chaseFlagged":false,"holdAmount":0.0,"holdJournalNo":0,"consultantIdentifier":null,"caseId":null,"lastUpdatedAt":null,"holdLiftedAt":null},{"account":2173375314,"amount":-20.0,"balance":14525.18,"categoryId":2001,"categoryName":"Transfer","fee":0.0,"transactionId":64474733109,"moneyIn":false,"parentCategoryId":2000,"postingDate":"2023-11-08","sortId":64585267491,"spendGroup":"StandingOrderInternalTransfer","listDescription":"Test","statementDescription":"Recurring Transfer (16230098): Test","originalDescription":"TEST","transactionTypeDescription":"Transfer","transactionDate":"2023-11-07T20:44:06.817+02:00","txnCategory":"FINANCIAL","originatorId":null,"processDate":"2023-11-07T20:44:06.817+02:00","financialDate":"2023-11-07T20:44:06.817+02:00","journalNr":642962,"tranCode":1055,"toAccount":0,"cifNumber":null,"fraudFlagged":false,"holdFlagged":false,"chaseFlagged":false,"holdAmount":0.0,"holdJournalNo":0,"consultantIdentifier":null,"caseId":null,"lastUpdatedAt":null,"holdLiftedAt":null}]}';
    public static String failedJSON = '<html><body><h1>Whitelabel Error Page</h1><p>This application has no explicit mapping for /error, so you are seeing this as a fallback.</p><div id=\'created\'>Tue Nov 14 17:46:02 SAST 2023</div><div>There was an unexpected error (type=Internal Server Error, status=500).</div></body></html>';
    public static String emptyJSON = '{"accountNumber":null,"transactions":null}';
    public static String correctCAJSON = '{\n' +
            '      "account":2173375314,\n' +
            '      "amount":-7.0,\n' +
            '      "balance":14565.18,\n' +
            '      "categoryId":201,\n' +
            '      "categoryName":"Fees",\n' +
            '      "fee":0.0,\n' +
            '      "transactionId":64465739840,\n' +
            '      "moneyIn":false,\n' +
            '      "parentCategoryId":200,\n' +
            '      "postingDate":"2023-10-31",\n' +
            '      "sortId":64576341543,\n' +
            '      "spendGroup":"Fee",\n' +
            '      "listDescription":null,\n' +
            '      "statementDescription":"Monthly Account Admin Fee",\n' +
            '      "originalDescription":null,\n' +
            '      "transactionTypeDescription":"Monthly Account Admin Fee",\n' +
            '      "transactionDate":"2023-10-31T20:12:12.397+02:00",\n' +
            '      "txnCategory":"FEE",\n' +
            '      "originatorId":null,\n' +
            '      "processDate":"2023-10-31T20:12:12.397+02:00",\n' +
            '      "financialDate":"2023-10-31T20:12:12.397+02:00",\n' +
            '      "journalNr":83409,\n' +
            '      "tranCode":9293,\n' +
            '      "toAccount":0,\n' +
            '      "cifNumber":null,\n' +
            '      "fraudFlagged":true,\n' +
            '      "holdFlagged":false,\n' +
            '      "chaseFlagged":true,\n' +
            '      "holdAmount":0.0,\n' +
            '      "holdJournalNo":0,\n' +
            '      "consultantIdentifier":null,\n' +
            '      "caseId":"5002600000WzdifAAB",\n' +
            '      "lastUpdatedAt":"2023-11-14T02:57:25.529618Z",\n' +
            '      "holdLiftedAt":null\n' +
            '   }';
}