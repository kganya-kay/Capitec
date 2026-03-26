/**
 * This class handles various HTTP callouts to the Capitec API endpoints.
 * It includes methods for making GET, POST, and PUT callouts with parameters or request bodies.
 *
 * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
 *
 * @date 13/04/2023
 * @author Dawid Kuczer
 *
 * @LastModified 10/09/2024
 * @LastModifiedBy Caleb Govender
 */
public with sharing class Capitec_CalloutHandler {
    public static final String PRODUCTS_LIST_URL = '/client/product-proxy/product/v1/account/list';
    public static final String TRANSACTION_HISTORY_LIST_URL = '/client/transaction-proxy/transaction/v1/history';
    public static final String TRANSACTION_HISTORY_FLAG_LIST_URL = '/client/transaction-proxy/transaction/v1/flagRisk';
    public static final String PRODUCTS_BLOCK_ACCOUNT = '/client/account-action-service/v1/account/block';
    public static final String PRODUCTS_UNBLOCK_ACCOUNT = '/client/account-action-service/v1/account/unblock';
    public static final String BLOCK_CHANNEL ='/client/account-action-service/v1/channel/block';
    public static final String UNBLOCK_CHANNEL ='/client/account-action-service/v1/channel/unblock';
    public static final String HOLD_CASHVOUCHER = '/client/account-action-service/v1/send-cash/hold-status';
    public static final String BLOCK_CARD = '/client/account-action-service/v1/card/stop';
    public static final String PAUSE_CARD = '/client/account-action-service/v1/card/pause';
    public static final String UNPAUSE_CARD = '/client/account-action-service/v1/card/unpause';

    public static HttpResponse makeGETCalloutWithParameters(String url, String parameters){

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response;

        request.setTimeout(10000);
        request.setMethod('GET');
        request.setEndpoint('callout:CapiEndpoints' + url + '?' + parameters);

        response = http.send(request);

        System.debug('REQUEST ENDPOINT: ' + request.getEndpoint());
        System.debug('RESPONSE BODY: ' + response.getBody());

        if(response.getStatusCode() != 200){
            response = http.send(request);
            System.debug('REQUEST ENDPOINT: ' + request.getEndpoint());
            System.debug('RESPONSE BODY: ' + response.getBody());
        }

        return response;
    }


    public static HttpResponse makePOSTCalloutWithBody(String url, String requestBody) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setTimeout(20000);
        request.setMethod('POST');
        request.setEndpoint('callout:CapiEndpoints' + url);
        request.setBody(requestBody);
        

        HttpResponse response = http.send(request);
        

        return response;
    }

    /**
    * Makes a PUT callout to the specified endpoint URL with the given request body.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-876'>FFSF-876</a>
    *
    * @param url The full URL of the endpoint.
    * @param requestBody The request body to send in the PUT callout.
    * @return The HTTP response from the callout.
    */
    public static HttpResponse makePUTCalloutWithBody(String url, String requestBody) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setTimeout(20000);
        request.setMethod('PUT');
        request.setEndpoint('callout:CapiEndpoints' + url);
        request.setBody(requestBody);

        HttpResponse response = http.send(request);


        return response;
    }
}