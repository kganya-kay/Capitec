/**
 * Created by dawid on 09.11.2023.
 */

 public with sharing class Capitec_FraudCalloutHandler {

    private static final String TH_NAMED_CREDENTIALS = 'callout:CapiEndpoints';

    private static final String TH_PRODUCTS_ENDPOINT = '/client/product-proxy/product/v1/account/list?';
    //private static final String TH_HISTORY_ENDPOINT = '/client/transaction-proxy/transaction/v1/history?';
    private static final String TH_CHASED_ENDPOINT = '/client/transaction-proxy/transaction/v1/chased?';  //not used
     
    //private static final String TH_FLAGGED_ENDPOINT = '/client/transaction-proxy/transaction/v1/flagged?';
    //private static final String TH_CONFIRM_HOLD_ENDPOINT = '/client/transaction-proxy/transaction/v1/confirm-hold'; //FFSF-513 - updated endpoint to include transaction-proxy

    private static final String TH_POST_CHASE_ENDPOINT = '/client/transaction-proxy/transaction/v1/chase?'; //not used
    //private static final String TH_POST_APPLY_ACTIONS_ENDPOINT = '/client/transaction-proxy/transaction/v1/apply-actions?';


    private static final String TH_POST_APPLY_ACTIONS_ENDPOINT = '/fraudp/salesforce-transaction/transaction/v1/apply-actions?';
    private static final String TH_HISTORY_ENDPOINT = '/fraudp/salesforce-transaction/transaction/v1/history?';
    private static final String TH_FLAGGED_ENDPOINT = '/fraudp/salesforce-transaction/transaction/v1/transactions/related/';
    private static final String TH_CONFIRM_HOLD_ENDPOINT = '/fraudp/salesforce-transaction/transaction/v1/confirm-hold'; //FFSF-513 - updated endpoint to include transaction-proxy

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

    public static String getTransactionsByProduct(String capiAccountNumber, String caseId, String startDate, String endDate, String accTypeVal){
        System.debug('****');
        System.debug(capiAccountNumber);
        System.debug(caseId);
        System.debug(startDate);
        System.debug(endDate);

        String accType = '&transactionClassificationTypeList=FINANCIAL&transactionClassificationTypeList=NON_FINANCIAL&transactionClassificationTypeList=CARD_AUTHORISATION&transactionClassificationTypeList=CARD_AUTH_FINANCIAL';

        If(accTypeVal == 'FINANCIAL'){
             accType = '&transactionClassificationTypeList=FINANCIAL';    
        } else If(accTypeVal == 'NON_FINANCIAL'){
             accType = '&transactionClassificationTypeList=NON_FINANCIAL'; 
        } else If(accTypeVal == 'CARD_AUTH_FINANCIAL'){
             accType = '&transactionClassificationTypeList=CARD_AUTH_FINANCIAL';
        }else If(accTypeVal == 'FINANCIALNONFINANCIAL'){
             accType = '&transactionClassificationTypeList=FINANCIAL&transactionClassificationTypeList=NON_FINANCIAL';
        }
        else If(accTypeVal == 'CARD_AUTHORISATION'){
             accType = '&transactionClassificationTypeList=CARD_AUTHORISATION';
        }
        String urlParameters = 'accountNumber=' + capiAccountNumber + '&caseId=' + caseId + '&startDate=' + startDate + '&endDate=' +endDate + accType ;
       // String urlParameters = 'accountNumber=' + '00000001774983166' + '&caseId=' + caseId + '&startDate=' + startDate + '&endDate=' +endDate;

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

    public static String getChasedTransactions(String caseId){
        String jsonString;

        String urlCifParameter = 'caseId=' + caseId;
        String fullEndpoint = constructURL(TH_FLAGGED_ENDPOINT, urlCifParameter);
        HttpResponse res = makeGetCallout(fullEndpoint);
        System.debug(fullEndpoint);
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

    public static String getChasedTransactions(String caseId, Boolean findHolds){  //FFSF 448 total amount defrauded API
        String jsonString;

        //String urlCifParameter = 'caseId=' + caseId + '&findHolds=' + findHolds ;
        String urlCifParameter = caseId  ;
        String fullEndpoint = constructURL(TH_FLAGGED_ENDPOINT, urlCifParameter);
        HttpResponse res = makeGetCallout(fullEndpoint);
		System.debug(fullEndpoint);
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

    public static String postChase(String payloadString){
        HttpResponse res = makePostCallout(constructURL(TH_POST_CHASE_ENDPOINT,''), payloadString);

        return JSON.serialize(res.getStatusCode());
    }

    public static String postConfirmHold(String payloadString){
        HttpResponse res = makePostCallout(constructURL(TH_CONFIRM_HOLD_ENDPOINT,''), payloadString);

        return JSON.serialize(res.getStatusCode());
    }

    private static String appendPositiveStatusToJSON(String jsonString){

        //jsonString = jsonString.replaceFirst('\\{', '{' +'"error" : false,' +'"statusCode" : 200,');

        //return jsonString;

     String prefix = '{"error": false, "statusCode": 200, ';
     String restOfJson = jsonString.substring(1); // Remove the first '{'

     // Return the combined JSON string
     return prefix + restOfJson;
        
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
        
        System.debug(res.getStatusCode());
        System.debug(res.getBody());
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
        System.debug(payload);

        res = http.send(req);

        System.debug(res.getStatusCode());
        System.debug(res.getBody());
        return res;
    }

    public static String constructURL(String endpoint, String parameters){
        return (TH_NAMED_CREDENTIALS + endpoint + parameters);
    }
}