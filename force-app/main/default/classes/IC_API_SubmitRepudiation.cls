public class IC_API_SubmitRepudiation {
    private static final String SUB_STATUS_PRELIMINARY_DECLINE = 'Preliminary Declined';

    @InvocableMethod(Label='Submit Repudiation' Description='Send an HTTP request for Submit Repudiation' Callout=true)
    public static List<Results> submitRepudiationRequest(List<Requests> requests) {
        List<Results> results = new List<Results>();
        Results result = new Results();
        result.results = new List<String>();

        try {
            for (Requests request : requests) {
                SubmitRepudiationRequestWrapper repudiationRequest = new SubmitRepudiationRequestWrapper();

                repudiationRequest.cifNumber = request.account.CIF_Number__c;
                repudiationRequest.policyNumber = request.childCase.IC_Policy_Number_child__c;
                repudiationRequest.claimNumber = request.childCase.CaseNumber;
                repudiationRequest.additionalClaimReferenceNumber = request.childCase.IC_Insurer_Claim_Reference__c;
                repudiationRequest.dateOfDeath = Datetime.newInstance(request.parentCase.IC_Deceased_Date_of_Death__c, Time.newInstance(0, 0, 0, 0));
                repudiationRequest.description = String.isNotBlank(request.parentCase.Description) ? request.parentCase.Description : request.parentCase.CaseNumber; //ICS-1797
                repudiationRequest.followUpDate = System.now() + 1;
                //repudiationRequest.clientEmail = request.account.PersonEmail;
                repudiationRequest.clientEmail = String.isNotBlank(request.parentCase.Email_Address__c) ? request.parentCase.Email_Address__c : 'noemail@gmail.com'; //ICS-1797
                repudiationRequest.clientName = request.account.Name;
                repudiationRequest.policyStartDate = request.policy.IC_Date_Opened__c;
                repudiationRequest.claimIncidentDate = request.parentCase.IC_Lodge_Date__c;
                repudiationRequest.repudiationAmount = request.childCase.IC_RecommendedPayoutAmount__c;
                repudiationRequest.repudiationReason = !String.isBlank(request.childCase.IC_2nd_Decline_Reason__c) ? request.childCase.IC_2nd_Decline_Reason__c : request.childCase.IC_Decline_Reason__c;
				System.debug(JSON.serialize(repudiationRequest));
                List<DocumentWrapper> documentList = new List<DocumentWrapper>();

                for (DocumentChecklistItem documentChecklistItem : request.documentChecklistItems) {
                    DocumentWrapper documentWrapper = new DocumentWrapper();
                    documentWrapper.documentName = documentChecklistItem.Name;
                    documentWrapper.documentType = 'Other';
                    documentWrapper.documentId = documentChecklistItem.IC_ExternalContentDocumentId__c;
                    documentList.add(documentWrapper);
                }
                repudiationRequest.documentList = documentList;

                System.debug(JSON.serialize(repudiationRequest));
                if(!String.isBlank(checkRequestBody(repudiationRequest))){
                    result.results.add(checkRequestBody(repudiationRequest)); 
                    results.add(result);
                    return results;
                }
                

                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:NC_CapiInsure/insure/c3/v1/submitRepudiation');
                req.setTimeout(120000); //ICS-1859 10 Dec 2024 G de Klerk - set maximum timeout duration
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(JSON.serialize(repudiationRequest));
                // Send the HTTP request
                Http http = new Http();
                HttpResponse res = http.send(req);
                System.debug('Status code: ' + res.getStatusCode());
                System.debug('Response body: ' + res.getBody());
                String taskrecTypeId = Schema.getGlobalDescribe().get('Task').getDescribe().getRecordTypeInfosByDeveloperName().get('Insurance_Claims_Task').getRecordTypeId();
                if (res.getStatusCode() == 200) {
                    result.results.add('Operation has completed successfully.');
                    Group waitingInsurerQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Waiting_for_Insurer' LIMIT 1];

                    request.childCase.Sub_Status__c = SUB_STATUS_PRELIMINARY_DECLINE;
                    //request.childCase.OwnerId = waitingInsurerQueue.Id; //REMOVE THE OWNER CHANGE FROM THE APEX AND HANDLE IN THE FLOW: 09 Nov 2024 - Gerhard de Klerk && Werner Wassermann
                    request.childCase.Centriq_email_has_been_sent__c = true;
                    update request.childCase;
                    insert new task(
                        recordtypeid=taskRecTypeId,
                        subject='Submit Repudiation',
                        Status_Code__c = res.getStatusCode(),
                        status='Completed', 
                        Response__c = 'Operation has completed successfully.',
                        //CIF_Number__c = request.account.CIF_Number__c,
                        OwnerId = UserInfo.getUserId(),
                        WhatId = request.childCase.Id,
                        //Type = 'Notification',
                        Priority = 'Normal',
                        ActivityDate = System.today()
                        //Source_System__c = 'Salesforce'
                    );

                } else {
                    result.results.add('Request failed: ' + res.getStatusCode() + ' ' + res.getStatus());
                    insert new task(
                        recordtypeid=taskRecTypeId,
                        Description= res.getBody(),
                        subject='Submit Repudiation',
                        Status_Code__c = res.getStatusCode(),
                        status='Completed', 
                        Response__c = 'Request failed: ' + res.getStatusCode() + ' ' + res.getStatus(),
                        //CIF_Number__c = request.account.CIF_Number__c,
                        OwnerId = UserInfo.getUserId(),
                        WhatId = request.childCase.Id,
                        //Type = 'Notification',
                        Priority = 'Normal',
                        ActivityDate = System.today());
                        //Source_System__c = 'Salesforce');
                }
            }
        } catch (Exception e) {
            result.results.add('Error occurred: ' + e.getMessage() + e.getLineNumber());
        }

        results.add(result);
        return results;
    }
    public static string checkRequestBody(SubmitRepudiationRequestWrapper repudiationRequest){
        String errMsg = '';
        if(String.isBlank(repudiationRequest.cifNumber)){errMsg+='cifNumber,';}
        if(String.isBlank(repudiationRequest.policyNumber)){errMsg+='policyNumber,';}
        if(String.isBlank(repudiationRequest.claimNumber)){errMsg+='claimNumber,';}
        if(repudiationRequest.dateOfDeath==null){errMsg+='dateOfDeath,';}
        if(repudiationRequest.followUpDate==null){errMsg+='followUpDate,';}
        if(String.isBlank(repudiationRequest.clientEmail)){errMsg+='clientEmail,';}
        if(String.isBlank(repudiationRequest.clientName)){errMsg+='clientName,';}
        if(repudiationRequest.policyStartDate==null){errMsg+='policyStartDate,';}
        if(repudiationRequest.claimIncidentDate==null){errMsg+='claimIncidentDate,';}
        if(repudiationRequest.repudiationAmount==null){errMsg+='repudiationAmount,';}
        if(String.isBlank(repudiationRequest.repudiationReason)){errMsg+='repudiationReason,';}
        if(String.isBlank(repudiationRequest.description)){errMsg+='description,';}
        if(repudiationRequest.documentList.isEmpty()){errMsg+='Document Details,';}
        
        if(!String.isBlank(errMsg)){
            return 'Please complete: '+errMsg.substring(0,errMsg.length()-1)+'.';
        }
        else{
            return null;
        }
    }

    public class Requests {
        @InvocableVariable(Label='Account')
        public Account account;
        @InvocableVariable(Label='Child Case')
        public Case childCase;
        @InvocableVariable(Label='Parent Case')
        public Case parentCase;
        @InvocableVariable(Label='Policy')
        public IC_Policy__c policy;
        @InvocableVariable(Label='documentChecklistItems')
        public List<DocumentChecklistItem> documentChecklistItems;
    }

    public class Results {
        @InvocableVariable(Label='Results' Description='List of the results returned.' Required=true)
        public List<String> results;
    }

    public class SubmitRepudiationRequestWrapper {
        public String cifNumber;
        public String policyNumber;
        public String claimNumber;
        public String additionalClaimReferenceNumber;
        public Datetime dateOfDeath;
        public String description;
        public Datetime followUpDate;
        public String clientEmail;
        public String clientName;
        public Datetime policyStartDate;
        public Datetime claimIncidentDate;
        public Decimal repudiationAmount;
        public String repudiationReason;
        public List<DocumentWrapper> documentList;
    }

    public class DocumentWrapper {
        public String documentName;
        public String documentType;
        public String documentId;
    }
}