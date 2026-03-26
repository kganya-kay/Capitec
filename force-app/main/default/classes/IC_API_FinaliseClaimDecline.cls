/**
* Class Name:       IC_API_FinaliseClaimDecline
* Test Class:       IC_API_FinaliseClaimDecline_TEST
* Author           	Ridwan Moosuddee
* Company          	BlueSky
* Date             	06/11/2023
* Ticket      		ICS-319 - Assess Claim - Decline basic (Finalise Claim end point)
**/

public with sharing class IC_API_FinaliseClaimDecline {
    
    static List<IC_Finalise_Claim_Decline_API_Settings__mdt> apiSettings = IC_Finalise_Claim_Decline_API_Settings__mdt.getAll().values();
    
    //Variables passed from Flow to Apex class
    public class FlowRequestVariables {
        @InvocableVariable
        public String caseNumber;
        @InvocableVariable
        public String policyNumber;
        @InvocableVariable
        public String cifNumber;
        @InvocableVariable
        public Date eventDate;
        @InvocableVariable
        public String declineReason;
        @InvocableVariable(label='Group of Insurance Contracts')
        public String groupOfInsuranceContracts;
    }
    
    @InvocableMethod(label='Make Callout to Finalise Claim Decline' description='Makes a callout for payment to be scheduled by calling the Finalise Claim')
    public static List<String> makeDeclineFinaliseClaimCallout(List<FlowRequestVariables> reqVar) {
        
        FlowRequestVariables request = reqVar[0];
        System.debug('Flow Request Variables: ' + reqVar);
        String requestBody = JSON.serialize(request);
        Integer timeoutValue = Integer.valueOf(apiSettings[0].Timeout_in_sec__c *1000);
        
        List<String> results = new List<String>();
        
        try {
            // Callout logic
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiSettings[0].Endpoint_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);
            req.setTimeout(timeoutValue);
            
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                System.debug(res.getBody());
                results.add('Success: ' + res.getBody());
            } else {
                // Handle HTTP errors
                 try {
                    Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    if(errorResponse.containsKey('Detail') && !((List<Object>)errorResponse.get('Detail')).isEmpty()) {
                        List<Object> details = (List<Object>)errorResponse.get('Detail');
                        for (Object detail : details) {
                            Map<String, Object> detailMap = (Map<String, Object>) detail;
                            String propertyName = (String) detailMap.get('PropertyName');
                            String errorMessage = (String) detailMap.get('ErrorMessage');
                            results.add('Error: ' + propertyName + ' - ' + errorMessage);
                        }
                    } else {
                        results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team');
                    }
                } catch (Exception e) {
                    // If there's an exception during error parsing, add the fallback error message
                    results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team');
                }
                
                String errorMsg = 'HTTP Error: ' + res.getStatusCode() + ' ' + res.getStatus();
                System.debug(errorMsg);
                results.add(errorMsg);
            }
        } catch(Exception e) {
            System.debug('Error making HTTP callout: ' + e.getMessage());
            results.add('Error: ' + e.getMessage());
        }
        return results;
    }
}