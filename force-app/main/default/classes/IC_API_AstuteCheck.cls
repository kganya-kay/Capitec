/*******************************************************************
* @Class Name        :  IC_API_AstuteCheck
* @Test Class        :  IC_API_AstuteCheck_TEST
* @Author            :  Tristan
* @Last Modified By  :  Tristan, 28-Feb-2024, Jira Tickets: ICS-642
* @Version           :  1.0
*
*******************************************************************/

public class IC_API_AstuteCheck {
    
    static List<IC_AstuteCheck_API_Settings__mdt> apiSettings = IC_AstuteCheck_API_Settings__mdt.getAll().values();
    
    public class DHAServiceRequest {
        @InvocableVariable(label='Case Number' required=true)
        public transient String caseNumber;
        
        @InvocableVariable(label='Deceased ID Number' required=true)
        public transient String idReferenceNo;
        
        public String transRefGuid;
        public String trackingReference;
        public List<VopdRequestDetails> vopdRequestDetails;
        
        public DHAServiceRequest() {
            this.transRefGuid = Capitec_GuidUtils.NewGuid();
        }
    }
    
    public class VopdRequestDetails {
        public Integer vopdVerificationType = 2;
        public String messageId;
        public Integer vopdIdType = 4;
        public String idReferenceNo;
        
        public VopdRequestDetails(String messageId, String idReferenceNo) {
            this.messageId = messageId;
            this.idReferenceNo = idReferenceNo;
        }
    }
    
    
    public class DHAPolicyResponse {
        public boolean successful;      
        public ResponseData responseData;            
    }
    
    public class ResponseData{
        public String transRefGuid;
        public String trackingReference;
        public DateTime requestDateTime;
        public Integer vopdRequestStatus;
        public Integer vopdRequestSource;
        public List<VerificationDetails> verificationDetails;      
    }
    
    public class VerificationDetails {
        public String gender;
        public String maritalStatus;
        public DateTime dateOfDeath;
        public DateTime dateOfBirth;
        public String placeOfDeath;
        public String causeOfDeath;
        public Boolean deathUnderInvestigation;
        public Integer vopdVerificationType;
        public String idNumber;
        public String errorMessage;
        public String smartId;
        public String surname;
        public String forename;
        public String deceasedStatus;
        public String requestMessageId;
    }
    
    
    @InvocableMethod(label='Make Callout to DHA Service' description='Makes a callout to verify deceased status with the DHA' callout=true)
    public static List<String> makeDHAServiceCallout(List<DHAServiceRequest> requests) {
        DHAServiceRequest currentRequest = requests[0];
        
        currentRequest.trackingReference = currentRequest.caseNumber;
        currentRequest.vopdRequestDetails = new List<VopdRequestDetails>{
            new VopdRequestDetails(currentRequest.caseNumber, currentRequest.idReferenceNo)
                };
                    
                    System.debug('currentRequest: ' +currentRequest);
        String requestBody = JSON.serialize(currentRequest);
        System.debug('requestBody: ' +requestBody);
        Integer timeoutValue = Integer.valueOf(apiSettings[0].Timeout_in_seconds__c *1000);
        
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
            
            System.debug('Endpoint URL: ' + req.getEndpoint());            
            HttpResponse res = http.send(req);
            System.debug('AstuteCheck Response: ' + res);
            
            if (res.getStatusCode() == 200) {
                
                System.debug('AstuteCheck Response Body: ' + res.getBody());
                results.add('Success: ' + res.getBody());
                
                String checkResponseBody = res.getBody();
                
                if(String.isNotBlank(checkResponseBody)){// Check if the response body is not empty or null
                    processDHAResponse(res.getBody(), currentRequest);
                    System.debug(res.getBody());
                    results.add('Success: ' + res.getBody());
                    
                }
                else{
                    // Handle empty response body
                    results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team. The response body from the callout is empty.');
                    System.debug('checkResponseBody: ' + checkResponseBody);
                }                
            } 
            else {
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
    
    private static void processDHAResponse(String responseBody, DHAServiceRequest request) {
        
        try{
            
            DHAPolicyResponse responseObj = (DHAPolicyResponse) JSON.deserialize(responseBody, DHAPolicyResponse.class);
            List<Case> casesToUpdate = new List<Case>();
            
            Case caseRecord = [SELECT Id, AccountId, Product_Type__c, IC_Type__c, Sub_Type__c, Sub_Type_Reason__c, OwnerId, Status, Sub_Status__c, IC_DHA_Cause_of_Death__c, IC_DHA_Date_of_Birth__c, IC_DHA_Name__c, IC_DHA_Surname__c, IC_DHA_Date_of_Death__c, IC_DHA_Deceased_Indicator__c, IC_DHA_Gender__c, IC_DHA_ID_Number__c, IC_DHA_Marital_Status__c, IC_DHA_Place_of_Death__c, IC_DHA_Request_Date_Time__c, IC_DHA_Response_Code__c, IC_DHA_Response_Message__c, IC_DHA_Transaction_Reference__c, IC_DHA_Under_Investigation__c, IC_DHA_Verified__c 
                               FROM Case WHERE CaseNumber = :request.caseNumber LIMIT 1];
            
            caseRecord.IC_DHA_Name__c = responseObj.responseData.verificationDetails[0].forename;
            caseRecord.IC_DHA_Surname__c = responseObj.responseData.verificationDetails[0].surname;
            caseRecord.IC_DHA_Date_of_Birth__c = responseObj.responseData.verificationDetails[0].dateOfBirth;
            caseRecord.IC_DHA_ID_Number__c = responseObj.responseData.verificationDetails[0].idNumber;
            caseRecord.IC_DHA_Gender__c = responseObj.responseData.verificationDetails[0].gender;
            caseRecord.IC_DHA_Marital_Status__c = responseObj.responseData.verificationDetails[0].maritalStatus;
            caseRecord.IC_DHA_Deceased_Indicator__c = responseObj.responseData.verificationDetails[0].deceasedStatus;
            caseRecord.IC_DHA_Date_of_Death__c = responseObj.responseData.verificationDetails[0].dateOfDeath;
            caseRecord.IC_DHA_Cause_of_Death__c = responseObj.responseData.verificationDetails[0].causeOfDeath;
            caseRecord.IC_DHA_Place_of_Death__c = responseObj.responseData.verificationDetails[0].placeOfDeath;
            caseRecord.IC_DHA_Under_Investigation__c = responseObj.responseData.verificationDetails[0].deathUnderInvestigation;
            caseRecord.IC_DHA_Response_Message__c = responseObj.responseData.verificationDetails[0].errorMessage;
            caseRecord.IC_DHA_Transaction_Reference__c =responseObj.ResponseData.transRefGuid;
            caseRecord.IC_DHA_Request_Date_Time__c = responseObj.ResponseData.requestDateTime;
            if (responseObj.responseData.verificationDetails[0].deceasedStatus == 'Deceased' && responseObj.successful == true ){
                caseRecord.IC_DHA_Verified__c = true;
            }
            
            update caseRecord;
        }
        catch (Exception e) {
            System.debug('Error processing response: ' + e.getMessage());
        }
    }
}