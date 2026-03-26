/**
* Class Name:       Capitec_CaseICS
* Test Class:       Capitec_CaseICS_TEST
* Author           	Ridwan Moosuddee
* Company          	BlueSky
* Date             	15/11/2023
* Ticket      		ICS-391 - Integration with Due Diligence check
**/
public without sharing class Capitec_CaseICS {

    private static final String CENTRIQ_UNDERWRITER = 'Centriq';
    private static final String SUB_STATUS_PRELIMINARY_DECLINE = 'Preliminary Declined';
    private static final Id INSURANCE_ASSESSMENT_REC_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
    private static final Id INSURANCE_CLAIMS_REC_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
    private static final String CENTRIQ_DECLINE_NOTIFICATION = 'Centriq_Decline';

    static List<IC_Check_Due_Diligence_API_Settings__mdt> apiSettings = IC_Check_Due_Diligence_API_Settings__mdt.getAll().values();

    @future(callout=true)
    public static void checkDueDiligence(set<Id> caseIdSetToProcess) {

        System.debug('caseIdSetToProcess: ' + caseIdSetToProcess);

        List<Case> caseToCheck = [SELECT Id, CIF_Number__c, IC_Policy_Number_child__c, Account.Identity_Number__c, Is_Fraudulent__c from Case where id IN :caseIdSetToProcess];

        System.debug('caseToCheck ' + caseToCheck);

        // Serialize the specific fields from the first record in the list
        String requestBody = JSON.serialize(new Map<String, Object>{
                'cifNumber' => caseToCheck[0].CIF_Number__c,
                'idNumber' => (caseToCheck[0].Account.Identity_Number__c != null) ? caseToCheck[0].Account.Identity_Number__c : null,
                'policyNumber' => caseToCheck[0].IC_Policy_Number_child__c
        });

        System.debug('Request Body: ' + requestBody);
        Integer timeoutValue = Integer.valueOf(apiSettings[0].Timeout_in_sec__c * 1000);
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
                processResponse(res.getBody(), caseToCheck);
            } else {
                // Handle HTTP errors

                try {
                    Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    if (errorResponse.containsKey('Detail') && !((List<Object>) errorResponse.get('Detail')).isEmpty()) {
                        List<Object> details = (List<Object>) errorResponse.get('Detail');
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
                System.debug(res);
                System.debug('Results: ' + results);
            }
        } catch (Exception e) {
            System.debug('Error making HTTP callout: ' + e.getMessage());
        }
    }

    private static void processResponse(String responseBody, List<Case> caseList) {

        try {
            ApiResponse apiResponse = (ApiResponse) JSON.deserialize(responseBody, ApiResponse.class);
            Boolean responseisFraudulent = apiResponse.isFraudulent;
            System.debug('Is Fraudulent: ' + responseisFraudulent);

            if (responseisFraudulent != null) {
                caseList[0].Is_Fraudulent__c = responseisFraudulent;
                update caseList;
            }

        } catch (Exception e) {
            System.debug('Error processing response: ' + e.getMessage());
        }
    }

    public class ApiResponse {
        public Boolean isFraudulent { get; set; }
    }

    @future(callout=true)
    public static void zipFileAndQueueUpdate(List<Id> caseIdsForZipCallout) {
        List<Case> cases = [SELECT Id, Status, ParentId FROM Case WHERE Id IN :caseIdsForZipCallout];
        List<IC_API_ZipFileService.FlowRequest> requests = new List<IC_API_ZipFileService.FlowRequest>();

        for (Case c : cases) {
            // Assuming each case needs to make a separate callout
            // Prepare the request for each case
            IC_API_ZipFileService.FlowRequest request = new IC_API_ZipFileService.FlowRequest();
            request.parentCaseId = c.ParentId;
            request.childCaseId = c.Id;
            request.password = 'Capitec1';
            requests.add(request);
        }

        List<String> results = IC_API_ZipFileService.processCaseFiles(requests);

        Boolean allResultsPassed = !results.isEmpty() && !results.contains('Error');
        if (allResultsPassed) {
            List<Group> queueList = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Waiting for Insurer' LIMIT 1];
            if (!queueList.isEmpty()) {
                Id newOwnerId = queueList[0].Id;
                List<Case> casesToUpdate = new List<Case>();

                for (Case c : cases) {
                    c.OwnerId = newOwnerId;
                    c.IC_1st_decline_process_completed__c = true;
                    casesToUpdate.add(c);
                }

                // Perform the update in bulk
                update casesToUpdate;
            } else {
                System.debug('Queue not found');
            }
        }
    }

    public static void ValidateCaseStatus(List<Case> newList, Map<Id, Case> oldMap) {
        // Collect IDs of parent cases being closed
        List<Id> parentCaseIdsBeingClosed = new List<Id>();
        Id insuranceClaimsRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        for (Case newCase : newList) {
            Case oldCase = oldMap.get(newCase.Id);
            // Check if the case status is being changed to 'Closed'
            if (newCase.Status == 'Closed' && oldCase.Status != 'Closed' && newCase.RecordTypeId == insuranceClaimsRecordTypeId) {
                parentCaseIdsBeingClosed.add(newCase.Id);
            }
        }

        // Early exit if no cases are being closed
        if (parentCaseIdsBeingClosed.isEmpty()) {
            return;
        }

        // Query child cases that are not in the desired status
        Map<Id, Case> parentCasesWithOpenChildren = new Map<Id, Case>();
        for (Case childCase : [
                SELECT Id, ParentId
                FROM Case
                WHERE ParentId IN :parentCaseIdsBeingClosed
                AND RecordTypeId = :insuranceClaimsAssessmentRTId
                AND Status NOT IN ('Finalised', 'Closed')
        ]) {
            parentCasesWithOpenChildren.put(childCase.ParentId, childCase);
        }

        // Prevent the parent case from being closed if there are open child cases
        for (Case parentCase : newList) {
            if (parentCasesWithOpenChildren.containsKey(parentCase.Id)) {
                parentCase.addError('Please update the child case(s) to Status Finalised or Closed, where applicable. This case will be closed automatically once all child cases have been Finalised or Closed.');
            }
        }
    }

    //ICS-426
    public static void call_IC_API_PolicyServiceQueueable(List<Case> newCases) {
        List<IC_API_PolicyService.FlowRequest> flowRequests = new List<IC_API_PolicyService.FlowRequest>();
        System.debug('call_IC_API_PolicyServiceQueueable');

        for (Case c : newCases) {
            if (c.IC_Data_Wash_Service__c && String.IsNotBlank(c.CIF_Number__c) && c.Event_Date__c != null && c.IC_Type__c == 'Death') {
                IC_API_PolicyService.FlowRequest request = new IC_API_PolicyService.FlowRequest();
                request.caseNumber = c.CaseNumber;
                request.cifNumber = c.CIF_Number__c;
                request.eventDate = c.Event_Date__c;
                request.productType = c.Product_Type__c;
                request.caseType = c.IC_Type__c;
                request.caseSubType = c.Sub_Type__c;
                request.lastWorkingDate = c.Last_Working_Date__c;
                request.eventApproved = true;

                flowRequests.add(request);
                System.debug('Enqueue called: ' + flowRequests);

                System.enqueueJob(new IC_API_PolicyServiceQueueable(new List<IC_API_PolicyService.FlowRequest>{
                        request
                }));
            }
        }
    }


    //ICS 1254 Dawid Kuczer
    //Modified to send email message per each child case created not per parent case
    //TODO This needs to be removed
/*    @InvocableMethod(Label='Send to Centriq' Category='Case' Callout=true)
    public static void processCentriqNotifications(List<Case> newCaseList) {
        List<String> matchingCaseIds = new List<String>();
        System.debug(newCaseList);
        for (Case tempCase : newCaseList) {
            System.debug(tempCase);
            if (tempCase.IC_Insurer_Underwriter_at_Event_Date__c == CENTRIQ_UNDERWRITER
                    && tempCase.RecordTypeId == INSURANCE_ASSESSMENT_REC_TYPE) {

                matchingCaseIds.add(tempCase.Id);
            }
        }
        System.debug('##***## 1');
        //notifyCentriqThroughEmail(matchingCaseIds);
    }*/


    public static void handleInsuranceEmailMsgs(Map<Id, Case> newCaseMap) {
        filterAndHandleInsuranceCaseEmails(null, newCaseMap, true);
    }


    public static void handleInsuranceEmailMsgs(Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap) {
        filterAndHandleInsuranceCaseEmails(oldCaseMap, newCaseMap, false);
    }

    public static void filterAndHandleInsuranceCaseEmails(Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap, Boolean newlyCreated) {

        List<Case> insuranceClaimsCases = new List<Case>();

        for (Id currentNewCaseId : newCaseMap.keySet()) {
            //Check the case type, only accept Insurance Claims & Insurance Claims Assessments
            if ((newCaseMap.get(currentNewCaseId).RecordTypeId == INSURANCE_ASSESSMENT_REC_TYPE) || (newCaseMap.get(currentNewCaseId).RecordTypeId == INSURANCE_CLAIMS_REC_TYPE)) {
                insuranceClaimsCases.add(newCaseMap.get(currentNewCaseId));
            }
        }

        //filterAndHandleCentriqCaseEmails(insuranceClaimsCases, oldCaseMap, newCaseMap, newlyCreated);
    }


    /* public static void filterAndHandleCentriqCaseEmails(List<Case> potentialCases, Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap, Boolean newlyCreated) {

         List<String> confirmedCaseIds = new List<String>();

         for (Case thisCase : potentialCases) {
             if (thisCase.IC_Insurer_Underwriter_at_Event_Date__c != 'Centriq') {
                 continue;
             }
             if (newlyCreated == false && (oldCaseMap.get(thisCase.Id).IC_1st_decline_process_completed__c == false
                     && newCaseMap.get(thisCase.Id).IC_1st_decline_process_completed__c == true
                     && newCaseMap.get(thisCase.Id).Centriq_email_has_been_sent__c == false)
                     && newCaseMap.get(thisCase.Id).IC_Event_Selection__c == 'Event Declined') {
                 confirmedCaseIds.add(thisCase.Id);
             } else if (newlyCreated == true
                     && newCaseMap.get(thisCase.Id).IC_1st_decline_process_completed__c == true
                     && newCaseMap.get(thisCase.Id).Centriq_email_has_been_sent__c == false
                     && newCaseMap.get(thisCase.Id).IC_Event_Selection__c == 'Event Declined'
             ) {
                 confirmedCaseIds.add(thisCase.Id);
             }
         }

         //Send emails related to the previously filtered cases
         if (confirmedCaseIds.isEmpty()) {
             return;
         }
         //notifyCentriqThroughEmail(confirmedCaseIds);
     }*/


    /*   @future(callout=true)
       public static void notifyCentriqThroughEmail(List<String> caseIdsToProcess) {

           if (caseIdsToProcess == null && caseIdsToProcess.isEmpty()) {
               System.debug('##***## 2');
               return;
           }
           System.debug('##***## 3');
           List<Case> casesToProcess = [SELECT Id, ParentId, Parent_Case_Strack_Incident_Number__c FROM Case WHERE Id IN :caseIdsToProcess];
           Map<Id, Case> casesByIds = new Map<Id, Case>(casesToProcess);
           List<IC_ResultWrapper> emailSendingResults = new List<IC_ResultWrapper>();
           List<IC_API_ZipFileService.FlowRequest> flowRequests = new List<IC_API_ZipFileService.FlowRequest>();
           OrgWideEmailAddress orgWideEmailAddr = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address LIKE :'insuranceclaims%' LIMIT 1];

           System.debug('##***## 4');
           if (casesToProcess.isEmpty()) {
               System.debug('##***## 5');
               return;
           }
           System.debug('##***## 6');
           for (Case currentCase : casesToProcess) {
               emailSendingResults.addAll(IC_EmailMessageDomain.sendMultipleEmailsWithTemplate(casesToProcess, System.Label.IC_Centriq_Email_Address.split(','), orgWideEmailAddr.Address, true,
                       true, true, false, 'Centriq_Child_Case_Created'));
           }
           System.debug('##***## 7');
           System.debug('##***## Sending Results: ');
           System.debug(emailSendingResults);

           List<String> caseIdsToUpdate = new List<String>();

           for (IC_ResultWrapper currentResult : emailSendingResults) {

               if (currentResult.success) {
                   caseIdsToUpdate.add(currentResult.relatedId);
               }
           }

           if (!caseIdsToUpdate.isEmpty()) {
               updateCaseAfterCentriqEmailSuccess(caseIdsToUpdate);
           }
       }*/


/*    public static void updateCaseAfterCentriqEmailSuccess(List<String> casesIds) {
        System.enqueueJob(new ScheduleCaseUpdateAfterEmailSentSuccess(casesIds, CENTRIQ_DECLINE_NOTIFICATION));
    }*/


/*    public class ScheduleCaseUpdateAfterEmailSentSuccess implements Queueable, Database.AllowsCallouts {
        private List<String> caseIds;
        private final String updateType;

        ScheduleCaseUpdateAfterEmailSentSuccess(List<String> caseIdsToProcess, String whatUpdateType) {
            caseIds = caseIdsToProcess;
            updateType = whatUpdateType;
        }

        public void execute(QueueableContext context) {
            List<Case> casesToProcess = [SELECT Id, Sub_Status__c, ParentId, OwnerId FROM Case WHERE Id IN :caseIds];

            if (updateType == CENTRIQ_DECLINE_NOTIFICATION) {
                processCentriqDeclineCase(casesToProcess);
            }

            update casesToProcess;
        }

    }*/

/*    private static void processCentriqDeclineCase(List<Case> centriqCases) {
        Group waitingInsurerQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Waiting_for_Insurer' LIMIT 1];

        for (Case currentCentriqCase : centriqCases) {
            currentCentriqCase.Sub_Status__c = SUB_STATUS_PRELIMINARY_DECLINE;
            currentCentriqCase.OwnerId = waitingInsurerQueue.Id;
            currentCentriqCase.Centriq_email_has_been_sent__c = true;
        }
    }*/
}