/*******************************************************************
* @Class Name        :  IC_API_InsuranceClaimsCase
* @Test Class        :  IC_API_InsuranceClaimsCase_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 3-Nov-2023, Jira Tickets: ICS-62, ICS-193, ICS-338, ICS-890, ICS-480, ICS-914, ICS-824
* @Version           :  1.0
*
*******************************************************************/

@RestResource(urlMapping='/InsuranceClaims/v1/*')
global with sharing class IC_API_InsuranceClaimsCase {
    
    public class Payload {
        public String ucs_id;
        public String cif_number;
        public String policy_number;
        public String status;
        public String sub_status;
        public String case_type;
        public String sub_type;
        public String sub_type_reason;
        public String product_type;
        public String id_number;
        public String passport_number;
        public String from_email_address;
        public String subject;
        public String description;
        public String claimant_title;
        public String claimant_first_name;
        public String claimant_surname;
        public String claimant_id_type;
        public String claimant_id_number;
        public String claimant_email_address;
        public String claimant_mobile_number;
        public String claimant_work_number;
        public String case_origin;
        public String event_date;
        /*ICS-480*/
        public String deceased_first_name;
        public String deceased_last_name;
        public String deceased_id_number;
        public String deceased_date_of_birth;
        //public String deceased_date_of_death;
        public String bi_number;
        /*ICS-815*/
        public String case_id;
        public ClaimParticipant[] claimParticipants;
        public Document[] documents;
        /*ICS-1097*/
        public PolicyParticipant[] policyParticipants;
        public IC_FuneralResponse.PolicyWrapper[] policies;
        /*ICS-1136*/
        public Boolean sanlam_claim;
        public String insurer_claim_ref;
        /*ICS-824*/
        public Boolean burial_repatriation_ind;
        
    }
    
    /*ICS-815*/
    public class ClaimParticipant {
        public String claimParticipant_title;
        public String claimParticipant_first_name;
        public String claimParticipant_surname;
        public String claimParticipant_id_type;
        public String claimParticipant_id_number;
        public String claimParticipant_date_of_birth;
        public String claimParticipant_email_address;
        public String claimParticipant_mobile_number;
        public String claimParticipant_work_number;
        public String claimParticipant_bank_name;
        public String claimParticipant_account_type;
        public String claimParticipant_branch_code;
        public String claimParticipant_account_number;
        
    }
    
    /*ICS-1097*/
    public class PolicyParticipant {
        public String policy_part_id_number;
        public String policy_part_name;
        public String policy_part_surname;
        public String policy_part_date_of_birth;
        public String policy_part_relationship;
        public String policy_part_cover_amount;
        public String policy_part_waiting_flag;
        public String policy_part_deceased_indicator;
        public String policy_name;
    }
    
    /* ICS-1295 */
    public class Document {
        public String documentumId;
        public String doc_parentRecordId;
        public String documentTypeId;
    }
    
    public class Response {
        public String ucs_id;
        public String case_id;
        public Integer status_code;
        public String message;
        public String case_number;
    }
    
    static List<Insurance_Claims_API_Setting__mdt> apiSettings = Insurance_Claims_API_Setting__mdt.getAll().values();
    
    @HttpPost
    global static void createClaim() {
        
        Boolean disableAPI = apiSettings[0].Disable_API__c;
        if (disableAPI) {
            RestContext.response.statusCode = 403; // Forbidden status code
            // Create a response object to capture both status code and message
            Response disabledResponse = new Response();
            disabledResponse.status_code = 403;
            disabledResponse.message = 'API is currently disabled.';
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(disabledResponse));
            return;
        }
        
        RestRequest req = RestContext.request;
        List<Payload> payloads = deserializePayload(req);
        
        // Retrieve and prepare necessary data for case creation
        Map<String, Id> accountLookups = retrieveAccounts(payloads);
        
        // Create cases
        List<Case> casesToInsert = prepareCases(payloads, accountLookups, apiSettings);
        List<Response> responses = insertCases(casesToInsert, payloads);
        
        // Finalize response
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responses));
    }
    
    private static List<Payload> deserializePayload(RestRequest req) {
        return (List<Payload>) JSON.deserialize(req.requestBody.toString(), List<Payload>.class);
    }
    
    private static Map<String, Id> retrieveAccounts(List<Payload> payloads) {
        // Gather all unique CIF, ID, and Passport numbers for querying
        Set<String> cifNumbers = new Set<String>();
        Set<String> idNumbers = new Set<String>();
        Set<String> passportNumbers = new Set<String>();
        
        // Prepare maps for quick lookups based on the queried accounts
        Map<String, Id> cifToAccountId = new Map<String, Id>();
        Map<String, Id> idToAccountId = new Map<String, Id>();
        Map<String, Id> passportToAccountId = new Map<String, Id>();
        
        // Create a combined map to handle all types of account lookups
        Map<String, Id> accountLookups = new Map<String, Id>();
        
        for(Payload p : payloads) {
            if(String.isNotBlank(p.cif_number)) cifNumbers.add(p.cif_number);
            if(String.isNotBlank(p.id_number)) idNumbers.add(p.id_number);
            if(String.isNotBlank(p.passport_number)) passportNumbers.add(p.passport_number);
        }
        
        // Query all potential accounts based on the collected identifiers
        List<Account> potentialAccounts = [ SELECT Id, CIF_Number__c, Identity_Number__c, Passport_Number__c 
                                           FROM Account 
                                           WHERE CIF_Number__c IN :cifNumbers 
                                           OR Identity_Number__c IN :idNumbers 
                                           OR Passport_Number__c IN :passportNumbers
                                          ];
        
        for(Account acc : potentialAccounts) {
            cifToAccountId.put(acc.CIF_Number__c, acc.Id);
            idToAccountId.put(acc.Identity_Number__c, acc.Id);
            passportToAccountId.put(acc.Passport_Number__c, acc.Id);
        }
        
        accountLookups.putAll(cifToAccountId);
        accountLookups.putAll(idToAccountId);
        accountLookups.putAll(passportToAccountId);
        System.debug('accountLookups: ' + accountLookups);
        return accountLookups;
    }
    
    
    private static List<Case> prepareCases(List<Payload> payloads, Map<String, Id> accountLookups, List<Insurance_Claims_API_Setting__mdt> apiSettings) {
        List<Case> cases = new List<Case>();
        String defaultRecordType = apiSettings[0].Default_Record_Type__c;
        Id insuranceClaimsTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(defaultRecordType).getRecordTypeId();
        Date eventDate = NULL;
        
        for(Payload p : payloads) {
            Case c = new Case();
            c.Id = p.case_id;
            if(String.isNotBlank(p.event_date)){
                eventDate = Date.valueOf(p.event_date);
            }    
            c.Event_Date__c = eventDate;
            c.IC_UCS_ID__c = p.ucs_id;
            c.IC_Policy_Number__c = p.policy_number;
            c.IC_Type__c = String.isEmpty(p.case_type) ? apiSettings[0].Default_Case_Type__c : p.case_type;
            c.Sub_Type__c = p.sub_type;
            if(p.case_type == 'Unemployment/ITEI' && String.isEmpty(p.sub_type_reason)){
                c.Sub_Type_Reason__c = apiSettings[0].Default_Sub_Type_Reason__c;
            } else {
                c.Sub_Type_Reason__c = p.sub_type_reason;
            }            
            c.Product_Type__c = String.isEmpty(p.product_type) ? apiSettings[0].Default_Product_Type__c : p.product_type;
            c.IC_From_Email_Address__c = p.from_email_address;
            c.Subject = String.isEmpty(p.subject) ? apiSettings[0].Default_Subject__c : p.subject;
            c.Description = p.description;
            c.Origin = String.isEmpty(p.case_origin) ? apiSettings[0].Default_Origin__c : p.case_origin;
            c.RecordTypeId = insuranceClaimsTypeId;
            if(p.case_type == 'Death'){
                c.IC_Deceased_First_Name__c = p.deceased_first_name;
                c.IC_Deceased_Surname__c = p.deceased_last_name;
                c.IC_Deceased_Date_of_Death__c = eventDate;
                /*c.IC_BenefitCode__c = p.benefit_code;*/ //ICS-480 : Benefit code to be removed
                c.IC_BI_Number__c = p.bi_number;
                c.IC_Deceased_Date_of_Birth__c  = String.isNotBlank(p.deceased_date_of_birth) ? Date.valueOf(p.deceased_date_of_birth) : NULL ;
                if(!String.isEmpty(p.deceased_id_number)){
                    c.IC_Deceased_Identity_Number__c = p.deceased_id_number;
                    c.IC_Deceased_ID_Number__c = TRUE;
                }
            }
            if(p.case_origin == 'Data Wash' || p.case_origin == 'Deceased Estates'){
                c.IC_Data_Wash_Service__c = true;
                c.Last_Working_Date__c = eventDate;
            }
            
            if(p.case_origin == 'NBS' && p.sanlam_claim != NULL){
                c.Status = 'Sanlam Assessment';
                c.Sub_Status__c = 'Sanlam Assessing';
                c.IC_Sanlam_Claim__c = p.sanlam_claim ? TRUE : FALSE;
                //c.IC_Insurer_Claim_Reference__c = p.insurer_claim_ref;
            }else{
                c.Status = (p.status != null && p.status != '') ? p.status : 'New';//ICS-890
                c.Sub_Status__c = p.sub_status;
            }
            // If no CIF or ID number is received identifying a policy holder, store info in the Claimants info section on the case
            //if(String.isEmpty(p.cif_number) && String.isEmpty(p.id_number)) {
            /*ICS-1096: remove Claimant code restriction for all products.*/
            c.Title__c = p.claimant_title;
            c.First_Name__c = p.claimant_first_name;
            c.Surname__c = p.claimant_surname;
            c.ID_Type__c = p.claimant_id_type;
            c.ID_Number__c = p.claimant_id_number;
            c.Email_Address__c = p.claimant_email_address;
            c.Mobile_Number__c = p.claimant_mobile_number;
            c.Work_Number__c = p.claimant_work_number;
            //}
            
            // Find related account using the accountLookups
            if(accountLookups.containsKey(p.cif_number)) {
                c.AccountId = accountLookups.get(p.cif_number);
            } else if(accountLookups.containsKey(p.id_number)) {
                c.AccountId = accountLookups.get(p.id_number);
            } else if(accountLookups.containsKey(p.passport_number)) {
                c.AccountId = accountLookups.get(p.passport_number);
            }
            
            //ICS-824
            if (p.burial_repatriation_ind == true) {
                c.IC_Burial_Repatriation_requested__c = true;                
            }
                
            cases.add(c);
        }
        
        return cases;
    }
    
    private static List<Response> insertCases(List<Case> cases, List<Payload> payloads) {
        
        Map<Id, List<IC_FuneralResponse.PolicyWrapper>> casePolicyParticipantsMap = new Map<Id, List<IC_FuneralResponse.PolicyWrapper>>();
        Map<String, String> documentumIdMap = new Map<String, String>();
        Map<String, String> documentTypeMap = new Map<String, String>();
        List<IC_Claim_Participant__c> cpInsertList = new List<IC_Claim_Participant__c>();
        List<IC_Policy__c> policiesToUpsert = new List<IC_Policy__c>();
        List<IC_Policy_Participant__c> ppInsertList = new List<IC_Policy_Participant__c>();
        List<DocumentChecklistItem> dcInsertList = new List<DocumentChecklistItem>(); 
        List<ContentVersion> cvInsertList = new List<ContentVersion>();
        List<Response> responses = new List<Response>();
        
        BypassUtil.FlowRequest bypass = new BypassUtil.FlowRequest();
        bypass.enable = true;
        bypass.disableValidationRules = true;
        BypassUtil.manageBypass(new List<BypassUtil.FlowRequest> { bypass });
        
        // Attempt to insert cases
        Database.UpsertResult[] results = Database.upsert(cases, false);
        
        // Create a list to hold the ids of successfully created cases
        List<Id> insertedCaseIds = new List<Id>();
        
        // Iterate over the results to collect the Ids of successfully created cases
        for (Database.UpsertResult sr : results) {
            if (sr.isSuccess()) {
                insertedCaseIds.add(sr.getId());
            }
        }
        
        // Query for the Case Numbers of the successfully created cases
        Map<Id, Case> caseNumberMap = new Map<Id, Case>();
        if (!insertedCaseIds.isEmpty()) {
            for (Case c : [SELECT Id, CaseNumber FROM Case WHERE Id IN :insertedCaseIds]) {
                caseNumberMap.put(c.Id, c);
            }
        }
        
        
        // Iterate over the results and payloads concurrently
        for (Integer i = 0; i < results.size(); i++) {
            Database.UpsertResult sr = results[i];
            Payload currentPayload = payloads[i];
            Response resp = new Response();
            resp.ucs_id = currentPayload.ucs_id;
            
            if (sr.isSuccess()) {
                // Successfully inserted, prepare a success response
                resp.status_code = 200;
                resp.case_id = sr.getId();
                resp.case_number = caseNumberMap.get(sr.getId()).CaseNumber;
                resp.message = String.isBlank(payloads[i].case_id) ? 'Case Created Successfully!' : 'Case Updated Successfully!';
            } else {
                // There were errors, prepare an error response
                resp.status_code = 400;
                resp.case_id = '';
                resp.case_number = '';
                resp.message = sr.getErrors()[0].getMessage();
                system.debug('tasser: ' + sr.getErrors()[0].getMessage());
            }
            
            if(payloads[i].case_type == 'Death'){
                if(String.isBlank(payloads[i].case_id)){//On Case creation
                    List<ClaimParticipant> cpList = payloads[i].claimParticipants;
                    if(cpList != NULL){
                        for(ClaimParticipant part : cpList){
                            IC_Claim_Participant__c cp = prepareClaimParticipants(part, sr.getId());
                            cpInsertList.add(cp);
                        }
                    }
                }
                if(payloads[i].case_origin == 'NBS'){
                    List<IC_FuneralResponse.PolicyWrapper> policyList = payloads[i].policies;
                    if(policyList != NULL){
                        policiesToUpsert.addAll(preparePolicies(policyList, sr.getId()));
                        casePolicyParticipantsMap.put(sr.getId(), policyList);
                    }
                }
                List<Document> docList = payloads[i].documents;
                if(docList != NULL){
                    for(Document doc : docList){
                        documentumIdMap.put(doc.documentumId, sr.getId());
                        documentTypeMap.put(doc.documentumId, doc.documentTypeId);
                    }
                }
            }
            responses.add(resp);
        }
        
        if(!documentumIdMap.isEmpty()){
            dcInsertList = prepareDocumentsChecklist(documentumIdMap, documentTypeMap);
            if(!dcInsertList.isEmpty()){
                // Attempt to insert DocumentChecklistItems
                Database.SaveResult[] resultsDC = Database.insert(dcInsertList, false);
            }
        }
        
        if(!cpInsertList.isEmpty()){
            // Attempt to insert Claim Participants
            Database.SaveResult[] resultsCP = Database.insert(cpInsertList, false);
        }
        
        if(!policiesToUpsert.isEmpty()){
            // Attempt to insert Policies
            Database.SaveResult[] resultsP = Database.insert(policiesToUpsert, false);
            if(!casePolicyParticipantsMap.isEmpty()){
                ppInsertList = preparePolicyParticipants(casePolicyParticipantsMap);
                if(!ppInsertList.isEmpty()){
                    // Attempt to insert Policy Participants
                    Database.SaveResult[] resultsPP = Database.insert(ppInsertList, false);
                }
            }
        }
        
        Bypass.disable = true;
        BypassUtil.manageBypass(new List<BypassUtil.FlowRequest> { bypass });
        
        return responses;
    }
    
    private static List<IC_Policy_Participant__c> preparePolicyParticipants(Map<Id, List<IC_FuneralResponse.PolicyWrapper>> casePolicyWrapperMap){
        List<IC_Policy_Participant__c> ppInsertList = new List<IC_Policy_Participant__c>(); 
        // Map to hold existing policies keyed by policy number
        Map<String, IC_Policy__c> existingPolicies = new Map<String, IC_Policy__c>();
        for (IC_Policy__c policy : [SELECT Id, Name FROM IC_Policy__c WHERE Parent_Case__c = : casePolicyWrapperMap.keySet()]) {
            existingPolicies.put(policy.Name, policy);
        }
        
        /*for(Id caseId : casePolicyParticipantsMap.keySet()){
List<PolicyParticipant> ppList = casePolicyParticipantsMap.get(caseId);
if(ppList != NULL){
for(PolicyParticipant part : ppList){
IC_Policy_Participant__c  pp = populatePolicyParticipants(part, caseId, existingPolicies.get(part.policy_name).Id);
ppInsertList.add(pp);
} 
}
}*/
        
        // Create lives assured with correct policy IDs
        for (Id caseId : casePolicyWrapperMap.keySet()) {
            List<IC_FuneralResponse.PolicyWrapper> ppList = casePolicyWrapperMap.get(caseId);
            
            //Reference each policy wrapper for each case in payload
            if(ppList != NULL){
                for(IC_FuneralResponse.PolicyWrapper policyWrapper : ppList){
                    IC_FuneralResponse.Policy policy = policyWrapper.policy;
                    
                    if (policyWrapper.roleplayers != null) {
                        //identy the policy participants
                        for (IC_FuneralResponse.RolePlayerWrapper rolePlayerWrapper : policyWrapper.roleplayers) {
                            
                            IC_FuneralResponse.Roleplayer details = rolePlayerWrapper.details;
                            
                            if (details.lifeAssured || details.beneficiary) { //ICS-1582
                                IC_Policy_Participant__c  livesAssured = populatePolicyParticipants(details, caseId, existingPolicies.get(policy.contractReference).Id);
                                ppInsertList.add(livesAssured);
                                if('MainLife'.equalsIgnoreCase(details.relationship) && details.lifeAssured){
                                    details.beneficiary = true;
                                    IC_Policy_Participant__c  beneficiaryML = populatePolicyParticipants(details, caseId, existingPolicies.get(policy.contractReference).Id);
                                    ppInsertList.add(beneficiaryML);
                                }
                            } 
                        }
                    }
                }
            }
        }
        
        return ppInsertList;
    }
    private static IC_Policy_Participant__c populatePolicyParticipants(IC_FuneralResponse.Roleplayer details, Id CaseId, Id policyId) {
        
        Id livesAssuredRecType = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Lives_Assured').getRecordTypeId();
        Id beneficiaryRecType = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Beneficiaries').getRecordTypeId();//ICS-1582
        
        IC_Policy_Participant__c livesAssured = new IC_Policy_Participant__c();
        livesAssured.RecordTypeId = (details.beneficiary != null && details.beneficiary) ? beneficiaryRecType : livesAssuredRecType; //ICS-1582
        livesAssured.IC_Case__c = CaseId;
        livesAssured.IC_Policy_Number__c = policyId; // Set Policy Number
        livesAssured.IC_Name__c = details.firstName;
        livesAssured.IC_Surname__c = details.surname;
        livesAssured.IC_Identity_Number__c = details.idNumber;
        livesAssured.IC_Date_of_Birth__c = details.dateOfBirth.date();
        livesAssured.IC_Relationship__c = details.relationship;
        livesAssured.IC_Cover_Amount__c = details.coverAmount;
        livesAssured.IC_Deceased_Indicator__c = details.deceased_indicator;
        //livesAssured.IC_In_Waiting_Period__c = details.waiting_flag;
        return livesAssured;
    }
    
    private static IC_Claim_Participant__c prepareClaimParticipants(ClaimParticipant part, Id CaseId) {
        IC_Claim_Participant__c cp = new IC_Claim_Participant__c ();
        cp.IC_Claim_Participant_Title__c = part.claimParticipant_title;
        cp.IC_Claim_Participant_FirstName__c = part.claimParticipant_first_name;
        cp.IC_Claim_Participant_Surname__c = part.claimParticipant_surname;
        cp.IC_Claim_Participant_ID_Type__c = part.claimParticipant_id_type;
        cp.IC_Claim_Participant_ID_Number__c = part.claimParticipant_id_number;
        cp.IC_Claim_Participant_Date_of_Birth__c = String.isNotBlank(part.claimParticipant_date_of_birth) ? Date.valueOf(part.claimParticipant_date_of_birth) : NULL;
        cp.IC_Claim_Participant_Email_Address__c = part.claimParticipant_email_address;
        cp.IC_Claim_Participant_Mobile_Number__c = part.claimParticipant_mobile_number;
        cp.IC_Claim_Participant_Work_Number__c = part.claimParticipant_work_number;
        cp.IC_Claim_Participant_Bank_Name__c = part.claimParticipant_bank_name;
        cp.IC_Claim_Participant_Account_Type__c = part.claimParticipant_account_type;
        cp.IC_Claim_Participant_Branch_code__c = part.claimParticipant_branch_code;
        cp.IC_Claim_Participant_Account_Number__c = part.claimParticipant_account_number;
        cp.IC_Case__c = CaseId;
        return cp;
    }
    
    private static List<IC_Policy__c> preparePolicies(List<IC_FuneralResponse.PolicyWrapper> policiesList, Id CaseId) {
        List<IC_Policy__c> policiesToUpsert = new List<IC_Policy__c>();
        
        for (IC_FuneralResponse.PolicyWrapper item : policiesList) {
            IC_Policy__c policy = new IC_Policy__c();
            policy.Parent_Case__c = CaseId;
            IC_FuneralResponse.Policy wrap = item.policy;
            
            policy.Name = wrap.contractReference;
            //policy.IC_Group_of_Insurance_Contracts__c = ifrS17Grouping;
            policy.IC_Date_Opened__c = wrap.commencementDate;
            policy.Policy_Version__c = '1'; // Defaulted to 1
            policy.Insurer_Underwriter_at_Event_Date__c = wrap.productCode;
            policy.IC_Arrears_Amount__c = (wrap.arrearDetails != null) ? wrap.arrearDetails.outstandingAmount : 0;
            
            policiesToUpsert.add(policy);
        }
        return policiesToUpsert;
    }
    
    private static List<DocumentChecklistItem> prepareDocumentsChecklist(Map<String, String> documentumIdMap, Map<String, String> documentTypeMap){
        List<DocumentChecklistItem> dcInsertList = new List<DocumentChecklistItem>(); 
        Map<String, ContentVersion> documentumCvMap = new Map<String, ContentVersion>(); 
        System.debug('1295 documentumIdMap : ' + documentumIdMap);
        for(ContentVersion conV : [SELECT Id, Title, Documentum_ID__c, ContentDocumentId FROM ContentVersion WHERE Documentum_ID__c =: documentumIdMap.keySet()]){
            documentumCvMap.put(conV.Documentum_ID__c, conV);
        }
        System.debug('1295 documentumCvMap : ' + documentumCvMap);
        for(String docId : documentumIdMap.keySet()){
            dcInsertList.add(createNewDocumentChecklistRecord(documentumIdMap.get(docId), documentumCvMap.get(docId), docId, documentTypeMap.get(docId)));
        }
        
        return dcInsertList;
    }
    
    private static DocumentChecklistItem createNewDocumentChecklistRecord(Id relatedCaseId, ContentVersion contentVersion, String documentumId, String documentTypeId) {
        // Create a new instance of your custom object and set the fields
        DocumentChecklistItem docRecord = new DocumentChecklistItem();
        System.debug('1295 contentVersion : ' + contentVersion);
        docRecord.Name = contentVersion.Title;
        docRecord.IC_Documentum_ID__c = documentumId;
        docRecord.ParentRecordId = relatedCaseId;
        
        // Construct the Salesforce URL to the ContentVersion record in Lightning Experience
        String baseUrl = URL.getCurrentRequestURL().toExternalForm();
        String documentUrl = baseUrl + '/lightning/r/ContentDocument/' + contentVersion.ContentDocumentId + '/view';
        docRecord.Document_Link__c = documentUrl;
        docRecord.IC_ContentDocumentId__c = contentVersion.ContentDocumentId;
        docRecord.DocumentTypeId = documentTypeId;
        docRecord.Status = 'Verified';
        
        return docRecord;
    }
}