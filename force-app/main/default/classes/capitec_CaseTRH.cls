/**
* Created by Sebastian on 22.03.2023.
* Updated by Cornelia Smit on 24.07.2024 for CECSF-215
* Updated by Lazola Magobiyane on 18.09.2024 for RCS-3592
* Updated by Johan Langenhoven on 01.10.2024 for CECSF-441
* Updated by Kevin Nundran on 10.10.2024 for CEDT-2700
* Updated by Anil = RCS-3707  AML CRA Onboarding RB - EDD Workflow Salesforce */

public with sharing class capitec_CaseTRH extends TriggerHandler {
    private static final String USER_CODE_ID = '005';
    private static final Set<String> CLOSED_SUBSTATUS_SET = new Set<String>{
            'Maintain - Review Complete', 'Maintain - Adverse Media', 'Maintain - Reported', 'Terminate - Review Complete', 'Terminate - Adverse Media', 'Terminate - Reported', 'EDD Requirements Failed', 'Hard Block Notification', 'Hard Block Applied', 'HB 48hrs SMS notice', 'Final Termination Notice Sent', 'Hard Block Notice - Credit or Funeral Products', 'Account Terminated'
    }; //RCS-3592
    private static final String AWAITING_APPROVAL_STATUS = 'Awaiting Sign Off';
    private static final String ORIGIN_MANUAL = 'Manual';
    private static final String ORIGIN_EXTERNAL_BANK = 'External Bank';
    private static final String API_USER_NAME = 'API User';
    private static final String FRAUD_DEVELOPER_NAME = 'Fraud_Record_Type';
    private static final String ICS_Child_Case_DEVELOPER_NAME = 'Insurance_Claims_Assessment'; //ICS-391
    private static final String SUSPICIOUS_STATUS = 'Suspicious';
    private static final String DECISION_STATUS = 'Decision';
    private static final String FRAUD_STATUS = 'Fraud';
    private Map<Id, Case> oldCaseMap;
    private Map<Id, Case> newCaseMap;
    private List<Case> oldCaseList;
    private List<Case> newCaseList;
    private final Id recordTypeFraud;
    private final Id recordTypeICSchildCase; //ICS-391

    public capitec_CaseTRH() {
        oldCaseMap = (Map<Id, Case>) Trigger.oldMap;
        newCaseMap = (Map<Id, Case>) Trigger.newMap;
        oldCaseList = (List<Case>) Trigger.old;
        newCaseList = (List<Case>) Trigger.new;
        recordTypeFraud = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(FRAUD_DEVELOPER_NAME).getRecordTypeId();
        recordTypeICSchildCase = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(ICS_Child_Case_DEVELOPER_NAME).getRecordTypeId(); //ICS-391
    }

    public override void beforeUpdate() {
        capitec_CaseDMN.checkUserAccessToCase(oldCaseMap, newCaseList);//CECSF-215
        capitec_CaseDMN.saveLastConsultant(validateContextUserForOldRecord(oldCaseMap, newCaseMap));
        capitec_CaseDMN.closeCaseMilestones(oldCaseMap, newCaseList);
        capitec_CaseCC.validateCaseClosure(oldCaseMap, newCaseMap);
        capitec_CaseDMN.validateClosingCaseCondition(selectCaseWithCloseStatus(newCaseList));
        List<Case> casesListAwaitingApproval = selectCasesAwaitingForApproval(newCaseList);
        if (casesListAwaitingApproval.size() > 0) {
            capitec_CaseDMN.validateAwaitingSignOffConditions(casesListAwaitingApproval);

        }
        capitec_CaseDMN.changeStatusOnOwnerChanged(selectCases(newCaseList), oldCaseMap);
        capitec_CaseCD.checkCashDisputeCreationRequiredFields(newCaseList);
        capitec_CaseCD.makePersonOfInterestRequired(oldCaseMap, newCaseList);
        capitec_CaseCD.checkIfQATeamBeforeClosing(oldCaseMap, newCaseList);
        Capitec_CaseICS.ValidateCaseStatus(newCaseList, oldCaseMap);
        capitec_CaseDMN.RHX_Case(oldCaseMap, newCaseMap);
    }

    public override void beforeInsert() {
        //RCS-3707  AML CRA Onboarding RB - EDD Workflow Salesforce
        capitec_CaseDMN.AMLCRAcaseBeforeInsert(newCaseList);
        capitec_CaseDMN.saveLastConsultant(validateContextUserForNewRecord(newCaseList));
        capitec_CaseDMN.linkToAccountByCIF(newCaseList);
        capitec_CaseDMN.setUpFieldsFromKafka(checkIfCaseIsKafkaOrigin((newCaseList)));
        capitec_CaseDMN.linkMilestoneToCase(newCaseList);
        List<Case> casesToChangeStatusOnCreationFraud = selectCasesToChangeStatusOnCreationFraud(newCaseList);
        if (casesToChangeStatusOnCreationFraud.size() > 0) {
            capitec_CaseDMN.changeStatusToActive(casesToChangeStatusOnCreationFraud);
        }
        capitec_CaseCD.setCashDisputeStatusNewOnCreation(newCaseList);
        capitec_CaseDMN.RHX_Case(oldCaseMap, newCaseMap);

    }

    public override void afterInsert() {
        capitec_CaseCD.checkCashDisputeCreationRequiredFields(newCaseList);
        /** Added for ICS-391 **/
        System.debug('newCaseList: ' + newCaseList);
        Set<Id> caseIdSetToProcess = validateCheckDueDiligence(newCaseList);
        if (caseIdSetToProcess.size() > 0) {
            capitec_CaseICS.checkDueDiligence(caseIdSetToProcess);
        }
        List<Id> caseIdsForZipCallout = validateEventDeclineAutoSendGuardRiskEmail(newCaseList);
        if (!caseIdsForZipCallout.isEmpty()) {
            capitec_CaseICS.zipFileAndQueueUpdate(caseIdsForZipCallout);
        }

        Capitec_CaseICS.handleInsuranceEmailMsgs(newCaseMap);
        Capitec_CaseICS.call_IC_API_PolicyServiceQueueable(newCaseList);
        IC_API_OIPA_Services.handleChildCaseCreationOIPACallout(newCaseList);
    }

    public override void afterUpdate() {
        //ICS 1254 Dawid Kuczer
        Capitec_CaseICS.handleInsuranceEmailMsgs(oldCaseMap, newCaseMap);
        capitec_CaseRC.updateChildCaseOwner(oldCaseMap, newCaseMap);//CEDT-2700
    }

    private List<Id> validateEventDeclineAutoSendGuardRiskEmail(List<Case> caseList) {

        //Set<String> validDeclineReasons = new Set<String>{'Waiting period', 'End of contract', 'Voluntary retrenchment', 'Credit granted after notification date', 'Retired', 'Resigned', 'Lawful dismissal', 'Not greater than 31 consecutive days', 'Partial salary', 'Short-time', 'Claim notification period expired', 'Participation in an unprotected strike', 'Voluntary forfeiture of income', 'Eligibility: Client reached max age', 'Misrepresentation', 'Non disclosure'};
        List<Id> caseIdsForCallout = new List<Id>();

        for (Case c : caseList) {
            //System.debug('--Decline Reason on Child' + c.IC_Decline_Reason__c);
            if (c.RecordTypeId == recordTypeICSchildCase && c.Status == 'Assessment Pending' && c.Sub_Status__c == 'Preliminary Declined' && c.Product_Type__c == 'Credit Life'
                    && c.IC_Type__c == 'Unemployment/ITEI' && c.IC_Insurer_Underwriter_at_Event_Date__c == 'GuardRisk' && c.IC_Event_Selection__c == 'Event Declined'
                    && String.isNotBlank(c.IC_Decline_Reason__c)
                    && (c.IC_Decline_Reason__c != 'Policy lapsed' && c.IC_Decline_Reason__c != 'No cover' && c.IC_Decline_Reason__c != 'Own credit insurance declined'
                    && c.IC_Decline_Reason__c != 'No Obligations at Event Date' && c.IC_Decline_Reason__c != 'Zero Balance at Event Date')) {
                caseIdsForCallout.add(c.Id);
            }
        }
        System.debug('caseIdsForCallout: ' + caseIdsForCallout);
        return caseIdsForCallout;
    }

    private Set<Id> validateCheckDueDiligence(List<Case> caseList) {
        Set<Id> caseIdSetToProcess = new Set<Id>();

        System.debug('caseList: ' + caseList);
        for (Case thisCase : caseList) {
            if (thisCase.RecordTypeId == recordTypeICSchildCase) {
                caseIdSetToProcess.add(thisCase.Id);
            }
        }
        System.debug('caseIdSetToProcess: ' + caseIdSetToProcess);

        return caseIdSetToProcess;
    }
    /** End of Added for ICS-391 **/

    private static List<Case> validateContextUserForNewRecord(List<Case> inputCase) {
        List<Case> caseToUpdate = new List<Case>();

        for (Case thisCase : inputCase) {
            if (String.valueOf(thisCase.OwnerId).startsWith(USER_CODE_ID)) {
                caseToUpdate.add(thisCase);
            }
        }

        return caseToUpdate;
    }

    private static List<Case> validateContextUserForOldRecord(Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap) {
        List<Case> caseToUpdate = new List<Case>();

        for (Case thisNewCase : newCaseMap.values()) {
            if (thisNewCase.OwnerId != oldCaseMap.get(thisNewCase.Id).OwnerId && String.valueOf(thisNewCase.OwnerId).startsWith(USER_CODE_ID)) {
                caseToUpdate.add(thisNewCase);
            }
        }

        return caseToUpdate;
    }

    private static List<Case> selectCaseWithCloseStatus(List<Case> caseList) {
        List<Case> caseListToReturn = new List<Case>();

        for (Case thisCase : caseList) {
            if (CLOSED_SUBSTATUS_SET.contains(thisCase.Sub_Status__c)) {
                caseListToReturn.add(thisCase);
            }
        }

        return caseListToReturn;
    }

    private static List<Case> selectCasesAwaitingForApproval(List<Case> caseList) {
        List<Case> caseListToReturn = new List<Case>();

        for (Case thisCase : caseList) {
            if (thisCase.Status == AWAITING_APPROVAL_STATUS) {
                caseListToReturn.add(thisCase);
            }
        }

        return caseListToReturn;
    }

    private static List<Case> checkIfCaseIsKafkaOrigin(List<Case> caseList) {
        List<Case> caseListToReturn = new List<Case>();

        for (Case thisCase : caseList) {
            if (thisCase.Kafka_record_type__c != null || thisCase.Owner_kafka__c != null) {
                caseListToReturn.add(thisCase);
            }
        }

        return caseListToReturn;
    }

    private List<Case> selectCasesToChangeStatusOnCreationFraud(List<Case> caseList) {
        List<Case> caseListToReturn = new List<Case>();
        User apiUser = [SELECT Id FROM User WHERE Name = :API_USER_NAME];

        for (Case thisCase : caseList) {
            if ((thisCase.Origin == ORIGIN_MANUAL || thisCase.Origin == ORIGIN_EXTERNAL_BANK) && thisCase.CreatedById != apiUser.Id && thisCase.RecordTypeId == recordTypeFraud) {
                caseListToReturn.add(thisCase);
            }
        }

        return caseListToReturn;
    }

    private List<Case> selectCases(List<Case> caseList) {
        List<Case> fraudCaseListToReturn = new List<Case>();
        List<Case> amlCaseListToReturn = new List<Case>();

        for (Case thisCase : caseList) {
            if (thisCase.RecordTypeId == recordTypeFraud && (thisCase.Status == SUSPICIOUS_STATUS || thisCase.Status == FRAUD_STATUS) && String.valueOf(thisCase.OwnerId).startsWith(USER_CODE_ID)) {
                fraudCaseListToReturn.add(thisCase);
            } else if (String.valueOf(thisCase.OwnerId).startsWith(USER_CODE_ID)) {
                amlCaseListToReturn.add(thisCase);
            }
        }

        if (fraudCaseListToReturn.size() != 0) {
            return fraudCaseListToReturn;
        } else {
            return amlCaseListToReturn;
        }
    }
}