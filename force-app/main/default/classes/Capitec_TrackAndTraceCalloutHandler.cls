/**
 * Capitec_TrackAndTraceCalloutHandler Class
 *
 * This class is responsible for making a callout to the Track and Trace service to fetch data.
 * It retrieves an access token from Custom Metadata, sends a GET request to the specified endpoint
 * with the token for authorization, and handles the response data.
 *
 * Created by: Tomasz
 */
public class Capitec_TrackAndTraceCalloutHandler {

    private final static String INTERNAL_ERROR_MESSAGE_PREFIX = '{\"error\": \"An error has occurred';
    private final static String INTERNAL_ERROR_MESSAGE_SUFFIX = '\"}';
    private final static String DESIRED_RESPONSE_SIZE = 'size=100&';




    /**
     * Created by: Dawid
     * makeCorebankingTransactionCallout Method
     *
     *
     * @param accountNumber string, specifies the account number for the request
     * @param startDate stringified starting Date in yyyy-MM-dd format. NOT DateTime
     * @param endDate stringified ending Date in yyyy-MM-dd format. NOT DateTime
     * @return returns a String containing either JSON response or error message
     *
     * This method specifies the endpoint and the parameters for calloutHandler Method
     */
    @AuraEnabled
    public static String makeCorebankingTransactionCallout(String accountNumber, String startDate, String endDate) {

        String parameters = + 'accountNumber=' + accountNumber + '&startDate=' + startDate.split('T')[0] + '&endDate=' + endDate.split('T')[0];

        return calloutHandler(prepareCalloutURL(parameters, 'TaT_Core_Banking_Transaction'));
    }




    /**
     * Created by: Dawid
     * makeATMEventsTransactionCallout Method
     *
     * @param deviceId string, specifies the device Id for the request
     * @param startDateTime stringified starting DateTime in yyyy-MM-dd HH:mm:ss.SSS format. NOT Date
     * @param endDateTime stringified ending DateTime in yyyy-MM-dd HH:mm:ss.SSS format. NOT Date
     * @return returns a String containing either JSON response or error message
     *
     * This method specifies the endpoint and the parameters for calloutHandler Method
     */

    public static String makeATMEventsTransactionCallout(String deviceId, String startDateTime, String endDateTime){
		System.debug(startDateTime + ' ' + endDateTime);
        String parameters = + 'deviceId=' + deviceId + '&startDateTime=' + startDateTime.substring(0, startDateTime.length() - 2) + '&endDateTime=' + endDateTime.substring(0, endDateTime.length() - 2);
        return calloutHandler(prepareCalloutURL(parameters, 'TaT_ATM_Events_Transaction'));
    }




    /**
     * Created by: Dawid
     * makeATMEventsDeviceCallout Method
     *
     * @param deviceId string, specifies the device Id for the request
     * @param startDateTime stringified starting DateTime in yyyy-MM-dd HH:mm:ss.SSS format. NOT Date
     * @param endDateTime stringified ending DateTime in yyyy-MM-dd HH:mm:ss.SSS format. NOT Date
     * @return returns a String containing either JSON response or error message
     *
     * This method specifies the endpoint and the parameters for calloutHandler Method
     */

    public static String makeATMEventsDeviceCallout(String deviceId, String startDateTime, String endDateTime){
        String parameters = + 'deviceId=' + deviceId + '&startDateTime=' + startDateTime.substring(0, startDateTime.length() - 2) + '&endDateTime=' + endDateTime.substring(0, endDateTime.length() - 2);
        System.debug(startDateTime + ' ' + endDateTime);
        return calloutHandler(prepareCalloutURL(parameters, 'TaT_ATM_Events_Device'));
    }




    /**
     * Created by: Dawid
     * makeCardTransactionCallout Method
     *
     * @param fromAccountNumber string, specifies the From Account Number (Account Number) of the Client for the request
     * @param startDateTime stringified starting DateTime in yyyy-MM-dd HH:mm:ss.SSS format. NOT Date
     * @param endDateTime stringified ending DateTime in yyyy-MM-dd HH:mm:ss.SSS format. NOT Date
     * @return returns a String containing either JSON response or error message
     *
     * This method specifies the endpoint and the parameters for calloutHandler Method
     */

    @AuraEnabled
    public static String makeCardTransactionCallout(String fromAccountNumber, String startDateTime, String endDateTime){
        String parameters = + 'accountNumber=' + fromAccountNumber + '&startDateTime=' + startDateTime  + 'T00%3A00%3A00.00' + '&endDateTime=' + endDateTime.split('T')[0]  + 'T23%3A59%3A59.59';
		System.debug(startDateTime + ' ' + endDateTime + ' '+ fromAccountNumber);
        return calloutHandler(prepareCalloutURL(parameters, 'TaT_Card_Transaction'));
    }




    /**
     * Created by: Dawid
     * prepareCalloutURL Method
     *
     * @param parameters string, specifies parameters that should be included in the callouts' endpoint URL
     * @param endpointMDTDevName string, DeveloperName of the custom metadata record that contains URL address for this endpoint
     * @return returns a String containing either a full endpoint URL with parameters or an error message
     *
     * This method specifies the endpoint and the parameters for calloutHandler Method
     */

    private static String prepareCalloutURL(String parameters, String endpointMDTDevName){
        try{
            Capitec_Endpoint__mdt endpointMdt = [SELECT Id, URL__c, DeveloperName FROM Capitec_Endpoint__mdt WHERE DeveloperName = :endpointMDTDevName LIMIT 1];
            if(!String.isBlank(endpointMdt.URL__c)){
                return (endpointMdt.URL__c + DESIRED_RESPONSE_SIZE + parameters.replaceAll(':','%3A'));
            }
            else{
                return INTERNAL_ERROR_MESSAGE_PREFIX + 'URL address is not configured for this endpoint\'s custom metadata' + INTERNAL_ERROR_MESSAGE_SUFFIX;
            }
        }
        catch (QueryException e){
            System.debug(e.getMessage());
            return INTERNAL_ERROR_MESSAGE_PREFIX + e.getMessage() + INTERNAL_ERROR_MESSAGE_SUFFIX;
        }
    }




    /**
     * Created by: Tomasz
     * calloutHandler Method
     *
     * This method performs a callout to the Track and Trace service to retrieve data,
     * necessary parameters and handles the response.
     *
     *
     * Modified by: Dawid - 13.10.2023
     *
     * @param endpoint string argument that specifies exact URL address of the endpoint and it's parameters
     * @return String
     *
     */

    public static String calloutHandler(String endpoint) {
        try{

            Http http = new Http();
            HttpRequest req = new HttpRequest();
            HttpResponse res;

            req.setEndpoint('callout:NC_CapiTrack' + endpoint);
            req.setMethod('GET');

            res = http.send(req);
            System.debug(req.getEndpoint());

            if (res.getStatusCode() == 200) {
                // Handle successful response

                System.debug('Response Body');
                System.debug(res.getBody());

                return res.getBody();
            }
            else {
                // Handle response errors
                System.debug('Error: ' + res.getStatus());
                System.debug('Response Body: ' + res.getBody());

                return INTERNAL_ERROR_MESSAGE_PREFIX + res.getStatus() + INTERNAL_ERROR_MESSAGE_SUFFIX;
            }

        } catch (CalloutException e) {
            // Handle exceptions
            System.debug('An error occurred while fetching the token: ' + e.getMessage());

            return INTERNAL_ERROR_MESSAGE_PREFIX + e.getMessage() + INTERNAL_ERROR_MESSAGE_SUFFIX;
        }
    }
}