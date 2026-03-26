/**
 * Created by Pako on 16.02.2024.
 */

public with sharing class Capitec_NoticeDepositsCalloutHandler {

    private static final String TH_NAMED_CREDENTIALS = 'callout:CapiEndpoints';

    private static final String TH_PRODUCTS_ENDPOINT = '/client/product-proxy/product/v1/account/list?';
    private static final String TH_HISTORY_ENDPOINT = '/client/transaction-proxy/transaction/v1/history?';
    private static final String TH_FLAGGED_ENDPOINT = '/client/transaction-proxy/transaction/v1/flagged?';

    private static final String TH_POST_APPLY_ACTIONS_ENDPOINT = '/client/transaction-proxy/transaction/v1/apply-actions?';

    private static final Integer MAX_TIMEOUT_VAL = 120000;


    public static String getProductsByCIF(String cifNumber){

        String urlCifParameter = 'cifNumber=' + cifNumber;
        String fullEndpoint = constructURL(TH_PRODUCTS_ENDPOINT, urlCifParameter);
        HttpResponse res = makeGetCallout(fullEndpoint);

        if(res.getStatusCode() == 200){
            return appendPositiveStatusToJSON(res.getBody());
        }

        if(res.getStatusCode() == 400){
            return constructErrorJSON(res.getStatusCode(), 'There are no Products associated with this CIF Number');
        }

        return constructErrorJSON(res.getStatusCode(), 'An unexpected error has occurred, please try again later');
    }

    public static String getTransactionsByProduct(String capiAccountNumber, String caseId, String startDate, String endDate){

        String urlParameters = 'accountNumber=' + capiAccountNumber + '&caseNumber=' + caseId + '&startDate=' + startDate + '&endDate=' +endDate;
        String fullEndpoint = constructURL(TH_HISTORY_ENDPOINT, urlParameters);
        HttpResponse res = makeGetCallout(fullEndpoint);

        System.debug(res.getStatusCode());
        System.debug(res.getBody());

        if(res.getStatusCode() == 200){
            return appendPositiveStatusToJSON(res.getBody());
        }
         if(res.getStatusCode() == 400){
            return constructErrorJSON(res.getStatusCode(), 'There are no Transaction History items associated with this Account Number');
        }

        return constructErrorJSON(res.getStatusCode(), 'An unexpected error has occurred, please try again later');
    }

    public static String getFlaggedTransactions(String caseId){
        String jsonString;

        String urlCifParameter = 'caseId=' + caseId;
        String fullEndpoint = constructURL(TH_FLAGGED_ENDPOINT, urlCifParameter);
        HttpResponse res = makeGetCallout(fullEndpoint);

        System.debug(res.getStatusCode());
        System.debug(res.getBody());


        if(res.getStatusCode() == 200){
            return res.getBody();
        }

        if(res.getStatusCode() == 404){
            return constructErrorJSON(res.getStatusCode(), 'There are no Transaction History items associated with this Case Id');
        }

        return constructErrorJSON(res.getStatusCode(), 'An unexpected error has occurred, please try again later');
    }

    public static String postApplyActions(String payloadString){
        HttpResponse res = makePostCallout(constructURL(TH_POST_APPLY_ACTIONS_ENDPOINT,''), payloadString);

        return JSON.serialize(res.getStatusCode());
    }

    private static String appendPositiveStatusToJSON(String jsonString){

        jsonString = jsonString.replaceFirst('\\{', '{' +
                                                    '"error" : false,' +
                                                    '"statusCode" : 200,');

        return jsonString;
    }
    private static String constructErrorJSON(Integer statusCode, String message){

        String jsonString = '{\n' +
                            '  "error" : true,\n' +
                            '  "statusCode" : "' + statusCode + '",\n' +
                            '  "message" : "' + message + '"\n' +
                            '}';

        return jsonString;
    }

    public static HttpResponse makeGetCallout(String fullEndpointUrl){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res;

        req.setMethod('GET');
        req.setTimeout(MAX_TIMEOUT_VAL);
        req.setEndpoint(fullEndpointUrl);

        System.debug(req.getEndpoint());

        res = http.send(req);
        return res;
    }

    public static HttpResponse makePostCallout(String fullEndpointUrl, String payload){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res;

        req.setMethod('POST');
        req.setTimeout(MAX_TIMEOUT_VAL);
        req.setEndpoint(fullEndpointUrl);
        req.setBody(payload);

        System.debug(req.getEndpoint());

        res = http.send(req);

        System.debug(res.getStatusCode());
        System.debug(res.getBody());
        return res;
    }

    public static String constructURL(String endpoint, String parameters){
        return (TH_NAMED_CREDENTIALS + endpoint + parameters);
    }
}