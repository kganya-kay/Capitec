/*******************************************************************
* @Class Name        :  IC_MinimumDocTypeChecker
* @Test Class        :  IC_MinimumDocTypeChecker_TEST
* @Author            :  Dhriven
* @Last Modified By  : Samiirah.A@bsky.co.za
* @Version           :  1.0
*
*******************************************************************/

public class IC_MinimumDocTypeChecker {
    
    public class FlowInputs {
        @InvocableVariable(label='Case Id' required=true)
        public String caseId;
        
        @InvocableVariable(label='Case Type' required=true)
        public String caseType;
        
        @InvocableVariable(label='Sub Type')
        public String subType;
        
        @InvocableVariable(label='Product Type' required=true)
        public String productType;
        
        @InvocableVariable(label='Case Origin' required=true)
        public String caseOrigin;
        
        @InvocableVariable(label='Sub Type Reason')
        public String subTypeReason;
        
        @InvocableVariable(label='Claimant Surname')
        public String claimantSurname;
        
        @InvocableVariable(label='Claimant ID')
        public String claimantId;
        
        @InvocableVariable(label='Policy Holder ID')
        public String policyHolderId;
        
        @InvocableVariable(label='No ID number available')
        public Boolean noIDNumberAvailable;//ICS-630
        
    }
    
    @InvocableMethod(label='Check Minimum Document Requirement' description='Checks if the Case documents match the Minimum Document Requirement')
    public static List<String> doesDocumentTypeMatch(List<FlowInputs> inputs) {
        
        Boolean foundMatch = false;//Used for minimum required doc check where only one doc as specified in the custom metatdata is needed.
        
        // Initialize mandatoryDocsMatched to true at the start of the check
        Boolean mandatoryDocsMatched = true; // Assume all mandatory documents are present until proven otherwise
        
        for(FlowInputs input : inputs) {
            
            //FlowInputs input = inputs[0]; // Taking only the first input
            // Query the associated documents for the case
            List<DocumentChecklistItem> caseDocuments = [SELECT DocumentTypeId FROM DocumentChecklistItem WHERE ParentRecordId = :input.caseId AND Status = 'Verified'];
            
            Set<Id> documentTypeIds = new Set<Id>();
            for(DocumentChecklistItem item : caseDocuments) {
                documentTypeIds.add(item.DocumentTypeId);
            }
            
            List<DocumentType> caseDocumentNames = [SELECT MasterLabel FROM DocumentType WHERE Id IN :documentTypeIds];
            
            Set<String> docNamesSet = new Set<String>();
            for(DocumentType docType : caseDocumentNames) {
                docNamesSet.add(docType.MasterLabel);
            }
            
            System.debug('docNamesSet: '+docNamesSet);
            
            System.debug('documentTypeIds from case: ' + documentTypeIds);
            
            List<IC_Minimum_Doc_Checklist__mdt> mandatoryMetadata;
            
            //ICS-483-START - CHECK FOR MANDATORY DOCS
            // Query the Custom Metadata Type for mandatory documents
            if(input.productType.equals('Credit Life')) {
                mandatoryMetadata = [
                    SELECT Id, Document_Type__c 
                    FROM IC_Minimum_Doc_Checklist__mdt 
                    WHERE Case_Type__c = :input.caseType 
                    AND Sub_Type__c = :input.subType 
                    AND Product_Type__c = :input.productType
                    AND Case_Origin__c = :input.caseOrigin
                    AND Is_Required__c = true
                ];
            }
            
            
            
            //Condition to include the Sub Type Reason in the query when product type is Funeral
            else if(input.productType.equals('Funeral')) {
                mandatoryMetadata = [
                    SELECT Id, Document_Type__c 
                    FROM IC_Minimum_Doc_Checklist__mdt 
                    WHERE Case_Type__c = :input.caseType 
                    AND Sub_Type__c = :input.subType 
                    AND Sub_Type_Reason__c = :input.subTypeReason
                    AND Product_Type__c = :input.productType
                    AND Case_Origin__c = :input.caseOrigin
                    AND Is_Required__c = true
                ];
                System.debug('1. mandatoryMetadata: ' +mandatoryMetadata);
                
                
                //START ICS-630
                if(input.subType.equals('Stillborn') ){ //&& (input.noIDNumberAvailable == NULL || !input.noIDNumberAvailable)){//ICS-1549
                    
                    mandatoryMetadata.addAll(new List<IC_Minimum_Doc_Checklist__mdt>{
                        new IC_Minimum_Doc_Checklist__mdt(Document_Type__c = 'Death certificate'),
                        new IC_Minimum_Doc_Checklist__mdt(Document_Type__c = 'Claimant\'s ID'),
                        new IC_Minimum_Doc_Checklist__mdt(Document_Type__c = 'BI-1663 / DHA-1663')
                    });   

                    //ICS-1549 - If No Id available field is unchecked, Unabridged birth certificate is also required                   
                    if(input.noIDNumberAvailable == NULL || !input.noIDNumberAvailable){
                        mandatoryMetadata.add(
                            new IC_Minimum_Doc_Checklist__mdt(Document_Type__c = 'Unabridged birth certificate')
                        );
                    }
                    else{ //ICS 0 1549 - Make Antenatal clinic card required on Salesforce
                        mandatoryMetadata.add(
                            new IC_Minimum_Doc_Checklist__mdt(Document_Type__c = 'Antenatal clinic card')
                        );
                    }
                    
                }
                System.debug('ICS-630 : ' +mandatoryMetadata);
                //END ICS-630
                                
                
                //ICS-708
                // Check if the Sub Type Reason is 'Other Life'
                if(input.subTypeReason.equalsIgnoreCase('Other Life')) {
                    // If the Claimant ID has not been completed, 'Claimant’s ID' is mandatory, so do nothing.
                    if(String.isBlank(input.claimantId)) {
                        // 'Claimant’s ID' is mandatory, do nothing.
                        System.debug('input.claimantId: '+input.claimantId);
                    } 
                    // Else if the Claimant ID has been completed and is not equal to Policyholder ID, 'Claimant’s ID' is mandatory, so do nothing.
                    else if(!input.claimantId.equals(input.policyHolderId)) {
                        // 'Claimant’s ID' is mandatory, do nothing.
                        System.debug('input.claimantId: '+input.claimantId);
                        System.debug('input.policyHolderId: '+input.policyHolderId);
                    } 
                    // Otherwise, 'Claimant’s ID' is optional, so remove it from the mandatoryMetadata list.
                    else {
                        // Remove 'Claimant’s ID' from the list of mandatory documents as it's optional.
                        for(Integer i = 0; i < mandatoryMetadata.size(); i++) {
                            if(mandatoryMetadata.get(i).Document_Type__c.equalsIgnoreCase('Claimant\'s ID')) {
                                mandatoryMetadata.remove(i);
                                System.debug('2. mandatoryMetadata' + mandatoryMetadata);
                                break; // Assuming there's only one item with 'Claimant’s ID', we can break after removing it.
                            }
                        }
                    }
                }
            }
            
            
            System.debug('3. mandatoryMetadata : ' + mandatoryMetadata);
            
            // Check for the presence of mandatory documents
            for(IC_Minimum_Doc_Checklist__mdt mandatoryDoc : mandatoryMetadata) {
                // Unique scenario for Credit Life and Disability - ICS-840
                System.debug('136 mandatoryDoc: ' + mandatoryDoc);
                if(input.productType.equals('Credit Life') && input.caseType.equals('Disability')) {
                    // Check if at least one of the specified documents is present
                    if(docNamesSet.contains('Employee/Client Declaration') || docNamesSet.contains('Employer Declaration')) {
                        System.debug('Either Employee/Client Declaration OR Employer Declaration was provided: ' + docNamesSet);
                        mandatoryDocsMatched = true; // Set to true if at least one document is present
                        break; // Exit loop as the condition is satisfied
                    } else {
                        System.debug('Neither Employee/Client Declaration nor Employer Declaration was provided.');
                        mandatoryDocsMatched = false; // Set to false if neither document is present
                        break; // Exit loop as the mandatory document condition is not met
                    }
                }
                // Check for all other product and case types
                else if(!docNamesSet.contains(mandatoryDoc.Document_Type__c)) {
                    System.debug('Missing mandatory document: ' + mandatoryDoc.Document_Type__c);
                    mandatoryDocsMatched = false; // Set to false if any mandatory document is missing
                    break; // No need to check further, at least one mandatory document is missing
                }
            }
            
            // Log the final result
            System.debug('Final status of mandatoryDocsMatched: ' + mandatoryDocsMatched);
            
            
            // If a mandatory document is missing, return immediately
            if(!mandatoryDocsMatched) {
                System.debug('At least one mandatory doc is missing');
                return new List<String>{'Fail'};
                    }
            
            
            //ICS-483-END
            
            //CHECK FOR OTHER MINIMUM REQUIRED DOCS
            // If no mandatory documents are missing, proceed to check for Other minimum required documents
            // Query the Custom Metadata Type
            
            List<IC_Minimum_Doc_Checklist__mdt> matchingMetadata;
            
            if(input.productType.equals('Credit Life')) {
                matchingMetadata = [
                    SELECT Id, Document_Type__c 
                    FROM IC_Minimum_Doc_Checklist__mdt 
                    WHERE Case_Type__c = :input.caseType 
                    AND Sub_Type__c = :input.subType 
                    AND Product_Type__c = :input.productType
                    AND Case_Origin__c = :input.caseOrigin
                    AND Is_Required__c = false
                ];
            }
            
            
            //Condition to include the Sub Type Reason in the query when product type is Funeral
            else if(input.productType.equals('Funeral')) {
                matchingMetadata = [
                    SELECT Id, Document_Type__c 
                    FROM IC_Minimum_Doc_Checklist__mdt 
                    WHERE Case_Type__c = :input.caseType 
                    AND Sub_Type__c = :input.subType 
                    AND Sub_Type_Reason__c = :input.subTypeReason
                    AND Product_Type__c = :input.productType
                    AND Case_Origin__c = :input.caseOrigin
                    AND Is_Required__c = false
                ];
                
                System.debug('1. matchingMetadata: ' +matchingMetadata);
                
                //START ICS-630
                if(input.subType.equals('Stillborn') && input.noIDNumberAvailable == true){//ICS-1549
                    
                    matchingMetadata.addAll(new List<IC_Minimum_Doc_Checklist__mdt>{
                        new IC_Minimum_Doc_Checklist__mdt(Document_Type__c = 'Gestation Period Note'),
                        new IC_Minimum_Doc_Checklist__mdt(Document_Type__c = 'Medical certificates')
                    });                    
                }
                System.debug('ICS-630 : ' +matchingMetadata);
                //END ICS-630
                
            }
            
            
            
            // Check if matchingMetadata list is empty. If so, set foundMatch to true and break.
            // ICS-399 - This indicates that if there are no min required document types for a case, the method assumes that the case passes the document type check by default.
            if (matchingMetadata.isEmpty()) {
                foundMatch = true;
                break;
            }
            
            System.debug('2. matchingMetadata: '+matchingMetadata);
            
            // Compare the queried documents against the document types from the Custom Metadata
            for(IC_Minimum_Doc_Checklist__mdt metadataRecord : matchingMetadata) {
                if(docNamesSet.contains(metadataRecord.Document_Type__c)) {
                    foundMatch = true;
                    break;
                }
            }
            
            if (foundMatch) {
                break;
            }
        }
        System.debug('foundMatch: '+foundMatch);
        // If all mandatory documents are present and minimum documents match, return Pass
        return new List<String>{foundMatch ? 'Pass' : 'Fail'};
            }
}