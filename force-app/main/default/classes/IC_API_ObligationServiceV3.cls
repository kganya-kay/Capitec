/**
* Class Name:       IC_API_ObligationServiceV3
* Test Class:       IC_API_ObligationServiceV3_TEST
* Author            Ridwan Moosuddee
* Company           BlueSky
* Ticket            ICS-1073 - DEV Funeral: Get Obligations additional fields returned - Integration
**/
public without sharing class IC_API_ObligationServiceV3 {
    
    static List<IC_Get_Obligations_V3_API_Settings__mdt> apiSettings = IC_Get_Obligations_V3_API_Settings__mdt.getAll().values();
    
    //Variables passed from Salesforce flow to apex 
    //This will serve as the request body
    public class FlowRequest {
        @InvocableVariable public String caseNumber;
        @InvocableVariable public String cifNumber;
        @InvocableVariable public Date eventDate;
        @InvocableVariable public String productType;
        @InvocableVariable public String caseType;
        @InvocableVariable public String caseSubType;
        @InvocableVariable public Date lastWorkingDate;
        @InvocableVariable public String idNumber;
        @InvocableVariable public String product;
    }
    
    /**
    * @description Callout to get Policies, Beneficiaries, Lives assured and Arrears information
    * @author Samiirah.A@bsky.co.za | 12-03-2024 
    * @param requests 
    * @return List<String> 
    **/
    @InvocableMethod(label='Make Callout to Obligation Service V3' description='Makes a callout with the given details from the flow.')
    public static List<String> makePolicyCallout(List<FlowRequest> requests) {
        
        FlowRequest request = requests[0];
        String requestBody = JSON.serialize(request);
        Integer timeoutValue = Integer.valueOf(apiSettings[0].Timeout_in_seconds__c * 1000);
        
        List<String> results = new List<String>();
        
        final UUID randomUuid = UUID.randomUUID();
        final String randomUuidStr = randomUuid.toString();

       try {
            // Callout logic
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiSettings[0].Endpoint_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-request-id', randomUuidStr);
            req.setHeader('x-session-id', randomUuidStr);
            req.setHeader('x-requester-uid', 'SALESFORCE_00000_12_0000_00');
            req.setBody(requestBody);
            req.setTimeout(timeoutValue);
            
            HttpResponse res = http.send(req);

            System.debug('##***## requestBody: ' + requestBody);
            System.debug('##***## res: ' + res);
            
            if (res.getStatusCode() == 200) {
                
                String checkResponseBody = res.getBody();
                
                if (String.isNotBlank(checkResponseBody)) { // Check if the response body is not empty or null
                    Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    if (responseBody.containsKey('funeral') 
                        && ((Map<String, Object>)responseBody.get('funeral')).containsKey('policies') 
                        && ((List<Object>)((Map<String, Object>)responseBody.get('funeral')).get('policies')).isEmpty()) {
                        System.debug('responseBody: ' + responseBody);
                        results.add('Error: No policies found for this client');
                    } else {
                        processResponse(res.getBody(), request);
                        System.debug(res.getBody());
                        results.add('Success: ' + res.getBody());
                    }
                } else {
                    // Handle empty response body
                    results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team. The response body from the callout is empty.');
                    System.debug('checkResponseBody: ' + checkResponseBody);
                }
            } else {
                // Handle HTTP errors
                try {
                    Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    if (errorResponse.containsKey('Detail') 
                        && !((List<Object>) errorResponse.get('Detail')).isEmpty()) {
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
                System.debug(res.getBody());
                results.add(errorMsg);
            }
        } catch(Exception e) {
            System.debug('Error caught: ' + e.getMessage());
            results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team. ' + e.getMessage());
        }
        return results;
    }
    
    /**
    * @description Analyze response received and prepare updates for Salesforce data
    * @author Samiirah.A@bsky.co.za | 12-03-2024 
    * @param responseBody 
    * @param request 
    **/
    private static void processResponse(String responseBody, FlowRequest request) {

        try {
            IC_FuneralResponse funeralResponse = (IC_FuneralResponse) JSON.deserialize(responseBody, IC_FuneralResponse.class);
            Case caseRecord = [SELECT Id, Origin, AccountId, Product_Type__c, IC_Type__c, Sub_Type__c, Sub_Type_Reason__c, OwnerId, Status, Sub_Status__c, IC_Deceased_Date_of_Death__c,
                                Account.Name, Account.PersonTitle, Account.Birthdate__c, Account.Phone, Account.PersonEmail, Account.Identity_Number__c, Account.Gender__c,
                                Account.LastName, Account.FirstName, Account.ID_Type__c, IC_Sanlam_Claim__c
                               FROM Case WHERE CaseNumber = :request.caseNumber LIMIT 1];
    
            List<IC_Policy__c> policiesToUpsert = new List<IC_Policy__c>();
            List<IC_Policy__c> lstAllPolicies = new List<IC_Policy__c>(); //Samiirah Aujub - ICS-1764 - Do not update policies linked to NBS case
            List<IC_Policy__c> oldPoliciesToDelete = new List<IC_Policy__c>();
            List<IC_Policy_Participant__c> livesAssuredToInsert = new List<IC_Policy_Participant__c>();
            List<IC_Policy_Participant__c> beneficiariesToInsert = new List<IC_Policy_Participant__c>();
            List<IC_Waiting_Period_Waiver__c> waiversToInsert = new List<IC_Waiting_Period_Waiver__c>(); //ICS-756
            Boolean updateCase; //ICS-756
            
            List<IC_Policy_Participant__c> livesAssuredToDelete = new List<IC_Policy_Participant__c>();
            List<IC_Policy_Participant__c> beneficiariesToDelete = new List<IC_Policy_Participant__c>();
            List<IC_Segment__c> participantSegments = new List<IC_Segment__c>();
    
            Id livesAssuredRTId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByName().get('Lives Assured').getRecordTypeId();
            Id beneficiariesRTId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByName().get('Beneficiaries').getRecordTypeId();

            Map<String, IC_Policy_Participant__c> participantsByIdentifiers = new Map<String, IC_Policy_Participant__c>();
            Map<String, List<IC_Segment__c>> segmentsByIdentifiers = new Map<String, List<IC_Segment__c>>();

            //ICS - 1802 - ICS-1704 : Samiirah Aujub - Store segments for participants from NBS
            Map<String,IC_Policy_Participant__c> mapIdentifierToParticipant = new Map<String, IC_Policy_Participant__c>();
            Set<Id> setParticipantIdWithSegments = new Set<Id>();
            List<IC_Segment__c> lstSegmentsNBSToCreate = new List<IC_Segment__c>();

            // Map to hold existing policies keyed by policy number
            Map<String, IC_Policy__c> existingPolicies = new Map<String, IC_Policy__c>();
            for (IC_Policy__c policy : [SELECT Id, Name, IC_Effective_Cancellation_Date__c, Insurer_Underwriter_at_Event_Date__c, IC_Status__c, IC_DeceasedCovermount__c FROM IC_Policy__c WHERE Parent_Case__c = :caseRecord.Id]) {
                existingPolicies.put(policy.Name, policy);
            }
            System.debug('existingPolicies ' + existingPolicies);
            
            Date deceasedDate = caseRecord.IC_Deceased_Date_of_Death__c;
            Boolean nbsOrigin = ('NBS'.equalsIgnoreCase(caseRecord.Origin)) ? TRUE : FALSE;
            
            // Subtract 2 months from the deceased date
            Date deceasedDateMinusTwoMonths = deceasedDate.addMonths(-2);
                      
            for (String key : existingPolicies.keySet()) {
                IC_Policy__c policy = existingPolicies.get(key);
                
                Date effectiveCancellationDate = policy.IC_Effective_Cancellation_Date__c; 
                
                //Check policy status if it is Cancelled or Lapsed or OutOfForce =- ICS-756
                if(policy.IC_Status__c == 'Cancelled' || policy.IC_Status__c == 'Lapsed' || policy.IC_Status__c == 'OutOfForce'){
                    if (deceasedDateMinusTwoMonths <= effectiveCancellationDate) {

                        IC_Waiting_Period_Waiver__c waiver = new IC_Waiting_Period_Waiver__c();
                        waiver.IC_Previous_insurer__c = policy.Insurer_Underwriter_at_Event_Date__c;
                        waiver.IC_Case__c = caseRecord.Id;
                        waiver.IC_Policy__c = policy.Id;
                        waiver.IC_Cover_amount__c = policy.IC_DeceasedCovermount__c;
                        
                        //waiver.IC_Previous_cover_start_date__c = today; 
                        //waiver.IC_Previous_cover_end_date__c = today();
                        
                        waiversToInsert.add(waiver);
                    }
                }
            }

            //Refactored code by Samiirah Aujub - 17/10/2024
            for (IC_Policy_Participant__c participant : [SELECT Id, 
                                                                IC_Name__c,
                                                                IC_Surname__c,
                                                                IC_Title__c,
                                                                IC_Date_of_Birth__c,
                                                                IC_Policy_Number__c,
                                                                IC_Identity_Number__c,
                                                                IC_Relationship__c,
                                                                IC_roleguids__c,
                                                                IC_Policy_Number__r.Name,
                                                                IC_Cover_Amount__c,
                                                                RecordtypeId 
                                                         FROM IC_Policy_Participant__c 
                                                         WHERE IC_Case__c =: caseRecord.Id]) {
                if (participant.RecordTypeId == livesAssuredRTId) {
                    livesAssuredToDelete.add(participant);
                } else if (participant.RecordTypeId == beneficiariesRTId) {
                    beneficiariesToDelete.add(participant);
                }

                //ICS-1802: Samiirah Aujub - Use RoleGUID to map Segments
                if( participant.IC_roleguids__c != null){
                    mapIdentifierToParticipant.put(participant.IC_roleguids__c, participant);
                }
            }

            System.debug('##1802 mapIdentifierToParticipant:' + mapIdentifierToParticipant);
    
            for (IC_FuneralResponse.PolicyWrapper policyWrapper : funeralResponse.funeral.policies) {
                
                IC_FuneralResponse.Policy policy = policyWrapper.policy;
                IC_Policy__c policyRecord;
    
                if (existingPolicies.containsKey(policy.contractReference)) {
                    // Update existing policy
                    policyRecord = existingPolicies.get(policy.contractReference);
                } else {
                    // Create new policy
                    policyRecord = new IC_Policy__c();
                    policyRecord.Parent_Case__c = caseRecord.Id;
                    policyRecord.OwnerId = caseRecord.OwnerId;
                    
                    if (existingPolicies.size() > 0) {
                        //Delete Old Policies
                        oldPoliciesToDelete = existingPolicies.values();
                    }
                }
    
                // Extract ifrS17Grouping from the first roleplayer
                String ifrS17Grouping = (policyWrapper.roleplayers != null && !policyWrapper.roleplayers.isEmpty()) ? policyWrapper.roleplayers[0].details.ifrS17Grouping : null;
    
                policyRecord.Name = policy.contractReference;
                policyRecord.IC_Group_of_Insurance_Contracts__c = ifrS17Grouping;
                policyRecord.IC_Date_Opened__c = policy.commencementDate;
                policyRecord.Policy_Version__c = '1'; // Defaulted to 1
                policyRecord.Insurer_Underwriter_at_Event_Date__c = policy.productCode;
                policyRecord.IC_Arrears_Amount__c = (policy.arrearDetails != null) ? policy.arrearDetails.outstandingAmount : 0;
                policyRecord.IC_Status__c = policy.status; //ICS-756 
                policyRecord.IC_Status__c = policy.pasStatus; //ICS-1738

                //ICS-1831 - Updated by Samiirah Aujub - AC1 - Use recordedCancellationDate
                policyRecord.IC_Effective_Cancellation_Date__c = (policy.cancellationDetails != null && policy.cancellationDetails.recordedCancellationDate != null) ? policy.cancellationDetails.recordedCancellationDate.date() : null;
                
                
                /* ICS-756 - START */
                if(policy.status == 'In Force'){ 
                    caseRecord.IC_In_waiting_period_Set__c = true;
                    updateCase = true;
                }
                /* ICS-756 - END */

                //Added by Samiirah Aujub - ICS 1764 - Do not update policies created by NBS
                if(existingPolicies.containsKey(policy.contractReference)){
                    if(nbsOrigin && caseRecord.IC_Sanlam_Claim__c){ //skips sanlam case

                    }
                    else{
                        policiesToUpsert.add(policyRecord);
                    }
                }
                else if(!existingPolicies.containsKey(policy.contractReference)){ //new policy
                    policiesToUpsert.add(policyRecord);
                }
                lstAllPolicies.add(policyRecord);
            }
            
            System.debug('oldPoliciesToDelete:' + oldPoliciesToDelete);
            System.debug('policiesToUpsert:' + policiesToUpsert);
            System.debug('lstAllPolicies:' + lstAllPolicies);
            
            // Delete Old policies
            if (!oldPoliciesToDelete.isEmpty() && !nbsOrigin) {
                delete oldPoliciesToDelete;
            }
    
            // Insert policies
            if (!lstAllPolicies.isEmpty()) { //ICS-1764

                if(!policiesToUpsert.isEmpty()){ //ICS-1764
                    upsert policiesToUpsert;
                }
                
                /* ICS-756 - START */
                if(updateCase = true){
                    update caseRecord;
                }
                /* ICS-756 - END */
                
    
                // Map to hold policy numbers and their corresponding inserted record IDs
                Map<String, Id> policyIdMap = new Map<String, Id>();
                for (IC_Policy__c policyRecord : lstAllPolicies) { //Updated by Samiirah Aujub - 1764
                    policyIdMap.put(policyRecord.Name, policyRecord.Id);
                }

                System.debug('policyIdMap:' + policyIdMap);

                // Create lives assured and beneficiaries with correct policy IDs
                for (IC_FuneralResponse.PolicyWrapper policyWrapper : funeralResponse.funeral.policies) {
                    
                    IC_FuneralResponse.Policy policy = policyWrapper.policy;
    
                    if (policyWrapper.roleplayers != null) {
                        for (IC_FuneralResponse.RolePlayerWrapper rolePlayerWrapper : policyWrapper.roleplayers) {
                            
                            IC_FuneralResponse.Roleplayer details = rolePlayerWrapper.details;
                            IC_Policy_Participant__c newParticipant = null;
                            IC_Policy_Participant__c newBeneficiary = null;
                            System.debug('1582 details: ' + details);
                            if (details.lifeAssured == true) {
                                IC_Policy_Participant__c livesAssured = new IC_Policy_Participant__c();
                                livesAssured.RecordTypeId = livesAssuredRTId;
                                livesAssured.IC_Case__c = caseRecord.Id;
                                livesAssured.IC_Policy_Number__c = policyIdMap.get(policy.contractReference); // Set Policy Number
                                livesAssured.IC_Recommended_Outcome__c = 'Accept';
                                livesAssured.IC_Name__c = details.firstName;
                                livesAssured.IC_Surname__c = details.surname;
                                livesAssured.IC_Identity_Number__c = details.idNumber;
                                livesAssured.IC_Date_of_Birth__c = details.dateOfBirth.date();
                                livesAssured.IC_Relationship__c = getRelationship(details.relationship);
                                livesAssured.IC_Cover_Amount__c = details.coverAmount;
                                livesAssured.IC_roleguids__c = details.recordID;
                                if(!nbsOrigin){ //ICS -1704
                                    livesAssuredToInsert.add(livesAssured);
                                }
                               
                                newParticipant = livesAssured;

                            }
                            System.debug('1582 details.relationship: ' + details.relationship);
                            if (details.beneficiary == true || 'MainLife'.equalsIgnoreCase(details.relationship) ) {

//══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
//                                @description modified for ICS-1529 to fetch the values from the Person Account rather
//                                than the response when Main Life
//                                Dawid Kuczer, 26.08.2024
//══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

                                IC_Policy_Participant__c beneficiary = new IC_Policy_Participant__c();
                                beneficiary.IC_Relationship__c = getRelationship(details.relationship);
                                if(beneficiary.IC_Relationship__c == 'Main Life'){

                                    //Populated from CASE and ACC:
                                    beneficiary.IC_Case__c = caseRecord.Id;
                                    beneficiary.IC_Name__c = caseRecord.Account.FirstName;
                                    beneficiary.IC_Surname__c = caseRecord.Account.LastName;
                                    beneficiary.IC_Title__c = caseRecord.Account.PersonTitle;
                                    beneficiary.IC_Date_of_Birth__c = caseRecord.Account.Birthdate__c;
                                    beneficiary.IC_Identity_Number__c = details.idNumber;//ICS-1799
                                    beneficiary.IC_Identity_Type__c = caseRecord.Account.ID_Type__c;
                                    beneficiary.IC_Phone_Number__c = caseRecord.Account.Phone;
                                    beneficiary.IC_Email__c = caseRecord.Account.PersonEmail;

                                    //Populated from RESULT and OTHERS
                                    beneficiary.RecordTypeId = beneficiariesRTId;
                                    beneficiary.IC_Policy_Number__c = policyIdMap.get(policy.contractReference); // Set Policy Number
                                    beneficiary.IC_BenefitAmount__c = details.benefitPayout;
                                    beneficiary.IC_Identity_Type__c = setIDType(details.idType);//ICS-1305
                                    beneficiary.IC_CreatedBySalesforce__c = !details.beneficiary;//ICS-1419
                                }
//══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
//                                ICS-1529 END
//══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
                                
                                beneficiary.IC_Policy_Number__c = policyIdMap.get(policy.contractReference); // Set Policy Number
                                beneficiary.IC_Case__c = caseRecord.Id;
                                beneficiary.RecordTypeId = beneficiariesRTId;
                                beneficiary.IC_Surname__c = details.surname;
                                beneficiary.IC_Identity_Number__c = details.idNumber;
                                beneficiary.IC_BenefitAmount__c = details.benefitPayout;
                                beneficiary.IC_Gender__c = details.gender;//ICS-1305
                                beneficiary.IC_Identity_Type__c = setIDType(details.idType);//ICS-1305
                                beneficiary.IC_CreatedBySalesforce__c = !details.beneficiary;//ICS-1419
                                beneficiary.IC_roleguids__c = details.recordID;
                                //TODO

                                // Accessing branchCode from paymentTransaction
                                String branchCode = '';
                                String accountName = '';
                                String accountNumber = '';
                                String accountType = '';
                                String bank = '';
                                if ('MainLife'.equalsIgnoreCase(details.relationship)) {
                                    if (policy.deductionDetails != null) {
                                        if (policy.deductionDetails.bankDetails != null) {
                                            branchCode = policy.deductionDetails.bankDetails.branchCode;
                                            accountName = policy.deductionDetails.bankDetails.accountName;
                                            accountNumber = policy.deductionDetails.bankDetails.accountNumber;
                                            accountType = policy.deductionDetails.bankDetails.accountType;
                                            bank = policy.deductionDetails.bankDetails.bank;
                                        }
                                    } 
                                } 
                                /* Commented for AC1 on 1126 / ICS-1529
                                 * else {
                                    if (policy.claims != null) {
                                        for (IC_FuneralResponse.Claim claim : policy.claims) {
                                            if (claim.paymentTransaction != null) {
                                                for (IC_FuneralResponse.PaymentTransaction paymentTransaction : claim.paymentTransaction) {
                                                    if (paymentTransaction.bankDetails != null) {
                                                        for (IC_FuneralResponse.BankDetail bankDetail : paymentTransaction.bankDetails) {
                                                            branchCode = bankDetail.branchCode;
                                                            accountName = bankDetail.accountName;
                                                            accountNumber = bankDetail.accountNumber;
                                                            accountType = bankDetail.accountType;
                                                            bank = bankDetail.bank;
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                */
                                beneficiary.IC_Bank_Name__c = bank;
                                beneficiary.IC_Account_Name__c = accountName;
                                beneficiary.IC_Account_Number__c = accountNumber;
                                beneficiary.IC_Account_Type__c = accountType;
                                beneficiary.IC_Branch_Code__c = branchCode;
                               // if(!nbsOrigin){ //ICS -1704
                                beneficiariesToInsert.add(beneficiary);
                                //}
                                newBeneficiary = beneficiary;
                            }
                            System.debug('1582 newBeneficiary: ' + newBeneficiary);
                            System.debug('1582 beneficiariesToInsert: ' + beneficiariesToInsert);
                           participantSegments = new List<IC_Segment__c>();

                            String identifier;
                            System.debug('*** Roleplayer Benefits: ***');
                            System.debug(rolePlayerWrapper.benefits);

                            for(IC_FuneralResponse.RoleplayerBenefit roleplaySegment : rolePlayerWrapper.benefits){
                                IC_Segment__c newIcSegment = new IC_Segment__c();
                                newIcSegment.IC_Segment_Type__c = roleplaySegment.benefit;
                                newIcSegment.IC_Cover_Amount__c = roleplaySegment.coverAmount;

                                newIcSegment.IC_Cover_Effective_Date__c = (roleplaySegment.waitingPeriodEndDate < Date.valueOf('1900-12-31T16:00:00') ? Date.valueOf('1900-12-31T16:00:00') : roleplaySegment.waitingPeriodEndDate.date());
                                //newIcSegment.IC_Start_Date__c = (roleplaySegment.coverStartDate < Date.valueOf('1900-12-31T16:00:00') ? Date.valueOf('1900-12-31T16:00:00') : roleplaySegment.coverStartDate.date());

                                //ICS-1630 - Correction of mapping [Samiirah Aujub]
                                newIcSegment.IC_Start_Date__c = (roleplaySegment.benefitStartDate < Date.valueOf('1900-12-31T16:00:00') ? Date.valueOf('1900-12-31T16:00:00') : roleplaySegment.benefitStartDate.date());
                                newIcSegment.IC_End_Date__c = (roleplaySegment.benefitEndDate < Date.valueOf('1900-12-31T16:00:00') ? Date.valueOf('1900-12-31T16:00:00') : roleplaySegment.benefitEndDate.date());
                                newIcSegment.IC_End_Date__c = (roleplaySegment.benefitEndDate > Date.valueOf('4000-12-31T00:00:00') ? Date.valueOf('4000-12-31T00:00:00') : roleplaySegment.benefitEndDate.date());

                                newIcSegment.IC_Deceased_Date_of_Death__c = caseRecord.IC_Deceased_Date_of_Death__c;

                                 //ICS-1704 -Samiirah Aujub -- verifies if participant related to Segment already exists in SF
                                 //ICS - 1802: Samiirah Aujub - Use RoleGUID to match segments
                                 if(nbsOrigin){
                                    if(newParticipant != null){
                                        if(mapIdentifierToParticipant.containsKey(newParticipant.IC_roleguids__c)){
                                            IC_Policy_Participant__c existingParticipant =  mapIdentifierToParticipant.get(newParticipant.IC_roleguids__c);

                                            newIcSegment.IC_Policy_Participant__c = existingParticipant.Id;
                                            setParticipantIdWithSegments.add(existingParticipant.Id);
                                            lstSegmentsNBSToCreate.add(newIcSegment);
                                        }
                                    }
                                    
                                }
                                else{
                                    participantSegments.add(newIcSegment);
                                }
                            }
                            System.debug('##1802 participantSegments: ' + participantSegments);
                            System.debug('##1802 setParticipantIdWithSegments: ' + setParticipantIdWithSegments);

                            if(!participantSegments.isEmpty()){
                                if(newParticipant != null){
                                    identifier = String.valueOf(UUID.randomUUID());
                                    participantsByIdentifiers.put(identifier, newParticipant);
                                    segmentsByIdentifiers.put(identifier,  new List<IC_Segment__c>(participantSegments.deepClone()));
                                }
                                
                                if(newBeneficiary != null){
                                    identifier = String.valueOf(UUID.randomUUID());
                                    participantsByIdentifiers.put(identifier, newBeneficiary);
                                    segmentsByIdentifiers.put(identifier,  new List<IC_Segment__c>(participantSegments.deepClone()));
                                }
                            }
                        }
                    }
                }
            }
            
            //ICS-756
            if (!waiversToInsert.isEmpty()) {
                insert waiversToInsert;
            }

            System.debug('livesAssuredToDelete ' + livesAssuredToDelete); 
            System.debug('beneficiariesToDelete ' + beneficiariesToDelete);
            System.debug('livesAssuredToInsert ' + livesAssuredToInsert);
            System.debug('beneficiariesToInsert ' + beneficiariesToInsert);
            System.debug('lstSegmentsNBSToCreate ' + lstSegmentsNBSToCreate);

            //Added by Samiirah Aujub - 30/10/2024 - To resolve DML error on PROD [NBS Bulk cases]
            if(!nbsOrigin){
                // Refactored by Samiirah Aujub - 30/10/2024 
                //Insert Lives Assured and Beneficiaries
                List <IC_Policy_Participant__c> lstParticipantsToCreate = new List<IC_Policy_Participant__C>();
                List <IC_Policy_Participant__c> lstParticipantsToDelete = new List<IC_Policy_Participant__C>();

                if (!livesAssuredToInsert.isEmpty()) {
                    if (!livesAssuredToDelete.isEmpty()) {
                        lstParticipantsToDelete.addAll(livesAssuredToDelete);
                    }
                    lstParticipantsToCreate.addAll(livesAssuredToInsert);
                }

                if (!beneficiariesToInsert.isEmpty()) {
                    if (!beneficiariesToDelete.isEmpty()) {
                        lstParticipantsToDelete.addAll(beneficiariesToDelete);
                    }
                    lstParticipantsToCreate.addAll(beneficiariesToInsert);
                }

                System.debug('##lstParticipantsToDelete :' + lstParticipantsToDelete);
                System.debug('##lstParticipantsToCreate :' + lstParticipantsToCreate);

                //Delete all participants
                if(!lstParticipantsToDelete.isEmpty() && lstParticipantsToDelete != null){
                    delete lstParticipantsToDelete;
                }

                //Recreate all participants
                if(!lstParticipantsToCreate.isEmpty() && lstParticipantsToCreate != null){
                    insert lstParticipantsToCreate;
                }

                Set<String> segmentsToNukeByParticipantsId = new Set<String>();
                List<IC_Segment__c> newSegments = new List<IC_Segment__c>();
    
                for (String ident : participantsByIdentifiers.keySet()) {
                    String participantId = participantsByIdentifiers.get(ident).Id;
                    segmentsToNukeByParticipantsId.add(participantId);
    
                    for(IC_Segment__c currSegment : segmentsByIdentifiers.get(ident)){
                        currSegment.IC_Policy_Participant__c = participantId;
                        newSegments.add(currSegment);
                    }
                }
    
                if (!segmentsToNukeByParticipantsId.isEmpty()) {
                    List<IC_Segment__c> segmentsToBeDeleted = [SELECT Id, IC_Policy_Participant__c FROM IC_Segment__c WHERE IC_Policy_Participant__c IN :segmentsToNukeByParticipantsId];
                    if (!segmentsToBeDeleted.isEmpty()) {
                        delete segmentsToBeDeleted;
                    }
                }
    
                for(IC_Segment__c seg : newSegments){
                    System.debug('*** ');
                    System.debug(seg);
                }
    
                if (!newSegments.isEmpty()) {
                    insert newSegments;
                }

            }

            //Added by Samiirah Aujub - ICS 1704 & ICS 1749 & ICS-1802
            if(nbsOrigin){
                List<IC_Policy_Participant__c> lstParticipantToUpdate = new List<IC_Policy_Participant__c>();

                //Create/Update Beneficiaries only for NBS
                if (!beneficiariesToInsert.isEmpty()) {
                    if (!beneficiariesToDelete.isEmpty()) {
                        System.debug('##NBS beneficiariesToDelete:' + beneficiariesToDelete);
                        delete beneficiariesToDelete;
                    }
                    System.debug('##NBS beneficiariesToInsert:' + beneficiariesToInsert);
                    lstParticipantToUpdate.addAll(beneficiariesToInsert);
                }

                //ICS -1704
                if(!lstSegmentsNBSToCreate.isEmpty() && lstSegmentsNBSToCreate != null){
                    processSegmentNBS(lstSegmentsNBSToCreate, setParticipantIdWithSegments);
                }

            
                System.debug('##NBS lstParticipantToUpdate:' + lstParticipantToUpdate);

                if(!lstParticipantToUpdate.isEmpty() && lstParticipantToUpdate != null){
                    upsert lstParticipantToUpdate; //create beneficiaries and map roleguid to liveassured for NBS
                }
            }


        } catch (Exception e) {
            System.debug('Error processing response: ' + e.getMessage());
            System.debug( e.getStackTraceString());
        }
    }


    /**
    * @description ICS-1704 Method to create segments and relate them to existing lives assured/beneficiaries for cases with 'NBS' origin
    * @author Samiirah.A@bsky.co.za | 10-17-2024  
    * @param lstSegmentsToCreate 
    * @param setParticipantsId 
    **/
    public static void processSegmentNBS(List<IC_Segment__c> lstSegmentsToCreate, Set<Id> setParticipantsId){
        System.debug('## processSegmentNBS lstSegmentsToCreate:' + lstSegmentsToCreate);
        
        if(!setParticipantsId.isEmpty() && setParticipantsId != null){
            List<IC_Segment__c> lstSegmentsToDel = [SELECT Id FROM IC_Segment__c WHERE IC_Policy_Participant__c IN: setParticipantsId];
            System.debug('## processSegmentNBS lstSegmentsToDel:' + lstSegmentsToDel);
            //to prevent duplicates
            if(!lstSegmentsToDel.isEmpty() && lstSegmentsToDel != null){
                delete lstSegmentsToDel;
            }
            insert lstSegmentsToCreate;
        }
    }

  
    /**
    * @description Id type mappings
    * @author Samiirah.A@bsky.co.za | 12-03-2024 
    * @param idType 
    * @param //ICS-1305 
    * @return String 
    **/
    private static String setIDType(String idType) {//ICS-1305
        Map<String, String> idTypeMap = new Map<String, String>{
        'RSAID' => 'SA ID',
        'PAS' => 'SA Passport',
        'CLNTCODE' => ''
        };

        return idTypeMap.get(idType) != null ? idTypeMap.get(idType) : '';
    }

    /**
    * @description ICS-1225
    * @author Samiirah.A@bsky.co.za | 11-27-2024 
    * @param lstArrears 
    **/
    private static final Map<String, String> RELATIONSHIP_MAP = new Map<String, String> {
        'MainLife' => 'Main Life',
        'Child' => 'Child',
        'ExtendedFamily' => 'Extended Family',
        'Spouse' => 'Spouse',
        'Parent' => 'Parent',
        'ExtendedChild' => 'Extended Child',
        'ExtendedSpouse' => 'Extended Spouse',
        'ExtendedParent' => 'Extended Parent',
        'Sibling' => 'Sibling',
        'ParentInLaw' => 'Parent In Law',
        'NephewNiece' => 'Nephew Niece',
        'Grandparent' => 'Grandparent',
        'Grandchild' => 'Grandchild',
        'Cousinschild' => 'Cousins Child',
        'AuntUncle' => 'Aunt Uncle',
        'Firstcousin' => 'First Cousin',
        'Greatgrandparent' => 'Great Grandparent',
        'Greatgrandchild' => 'Great Grandchild',
        'BeneficiaryOnly' => 'Beneficiary Only' 
    };
                
    /**
    * @description Mapping of relationship names/API between service provider and Salesforce
    * @author Samiirah.A@bsky.co.za | 12-03-2024 
    * @param relationship 
    * @return String 
    **/
    public static String getRelationship(String relationship) {
        if (RELATIONSHIP_MAP.containsKey(relationship)) {
            return RELATIONSHIP_MAP.get(relationship);
        } else {
            return relationship; 
        }
    }
    // ICS-1225 End
}