public with sharing class Capitec_BadBeneficiariesMockResponses {

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"response":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    public class GetBadBeneficiaries implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(FullJSON);
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }

    public class EmptyBadBeneficiaries implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(emptyJSON);
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
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

    public class UploadBadBeneficiaries implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(FullJSON);
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(204);
            return res;
        }
    }

    public static String correctJSON = '{"error" : false, "statusCode" : 200, "data" : []}';
    public static String FullJSON = '{"beneficiaries":[{"benIdentifier":"62783236336","institution":"UNKNOWN","badBenStatus":"PENDING_FRAUD","benType":"ACCOUNT_NUMBER","caseCount":6,"riskScore":0.0,"createDate":"2024-09-09T13:27:45.845692+02:00","updatedDate":"2024-09-17T12:46:20.759098+02:00","ageInMonths":0,"numberOfPayments":1,"turnover":100.0},{"benIdentifier":"1303498705","institution":"UNKNOWN","badBenStatus":"NO_FRAUD","benType":"ACCOUNT_NUMBER","caseCount":3,"riskScore":0.0,"createDate":"2024-09-16T13:14:00.458391+02:00","updatedDate":"2024-09-17T12:46:26.171625+02:00","ageInMonths":0,"numberOfPayments":0,"turnover":0.0}],"pageSize":100,"currentPage":1,"totalNumberOfPages":1}';
    public static String failedJSON = '{"error" : true, "statusCode" : 500, "message" : "An unexpected error has occurred, please try again later"}';
    public static String emptyJSON = '{"error" : true, "statusCode" : 400, "message" : "There are no Bad Beneficiaries associated with this Account Number"}';
}