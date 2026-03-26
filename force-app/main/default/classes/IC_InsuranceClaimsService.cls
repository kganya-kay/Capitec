/********************************\
    @ Func Area     : IC Insurance Claims Service
    @ Author        : Gerhard de Klerk
    @ Date          : 19 Feb 2025
    @ Description   : REST Service to facilitate Claim Reopening Logic
    @ Related files :
    @ Test File     : IC_InsuranceClaimsService_TEST
                    :
===================================
    @ Last Modified By  :
    @ Last Modified On  :
    @ Modification Description :
	@ -
	@ -
===================================
**********************************/
@RestResource(UrlMapping='/insuranceclaimsmanagement/v1/reopen/*')
global with sharing class IC_InsuranceClaimsService {

/* ================================================================================================================
 *  CUSTOM EXCEPTION CLASSES
 * ================================================================================================================
 */
    global class InputException         extends Exception {}
    global class ProcessingException    extends Exception {}

/* ================================================================================================================
 * HTTP METHODS
 * ================================================================================================================
 */

    @HttpPost
    global static void doPost(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try{
            //CHECK AND ASSIGN URI PARAMETER
            Id caseId = null;
            String uriParameter = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
            if (uriParameter == null || uriParameter == '') {
             throw new InputException('No Case Id provided as URI Parameter');
            }
            caseId = (Id)uriParameter;

            //PERFORM REOPEN LOGIC
            IC_LongOutstandingClaims_Reopen.reopenClaim(caseId,'External system',false);

            // A success response
            returnSuccess(200);

        }catch(InputException      e){
            returnError(400, 'INVALID_INPUT', e.getMessage());
        }catch(ProcessingException      e){
            returnError(400, 'PROCESSING_EXCEPTION', e.getMessage());
        }catch(Exception           e){
            returnError(500, 'APEX_ERROR',    e.getMessage());
        }
    }

/* ================================================================================================================
 *  HELPER METHODS
 * ================================================================================================================
 */

    /**
     * @description Method to set the API response to a custom JSON object
     *              that serialized the response variable
     *
     * @param  statusCode The status code to respond with (i.e. 200, 201)
     */
    public static void returnSuccess(Integer statusCode){

        // Respond in JSON
        RestContext.response.headers.put('Content-Type', 'application/json');

        // Set the response status code
        RestContext.response.statusCode = statusCode;

    }


    /**
     * @description Method to set the API response to a custom JSON error object
     *              that matches the standard Salesforce REST API Error response
     *
     * @param  statusCode The status code to respond with (i.e. 400, 402, 403, 404)
     * @param  errorCode  The error code to respond with  (i.e. INVALID_INPUT)
     * @param  message    The message to respond with
     */
    public static void returnError(Integer statusCode, String errorCode, String message){

        // Respond in JSON
        RestContext.response.headers.put('Content-Type', 'application/json');

        // Set the response status code
        RestContext.response.statusCode = statusCode;

        // Set the response header to be just like a Salesforce REST API header
        RestContext.response.responseBody = Blob.valueOf(
                JSON.serializePretty(new List<Map<String,String>>{
                        new Map<String,String>{
                                'message'   => message,
                                'errorCode' => errorCode
                        }
                }
                ));
    }
}