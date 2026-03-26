/*******************************************************************
* @Class Name        :  IC_API_ObligationService
* @Test Class        :  IC_API_ObligationService_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 1-Dec-2023, Jira Tickets: ICS-405
* @Version           :  1.0
*
*******************************************************************/

public class IC_API_ObligationService {
    static List<IC_Get_Obligations_API_Settings__mdt> apiSettings = IC_Get_Obligations_API_Settings__mdt.getAll().values();
    
    // Inner classes for JSON parsing
    public class PolicyResponse {
        public Integer count;
        public List<PolicyItem> items;
    }
    
    //This class reflects the structure of each individual policy item in the response.
    public class PolicyItem {
        public String policyNumber;
        public Boolean accountConsolidated; //ICS-799
        public String insurerUnderWriterAtEventDate;
        public String balanceOutstandingAtEventDate;
        public String recommendedOutcome;
        public Integer remainingTermAtLastWorkingDate;
        public String recommendedReason;
        public String creditProductType;
        public Boolean inwaitingPeriod;
        public String policyVersion;
        public String groupOfInsuranceContracts;
        public String accountBranch;
    }
    
    
    //Variables passed from Salesforce flow to apex 
    //This will serve as the request body
    public class FlowRequest {
        @InvocableVariable
        public String caseNumber;
        @InvocableVariable
        public String cifNumber;
        @InvocableVariable
        public Date eventDate;
        @InvocableVariable
        public String productType;
        @InvocableVariable
        public String caseType;
        @InvocableVariable
        public String caseSubType;
        @InvocableVariable
        public Date lastWorkingDate;
        @InvocableVariable
        public String idNumber;
    }
    
    @InvocableMethod(label='Make Callout to Obligation Service' description='Makes a callout with the given details from the flow.')
    public static List<String> makePolicyCallout(List<FlowRequest> requests) {
        FlowRequest request = requests[0];
        System.debug('Flow requests: ' +requests);
        String requestBody = JSON.serialize(request);
        Integer timeoutValue = Integer.valueOf(apiSettings[0].Timeout_in_seconds__c *1000);
        
        List<String> results = new List<String>();
        
        System.debug('requestBody: ' + requestBody);
        
        try {
            // Callout logic
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiSettings[0].Endpoint_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);
            req.setTimeout(timeoutValue);

            System.debug('##***Obligations Request body: ');
            System.debug(req.getBody());

            HttpResponse res = http.send(req);

            System.debug('##***Obligations Response body: ');
            System.debug(res.getBody());

            if (res.getStatusCode() == 200) {
                
                String checkResponseBody = res.getBody();
                
                if(String.isNotBlank(checkResponseBody)){// Check if the response body is not empty or null
                    Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    if((Integer)responseBody.get('count') == 0 && ((List<Object>)responseBody.get('items')).isEmpty()){
                        String errorMsg = apiSettings[0].No_Policies_Error_Message__c;
                        System.debug(errorMsg);
                        System.debug('responseBody: ' + responseBody);
                        results.add(errorMsg);
                    }
                    else{
                        processResponse(res.getBody(), request);
                        System.debug(res.getBody());
                        results.add('Success: ' + res.getBody());
                    }
                }
                
                else{
                    // Handle empty response body
                    results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team. The response body from the callout is empty.');
                    System.debug('checkResponseBody: ' + checkResponseBody);
                }
                
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
            System.debug('Error caught: ' + e.getMessage());
            results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team. ' + e.getMessage());
        }
        
        return results;
    }
    
    private static void processResponse(String responseBody, FlowRequest request) {
        try {
            PolicyResponse responseObj = (PolicyResponse) JSON.deserialize(responseBody, PolicyResponse.class);
            Case caseRecord = [SELECT Id, AccountId, Product_Type__c, IC_Type__c, Sub_Type__c, Sub_Type_Reason__c, OwnerId, Status, Sub_Status__c FROM Case WHERE CaseNumber = :request.caseNumber LIMIT 1];
            
            // Map to hold existing policies keyed by policy number
            Map<String, IC_Policy__c> existingPolicies = new Map<String, IC_Policy__c>();
            for (IC_Policy__c policy : [SELECT Id, Name FROM IC_Policy__c WHERE Parent_Case__c = :caseRecord.Id]) {
                existingPolicies.put(policy.Name, policy);
            }
            
            List<IC_Policy__c> policiesToUpsert = new List<IC_Policy__c>();
            
            for (PolicyItem item : responseObj.items) {
                IC_Policy__c policy;
                if (existingPolicies.containsKey(item.policyNumber)) {
                    // Update existing policy
                    policy = existingPolicies.get(item.policyNumber);
                } else {
                    // Create new policy
                    policy = new IC_Policy__c();
                    policy.Parent_Case__c = caseRecord.Id;
                    policy.OwnerId = caseRecord.OwnerId;
                    policy.Name = item.policyNumber;
                }
                
                // Set or update fields
                policy.Insurer_Underwriter_at_Event_Date__c = item.insurerUnderWriterAtEventDate;
                policy.IC_Consolidated_Loan__c = (item.accountConsolidated != null) ? item.accountConsolidated : false; //ICS-799
                policy.Balance_Outstanding_at_Event_Date__c = (item.balanceOutstandingAtEventDate != null) ? Decimal.valueOf(item.balanceOutstandingAtEventDate) : Decimal.valueOf(0);
                policy.Recommended_Outcome__c = item.recommendedOutcome;
                policy.Remaining_Term_at_Last_Working_Date__c = (item.remainingTermAtLastWorkingDate != null) ? item.remainingTermAtLastWorkingDate : 0;
                policy.Recommended_Reason__c = item.recommendedReason;
                policy.Credit_Product_Type__c = item.creditProductType;
                policy.In_Waiting_Period_Flag__c = (item.inwaitingPeriod != null) ? item.inwaitingPeriod : false;
                policy.Policy_Version__c = item.policyVersion;
                policy.IC_Group_of_Insurance_Contracts__c = item.groupOfInsuranceContracts;
                policy.IC_BranchCode__c = item.accountBranch;
                
                policiesToUpsert.add(policy);
            }
            
            if (!policiesToUpsert.isEmpty()) {
                Database.upsert(policiesToUpsert, false); // false for partial success
            }
        } catch (Exception e) {
            System.debug('Error processing response: ' + e.getMessage());
        }
    }
}