/*******************************************************************
* @Class Name        :  IC_LodgeClaimFieldChecker
* @Test Class        :  IC_LodgeClaimFieldChecker_TEST
* @Author            :  Dhriven
* @Last Modified By  : Samiirah.A@bsky.co.za
* @Version           :  1.0
*
*******************************************************************/

public class IC_LodgeClaimFieldChecker {
    
    public class Request {
        @InvocableVariable(label='Case Number' required=true)
        public String caseNumber;
        
        @InvocableVariable(label='Product Type' required=true)
        public String productType;
        
        @InvocableVariable(label='Case Type' required=true)
        public String caseType;
        
        // Add an action property to indicate the current action
        @InvocableVariable(label='Button Selected' required=true)
        public String buttonSelected;
        
        @InvocableVariable(label='Case Origin')
        public String caseOrigin;

        @InvocableVariable(label='Claimant Relationship')
        public String claimantRelationship;
    }
    
    @InvocableMethod(label='Check Mandatory Fields' description='Return a list of unfilled mandatory fields for a specific product type.')
    public static List<String> checkMandatoryFields(List<Request> requests) {
        // Assuming one record for simplicity, but you can bulkify this if needed
        Request currentRequest = requests[0];
        // Fetch all mandatory fields for the given product type
        String buttonS = '%' + currentRequest.buttonSelected + '%';
        List<IC_Lodge_Claim_Mandatory_Fields__mdt> mandatoryFields = [
            SELECT Field_API_Name__c, Field_Label__c, Related_Object__c
            FROM IC_Lodge_Claim_Mandatory_Fields__mdt
            WHERE Product_Type__c = :currentRequest.productType
            AND Case_Type__c = :currentRequest.caseType
            AND Button_Selection__c LIKE :buttonS
        ];
        
        // Check if there are no mandatory fields defined
        if (mandatoryFields.isEmpty()) {
            return new List<String> { '' }; // Return a list with an empty string
                }
        
        // Construct a set of field API names from the CMDT
        Set<String> fieldNames = new Set<String>();

        /*ICS-1576 - START Lives Assured mandatory fields*/

        Map<String, String> mapLivesAssuredFields = new Map<String,String>();
        Map<String, String> mapBeneficiariesFields = new Map<String,String>();
        for (IC_Lodge_Claim_Mandatory_Fields__mdt field : mandatoryFields) {
            System.debug('##field:' + field);
            if(field.Related_Object__c == 'Lives Assured'){
                mapLivesAssuredFields.put(field.Field_API_Name__c, field.Field_Label__c);
            }
            else if(field.Related_Object__c == 'Beneficiaries'){
                mapBeneficiariesFields.put(field.Field_API_Name__c, field.Field_Label__c);
            }
            else{
                fieldNames.add(field.Field_API_Name__c);
            }
        }
        fieldNames.add('IC_Deceased_ID_Number__c');

        System.debug('##fieldNames:' + fieldNames);
        
        // Construct the dynamic SOQL query
        
        String dynamicQuery = 'SELECT Id, IC_No_ID_number_available__c, Traditional_Leader_Flag__c, ' + String.join(new List<String>(fieldNames), ', ') +
            ' FROM Case WHERE CaseNumber = \'' + String.escapeSingleQuotes(currentRequest.caseNumber) + '\' LIMIT 1';
        
        // Execute the dynamic SOQL
        sObject caseRecord = Database.query(dynamicQuery);
        
        List<String> missingFieldsList = new List<String>();
        
        for (IC_Lodge_Claim_Mandatory_Fields__mdt field : mandatoryFields) {
            if ((field.Related_Object__c == null ||  field.Related_Object__c == 'Case')&& caseRecord.get(field.Field_API_Name__c) == null) {
                missingFieldsList.add(field.Field_Label__c);
            }
        }
        System.debug('##missingFieldsList:' + missingFieldsList);
        //START ICS-426
        //System.debug('missingFieldsList before removal: ' + missingFieldsList);
        
        for (Integer i = 0; i < missingFieldsList.size(); i++) {
            if (currentRequest.caseOrigin.equalsIgnoreCase('data wash') &&
                currentRequest.buttonSelected.equalsIgnoreCase('approve') &&
                missingFieldsList[i].equalsIgnoreCase('Sub Type')) {
                    
                    missingFieldsList.remove(i);
                    break; // Exit the loop once the item is removed
                }
        }
        // START ICS-1079
        Set<String> missingFieldsSet = new Set<String>(missingFieldsList);
        Boolean traditionalLeaderFlag = (Boolean) caseRecord.get('Traditional_Leader_Flag__c');
        if (traditionalLeaderFlag != null) {
            if (traditionalLeaderFlag && missingFieldsSet.containsAll(doctorFields)) {
                missingFieldsSet.removeAll(doctorFields);
            } else if (!traditionalLeaderFlag && missingFieldsSet.containsAll(leaderFields)) {
                missingFieldsSet.removeAll(leaderFields);
            }
        }
        // ICS-973
        Boolean removeUnaturalDT = true;
        String subType = (String) caseRecord.get('Sub_Type__c');
        if (subType != null && ('Unnatural'.equalsIgnoreCase(subType) || 'Under investigation'.equalsIgnoreCase(subType))) {
            removeUnaturalDT = false;
        }
        if (removeUnaturalDT) {
            missingFieldsSet.remove(unaturalDeathTypeField);
        }
        // END ICS-973
        
        //START ICS-630
        Boolean noIDNumberAvailable = (Boolean) caseRecord.get('IC_No_ID_number_available__c');
        Boolean deceasedFieldAvailable = (Boolean) caseRecord.get('IC_Deceased_ID_Number__c');
        if((subType == 'Stillborn' && noIDNumberAvailable) || !deceasedFieldAvailable){
            missingFieldsSet.remove('Deceased ID Number');
            missingFieldsSet.remove('Sub Status');
        }
        if(currentRequest.productType == 'Funeral' && currentRequest.caseType == 'Death'){//ICS-1549
            missingFieldsSet.remove('Sub Type');
            if(caseRecord.get('Email_Address__c') != NULL || caseRecord.get('Work_Number__c') != NULL || caseRecord.get('Mobile_Number__c') != NULL){//ICS-1549
                missingFieldsSet.remove('Claimant Mobile Number');
                missingFieldsSet.remove('Claimant Work Number');
                missingFieldsSet.remove('Claimant Email Address');
            }
        }
        //END ICS-630        
        
        missingFieldsList = new List<String>(missingFieldsSet);
        // END ICS-1079
        //END ICS-426
        //System.debug('missingFieldsList after removal: ' + missingFieldsList);
		
        System.debug('missingFieldsList : ' + missingFieldsList);
        
        String missingFields = '';
        
        if( missingFieldsList != null && !missingFieldsList.isEmpty() ){
            
            missingFields += '<b> The claim must have the required fields below: </b> <br> <ul>';
            for(String field : missingFieldsList) {
                missingFields += '<li>' + field + '</li>';
            }
            missingFields += '</ul>';
            
            /* ICS- 1576 START-Updated by Samiirah Aujub on 26/09/2024*/
             List<String> lstMissingFieldsOnParticipants = checkFieldsOnParticipants(mapLivesAssuredFields, mapBeneficiariesFields, caseRecord);
             if(!lstMissingFieldsOnParticipants.isEmpty() && lstMissingFieldsOnParticipants != null){
                missingFields += String.join(lstMissingFieldsOnParticipants, '<br>');
             }
           
             /* ICS- 1576 END*/
        }
        
        


         
        
        System.debug('missingFields: ' + missingFields);
                
        return new List<String> { missingFields };
    }

    public static List<String> checkFieldsOnParticipants(Map<String, String> mapLivesAssuredFields, Map<String, String> mapBeneficiariesFields, sObject caseRecord){
        List<String> lstMessages = new List <String>();
        /* ICS- 1576 START-Updated by Samiirah Aujub on 26/09/2024*/
        if((!mapLivesAssuredFields.isEmpty() && mapLivesAssuredFields != null) || 
            (!mapBeneficiariesFields.isEmpty() && mapBeneficiariesFields != null))
        {

            Id livesAssuredRTId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Lives_Assured').getRecordTypeId();
            Id beneficiariesRTId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Beneficiaries').getRecordTypeId();

            Set<String> setParticipantFields = new Set<String>();
            setParticipantFields.addAll(mapLivesAssuredFields.keySet());
            setParticipantFields.addAll(mapBeneficiariesFields.keySet());
            Id caseId = (Id)caseRecord.get('Id');


            // Construct the dynamic SOQL query
            String soqlQuery = 'SELECT IC_Deceased_Indicator__c, RecordTypeId,' + String.join(new List<String>(setParticipantFields), ', ') + ' FROM IC_Policy_Participant__c ' +
            'WHERE IC_Case__c =:caseId ' +
            'AND (RecordTypeId =:livesAssuredRTId OR RecordTypeId =:beneficiariesRTId)';


            List<IC_Policy_Participant__c> lstParticipants = Database.query(soqlQuery);

            String messageLiveAssured = '<b>Life Assured selected as the deceased in the portfolio tab (Lives Assured section) must have the required fields below:</b><br> <ul>';
            String messageBeneficiaries = '<b>Beneficiaries associated to the claim must have the required fields below:</b><br> <ul>';
            Boolean deceasedPresent = false;
            Set<String> setMissingFieldsDeceased = new Set<String>();
            Set<String> setMissingFieldsBeneficiaries = new Set<String>();

            
            for(IC_Policy_Participant__c participant : lstParticipants){
                if(participant.RecordTypeId ==  livesAssuredRTId && participant.IC_Deceased_Indicator__c == true){
                    deceasedPresent = true;
                    for (String fieldApiName : mapLivesAssuredFields.keySet()) {
                        String labelName = mapLivesAssuredFields.get(fieldApiName);

                        if (participant.get(fieldApiName) == null && !setMissingFieldsDeceased.contains(fieldApiName)) {
                            setMissingFieldsDeceased.add(fieldApiName);
                            messageLiveAssured += '<li>'+labelName+'</li>';
                        }
                    }
                }
                else{
                    for (String fieldApiName : mapBeneficiariesFields.keySet()) {
                        String labelName = mapBeneficiariesFields.get(fieldApiName);

                        // Check for both email and phone number being null
                        if (fieldApiName == 'IC_Email__c' || fieldApiName == 'IC_Phone_Number__c') {
                            if (participant.IC_Email__c == null && participant.IC_Phone_Number__c == null && !setMissingFieldsBeneficiaries.contains(fieldApiName)) {
                                // Add to missing fields and update message only when both are null
                                setMissingFieldsBeneficiaries.add(fieldApiName);
                                messageBeneficiaries += '<li>' + labelName + '</li>';
                            }
                        } 
                        else if (participant.get(fieldApiName) == null && !setMissingFieldsBeneficiaries.contains(fieldApiName) ) {
                            // For all other fields
                            setMissingFieldsBeneficiaries.add(fieldApiName);
                            messageBeneficiaries += '<li>' + labelName + '</li>';
                        }
                    }
                }
            }

            if(deceasedPresent == false){
                lstMessages.add('At least one Life assured must be selected as the deceased on at least one policy');
            }
            else if(!setMissingFieldsDeceased.isEmpty() && setMissingFieldsDeceased != null){
                lstMessages.add(messageLiveAssured);
            }
            if(!setMissingFieldsBeneficiaries.isEmpty() && setMissingFieldsBeneficiaries != null) {
                lstMessages.add(messageBeneficiaries);
            }
        }

        return lstMessages;
         /* ICS- 1576 END*/
    }
    
    static Set<String> doctorFields = new Set<String>{'BI Doctor Name', 'BI Doctor Surname'};
    static Set<String> leaderFields = new Set<String>{'BI Traditional Leader Name', 'BI Traditional Leader Surname'};
    static String unaturalDeathTypeField = 'Unnatural Death Type';
    
}