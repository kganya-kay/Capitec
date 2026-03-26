/*******************************************************************
* @Class Name        :  IC_API_PolicyService
* @Test Class        :  IC_API_PolicyService_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 31-Oct-2023, Jira Tickets: ICS-225 
* @Version           :  1.0
*
*******************************************************************/

public with sharing class IC_API_PolicyService {
    
    static List<IC_Lodge_Claim_API_Settings__mdt> apiSettings = IC_Lodge_Claim_API_Settings__mdt.getAll().values();
    
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
        public String creditProductType;
        public String policyVersion;
        public String productDescription;
        public Date dateOpened; // This is a date in the format YYYY-MM-DD
        public String ccsStatusAtEventDate;
        public String balanceOutstandingAtEventDate;
        public String installmentAmountAtEventDate;
        public Integer remainingTermAtEventDate;
        public Integer remainingTermAtLastWorkingDate;
        public Date firstPaymentDueDate; // Date in the format YYYY-MM-DD
        public String paymentFrequency;
        public Integer recommendedNumberOfPayments;
        public Integer numberOfCatchupPayments;
        public Boolean inForceOnEventDate;
        public Boolean inwaitingPeriod;
        public String recommendedOutcome;
        public String recommendedReason;
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
        public Boolean eventApproved;
        @InvocableVariable
        public transient String declineReason;
        @InvocableVariable
        public transient String claimComment;
    }
    
    @InvocableMethod(label='Make Callout to Policy Service' description='Makes a callout with the given details from the flow.')
    public static List<String> makePolicyCallout(List<FlowRequest> requests) {
        
        FlowRequest request = requests[0];
        System.debug('Flow requests: ' +requests);
        String requestBody = JSON.serialize(request);
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
            
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                
                String checkResponseBody = res.getBody();
                
                
                if(String.isNotBlank(checkResponseBody)){// Check if the response body is not empty or null
                    Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    if((Integer)responseBody.get('count') == 0 && ((List<Object>)responseBody.get('items')).isEmpty()){
                        String errorMsg = apiSettings[0].No_Policies_Error_Message__c;
                        System.debug(errorMsg);
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
        
        try{
            
            PolicyResponse responseObj = (PolicyResponse) JSON.deserialize(responseBody, PolicyResponse.class);
            List<Case> casesToInsert = new List<Case>();
            
            Id creditLifeNonMedicalQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Credit Life Non-Medical' LIMIT 1].Id;
            
            Case caseRecord = [SELECT Id, AccountId, IC_Duration_of_Condition__c, Product_Type__c, IC_Type__c, Sub_Type__c, Sub_Type_Reason__c, OwnerId, Status, Sub_Status__c, IC_Data_Wash_Service__c FROM Case WHERE CaseNumber = :request.caseNumber LIMIT 1];
            
            String defaultRecordType = apiSettings[0].Child_Record_Type__c;
            Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(defaultRecordType).getRecordTypeId();
            
            for (PolicyItem item : responseObj.items) {
                Case c = new Case();
                c.Subject = 'Policy Case for ' + item.policyNumber;
                c.ParentId = caseRecord.Id; //case id where the Lodge button was clicked from

                if(request.eventApproved == false){//ICS-833
                    c.IC_Decline_Reason__c = request.declineReason;//ICS-833
                    c.IC_Finalise_Claim_Comment__c = request.claimComment;//ICS-833
                    c.IC_1st_decline_process_completed__c = TRUE;//ICS-833
                    
                    //ICS-953 -Start: Added in the if conidition of eventApproved = False
                    //ICS-901 - Start
                    if(item.insurerUnderWriterAtEventDate == 'CapitecLife'
                       && caseRecord.Product_Type__c == 'Credit Life'
                       && caseRecord.IC_Type__c == 'Unemployment/ITEI'){
                           //c.OwnerId = caseRecord.OwnerId; //Commented for ICS-901
                           c.OwnerId = creditLifeNonMedicalQueueId; // ICS-901 -> Change owner to Credit Life non medical queue
                       }
                    else{
                        c.OwnerId = caseRecord.OwnerId;
                    }
                    //ICS-901 - End
                    //ICS-953 - End
                }                
                c.IC_Declined_Agent__c = UserInfo.getUserId();
                System.debug('caseApi caseRecord.AccountId: '+ caseRecord.AccountId);
                c.AccountId = caseRecord.AccountId;
                c.IC_Type__c = caseRecord.IC_Type__c;
                c.IC_Consolidated_Loan__c = (item.accountConsolidated != null) ? item.accountConsolidated : false; //ICS-799
                c.Sub_Type__c = caseRecord.Sub_Type__c;
                c.Sub_Type_Reason__c = caseRecord.Sub_Type_Reason__c;
                c.Product_Type__c = caseRecord.Product_Type__c;
                c.RecordTypeId = insuranceClaimsAssessmentRTId;
                c.IC_Policy_Count__c = responseObj.count; // Storing the count value in the Case
                c.IC_Policy_Number_child__c = item.policyNumber;
                c.IC_Insurer_Underwriter_at_Event_Date__c = item.insurerUnderWriterAtEventDate;
                c.IC_Credit_Product_Type__c = item.creditProductType;
                c.IC_Policy_Version__c = item.policyVersion;
                c.IC_Product_Description__c = item.productDescription;
                if (item.dateOpened != null) {
                    c.IC_Date_Opened__c = Date.valueOf(item.dateOpened);
                }
                c.IC_CCS_Status_at_Event_Date__c = item.ccsStatusAtEventDate;
                if (item.ccsStatusAtEventDate == 'J'){ // ICS-624 
                    c.Status = 'Closed';
                    c.Sub_Status__c = 'Sold';
                }
                else if (item.insurerUnderWriterAtEventDate == 'None'){ // ICS-1230, ICS-1371, ICS-1501
                    c.Status = 'Assessment';
                    c.Sub_Status__c = 'Allocated Assessing';
                }
                else{
                    c.Status = request.eventApproved ? apiSettings[0].Child_Default_Status__c : apiSettings[0].Child_Status_Decline__c;//ICS-518
                    c.Sub_Status__c = request.eventApproved ? apiSettings[0].Child_Default_Sub_Status__c : apiSettings[0].Child_Sub_Status_Decline__c;//ICS-518
                }
                c.IC_Balance_Outstanding_at_Event_Date__c = (item.balanceOutstandingAtEventDate != null) ? Decimal.valueOf(item.balanceOutstandingAtEventDate) : Decimal.valueOf(0);
                c.IC_Claim_Lump_Sum_Amount__c = (item.balanceOutstandingAtEventDate != null) ? Decimal.valueOf(item.balanceOutstandingAtEventDate) : Decimal.valueOf(0);
                c.IC_Installment_Amount_at_Event_Date__c = (item.installmentAmountAtEventDate != null) ? Decimal.valueOf(item.installmentAmountAtEventDate) : Decimal.valueOf(0);
                c.IC_Claim_Annuity_Amount__c = (item.installmentAmountAtEventDate != null) ? Decimal.valueOf(item.installmentAmountAtEventDate) : Decimal.valueOf(0);
                c.IC_Remaining_Term_at_Event_Date__c = (item.remainingTermAtEventDate != null) ? item.remainingTermAtEventDate : 0;
                c.IC_Remaining_Term_at_Last_Working_Date__c = (item.remainingTermAtLastWorkingDate != null) ? item.remainingTermAtLastWorkingDate : 0;
                if (item.firstPaymentDueDate != null) {
                    c.IC_First_Payment_Due_Date__c = Date.valueOf(item.firstPaymentDueDate);
                }
                c.IC_Payment_Frequency__c = (item.paymentFrequency == 'Biweekly' ? 'Fortnightly' : item.paymentFrequency);
                
                //ICS-812, ICS-1234
                setNumberOfPayments(c, caseRecord, item);
                
                c.IC_Number_of_Catch_Up_Payments__c = (item.numberOfCatchupPayments != null) ? item.numberOfCatchupPayments : 0;
                c.IC_In_force_on_Event_Date__c = (item.inForceOnEventDate != null) ? item.inForceOnEventDate : false;
                c.IC_In_Waiting_Period_Flag__c = (item.inwaitingPeriod != null) ? item.inwaitingPeriod : false;
                c.IC_Recommended_Outcome__c = item.recommendedOutcome;
                c.IC_Recommended_Reason__c = item.recommendedReason;
                c.IC_Group_of_Insurance_Contracts__c = item.groupOfInsuranceContracts;
                c.IC_Event_Selection__c = request.eventApproved ? 'Event Approved' : 'Event Declined';//ICS-710
                c.IC_BranchCode__c = item.accountBranch;
                
                casesToInsert.add(c);
                system.debug('CASES TO INSERT:::' +casesToInsert);
            }
            
            if (!casesToInsert.isEmpty()) {
                BypassUtil.FlowRequest bypass = new BypassUtil.FlowRequest();
                bypass.enable = true;
                bypass.disableValidationRules = true;
                BypassUtil.manageBypass(new List<BypassUtil.FlowRequest> { bypass });
                
                Database.SaveResult[] results = Database.insert(casesToInsert, true);
                //If any single record fails, none of the records will be saved to the database when the allOrNone parameter is set to true.
                Bypass.disable = true;
                BypassUtil.manageBypass(new List<BypassUtil.FlowRequest> { bypass });
                
                Boolean allSuccess = true;
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess()) {
                        allSuccess = false;
                        // Log the error
                        System.debug('Failed to insert record with ID: ' + result.getId() + '. Error: ' + result.getErrors()[0].getMessage());
                        break; // exit loop early if any case failed
                    }
                }
                
                if (allSuccess) {//Update the parent record
                    caseRecord.Status = request.eventApproved ? apiSettings[0].Parent_Default_Status__c : apiSettings[0].Parent_Status_Decline__c;//ICS-518
                    if(caseRecord.IC_Data_Wash_Service__c){//ICS-426
                        caseRecord.Sub_Status__c = 'Allocated Assessing';
                    }
                    else{
                        caseRecord.Sub_Status__c = request.eventApproved ? apiSettings[0].Parent_Default_Sub_Status__c : apiSettings[0].Parent_Sub_Status_Decline__c;//ICS-518
                    }
                    caseRecord.IC_Claim_Lodged__c = true;
                    update caseRecord;
                }
            }
            
        }
        catch (Exception e) {
            System.debug('Error processing response: ' + e.getMessage());
        }
    }
    
    private static void setNumberOfPayments(Case c, Case caseRecord, PolicyItem item) {//ICS-812, ICS-1234
        if (shouldApplyDisabilityLogic(item, caseRecord)) {
            Integer recommendedPayments = calculateRecommendedPayments(caseRecord, item.paymentFrequency);
            c.IC_Recommended_Number_of_Payments__c = recommendedPayments;
            c.IC_Claim_Number_of_Payments__c = recommendedPayments;
        } else {
            Integer defaultPayments = (item.recommendedNumberOfPayments != null) ? item.recommendedNumberOfPayments : 0;
            c.IC_Recommended_Number_of_Payments__c = defaultPayments;
            c.IC_Claim_Number_of_Payments__c = defaultPayments;
        }
    }
    
    private static Boolean shouldApplyDisabilityLogic(PolicyItem item, Case caseRecord) {//ICS-812, ICS-1234
        return item.recommendedNumberOfPayments > caseRecord.IC_Duration_of_Condition__c &&
            caseRecord.IC_Duration_of_Condition__c != null &&
            caseRecord.Product_Type__c == 'Credit Life' &&
            caseRecord.IC_Type__c == 'Disability' &&
            caseRecord.Sub_Type__c == 'Temporary';
    }
    
    private static Integer calculateRecommendedPayments(Case caseRecord, String paymentFrequency) {//ICS-812, ICS-1234
        if (paymentFrequency.equalsIgnoreCase('Weekly')) {
            return (Integer) Math.ceil(caseRecord.IC_Duration_of_Condition__c * 4.33);
        } else if (paymentFrequency.equalsIgnoreCase('Fortnightly')) {
            return (Integer) caseRecord.IC_Duration_of_Condition__c * 2;
        } else {
            return (Integer) caseRecord.IC_Duration_of_Condition__c;
        }
    }
}