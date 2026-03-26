/**
 * Created by dawid on 14.11.2023.
 * Updated by Cornelia on 18.11.2024
 */

public without sharing class Capitec_FraudTHMockResponses{

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

    //CEDT-3267 - Updated column names to match new endpoint
    public static String correctJSON = '{"accountNumber":"2173375314","transactions":[{"trackingGuid":"38ef22de-050e-482f-8fa8-89803c3481d5","sourceSystem":"","tranId":"72057668039781886","sortId":74001853950,"postingDate":"2024-11-07","transactionDateTime":"2024-11-07T17:48:11.626+02:00","processDateTime":"2024-11-07T17:48:11.626+02:00","accountNr":2173375314,"cifNr":162533071,"cardNr":"0******0","journalNr":359966,"amount":609.0,"balance":0.0,"availableBalance":0.0,"fee":0.0,"moneyIn":true,"tranCode":9093,"tranSubCode":" ","branch":2001,"teller":28164,"originatorRef":"","accountRestrictionReasonCode":0,"accountRestrictionState":0,"accountRestrictionDate":"2024-11-07","classificationType":"NON_FINANCIAL","tranGroupType":"NON_FINANCIAL","channelType":"OTHER","channelTypeDesc":"","originalDesc":"SF fraud 02236475","tranTypeDesc":"Set Hold","friendlyTranTypeDesc":"Set Hold","statementDesc":"Set Hold: Sf Fraud 02236475","shortDesc":"Set Hold","merchantDesc":"","categoryId":0,"categoryName":"Uncategorised","parentCategoryId":0,"toAccountNr":0,"flaggedFraud":false,"flaggedHold":false,"flaggedChase":false,"holdAmount":0.0,"holdJournalNo":0,"holdDate":null,"autoUnholdDate":null,"updatedAt":null,"consultantIdentifier":null,"caseId":null,"toDescription":null,"caseNumber":null},{"trackingGuid":"13c037ad-c430-4851-80bf-ac2e47d7d373","sourceSystem":"","tranId":"72057668039781885","sortId":74001853949,"postingDate":"2024-11-07","transactionDateTime":"2024-11-07T17:46:02.696+02:00","processDateTime":"2024-11-07T17:46:02.696+02:00","accountNr":2173375314,"cifNr":162533071,"cardNr":"0******0","journalNr":979389,"amount":609.0,"balance":0.0,"availableBalance":0.0,"fee":0.0,"moneyIn":true,"tranCode":9095,"tranSubCode":" ","branch":2001,"teller":28164,"originatorRef":"","accountRestrictionReasonCode":0,"accountRestrictionState":0,"accountRestrictionDate":"2024-11-07","classificationType":"NON_FINANCIAL","tranGroupType":"NON_FINANCIAL","channelType":"OTHER","channelTypeDesc":"","originalDesc":"SF Fraud","tranTypeDesc":"Remove Hold","friendlyTranTypeDesc":"Remove Hold","statementDesc":"Remove Hold: Sf Fraud","shortDesc":"Remove Hold","merchantDesc":"","categoryId":0,"categoryName":"Uncategorised","parentCategoryId":0,"toAccountNr":0,"flaggedFraud":false,"flaggedHold":false,"flaggedChase":false,"holdAmount":0.0,"holdJournalNo":0,"holdDate":null,"autoUnholdDate":null,"updatedAt":null,"consultantIdentifier":null,"caseId":null,"toDescription":null,"caseNumber":null},{"trackingGuid":"40633383-73db-473e-a9db-36135bc97c80","sourceSystem":"","tranId":"72057668039740400","sortId":74001812464,"postingDate":"2024-11-07","transactionDateTime":"2024-11-07T17:10:19.263+02:00","processDateTime":"2024-11-07T17:10:19.263+02:00","accountNr":2173375314,"cifNr":162533071,"cardNr":"0******0","journalNr":279845,"amount":-1.0,"balance":2226.1,"availableBalance":1617.1,"fee":0.0,"moneyIn":false,"tranCode":9724,"tranSubCode":" ","branch":9005,"teller":9008,"originatorRef":"DSPS6451cb3bbb41411aac5731d069f47999","accountRestrictionReasonCode":0,"accountRestrictionState":0,"accountRestrictionDate":null,"classificationType":"CARD_AUTHORISATION","tranGroupType":"CARD_TRANSACTION","channelType":"REMOTE_BANKING","channelTypeDesc":"Banking App","originalDesc":"","tranTypeDesc":"Immediate Payment Fee","friendlyTranTypeDesc":"Card transaction","statementDesc":"Card transaction","shortDesc":"Card transaction","merchantDesc":"","categoryId":201,"categoryName":"Fees","parentCategoryId":200,"toAccountNr":0,"flaggedFraud":false,"flaggedHold":false,"flaggedChase":false,"holdAmount":0.0,"holdJournalNo":0,"holdDate":null,"autoUnholdDate":null,"updatedAt":null,"consultantIdentifier":null,"caseId":null,"toDescription":null,"caseNumber":null},{"trackingGuid":"40633383-73db-473e-a9db-36135bc97c80","sourceSystem":"","tranId":"72057668039740399","sortId":74001812463,"postingDate":"2024-11-07","transactionDateTime":"2024-11-07T17:10:19.245+02:00","processDateTime":"2024-11-07T17:10:19.245+02:00","accountNr":2173375314,"cifNr":162533071,"cardNr":"0******0","journalNr":279845,"amount":-50.0,"balance":2227.1,"availableBalance":1618.1,"fee":0.0,"moneyIn":false,"tranCode":1055,"tranSubCode":"1","branch":9005,"teller":9008,"originatorRef":"DSPS6451cb3bbb41411aac5731d069f47999","accountRestrictionReasonCode":0,"accountRestrictionState":0,"accountRestrictionDate":null,"classificationType":"FINANCIAL","tranGroupType":"PAYMENT_INTERNAL","channelType":"REMOTE_BANKING","channelTypeDesc":"Banking App","originalDesc":"WIAAN ACC 2","tranTypeDesc":"Immediate Payment","friendlyTranTypeDesc":"Immediate Payment","statementDesc":"Banking App Immediate Payment: Wiaan Acc 2","shortDesc":"Wiaan Acc 2","merchantDesc":"","categoryId":1527,"categoryName":"Digital Payments","parentCategoryId":1500,"toAccountNr":0,"flaggedFraud":false,"flaggedHold":false,"flaggedChase":false,"holdAmount":0.0,"holdJournalNo":0,"holdDate":null,"autoUnholdDate":null,"updatedAt":null,"consultantIdentifier":null,"caseId":null,"toDescription":null,"caseNumber":null},{"trackingGuid":"49cfd322-ae16-496c-a97c-41a82405cd40","sourceSystem":"","tranId":"72057668039740330","sortId":74001812394,"postingDate":"2024-11-07","transactionDateTime":"2024-11-07T16:59:00.429+02:00","processDateTime":"2024-11-07T16:59:00.429+02:00","accountNr":2173375314,"cifNr":162533071,"cardNr":"0******0","journalNr":291003,"amount":609.0,"balance":0.0,"availableBalance":0.0,"fee":0.0,"moneyIn":true,"tranCode":9093,"tranSubCode":" ","branch":2001,"teller":28164,"originatorRef":"","accountRestrictionReasonCode":0,"accountRestrictionState":0,"accountRestrictionDate":"2024-11-07","classificationType":"NON_FINANCIAL","tranGroupType":"NON_FINANCIAL","channelType":"OTHER","channelTypeDesc":"","originalDesc":"SF fraud 02236475","tranTypeDesc":"Set Hold","friendlyTranTypeDesc":"Set Hold","statementDesc":"Set Hold: Sf Fraud 02236475","shortDesc":"Set Hold","merchantDesc":"","categoryId":0,"categoryName":"Uncategorised","parentCategoryId":0,"toAccountNr":0,"flaggedFraud":false,"flaggedHold":false,"flaggedChase":false,"holdAmount":0.0,"holdJournalNo":0,"holdDate":null,"autoUnholdDate":null,"updatedAt":null,"consultantIdentifier":null,"caseId":null,"toDescription":null,"caseNumber":null}]}';
    public static String failedJSON = '<html><body><h1>Whitelabel Error Page</h1><p>This application has no explicit mapping for /error, so you are seeing this as a fallback.</p><div id=\'created\'>Tue Nov 14 17:46:02 SAST 2023</div><div>There was an unexpected error (type=Internal Server Error, status=500).</div></body></html>';
    public static String emptyJSON = '{"accountNumber":null,"transactions":null}';
    public static String correctCAJSON = '{\n' +
    '      "trackingGuid": "40633383-73db-473e-a9db-36135bc97c80",\n' +
    '      "sourceSystem": "",\n' +
    '      "tranId": "72057668039740399",\n' +
    '      "sortId": 74001812463,\n' +
    '      "postingDate": "2024-11-07",\n' +
    '      "transactionDateTime": "2024-11-07T17:10:19.245+02:00",\n' +
    '      "processDateTime": "2024-11-07T17:10:19.245+02:00",\n' +
    '      "accountNr": 1303498705,\n' +
    '      "cifNr": 162533071,\n' +
    '      "cardNr": "0******0",\n' +
    '      "journalNr": 279845,\n' +
    '      "amount": -50.0,\n' +
    '      "balance": 2227.1,\n' +
    '      "availableBalance": 1618.1,\n' +
    '      "fee": 0.0,\n' +
    '      "moneyIn": false,\n' +
    '      "tranCode": 1055,\n' +
    '      "tranSubCode": "1",\n' +
    '      "branch": 9005,\n' +
    '      "teller": 9008,\n' +
    '      "originatorRef": "DSPS6451cb3bbb41411aac5731d069f47999",\n' +
    '      "accountRestrictionReasonCode": 0,\n' +
    '      "accountRestrictionState": 0,\n' +
    '      "accountRestrictionDate": null,\n' +
    '      "classificationType": "FINANCIAL",\n' +
    '      "tranGroupType": "PAYMENT_INTERNAL",\n' +
    '      "channelType": "REMOTE_BANKING",\n' +
    '      "channelTypeDesc": "Banking App",\n' +
    '      "originalDesc": "WIAAN ACC 2",\n' +
    '      "tranTypeDesc": "Immediate Payment",\n' +
    '      "friendlyTranTypeDesc": "Immediate Payment",\n' +
    '      "statementDesc": "Banking App Immediate Payment: Wiaan Acc 2",\n' +
    '      "shortDesc": "Wiaan Acc 2",\n' +
    '      "merchantDesc": "",\n' +
    '      "categoryId": 1527,\n' +
    '      "categoryName": "Digital Payments",\n' +
    '      "parentCategoryId": 1500,\n' +
    '      "toAccountNr": 0,\n' +
    '      "flaggedFraud": false,\n' +
    '      "flaggedHold": false,\n' +
    '      "flaggedChase": false,\n' +
    '      "holdAmount": 0.0,\n' +
    '      "holdJournalNo": 0,\n' +
    '      "holdDate": null,\n' +
    '      "autoUnholdDate": null,\n' +
    '      "updatedAt": null,\n' +
    '      "consultantIdentifier": null,\n' +
    '      "caseId": null,\n' +
    '      "toDescription": null,\n' +
    '      "caseNumber": null\n' +
    '   }';
}