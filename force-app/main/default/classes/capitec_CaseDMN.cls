/**
 * Created by Sebastian on 22.03.2023.
 * Updated by Cornelia Smit on 22.07.2024 for CECSF-215
 * Updated by Johan Langenhoven on 22.07.2024 for CRBSKY-234
 * Updated by Cornelia Smit on 27.08.2024 for CECSF-387
 * Updated by Johan Langenhoven on 01.10.2024 for CECSF-441
 * Updated by Anil - RCS-3707  AML CRA Onboarding RB - EDD Workflow Salesforce
 * Updated by Caleb Govender on 12.09.2024 for FFSF-896 
 * Updated by Dhriven Hamlall on 14.01.2025 for FCO-112 
*/

public with sharing class capitec_CaseDMN {
    @TestVisible private static final String CONSULTANT_DEVNAME = 'Consultant_AML';
    @TestVisible private static final String ERROR_MSG = 'In order to close Case, you have to answer all question sections.';
    @TestVisible private static final String ERROR_MSG2 = 'In order to submit case for approval, you have to upload attachments first.';
    @TestVisible private static final String ERROR_MSG3 = 'Please take ownership of this case in order to edit details on the case.';//CECSF-215
    @TestVisible private static final String AML_CONSULTANTS_TEXT = 'AML_Consultants';
    @TestVisible private static final String AML_TEXT = 'AML';
    private static final String MILESTONE_AML_CLIENT_RESPONSE = 'AML Awaiting Client Response';
    private static final String MILESTONE_AML_FULL_CASE_SLA = 'AML Full Case SLA';

    private static final String CASE_FIELD = 'Case__c';
    private static final String QUESTION_TYPE_FIELD = 'Question_Type__c';
    private static final String AML_SLA_NAME = 'AML Full Case SLA';
    private static final String CASE_ENTITY_TYPE = 'Case';
    private static final String LINKED_ENTITY_ID_FILED = 'LinkedEntityId';


    //Case Statuses
    private static final String STATUS_ACTIVE = 'Active';
    private static final String STATUS_NEW = 'New';
    private static final String STATUS_DECISION = 'Decision';
    private static final String STATUS_SUSPICIOUS = 'Suspicious';
    private static final String STATUS_FRAUD = 'Fraud';
    private static final String STATUS_NOT_FRAUD = 'Not Fraud';
    private static final String STATUS_ACTIVE_INVESTIGATION = 'Active Investigation UTD';
    private static final String STATUS_WAITING_EXTERNAL = 'Waiting On External Party';
    private static final String STATUS_REPATRIATION_PROGRESS = 'Repatriation In Progress';
    private static final String STATUS_REPATRIATION_COMPLETED = 'Repatriation Completed';
    private static final String STATUS_CLOSED = 'Closed';
    private static final String STATUS_CLIENT_COMPLAINT = 'Client Complaint';
    private static final String STATUS_OMBUDSMAN_COMPLAINT = 'Ombudsman Complaint';
    private static final String SUBSTATUS_REVIEW_NOT_REQUIRED = 'Awaiting Sign Off: Review Not Required';

    private static final Id ADHOC_RECOVERIES_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Adhoc_Recoveries').getRecordTypeId(); //Get Adhoc_Recoveries record type CRBSKY-234
    private static final Id ADMINISTRATION_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Administration').getRecordTypeId(); //Get Administration record type CRBSKY-234
    private static final Id AGENT_EFFICIENCY_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Agent_Efficiency').getRecordTypeId(); //Get Agent efficiency record type CRBSKY-234
    private static final Id RECOVERIES_FINANCE_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Recoveries_Finance').getRecordTypeId(); //Get Recoveries_Finance record type CRBSKY-234
    private static final Id SEQUESTRATION_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Sequestration').getRecordTypeId(); //Get Sequestration record type CRBSKY-234
    private static final Id RETAIL_COMPLAINTS_HANDOFF_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Retail_Complaints_Handoff').getRecordTypeId(); //Get Retail_Complaints_Handoff record type CRBSKY-234
    private static final String AML_CASE_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('AML_Record_Type').getRecordTypeId();
    private static final String FRAUD_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Fraud_Record_Type').getRecordTypeId();
    private static final String CASH_DISPUTES_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Cash_Disputes').getRecordTypeId();
    private static final String ESCALATIONS_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Client_Escalations').getRecordTypeId();//CECSF-215

    private static final String MILESTONE_NAME_FRAUD_CASE_ACCPETANCE = 'Fraud Case Acceptance';
    private static final String MILESTONE_NAME_FRAUD_ACTIVE = 'Fraud Active to Fraud/Suspicious/Not Fraud';
    private static final String MILESTONE_NAME_FRAUD_EXTERNAL = 'Fraud Investigation';
    private static final String MILESTONE_NAME_FRAUD_INTERNAL = 'Fraud Investigation Acceptance';
    private static final String MILESTONE_NAME_FRAUD_WAITING_EXTERNAL = 'Fraud Waiting on External Party';

    private static final Set<Id> OUTSOURCED_RECOVERIES_CASE_RECORD_TYPE_IDS = new Set<Id>{
            ADHOC_RECOVERIES_RECORD_TYPE_ID,
            ADMINISTRATION_RECORD_TYPE_ID,
            AGENT_EFFICIENCY_RECORD_TYPE_ID,
            RECOVERIES_FINANCE_RECORD_TYPE_ID,
            SEQUESTRATION_RECORD_TYPE_ID,
            RETAIL_COMPLAINTS_HANDOFF_RECORD_TYPE_ID
    };

    public static void saveLastConsultant(List<Case> caseList) {
        Set<Id> userIdSet = new Set<Id>();

        for (Case thisCase : caseList) {
            userIdSet.add(thisCase.OwnerId);
        }

        Map<Id, User> userMap = new Map<Id, User>([SELECT Name, UserRole.DeveloperName FROM User WHERE Id IN :userIdSet]);

        for (Case thisCase : caseList) {
            if (userMap.get(thisCase.OwnerId).UserRole.DeveloperName == CONSULTANT_DEVNAME) {
                thisCase.Last_Consultant__c = thisCase.OwnerId;
            }
        }
    }

    /**
     * Checks user access to client escalation cases.
     * @param oldCases A map of old cases with their IDs as keys.
     * @param newCases A list of new cases to be checked.
     */
    public static void checkUserAccessToCase(Map<Id, Case> oldCases, List<Case> newCases) {
        // List to store new client escalation cases
        List<Case> newClientECases = new List<Case>();
        // Get the current user ID
        Id currentUserId = UserInfo.getUserId();
        // Retrieve case edit settings
        Case_Edit_Settings__c caseEditSettings = Case_Edit_Settings__c.getInstance();

        // Filter new cases to find those with the escalation record type
        for (Case currentCase : newCases) {
            if (currentCase.RecordTypeId == ESCALATIONS_RECORD_TYPE_ID) {
                newClientECases.add(currentCase);
            }
        }

        // Iterate through the filtered new client escalation cases
        if (!newClientECases.isEmpty()) {
            for (Case newCase : newClientECases) {
                // Get the corresponding old case
                Case oldCase = oldCases.get(newCase.Id);
                // Check if the current user is the owner of the new case
                Boolean isOwner = (newCase.OwnerId == currentUserId);

                // Skip if the current user is the owner or if the owner has changed
                if (isOwner || newCase.OwnerId != oldCase.OwnerId) {
                    continue;
                }

                // If case edit settings are null or the user does not have edit permissions
                if (caseEditSettings == null || !caseEditSettings.Can_Edit_Permission__c) {
                    // Iterate through all fields of the Case object
                    for (Schema.SObjectField field : Case.SObjectType.getDescribe().fields.getMap().values()) {
                        String fieldName = field.getDescribe().getName();
                        // Skip the OwnerId field
                        if (fieldName == 'OwnerId') {
                            continue;
                        }

                        // Get the old and new values of the field
                        Object oldValue = oldCase.get(fieldName);
                        Object newValue = newCase.get(fieldName);

                        // If the values are different, add an error to the new case
                        if (oldValue != newValue) {
                            newCase.addError(ERROR_MSG3);
                        }
                    }
                }
            }
        }
    }

    public static void linkToAccountByCIF(List<Case> casesToCreate) {

        Map<String, Account> accountsListsByCIF = new Map<String, Account>();
        Set<String> cifNumbers = new Set<String>();
        List<Account> linkedAccounts;

        for (Case currentCase : casesToCreate) {
            if (currentCase.Account_CIF_Number__c != null) {
                cifNumbers.add(currentCase.Account_CIF_Number__c);
            }
        }

        linkedAccounts = [SELECT Id, CIF_Number__c, PersonContactId FROM Account WHERE CIF_Number__c IN :cifNumbers];

        for (Account currentAcc : linkedAccounts) {
            accountsListsByCIF.put(currentAcc.CIF_Number__c, currentAcc);
        }

        for (Case currentCase : casesToCreate) {
            if (currentCase.Account_CIF_Number__c != null && accountsListsByCIF.containsKey(currentCase.Account_CIF_Number__c)) {
                currentCase.AccountId = accountsListsByCIF.get(currentCase.Account_CIF_Number__c).Id;

                if (currentCase.RecordTypeId == ESCALATIONS_RECORD_TYPE_ID) {
                    currentCase.ContactId = accountsListsByCIF.get(currentCase.Account_CIF_Number__c).PersonContactId;
                }
            }
        }
    }

    public static void closeCaseMilestones(Map<Id, Case> oldCases, List<Case> newCases) {
        List<String> cmsAMLIds = new List<String>();
        List<String> cmsTypeFraudCaseAcceptanceIds = new List<String>();
        List<String> cmsTypeFraudSuspiciousIds = new List<String>();
        List<String> cmsTypeFraudExternalInternalIds = new List<String>();
        List<String> cmsTypeFraudWaitingExternalIds = new List<String>();
        Set<Id> cmsTypeOutsourcedRecoveriesIds = new Set<Id>(); //added the Outsourced Recoveries case Ids. CRBSKY-234
        List<CaseMilestone> cmsToUpdate;


        for (Case currentCase : newCases) {

            if (currentCase.RecordTypeId == AML_CASE_RECORD_TYPE_ID) {
                if (currentCase.Status == STATUS_DECISION && oldCases.get(currentCase.Id).Status != STATUS_DECISION) {
                    cmsAMLIds.add(currentCase.Id);
                }
                continue;
            }

            //Added logic for all case milestones CRBSKY-234
            if (OUTSOURCED_RECOVERIES_CASE_RECORD_TYPE_IDS.contains(currentCase.RecordTypeId) && currentCase.Status == STATUS_CLOSED) {
                cmsTypeOutsourcedRecoveriesIds.add(currentCase.Id);
                continue;
            }

            if (currentCase.RecordTypeId == FRAUD_RECORD_TYPE_ID) {
                Case oldCase = oldCases.get(currentCase.Id);
                if (oldCase != null && (oldCase.Status == STATUS_CLOSED || oldCase.Status == STATUS_NOT_FRAUD) && currentCase.Status == STATUS_NEW) {
                    continue;
                }
                if (currentCase.Status == STATUS_ACTIVE) {
                    cmsTypeFraudCaseAcceptanceIds.add(currentCase.Id);
                    continue;
                }
                if (currentCase.Status == STATUS_SUSPICIOUS || currentCase.Status == STATUS_FRAUD || currentCase.Status == STATUS_NOT_FRAUD || currentCase.Status == STATUS_CLOSED) {

                    cmsTypeFraudSuspiciousIds.add(currentCase.Id);
                    continue;
                }
                if (currentCase.Status == STATUS_REPATRIATION_PROGRESS || currentCase.Status == STATUS_REPATRIATION_COMPLETED || currentCase.Status == STATUS_CLOSED ||
                        currentCase.Status == STATUS_CLIENT_COMPLAINT || currentCase.Status == STATUS_OMBUDSMAN_COMPLAINT) {

                    cmsTypeFraudWaitingExternalIds.add(currentCase.Id);

                    if (currentCase.Status == STATUS_CLOSED || currentCase.Status == STATUS_CLIENT_COMPLAINT || currentCase.Status == STATUS_OMBUDSMAN_COMPLAINT) {
                        cmsTypeFraudExternalInternalIds.add(currentCase.Id);
                    }
                }
            }
        }

        cmsToUpdate = [
                SELECT Id, IsCompleted, CompletionDate
                FROM CaseMilestone CM
                WHERE (CaseId IN :cmsAMLIds AND (CM.MilestoneType.Name = :MILESTONE_AML_CLIENT_RESPONSE OR CM.MilestoneType.Name = :MILESTONE_AML_FULL_CASE_SLA))
                OR (CaseId IN :cmsTypeFraudCaseAcceptanceIds AND CM.MilestoneType.Name = :MILESTONE_NAME_FRAUD_CASE_ACCPETANCE AND IsCompleted = FALSE) //FFSF-896 Added IsCompleted = FALSE for Production Bug
                OR (CaseId IN :cmsTypeFraudSuspiciousIds AND CM.MilestoneType.Name = :MILESTONE_NAME_FRAUD_ACTIVE AND IsCompleted = FALSE) //FFSF-896 Added IsCompleted = FALSE for Production Bug
                OR (CaseId IN :cmsTypeFraudWaitingExternalIds AND CM.MilestoneType.Name = :MILESTONE_NAME_FRAUD_WAITING_EXTERNAL AND IsCompleted = FALSE) //FFSF-896 Added IsCompleted = FALSE for Production Bug
                OR (CaseId IN :cmsTypeFraudExternalInternalIds AND (CM.MilestoneType.Name = :MILESTONE_NAME_FRAUD_INTERNAL OR CM.MilestoneType.Name = :MILESTONE_NAME_FRAUD_EXTERNAL) AND IsCompleted = FALSE) //FFSF-896 Added IsCompleted = FALSE for Production Bug
                OR (CaseId IN :cmsTypeOutsourcedRecoveriesIds AND IsCompleted = FALSE)// Query Agent Efficiency case milestones CRBSKY-234
        ];

        for (CaseMilestone cm : cmsToUpdate) {
                cm.CompletionDate = (Datetime.now());
        }
        update cmsToUpdate;
    }

    public static void validateClosingCaseCondition(List<Case> caseList) {

        Set<String> questionTypesList = getQuestionTypes();
        Set<Id> caseIdSet = new Set<Id>();
        Map<Id, Set<String>> caseIdToQuestionTypeSetMap = new Map<Id, Set<String>>();

        for (Case thisCase : caseList) {
            if (thisCase.RecordTypeId != AML_CASE_RECORD_TYPE_ID) {
                continue;
            }
            caseIdSet.add(thisCase.Id);
        }

        List<AggregateResult> answersList = [SELECT Case__c, COUNT(Id), Question_Type__c FROM Answer__c WHERE Case__c IN :caseIdSet AND Question_Type__c != 'DS Prod Analysis' GROUP BY Case__c, Question_Type__c];

        for (AggregateResult thisAr : answersList) {
            if (!caseIdToQuestionTypeSetMap.containsKey((Id) thisAr.get(CASE_FIELD))) {
                caseIdToQuestionTypeSetMap.put((Id) thisAr.get(CASE_FIELD), new Set<String>{
                        (String) thisAr.get(QUESTION_TYPE_FIELD)
                });
            } else {
                Set<String> statusSet = caseIdToQuestionTypeSetMap.get((Id) thisAr.get(CASE_FIELD));
                statusSet.add((String) thisAr.get(QUESTION_TYPE_FIELD));
                caseIdToQuestionTypeSetMap.put((Id) thisAr.get(CASE_FIELD), statusSet);
            }
        }

        System.debug(caseIdToQuestionTypeSetMap);

        for (Case thisCase : caseList) {
            if (!caseIdToQuestionTypeSetMap.containsKey(thisCase.Id)) {
                thisCase.Sub_Status__c.addError(ERROR_MSG);
            } else if (answersList.size() < 0) {
                thisCase.Sub_Status__c.addError(ERROR_MSG);
            } else if (thisCase.Summary__c == null) {

                thisCase.Sub_Status__c.addError(ERROR_MSG);
            }
        }
    }

    public static void setUpFieldsFromKafka(List<Case> caseList) {
        Group amlConsultantsQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :AML_CONSULTANTS_TEXT LIMIT 1];
        Id amlRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('AML_Record_Type').getRecordTypeId();

        for (Case thisCase : caseList) {
            if (thisCase.Owner_kafka__c == AML_CONSULTANTS_TEXT) {
                thisCase.OwnerId = amlConsultantsQueue.Id;
            }
            if (thisCase.Kafka_record_type__c == AML_TEXT) {
                thisCase.RecordTypeId = amlRecordType;
            }
        }
    }

    public static void linkMilestoneToCase(List<Case> caseList) {
        Id amlRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('AML_Record_Type').getRecordTypeId();
        Id AMlCRAORecTpye = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('AML_CRA_Onboarding').getRecordTypeId();

        try {
            Entitlement entitlement = [SELECT Id FROM Entitlement WHERE Name = :AML_SLA_NAME LIMIT 1];
            Entitlement AMLCRAOnEntitlement = [SELECT Id FROM Entitlement WHERE Name = 'AML CRA Onboarding' LIMIT 1];
            for (Case thisCase : caseList) {
                if (entitlement != null && thisCase.RecordTypeId == amlRecordType) {
                    thisCase.EntitlementId = entitlement.Id;
                }
                if (entitlement != null && thisCase.RecordTypeId == AMlCRAORecTpye) {
                    thisCase.EntitlementId = AMLCRAOnEntitlement.Id;
                }
            }
        } catch (QueryException e) {
            return;
        }
    }

    public static void validateAwaitingSignOffConditions(List<Case> caseList) {
        Map<Id, Boolean> caseWithAttachmentMap = new Map<Id, Boolean>();
        Set<Id> caseIdSet = new Set<Id>();

        for (Case thisCase : caseList) {
            if (thisCase.Sub_Status__c != SUBSTATUS_REVIEW_NOT_REQUIRED) {
                caseIdSet.add(thisCase.Id);
                caseWithAttachmentMap.put(thisCase.Id, false);
            }
        }

        if (caseIdSet.size() != 0) {
            List<AggregateResult> attachmentsList = [SELECT COUNT(Id), LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :caseIdSet AND LinkedEntity.Type = :CASE_ENTITY_TYPE GROUP BY LinkedEntityId];

            for (AggregateResult thisAr : attachmentsList) {
                caseWithAttachmentMap.put((Id) thisAr.get(LINKED_ENTITY_ID_FILED), true);
            }

            for (Case thisCase : caseList) {
                if (!caseWithAttachmentMap.get(thisCase.Id)) {
                    thisCase.Status.addError(ERROR_MSG2);
                }
            }
        }
    }

    public static void changeStatusToActive(List<Case> caseList) {
        for (Case thisCase : caseList) {
            thisCase.Status = STATUS_ACTIVE;
        }
    }

    public static void changeStatusOnOwnerChanged(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {

        Group fraudInvestigationQueue = [SELECT Id FROM Group WHERE Name = 'Fraud Investigation' AND Type = 'Queue' LIMIT 1];
        Group amlConsultantQueue = [SELECT Id FROM Group WHERE Name = 'AML Consultants' AND Type = 'Queue' LIMIT 1];
        Group amlCRAOnbardingQueue = [SELECT Id FROM Group WHERE Name = 'AML Onboarding Consultant' AND Type = 'Queue' LIMIT 1];

        for (Case newCase : newCaseList) {
            if (oldCaseMap.get(newCase.Id).OwnerId == fraudInvestigationQueue.Id) {
                newCase.Status = 'Active Investigation UTD';
            } else if (oldCaseMap.get(newCase.Id).OwnerId == amlConsultantQueue.Id) {
                newCase.Status = 'Review in progress';
                newCase.Sub_Status__c = 'Review in Progress';
            } else if (oldCaseMap.get(newCase.Id).OwnerId == amlCRAOnbardingQueue.Id) {
                newCase.Status = 'Review in progress';
                newCase.Sub_Status__c = 'Review in Progress';
            }
        }
    }

    private static Set<String> getQuestionTypes() {
        Set<String> pickListValuesList = new Set<String>();

        Schema.DescribeFieldResult fieldResult = Answer__c.Question_Type__c.getDescribe();
        List<Schema.PicklistEntry> pickListEntry = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry pickListVal : pickListEntry) {
            pickListValuesList.add(pickListVal.getLabel());
        }

        return pickListValuesList;
    }
    //RCS-3707  AML CRA Onboarding RB - EDD Workflow Salesforce
    public static void AMLCRAcaseBeforeInsert(List<Case> newCases) {
        Id amlCraOnboardingRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('AML_CRA_Onboarding').getRecordTypeId();

        for (Case caseRecord : newCases) {
            // Auto alert creation from API
            if (caseRecord.Kafka_record_type__c == 'AMLCRA'
                    && caseRecord.Owner_kafka__c == 'AML_Onboarding_Consultant'
                    && caseRecord.Type == 'High Risk - Onboarding') {
                caseRecord.RecordTypeId = amlCraOnboardingRecordTypeId;

            }
            // Manual & Auto creation - Check if the Case RecordTypeId matches "AML_CRA_Onboarding"
            if (caseRecord.RecordTypeId == amlCraOnboardingRecordTypeId) {
                // Set fields only if RecordType is "AML_CRA_Onboarding"
                caseRecord.Type = 'High Risk - Onboarding';
                caseRecord.Origin = 'New Client Review';
                caseRecord.status = 'Open';
                caseRecord.Sub_Status__c = 'Not Yet Started';
                if (caseRecord.Kafka_record_type__c != 'AMLCRA') {
                    caseRecord.Alert_Create_Date__c = String.valueOf(Date.today());
                }
            }
        }
    }

    public static void RHX_Case(Map <Id, Case> oldCase, Map <Id, Case> newCase) {
        Type rollClass = System.Type.forName('rh2', 'ParentUtil');
        if (rollClass != null) {
            rh2.ParentUtil pu = (rh2.ParentUtil) rollClass.newInstance();
            if (trigger.isBefore) {
                pu.performTriggerRollups(oldCase, newCase, new String[]{
                        'Case'
                }, null);
            }
        }
    }
}