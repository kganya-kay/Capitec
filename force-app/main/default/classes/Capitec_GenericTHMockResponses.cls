/*
********************************************************************************************
Apex Class Name    : Capitec_GenericTHMockResponses
Created Date       : November 03, 2024
@description       : Cloned and updated from Capitec_FraudTHMockResponses, by Dawid Kuczer
                     Mock responses for Capitec_GenericTHControllerTest
@author            : Cornelia Smit
Modification Log:
Ver   Date         Author                 Modification
1.0   03-11-2024   Cornelia Smit         Initial Version
********************************************************************************************
*/
public without sharing class Capitec_GenericTHMockResponses {

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
            res.setStatusCode(400);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    public class CorrectGetProductsResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(productJSON);
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    public class FailedGetProductsResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            res.setBody(failedJSON);
            res.setStatusCode(400);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    public static String correctJSON = Capitec_GenericTHController.TRANHISTORYExample;
    public static String productJSON = Capitec_GenericTHController.PRODUCTSExample;
    public static String failedJSON = '{"error":true,"statusCode":400,"message":"Invalid request parameters."}';
    public static String emptyJSON = '[]';
    }