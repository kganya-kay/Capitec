/**
 * This class handles the callouts to the Capitec Bad Beneficiaries API.
 * It provides methods to retrieve and update bad beneficiaries, construct URLs, and make HTTP callouts.
 *
 * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
 *
 * @author Caleb Govender
 * @date 2024/09/17
 */
public with sharing class Capitec_BadBeneficiariesCalloutHandler {

    private static final String BB_NAMED_CREDENTIALS = 'callout:CapiEndpoints';

    private static final String BB_GET_BAD_BENEFICIARIES_ENDPOINT = '/fraudp/salesforce-global-ben/salesforce-global-ben/v1/beneficiaries?';
    private static final String BB_STATUS_UPDATE_ENDPOINT = '/fraudp/salesforce-global-ben/salesforce-global-ben/v1/update/status?';
    private static final String BB_UPLOAD_FILE_ENDPOINT = '/fraudp/salesforce-global-ben/salesforce-global-ben/v1/beneficiaries/update/status?';
    private static final String DEFAULT_PAGE_SIZE = '50';
    private static final String DEFAULT_CURRENT_PAGE = '1';
    private static final Integer MAX_TIMEOUT_VAL = 120000;


    /**
     * Retrieves bad beneficiaries based on the provided parameters
     *
     * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
     *
     * @author Caleb Govender
     * @date 2024/09/17
     *
     * @param sAccountNumber The account number to search for.
     * @param sStatus The status of the beneficiaries.
     * @param sPageSize The number of records per page.
     * @param sCurrentPage The current page number.
     * @return A JSON string containing the response from the API.
     */
    public static String getBadBeneficiaries(String sAccountNumber, String sStatus, String sPageSize, String sCurrentPage){

        String urlParameters = constructURLParameters(sAccountNumber, sStatus, sPageSize, sCurrentPage);
        String fullEndpoint = constructURL(BB_GET_BAD_BENEFICIARIES_ENDPOINT, urlParameters);
        HttpResponse res = makeGetCallout(fullEndpoint);
        System.debug(fullEndpoint);
        System.debug(res.getStatusCode());
        System.debug(res.getBody());

        if(res.getStatusCode() == 200){
            return appendPositiveStatusToJSON(res.getBody());
        }
        if(res.getStatusCode() == 400){
            return constructErrorJSON(res.getStatusCode(), 'There are no Bad Beneficiaries associated with this Account Number');
        }

        return constructErrorJSON(res.getStatusCode(), 'An unexpected error has occurred, please try again later');
    }


    /**
    * Updates the status of a bad beneficiary.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
    *
    * @author Caleb Govender
    * @date 2024/09/17
    *
    * @param payloadString The JSON payload containing the update information.
    * @return A JSON string containing the response from the API.
    */
    public static String updateBadBeneficiaryStatus(String payloadString){
        System.debug(payloadString);
        HttpResponse res = makeUpdateCallout(constructURL(BB_STATUS_UPDATE_ENDPOINT,''), payloadString,'PUT');
        System.debug(res);
        return JSON.serialize(res.getStatusCode());
    }

    /**
    * Appends a positive status to the given JSON string.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
    *
    * @author Caleb Govender
    * @date 2024/09/17
    *
    * @param jsonString The original JSON string.
    * @return The modified JSON string with a positive status.
    */
    private static String appendPositiveStatusToJSON(String jsonString){

        jsonString = jsonString.replaceFirst('\\{', '{' +
                '"error" : false,' +
                '"statusCode" : 200,');

        return jsonString;
    }

    /**
    * Constructs an error JSON string with the given status code and message.
	*
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
    *
    * @author Caleb Govender
    * @date 2024/09/17
    *
    * @param statusCode The HTTP status code.
    * @param message The error message.
    * @return The constructed error JSON string.
    */
    private static String constructErrorJSON(Integer statusCode, String message){

        String jsonString = '{\n' +
                '  "error" : true,\n' +
                '  "statusCode" : "' + statusCode + '",\n' +
                '  "message" : "' + message + '"\n' +
                '}';

        return jsonString;
    }

    /**
    * Makes a GET callout to the specified endpoint URL.
    *
    *<a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
    *
    * @author Caleb Govender
    * @date 2024/09/17
    *
    * @param fullEndpointUrl The full URL of the endpoint.
    * @return The HTTP response from the callout.
    */
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

    /**
    * Makes an update callout to the specified endpoint URL with the given payload and method.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
    *
    * @author Caleb Govender
    * @date 2024/09/17
    *
    * @param fullEndpointUrl The full URL of the endpoint.
    * @param payload The payload to send in the request body.
    * @param sMethod The HTTP method to use (e.g., PUT).
    * @return The HTTP response from the callout.
    */
    public static HttpResponse makeUpdateCallout(String fullEndpointUrl, String payload, String sMethod){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res;

        req.setMethod(sMethod);
        req.setTimeout(MAX_TIMEOUT_VAL);
        req.setEndpoint(fullEndpointUrl);
        req.setBody(payload);

        System.debug(req.getEndpoint());

        res = http.send(req);

        System.debug(res.getStatusCode());
        System.debug(res.getBody());
        return res;
    }

    /**
    * Constructs a full URL by combining the endpoint and parameters.
    *
	* <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
    *
    * @author Caleb Govender
    * @date 2024/09/17
    *
    * @param endpoint The endpoint path.
    * @param parameters The URL parameters.
    * @return The constructed full URL.
    */
    public static String constructURL(String endpoint, String parameters){
        return (BB_NAMED_CREDENTIALS + endpoint + parameters);
    }


    /**
    * Constructs URL parameters based on the provided account number and status.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
    *
    * @author Caleb Govender
    * @date 2024/09/17
    *
    * @param sAccountNumber The account number to include in the parameters.
    * @param sStatus The status to include in the parameters.
    * @param sPageSize The page size to include in the parameters.
    * @param sCurrentPage The current page to include in the parameters.
    * @return The constructed URL parameters.
    */
    public static String constructURLParameters(String sAccountNumber, String sStatus, String sPageSize, String sCurrentPage){
        List<String> parameters = new List<String>();

        if (sAccountNumber != '') {
            parameters.add('identifier=' + sAccountNumber);
        }

        if (sStatus != '') {
            parameters.add('status=' + sStatus);
        }

        if (sCurrentPage != '') {
            parameters.add('pageNumber=' + sCurrentPage);
        }

        if (sPageSize != null && sPageSize != '') {
            parameters.add('pageSize=' + sPageSize);
        }

        // Join all the parameters with '&'
        return String.join(parameters, '&');
    }
    /**
    * Upload risky beneficiaries.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-895'>FFSF-895</a>
    *
    * @author BlueSky
    * @date 2024/05/12
    *
    * @param payload Data from the upload file.
    * @return A JSON string containing the response from the API.
    */
    public static String uploadBadBeneficiary(String payloadString){
        HttpResponse res = makeUpdateCallout(constructURL(BB_UPLOAD_FILE_ENDPOINT,''), payloadString,'PUT');
       return JSON.serialize(res.getStatusCode());
    }

}