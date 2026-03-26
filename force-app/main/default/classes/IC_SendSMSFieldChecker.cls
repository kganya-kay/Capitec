/**
* Class Name:       IC_SendSMSFieldChecker
* Test Class:       IC_SendSMSFieldChecker_TEST
* Author           	Ridwan Moosuddee
* Company          	BlueSky
* Ticket      		ICS-685 - Send SMS communication to client
**/

public class IC_SendSMSFieldChecker {
	
    public class Request {
        @InvocableVariable(label='Case Number' required=true) public String caseNumber;
        @InvocableVariable(label='Template Description' required=true) public String templateDescription;
        @InvocableVariable(label='CIF Number' required=true) public String cifNumber;
        @InvocableVariable(label='Product Type') public String productType;
    }
    
    @InvocableMethod(label='Check Mandatory Fields' description='Return a list of unfilled mandatory fields for a specific template description.')
    public static List<String> checkMandatoryFields(List<Request> requests) {
        
        List<String> missingFieldsList = new List<String>();
        String missingFields;
        
        if( requests[0].productType != null && requests[0].productType == 'Funeral' || requests[0].productType == 'Credit Life'){
        
			Request currentRequest = requests[0];
            
            System.debug('currentRequest ' + currentRequest.templateDescription);
            System.debug('requests[0].productType ' + requests[0].productType);
			
			//Get Template Name & Template Description mappings 
			List<IC_Send_SMS_Template_mappings__mdt> metadataRecords = [SELECT Template_Description__c, Template_name__c FROM IC_Send_SMS_Template_mappings__mdt WHERE Template_name__c =: currentRequest.templateDescription AND Product_Type__c = :requests[0].productType]; 
			
            if (metadataRecords.isEmpty()) {
                missingFieldsList.add('Error: No template mappings found.');
                return missingFieldsList;
            }
                        
            String templateName = metadataRecords[0].Template_Description__c;
			
			System.debug('templateName ' + templateName);
			
			// Fetch all mandatory fields for the given product type
			List<IC_Send_SMS_Fields__mdt> mandatoryFields = [
				SELECT Field_API_Name__c, Field_Label__c, MasterLabel
				FROM IC_Send_SMS_Fields__mdt
				WHERE Template_name__c = :templateName
				AND Mandatory__c = true
				AND Value__c = null
				AND Product_Type__c = :requests[0].productType
			];
			
			 System.debug('mandatoryFields ' + mandatoryFields);
			
			// Check if there are no mandatory fields defined
			if (mandatoryFields.isEmpty()) {
				return new List<String> { '' }; // Return a list with an empty string
			}
			
			// Construct a set of field API names from the CMDT
			Set<String> fieldNames = new Set<String>();
			for (IC_Send_SMS_Fields__mdt field : mandatoryFields) {
				fieldNames.add(field.Field_API_Name__c);
			}
			
			System.debug('fieldNames ' + fieldNames);
			
			// Construct the dynamic SOQL query
			String dynamicQuery = 'SELECT ' + String.join(new List<String>(fieldNames), ', ') + 
				' FROM Case WHERE CaseNumber = \'' + String.escapeSingleQuotes(currentRequest.caseNumber) + '\' LIMIT 1';
			
			System.debug('dynamicQuery: '+ dynamicQuery);
			
			// Execute the dynamic SOQL
			sObject caseRecord = Database.query(dynamicQuery);
						
			for (IC_Send_SMS_Fields__mdt field : mandatoryFields) {
				if (caseRecord.get(field.Field_API_Name__c) == null) {
					missingFieldsList.add(field.MasterLabel);
				}
			}
			
			missingFields = String.join(missingFieldsList, '\n');
			
			System.debug('missingFields: '+ missingFields);
		}
        return new List<String> { missingFields };
	}
}