/**
 * @description       : Custom API for Creating cases from Conversion Domain
 * @author            : Rajesh Yandrathi
 * @group             : Central Conversions
 * @last modified on  : 03-16-2026
 * @last modified by  : Samiirah Aujub
**/
@RestResource(urlMapping='/createDebitOrderSwitchCase/v1')
global with sharing class Conversions_DebitOrderSwitchCaseCreation {

    global class DebitOrderWrapper {
        public String  fromAccount;
        public String  toCapitecAccount;
        public Decimal amount;
        public Date    debitOrderDate;
        public String  name;
        public String  externalInitiatorId;
        public String  externalInitiatorName;
        public String  category;
        public Date    submissionDate;
    }

    global class DocumentChecklistItemWrapper {
        public String name;
        public String documentLink;
        public String documentumId;
        public String documentType;
    }

    global class RequestWrapper {
        public String cdCIF;
        public String idNumber;
        public String consultantCP;
        public String complexity;
        public Time   preferredTime;
        public String preferredLanguage;
        public String preferredContactMethod;
        public String comments;
        public String oldAccount;
        public String oldBank;
        public String oldBranchCode;
        public String origin;
        public String typeValue;
        public String subject;
        public String statusValue;
        public String priorityValue;
        public String switchRequestId;
        public String recordTypeId;
        public String ownerId;
        public Boolean manualCase; //COCONV-2417

        public List<DebitOrderWrapper>            debitOrders;
        public List<DocumentChecklistItemWrapper> documents;
    }

    global class ResponseWrapper {
        public String  caseId;
        public String  caseNumber;
        public String  message;
        public String  emailTrackingThreadId;//Added by Samiirah Aujub - For submission's email responses to be attached to the case
        public String  clientEmail; //Added by Samiirah Aujub - COCONV 2510
        public Boolean success;
    }

    @HttpPost
    global static ResponseWrapper createCase() {
        ResponseWrapper resp = new ResponseWrapper();
        Boolean createCase = true;

        try {
            RestRequest req = RestContext.request;
            if (req == null || String.isBlank(req.requestBody.toString())) {
                resp.success = false;
                resp.message = 'Error: Empty request body';
                return resp;
            }

            RequestWrapper input = (RequestWrapper) JSON.deserialize(req.requestBody.toString(), RequestWrapper.class);
            Case duplicateCase = getDuplicateCase(input.switchRequestId);

            if(duplicateCase == null){
                Case cs = new Case(
                    RecordTypeId                   = input.recordTypeId,
                    OwnerId                        = input.ownerId,
                    Origin                         = input.origin,
                    Type                           = input.typeValue,
                    Subject                        = input.subject,
                    Status                         = input.statusValue,
                    Priority                       = input.priorityValue,
                    CD_ClientCIFNumber__c          = input.cdCIF,
                    ID_Number__c                   = input.idNumber,
                    Branch_Consultant_CP_Number__c = input.consultantCP,
                    CM_Complexity__c               = input.complexity,
                    Claim_Number__c                = input.switchRequestId
                );
                insert cs;

                cs = [
                    SELECT Id, 
                           CaseNumber,
                           Account.PersonEmail
                    FROM Case
                    WHERE Id = :cs.Id
                ];

                System.enqueueJob(
                    new Conversions_DebitOrderAsyncProcessor(cs.Id, input)
                );

                String threadId = EmailMessages.getFormattedThreadingToken(cs.Id);
                System.debug('##Generated thread Id:' + threadId);

                resp.caseId     = cs.Id;
                resp.caseNumber = cs.CaseNumber;
                resp.emailTrackingThreadId = threadId;//Added by Samiirah Aujub - For submission's email responses to be attached to the case
                resp.clientEmail = cs.Account.PersonEmail; //Added by Samiirah Aujub - COCONV-2510
                resp.success    = true;
                resp.message    = 'Case created successfully. Related records are being processed.';
            }
            else{
                String exThreadId = EmailMessages.getFormattedThreadingToken(duplicateCase.Id);
                resp.caseId     = duplicateCase.Id;
                resp.caseNumber = duplicateCase.CaseNumber;
                resp.emailTrackingThreadId = exThreadId;
                resp.clientEmail = duplicateCase.Account.PersonEmail; //Added by Samiirah Aujub - COCONV-2510
                resp.success    = false;
                resp.message    = 'Switch Reference ID already exists.';
            }
            
            
        }
        catch (Exception ex) {
            resp.success = false;
            resp.message = 'Error creating case: ' + ex.getMessage();
        }

        return resp;
    }

    public static Case getDuplicateCase(String switchRequestId) {
        Id conversionsRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();

        if(switchRequestId == null) return null;

        List<Case> lstCases = [SELECT Id, 
                                      CaseNumber, 
                                      Claim_Number__c,
                                      Account.PersonEmail
                               FROM Case
                               WHERE RecordTypeId = :conversionsRecordTypeId
                               AND Claim_Number__c = :switchRequestId
                               LIMIT 1
                        ];

        return lstCases.isEmpty() ? null : lstCases[0];
    }
}