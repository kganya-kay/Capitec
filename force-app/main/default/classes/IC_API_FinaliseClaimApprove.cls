/**
* Class Name:       IC_API_FinaliseClaimApprove
* Test Class:       IC_API_FinaliseClaimApprove_TEST
* Author           	Ridwan Moosuddee
* Company          	BlueSky
* Ticket      		ICS-225 - Assess Claim - Approve basic (Finalise Claim end point)
* LastModifiedBy:   Jason Folding (EXAH)
* Description:      Added the accountHolder variable to FlowRequestVariables IC-1804
**/

public with sharing class IC_API_FinaliseClaimApprove {
    
    static List<IC_Finalise_Claim_Approve_API_Settings__mdt> apiSettings = IC_Finalise_Claim_Approve_API_Settings__mdt.getAll().values();
    
    //Variables passed from Flow to Apex class
    public class FlowRequestVariables {
        @InvocableVariable(label='Case Number' required=true)
        public String caseNumber;
        
        @InvocableVariable(label='Policy Number' required=true)
        public String policyNumber;
        
        @InvocableVariable(label='CIF Number' required=true)
        public String cifNumber;
        
        @InvocableVariable(label='Event Date' required=true)
        public Date eventDate;
        
        @InvocableVariable(label='Insurer Underwriter At Event Date' required=true)
        public String insurerUnderwriterAtEventDate;
        
        @InvocableVariable(label='Claim Installment Period' required=true)
        public Integer claimInstallmentPeriod;
        
        @InvocableVariable(label='Claim Lump Sum Amount' required=true)
        public Decimal claimLumpSumAmount;
        
        @InvocableVariable(label='Claim Annuity Amount' required=true)
        public Decimal claimAnnuityAmount;
        
        @InvocableVariable(label='Remaining Term At Event Date' required=true)
        public Integer remainingTermAtEventDate;
        
        @InvocableVariable(label='Remaining Term At Last Working Date' required=true)
        public Integer remainingTermAtLastWorkingDate;
        
        @InvocableVariable(label='First Payment Due Date' required=true)
        public Date firstPaymentDueDate;
        
        @InvocableVariable(label='Payment Frequency' required=true)
        public String paymentFrequency;
        
        @InvocableVariable(label='Number Of Catch Up Payments' required=true)
        public Integer numberOfCatchUpPayments;
        
        @InvocableVariable(label='Group of Insurance Contracts')
        public String groupOfInsuranceContracts;
        
        //ICS-683
        @InvocableVariable(label='Claim Type')
        public String claimType;
        
        @InvocableVariable(label='Policy Version')
        public String policyVersion;
        
        @InvocableVariable(label='Account Created Date')
        public Date accountCreatedDate;
        
        @InvocableVariable(label='Retrenchment Date')
        public Date retrenchmentDate;
        
        @InvocableVariable(label='Parent Case Number')
        public String ParentCaseNumber;
        
        @InvocableVariable(label='Reported DateTime')
        public DateTime reportedDateTime;
        
        @InvocableVariable(label='Approved DateTime')
        public DateTime approvedDate;
        
        @InvocableVariable(label='Resolved DateTime')
        public DateTime resolvedDateTime;
        
        @InvocableVariable(label='Balance Outstanding')
        public Decimal balanceOutstanding;
        
        @InvocableVariable(label='Duration Of Medical Condition')
        public String durationOfMedicalCondition;
        
        @InvocableVariable(label='Product Type')
        public String productType;
        
        @InvocableVariable(label='Credit Product Type')
        public String creditProductType;
        
        @InvocableVariable(label='Branch Code')
        public String accountBranch;
        
        @InvocableVariable(label='Case Origin')
        public String caseOrigin;
        
        @InvocableVariable(label='Employer Name')
        public String employerName;
        
        @InvocableVariable(label='Employer Industry')
        public String employerIndustry;

        @InvocableVariable(label='Account Holder')
        public String accountHolder;
        
    }
    
    @InvocableMethod(label='Make Callout to Finalise Claim Approve' description='Makes a callout for payment to be scheduled by calling the Finalise Claim')
    public static List<String> makeApproveFinaliseClaimCallout(List<FlowRequestVariables> reqVar) {
        
        FlowRequestVariables request = reqVar[0];
        System.debug('Flow Request Variables: ' + reqVar);
        String requestBody = JSON.serialize(request);
        System.debug('JSON Request: ' +requestBody);
        
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
            System.debug('Response from endpoint: ' + res);
            System.debug('Status code returned: ' + res.getStatusCode());
            System.debug('Body returned: ' + res.getBody());
            if (res.getStatusCode() == 200) {
                System.debug('Status code returned: ' + res.getStatusCode());
                System.debug('Body returned: ' + res.getBody());
                results.add('Success: ' + res.getBody());
            }
            // Handle HTTP error 400: ICS-911
            else if (res.getStatusCode() == 400) {
                
                // Deserialize the JSON response into a map
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                // Check the status code in the response
                if ((Integer)response.get('Status') == 400) {
                    // Get the Detail list, which contains JSON strings
                    List<Object> details = (List<Object>) response.get('Detail');
                    
                    // Iterate over each detail entry
                    for (Object detail : details) {
                        // Deserialize each detail entry, which is a JSON string, into another map
                        Map<String, Object> detailMap = (Map<String, Object>) JSON.deserializeUntyped((String)detail);
                        //System.debug('detailMap: ' +detailMap);
                        // Check the status and message in the detail map
                        if ((Integer)detailMap.get('Status') == 400) {
                            List<Object> detailMessages = (List<Object>) detailMap.get('Detail');
                            //System.debug('detailMessages: ' +detailMessages);
                            
                            //ICS-1865 11 Dec 2024 - G de Klerk - Add additional Message criteria to cater for Once-Off and Scheduled Payment checks 
                            if (detailMessages != null && (detailMessages.contains('Duplicate transaction found') || detailMessages.contains('Payment already scheduled'))) {
                                results.add('Error: This claim has already been scheduled for payment, please close this as a duplicate claim.');
                                System.debug('Duplicate transaction found with Status 400.');
                            } else {
                                //results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team');
                                //ICS-1178
                                // Iterate over detail messages for the second JSON structure
                                for (Object detailMessage : detailMessages) {
                                    try{
                                        Map<String, Object> messageMap = (Map<String, Object>) detailMessage;
                                        //System.debug('messageMap: ' +messageMap);
                                        String errorMessage = (String) messageMap.get('ErrorMessage');
                                        
                                        // Add the error message to the results
                                        results.add('Error: ' + errorMessage);
                                        //System.debug('Error: Status 400 found with message: ' + errorMessage);    
                                    }catch(Exception e){
                                        String errorMessage = (String) detailMessage;
                                        
                                        // Add the error message to the results
                                        results.add('Error: ' + errorMessage);
                                    }
                                    
                                }
                                //System.debug('Status 400 found, but no duplicate transaction message.');
                            }
                        }
                    }
                } else {
                    results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team');
                    System.debug('Response status is not 400.');
                }
                // END Handle HTTP error 400: ICS-911
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
}