/*
********************************************************************************************
Apex Class Name    : Capitec_GenericCalloutHandler
Created Date       : October 22, 2024
@description       : Cloned and updated from capitec_FraudCalloutHandler, by Dawid Kuczer
                     Retrieves products and transaction history via the generic
					 'support' endpoint - used for non-Fraud Transaction History operations.
@author            : Cornelia Smit
Modification Log:
Ver   Date         Author                 Modification
1.0   03-11-2024   Cornelia Smit         Initial Version
********************************************************************************************
*/

public with sharing class Capitec_GenericCalloutHandler {
    private static final String TH_PRODUCT_SERVICE = 'GenericProductService';
    private static final String TH_HISTORY_SERVICE = 'GenericTransactionHistoryService';
    private static final String TH_NAMED_CREDENTIALS = WebServiceSettings__c.getValues(TH_HISTORY_SERVICE).Scheme__c +
            WebServiceSettings__c.getValues(TH_HISTORY_SERVICE).Named_Credential__c;
    private static final String TH_PRODUCTS_ENDPOINT = WebServiceSettings__c.getValues(TH_PRODUCT_SERVICE).Endpoint_URL__c;
    private static final String TH_HISTORY_ENDPOINT = WebServiceSettings__c.getValues(TH_HISTORY_SERVICE).Endpoint_URL__c;
    private static final String TH_STATIC_PARAMETERS = '&startAtIndex=0&maxResults=50000&moneyType=BOTH';
    private static final Integer MAX_TIMEOUT_VAL = 120000;

    /**
     * @description  Retrieves the products linked to a customer account from an external object via http callout
     * @param        cifNumber CIF number of the customer account
     * @return       String containing the response JSON with the list of products
     */
    public static String getProductsByCIF(String cifNumber) {

        String urlCifParameter = 'cifNumber=' + EncodingUtil.urlEncode(cifNumber, 'UTF-8'); //Avoid URL injection issues
        String fullEndpoint = constructURL(TH_PRODUCTS_ENDPOINT, urlCifParameter);
        HttpResponse res = makeGetCallout(fullEndpoint);

        switch on res.getStatusCode() {
            when 200 {
                return appendPositiveStatusToJSON(res.getBody());
            }
            when 400 {
                return constructErrorJSON(res.getStatusCode(), 'There are no Products associated with this CIF Number');
            }
            when else {
                return constructErrorJSON(res.getStatusCode(), 'An unexpected error has occurred, please try again later');
            }
        }
    }

    /**
     * @description  Retrieves the transaction history for a specific product over a time period
     * @param        capiAccountNumber product account number with NO LEADING ZEROS
     * @param        startDate start date for transaction history data
     * @param        endDate end date for transaction history data
     * @return       String containing the response JSON with the list of transaction history lines for the product
     */
    public static String getTransactionsByProduct(String capiAccountNumber, String startDate, String endDate) {

        String urlParameters = 'accountNr=' + EncodingUtil.urlEncode(capiAccountNumber, 'UTF-8') +
                '&startDate=' + EncodingUtil.urlEncode(startDate, 'UTF-8') +
                '&endDate=' + EncodingUtil.urlEncode(endDate, 'UTF-8') +
                TH_STATIC_PARAMETERS;
        String fullEndpoint = constructURL(TH_HISTORY_ENDPOINT, urlParameters);
        HttpResponse res = makeGetCallout(fullEndpoint);

        switch on res.getStatusCode() {
            when 200 {
                return appendPositiveStatusToJSON(appendTransactionsNodeToJSON(res.getBody(), capiAccountNumber)); //Add the TH list to the 'transactions' node in the JSON response
            }
            when 204 {
                return constructErrorJSON(null, 'No Transaction History available for this account number');
            }
            when 400 {
                return constructErrorJSON(res.getStatusCode(), 'No Transaction History available for this account number');
            }
            when else {
                return constructErrorJSON(res.getStatusCode(), 'An unexpected error has occurred, please try again later');
            }
        }
    }

    /**
     * @description  Appends a positive status to a JSON response
     * @param        jsonString initial response string
     * @return       Updated response string
     */
    public static String appendPositiveStatusToJSON(String jsonString) {
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        jsonResponse.put('error', false);
        jsonResponse.put('statusCode', 200);
        return JSON.serialize(jsonResponse);
    }

    /**
     * @description  Appends a 'transaction' node to the array in the JSON response
     * @param        jsonString initial response string containing an array
     * @param        capiAccountNumber initial response capiAccountNumber
     * @return       Updated response string with node name
     */
    public static String appendTransactionsNodeToJSON(String jsonString, String capiAccountNumber) {
        Map<String, Object> jsonResponse = new Map<String, Object>();
        jsonResponse.put('transactions', JSON.deserializeUntyped(jsonString));
        jsonResponse.put('accountNumber', capiAccountNumber);
        return JSON.serialize(jsonResponse);
    }

    /**
     * @description  Constructs a JSON string response when an error occurs in a callout
     * @param        statusCode error code from the callout response
     * @param        message custom error message
     * @return       Error response JSON string
     */
    public static String constructErrorJSON(Integer statusCode, String message) {
        Map<String, Object> errorResponse = new Map<String, Object>{
                'error' => true,
                'statusCode' => statusCode,
                'message' => message
        };
        return JSON.serialize(errorResponse);
    }

    /**
     * @description  Makes an http callout to a specified endpoint
     * @param        fullEndpointUrl full endpoint string with parameters
     * @return       Http response object
     */
    public static HttpResponse makeGetCallout(String fullEndpointUrl) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setMethod('GET');
        req.setTimeout(MAX_TIMEOUT_VAL);
        req.setEndpoint(fullEndpointUrl);

        HttpResponse res = new HttpResponse();

        try {
            res = http.send(req);
        } catch (Exception e) {
            res.setBody(constructErrorJSON(500, 'Failed callout: ' + e.getMessage()));
        }
        return res;
    }

    /**
     * @description  Constructs a URL from a specified endpoint and parameters
     * @param        endpoint string endpoint
     * @param        parameters string parameters
     * @return       Full URL string
     */
    public static String constructURL(String endpoint, String parameters) {
        return (TH_NAMED_CREDENTIALS + endpoint + parameters);
    }
}