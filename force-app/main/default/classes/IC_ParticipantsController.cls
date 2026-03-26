/**
 * @description       : Controller class to manage policies, beneficiaries, and claim participants.
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 11-06-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public without sharing class IC_ParticipantsController {

    /**
    * @description This method returns all policies related to a claim and valid policies as well [ICS-1644]
    * @author Samiirah.A@bsky.co.za | 10-02-2024 
    * @param caseId 
    * @return String (JSON serialized response containing valid and all policies)
    **/
    @AuraEnabled(cacheable=true)
    public static String getLivesAssuredByCaseId(String caseId) {
        try {
            Id livesAssuredRTId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Lives_Assured').getRecordTypeId();
            Set<Id> setParticipantIds = new Set<Id>();
            List<IC_Policy_Participant__c> lstAllPolicies = new List<IC_Policy_Participant__c>();
            List<IC_Policy_Participant__c> lstValidPolicies = new List<IC_Policy_Participant__c>();

            // Debugging information for tracing execution
            System.debug('##livesAssuredRTId :' + livesAssuredRTId);
            System.debug('##caseId :' + caseId);

            // Get Valid Segments
            for (IC_Segment__c segment : [
                SELECT Id, IC_Policy_Participant__c
                FROM IC_Segment__c
                WHERE IC_Policy_Participant__r.RecordTypeId = :livesAssuredRTId
                AND IC_In_Force_on_Event_Date__c = true
                AND IC_Policy_Participant__r.IC_Case__c = :caseId
            ]) {
                setParticipantIds.add(segment.IC_Policy_Participant__c);
            }

            System.debug('##setParticipantIds Init:' + setParticipantIds);

            // Query all policies
            lstAllPolicies = [
                SELECT Id, IC_Policy_Number__c, IC_Policy_Number__r.Name,
                       IC_Name__c, IC_Surname__c, IC_Date_of_Birth__c, 
                       IC_Identity_Number__c, IC_Relationship__c, IC_Cover_Amount__c, 
                       IC_In_Waiting_Period__c, IC_Deceased_Indicator__c, 
                       IC_Calculated_Cover_Amount__c // ICS-1646
                FROM IC_Policy_Participant__c
                WHERE IC_Case__c = :caseId 
                AND RecordTypeId = :livesAssuredRTId
            ];

            // Filter valid policies
            for (IC_Policy_Participant__c participant : lstAllPolicies) {
                if (setParticipantIds.contains(participant.Id)) {
                    lstValidPolicies.add(participant);
                }
            }

            // Create a wrapper instance and serialize it
            participantWrapper wrapper = new participantWrapper(lstValidPolicies, lstAllPolicies);
            return JSON.serialize(wrapper);

        } catch (Exception e) {
            System.debug('Error in getLivesAssuredByCaseId: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while fetching policies. Please contact your administrator.');
        }
    }

    /**
    * @description This method returns a combination of all beneficiaries and valid beneficiaries [ICS-1644]
    * @author Samiirah.A@bsky.co.za | 10-03-2024 
    * @param caseId 
    * @return String (JSON serialized response containing valid and all beneficiaries)
    **/
    @AuraEnabled(cacheable=true)
    public static String getBeneficiariesByCaseId(String caseId) {
        try {
            Id beneficiariesRTId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Beneficiaries').getRecordTypeId();
            List<IC_Policy_Participant__c> lstAllPolicies = new List<IC_Policy_Participant__c>();
            List<IC_Policy_Participant__c> lstValidPolicies = new List<IC_Policy_Participant__c>();
            Set<String> setValidPolicies = new Set<String>();

            //ICS-1787 - Samiirah Aujub 
            setValidPolicies = getValidPoliciesSet(caseId);

            // Query all beneficiaries
            lstAllPolicies = [
                SELECT Id, IC_Policy_Number__c, IC_Policy_Number__r.Name,
                       IC_Title__c, IC_Name__c, IC_Surname__c, IC_Date_of_Birth__c, 
                       IC_Phone_Number__c, IC_Email__c, IC_Identity_Number__c, 
                       IC_Relationship__c, IC_BenefitAmount__c, IC_Bank_Name__c, 
                       IC_Account_Number__c, IC_Account_Type__c, IC_Branch_Code__c, 
                       IC_CreatedBySalesforce__c
                FROM IC_Policy_Participant__c
                WHERE IC_Case__c = :caseId 
                AND RecordTypeId = :beneficiariesRTId
            ];

            // Filter valid beneficiaries
            for (IC_Policy_Participant__c participant : lstAllPolicies) {
                if (setValidPolicies.contains(participant.IC_Policy_Number__r.Name)) {
                    lstValidPolicies.add(participant);
                }
            }

            // Create a wrapper instance and serialize it
            participantWrapper wrapper = new participantWrapper(lstValidPolicies, lstAllPolicies);
            return JSON.serialize(wrapper);

        } catch (Exception e) {
            System.debug('Error in getBeneficiariesByCaseId: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while fetching beneficiaries. Please contact your administrator.');
        }
    }

    /**
    * @description Get Policy Number that should be displayed by default
    * @author Samiirah.A@bsky.co.za | 11-06-2024 
    * @return Set<String> 
    **/
    public static Set<String> getValidPoliciesSet(String caseId){
        Set<String> setValidPolicies = new Set<String>();

        String livesAssured = getLivesAssuredByCaseId(caseId);
        participantWrapper deserializedWrapper = (participantWrapper) JSON.deserialize(livesAssured, participantWrapper.class);

        for(IC_Policy_Participant__c liveAssured : deserializedWrapper.validParticipants){
            setValidPolicies.add(liveAssured.IC_Policy_Number__r.Name);
        }
        System.debug('##setValidPolicies:' + setValidPolicies);

        return setValidPolicies;
    }

    /**
    * @description Returns claim participants for a given case ID.
    * @param caseId 
    * @return List<IC_Claim_Participant__c>
    **/
    @AuraEnabled(cacheable=true)
    public static List<IC_Claim_Participant__c> getClaimParticipantsByCaseId(String caseId) {
        try {
            return [
                SELECT Id, IC_Claim_Participant_FirstName__c, IC_Claim_Participant_Surname__c,
                       IC_Claim_Participant_ID_Type__c, IC_Claim_Participant_ID_Number__c,
                       IC_Claim_Participant_Email_Address__c, IC_Claim_Participant_Mobile_Number__c,
                       IC_Claim_Participant_Bank_Name__c, IC_Claim_Participant_Account_Number__c,
                       IC_Claim_Participant_Account_Type__c
                FROM IC_Claim_Participant__c
                WHERE IC_Case__c = :caseId
            ];
        } catch (Exception e) {
            System.debug('Error in getClaimParticipantsByCaseId: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while fetching claim participants. Please contact your administrator.');
        }
    }

    // Wrapper class to hold both lists of participants
    public class participantWrapper {
        @AuraEnabled public List<IC_Policy_Participant__c> validParticipants;
        @AuraEnabled public List<IC_Policy_Participant__c> allParticipants;

        public participantWrapper(List<IC_Policy_Participant__c> valid, List<IC_Policy_Participant__c> all) {
            this.validParticipants = valid;
            this.allParticipants = all;
        }
    }
}