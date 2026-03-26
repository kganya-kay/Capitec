/**
 * @description       : Handler for flow C&R: Case Auto Index
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 09-05-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class CR_CaseAutoIndexHandler {
    public static Map<String, Case> mapIdNumberToCaseObj = new Map<String, Case>();
    public static Map<String, Case> mapCifNumberToCaseObj = new Map<String, Case>();
    public static Set<String> setCaseParticipants = new Set<String>();
    public static Map<Id, String> mapCaseToFirstMatch = new Map<Id, String>();
    public static final Id ADMINISTRATION_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Administration').getRecordTypeId();
    public static final Id SEQUESTRATION_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Sequestration').getRecordTypeId();

    @InvocableMethod(Label='Analyze for CIF and Id number' Description='Analyze the case to look for CIF and ID number')
    public static void analyzeCase(List<Case> lstCases) {
        //Initialise all global variables
        mapIdNumberToCaseObj = new Map<String, Case>();
        mapCifNumberToCaseObj = new Map<String, Case>();
        mapCaseToFirstMatch = new Map<Id, String>();
        setCaseParticipants = new Set<String>();
        Set<Id> setCaseAllowParticipants = new Set<Id>(); // Stores case Ids that Allow participants
        Map<String, Set<String>> mapAllowParticipants = new Map<String, Set<String>>();


        //get case type and recordtype from metadata
        mapAllowParticipants = getCaseTypesMetadata();

        for (Case caseObj : lstCases) {
            if (caseObj.RecordTypeId == ADMINISTRATION_RECORD_TYPE_ID && mapAllowParticipants.get('Administration') != null) {
                if (mapAllowParticipants.get('Administration').contains(caseObj.Type)) {
                    setCaseAllowParticipants.add(caseObj.Id); // to query case participants
                }
            }

            if (caseObj.RecordTypeId == SEQUESTRATION_RECORD_TYPE_ID && mapAllowParticipants.get('Sequestration') != null) {
                if (mapAllowParticipants.get('Sequestration').contains(caseObj.Type)) {
                    setCaseAllowParticipants.add(caseObj.Id); // to query case participants
                }
            }
        }

        //get case participants -- to check if participant already exists
        if (!setCaseAllowParticipants.isEmpty()) {
            verifyCaseParticipant(setCaseAllowParticipants);
        }

        //analyse Subject and Description of case
        analyzeCaseDetails(lstCases, setCaseAllowParticipants);
    }

    public static Map<String, Set<String>> getCaseTypesMetadata() {

        Set<String> setAdminCaseTypes = new Set<String>();
        Set<String> setSequestrationCaseTypes = new Set<String>();
        Map<String, Set<String>> mapMetadataTypes = new Map<String, Set<String>>();

        for (Collections_and_Recoveries_Keyword__mdt metadata : [
                SELECT Case_Type__c, Case_Type__r.MasterLabel, Keyword__c, Allow_Second_Applicant__c
                FROM Collections_and_Recoveries_Keyword__mdt
                WHERE Allow_Second_Applicant__c = TRUE
        ]) {

            if (metadata.Case_Type__r.MasterLabel == 'Administration') setAdminCaseTypes.add(metadata.Keyword__c);
            if (metadata.Case_Type__r.MasterLabel == 'Sequestration') setSequestrationCaseTypes.add(metadata.Keyword__c);
        }

        if (setAdminCaseTypes != null) mapMetadataTypes.put('Administration', setAdminCaseTypes);
        if (setSequestrationCaseTypes != null) mapMetadataTypes.put('Sequestration', setSequestrationCaseTypes);

        return mapMetadataTypes;
    }

    public static void analyzeCaseDetails(List<Case> lstCases, Set<Id> setCaseAllowParticipants) {
        //Verifies and concatenate subject and description and prepares for scraping
        String contentToAnalyze;
        for (Case caseObj : lstCases) {
            contentToAnalyze = '';

            if (caseObj.Subject != null) {
                contentToAnalyze += caseObj.Subject;
            }
            if (caseObj.Description != null) {
                contentToAnalyze += ' ' + caseObj.Description;
            }
            if (contentToAnalyze != '') {
                extractIdNumber(contentToAnalyze, caseObj); //Extract Id number from the concatenated subject and description
                extractCIFNumber(contentToAnalyze, caseObj); //Extract CIF number from the concatenated subject and description
            }
        }

        if (mapCifNumberToCaseObj.keySet() != null || mapIdNumberToCaseObj.keySet() != null) {
            handleQueryAccount(mapIdNumberToCaseObj, mapCifNumberToCaseObj, setCaseAllowParticipants);
        }
    }

    public static void extractIdNumber(String content, Case caseRecord) {
        Pattern pattern = Pattern.compile('\\b\\d{13}\\b'); //13 digits regex pattern
        Matcher matcher = pattern.matcher(content);

        while (matcher.find()) {
            String idNumberExtracted = matcher.group(0);

            if (!mapCaseToFirstMatch.containsKey(caseRecord.Id)) {
                mapCaseToFirstMatch.put(caseRecord.Id, idNumberExtracted); // first match is considered as the main applicant
            }

            if (!setCaseParticipants.contains(idNumberExtracted) //if case participant already exists
                    && caseRecord.Client_ID_Number__c != idNumberExtracted) { //check if Account is already linked to the case
                mapIdNumberToCaseObj.put(idNumberExtracted, caseRecord);
            }
        }
    }

    public static void extractCIFNumber(String content, Case caseRecord) {
        Pattern pattern = Pattern.compile('\\b\\d{9}\\b'); //9 digits regex pattern
        Matcher matcher = pattern.matcher(content);

        while (matcher.find()) {
            if (!setCaseParticipants.contains(matcher.group(0))
                && caseRecord.CIF_Number__c != matcher.group(0) //check if Account is already linked to the case
            ) {
                if (!mapCaseToFirstMatch.containsKey(caseRecord.Id)) {
                    mapCaseToFirstMatch.put(caseRecord.Id, matcher.group(0));
                }
                mapCifNumberToCaseObj.put(matcher.group(0), caseRecord);
            }
        }

    }

    //to prevent duplicate participant from being created
    public static void verifyCaseParticipant(Set<Id> setCaseIds) {
        setCaseParticipants = new Set<String>(); //initialise set

        for (CaseParticipant caseParticipant : [SELECT Id, Identity_Number__c, CIF_Number__c FROM CaseParticipant WHERE CaseId IN :setCaseIds]) {
            if (caseParticipant.Identity_Number__c != null) {
                setCaseParticipants.add(caseParticipant.Identity_Number__c);
            }

            if (caseParticipant.CIF_Number__c != null) {
                setCaseParticipants.add(caseParticipant.CIF_Number__c);
            }
        }
    }

    public static void handleQueryAccount(Map<String, Case> mapIdNumberToCaseObj, Map<String, Case> mapCifNumberToCaseObj, Set<Id> setCaseAllowParticipants) {

        List<Case> lstCasesToUpdate = new List<Case>();
        List<CaseParticipant> lstCasePartToCreate = new List<CaseParticipant>();

        //Query all accounts with Id number or CIF number that matches the extracted Id and CIF from the cases
        for (Account account : [SELECT Id, Name, Identity_Number__c, CIF_Number__c FROM Account WHERE Identity_Number__c IN :mapIdNumberToCaseObj.keySet() OR CIF_Number__c IN :mapCifNumberToCaseObj.keySet()]) {

            if (account.Identity_Number__c != null && mapIdNumberToCaseObj.containsKey(account.Identity_Number__c)) {
                Case caseRecord = mapIdNumberToCaseObj.get(account.Identity_Number__c);
                Boolean isMainApplicant = mapCaseToFirstMatch.get(caseRecord.Id) == account.Identity_Number__c;
                Boolean allowsParticipants = setCaseAllowParticipants.contains(caseRecord.Id);

                //Verify if the case record allow Participants [Dual Id]
                if (allowsParticipants) {
                    //main applicant
                    if (isMainApplicant) {
                        caseRecord.AccountId = account.Id;
                        caseRecord.ID_Number__c = account.Identity_Number__c;
                        lstCasesToUpdate.add(caseRecord);
                    } else {
                        //second applicant
                        CaseParticipant caseParticipant = getParticipant(account, mapIdNumberToCaseObj.get(account.Identity_Number__c).Id);
                        lstCasePartToCreate.add(caseParticipant);
                    }
                } else {// case type does not allow participants, therefore account becomes main applicant
                    if (isMainApplicant) {
                        caseRecord.AccountId = account.Id;
                        caseRecord.ID_Number__c = account.Identity_Number__c;
                        lstCasesToUpdate.add(caseRecord);
                    }
                }
            }
            //CIF logics
            if (account.CIF_Number__c != null && mapCifNumberToCaseObj.containsKey(account.CIF_Number__c)) {
                Case caseRecord = mapCifNumberToCaseObj.get(account.CIF_Number__c);
                Boolean isMainApplicant = mapCaseToFirstMatch.get(caseRecord.Id) == account.CIF_Number__c;
                Boolean allowsParticipants = setCaseAllowParticipants.contains(caseRecord.Id);

                //Update case record with related client and update Id number on object
                if (allowsParticipants) {
                    //main applicant
                    if (isMainApplicant) {
                        caseRecord.AccountId = account.Id;
                        caseRecord.Account_CIF_Number__c = account.CIF_Number__c;
                        lstCasesToUpdate.add(caseRecord);
                    } else {
                        //second applicant
                        CaseParticipant caseParticipant = getParticipant(account, mapIdNumberToCaseObj.get(account.CIF_Number__c).Id);
                        lstCasePartToCreate.add(caseParticipant);
                    }
                } else {// case type does not allow participants, therefore account becomes main applicant
                    if (isMainApplicant) {
                        caseRecord.AccountId = account.Id;
                        caseRecord.Account_CIF_Number__c = account.CIF_Number__c;
                        lstCasesToUpdate.add(caseRecord);
                    }
                }
            }
        }

        if (!lstCasesToUpdate.isEmpty()) {
            try {
                update lstCasesToUpdate;
            } catch (Exception ex) {
                System.debug('handleQueryAccount update error: ' + ex.getMessage());
            }
        }

        if (!lstCasePartToCreate.isEmpty()) {
            try {
                insert lstCasePartToCreate;
            } catch (Exception ex) {
                System.debug('handleQueryAccount update error: ' + ex.getMessage());
            }
        }
    }

    public static CaseParticipant getParticipant(Account account, String caseId) {

        CaseParticipant caseParticipant = new CaseParticipant();
        caseParticipant.CaseId = caseId;
        caseParticipant.ParticipantId = account.Id;
        caseParticipant.Identity_Number__c = (account.Identity_Number__c != null) ? account.Identity_Number__c : null;
        caseParticipant.CIF_Number__c = (account.CIF_Number__c != null) ? account.CIF_Number__c : null;
        caseParticipant.Status = 'Active';
        caseParticipant.Role = 'Second Applicant';
        caseParticipant.CR_Second_Applicant_Name__c = account.Name;

        return caseParticipant;
    }
}