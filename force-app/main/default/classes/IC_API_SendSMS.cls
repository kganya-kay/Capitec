/**
* Class Name:       IC_API_SendSMS
* Test Class:       IC_API_SendSMS_TEST
* Author           	Ridwan Moosuddee
* Company          	BlueSky
* Ticket      		ICS-390 - Send an SMS from a Case (outbound parent & child cases)
**/

public class IC_API_SendSMS {
    
    static List<IC_Send_SMS_API_Settings__mdt> apiSettings = IC_Send_SMS_API_Settings__mdt.getAll().values();
 
    //Variables passed from Flow to Apex class
    public class FlowRequestVariables {
        
        @InvocableVariable(label='Case ID') public String caseId;
        @InvocableVariable(label='Template Name') public String templateName;
        @InvocableVariable(label='CIF Number' required=true) public String cifNumber;
        @InvocableVariable(label='Phone Number') public String Phone_Number;
        @InvocableVariable(label='Document Type required') public String documentType;
        @InvocableVariable(label='Product Type') public String productType;
    }
    
    @InvocableMethod(label='Send SMS' description='Makes a callout for sending SMS')
    public static List<String> sendSMSCallout(List<FlowRequestVariables> reqVar) {
        
        System.debug('Product Type' + reqVar[0].productType);
		
		List<String> results = new List<String>();
        
        /* ICS-507 - START */
        List<IC_Client_Mobile_Engagement_History__c> historyList = new List<IC_Client_Mobile_Engagement_History__c>();
        List<IC_Message_Parameter__c> messageParamList = new List<IC_Message_Parameter__c>();
        IC_Client_Mobile_Engagement_History__c history = new IC_Client_Mobile_Engagement_History__c();
        String pk;
        /* ICS-507 - END */
		
		if( reqVar[0].productType != null && reqVar[0].productType == 'Funeral' || reqVar[0].productType == 'Credit Life'){
			
			Id yourCaseId = reqVar[0].caseId;     
		
			//Get Template Name & Template Description mappings 
			List<IC_Send_SMS_Template_mappings__mdt> metadataRecords = [
                SELECT Template_Description__c, Template_name__c, Product_Type__c 
                FROM IC_Send_SMS_Template_mappings__mdt 
                WHERE Template_name__c = :reqVar[0].templateName AND Product_Type__c = :reqVar[0].productType
            ];
            
            System.debug('metadataRecords' + metadataRecords);
            
            if (metadataRecords.isEmpty()) {
                results.add('Error: No template mappings found.');
                return results;
            }
            
			// Query to retrieve template parameters
			List<IC_Send_SMS_Fields__mdt> templateParametersQueryResult = [
                SELECT Field_API_Name__c, Field_Label__c, Template_name__c, Value__c, Product_Type__c 
                FROM IC_Send_SMS_Fields__mdt 
                WHERE Template_name__c = :metadataRecords[0].Template_Description__c AND Product_Type__c = :reqVar[0].productType
            ];
            
             System.debug('templateParametersQueryResult' + templateParametersQueryResult);
            
            if (templateParametersQueryResult.isEmpty()) {
                results.add('Error: No template parameters found.');
                return results;
            }
            
			System.debug('templateParametersQueryResult: ' + templateParametersQueryResult);
			String fields = '';
			List<String> fieldsList = new List<String>();
			
			for (IC_Send_SMS_Fields__mdt record : templateParametersQueryResult) {
				
				if(record.Field_API_Name__c != null) {
					
					if (!fieldsList.contains(record.Field_API_Name__c)) {
						
						 fields += record.Field_API_Name__c;
						 fields += ' ,';
						 fieldsList.add(record.Field_API_Name__c);
					}                
				}
			}
			
			System.debug('fields ' + fields);
			
			fields = fields.removeEnd(',');
				   
			// Build the SELECT clause dynamically
			String selectClause = 'SELECT';
			selectClause += ' ' + fields;
			
			// Build the full SOQL query
			String soqlQuery = selectClause + ' ,Recordtype.Name  FROM Case WHERE Id = :yourCaseId LIMIT 1';
			
			System.debug('soqlQuery ' + soqlQuery);
			
			Case myCase = Database.query(soqlQuery);
			
			String recordtypeName = myCase.Recordtype.Name;
            String productType = myCase.Recordtype.Name;
					   
			System.debug('recordtypeName ' + recordtypeName);
			
			// Create a Map to store field labels and values
			Map<String, Object> caseFieldMap = new Map<String, Object>();
			
			for (IC_Send_SMS_Fields__mdt record : templateParametersQueryResult) {
				
				// Get the field label
				String fieldLabel = record.Field_Label__c;
				
				// Get the field value from the Case instance
				Object fieldValue = myCase.get(record.Field_API_Name__c);

				// Add the field label and value to the map
				caseFieldMap.put(fieldLabel, fieldValue);
			}
			//System.debug('caseFieldMap: ' + caseFieldMap);
			List<Map<String, String>> templateParametersList = new List<Map<String, String>>();
			String outputString;
			
			// Populate the templateParametersList from the query result
			for (IC_Send_SMS_Fields__mdt record : templateParametersQueryResult) {
				
                
		       	IC_Message_Parameter__c msgParam = new IC_Message_Parameter__c();
                
				if (String.valueOf(record.Field_Label__c) == 'Document_Name') { 
					// Replace semicolon with comma
					outputString = String.valueOf(myCase.get(record.Field_API_Name__c)).replace(';', ', ');
				}
				else{
					outputString = String.valueOf(myCase.get(record.Field_API_Name__c));
				}
				
				System.debug('RIDWAN ' + String.valueOf(myCase.get(record.Field_API_Name__c)));
				
				Map<String, String> templateParametersMap = new Map<String, String>{};
				
				// Check if outputString equals 'Insurer_Name', and adjust 'name' accordingly
				if ((String.valueOf(record.Field_Label__c).equals('Insurer_Name') && recordtypeName == 'Insurance Claims') ||
                   (String.valueOf(record.Field_Label__c).equals('Insurer_Name') && recordtypeName == 'Insurance Claims' && reqVar[0].productType == 'Funeral')) { //Updated for ICS-1684
					templateParametersMap.put('value', record.Value__c);
					templateParametersMap.put('name', record.Field_Label__c);
                     /* ICS-507 - START */
                    msgParam.IC_Name__c = record.Field_Label__c;
                    msgParam.IC_Value__c = record.Value__c;
                    /* ICS-507 - END */
				} 
				else if (String.valueOf(record.Field_Label__c).equals('Claim_Email')){
					templateParametersMap.put('value', record.Value__c);
					templateParametersMap.put('name', record.Field_Label__c);
                    /* ICS-507 - START */
                    msgParam.IC_Name__c = record.Field_Label__c;
                    msgParam.IC_Value__c = record.Value__c;
                    /* ICS-507 - END */
				}
                else if (String.valueOf(record.Field_Label__c).equals('contact_date')) {
                    
                    String dateTimeString = outputString; // Get the value as a String
                    
                    templateParametersMap.put('name', record.Field_Label__c);
                    
                    System.debug(dateTimeString); 
                    String formattedDate;
                    if (dateTimeString != null && dateTimeString != '') {
                        
                        dateTimeString = dateTimeString.trim();  // Trim any extra spaces
                        
                        // Assuming the format is 'yyyy-MM-dd HH:mm:ss', extract the date part
                        String datePart = dateTimeString.substring(0, 10); // Extract 'yyyy-MM-dd'
                        
                        // Rearrange the date part to 'dd/MM/yyyy'
                        String[] dateParts = datePart.split('-'); // Split by '-'
                        formattedDate = dateParts[2] + '/' + dateParts[1] + '/' + dateParts[0]; // Rearrange
                        templateParametersMap.put('value', formattedDate);
                        System.debug(formattedDate); 
                    } else {
                        System.debug('Value__c is null or empty');
                        templateParametersMap.put('value', '');
                    }
                    
                    /* ICS-507 - START */
                    msgParam.IC_Name__c = record.Field_Label__c;
                    msgParam.IC_Value__c = formattedDate;
                    /* ICS-507 - END */
                }

                else if (String.valueOf(record.Field_Label__c).equals('Primary_Key')){
                    templateParametersMap.put('value', outputString);
                    templateParametersMap.put('name', record.Field_Label__c);     
                    /* ICS-507 - START */
                    pk = outputString;
                    msgParam.IC_Name__c = record.Field_Label__c;
                    msgParam.IC_Value__c = outputString;
                    /* ICS-507 - END */
				}
				else if (String.valueOf(record.Field_Label__c).equals('Title')){
					if (myCase.IC_Account_Salutation__c == null ) {
						templateParametersMap.put('value', '');
						templateParametersMap.put('name', record.Field_Label__c);
                        /* ICS-507 - START */
                        msgParam.IC_Name__c = record.Field_Label__c;
                        msgParam.IC_Value__c = '';
                        /* ICS-507 - END */
					}
					else{
						templateParametersMap.put('value', outputString);
						templateParametersMap.put('name', record.Field_Label__c);    
                        /* ICS-507 - START */
                        msgParam.IC_Name__c = record.Field_Label__c;
                        msgParam.IC_Value__c = outputString;
                        /* ICS-507 - END */
					}
				}
				else {
					//ICS-1684 - START
					if(String.valueOf(record.Field_Label__c).equals('Insurer_Name') && outputString == 'Capitec'){
						
						templateParametersMap.put('value', 'Capitec Life');
						templateParametersMap.put('name', record.Field_Label__c);
						/* ICS-507 - START */
						msgParam.IC_Name__c = record.Field_Label__c;
						msgParam.IC_Value__c = 'Capitec Life';
						/* ICS-507 - END */
						
					}
					else{
						templateParametersMap.put('value', outputString);
						templateParametersMap.put('name', record.Field_Label__c);
						/* ICS-507 - START */
						msgParam.IC_Name__c = record.Field_Label__c;
						msgParam.IC_Value__c = outputString;
						/* ICS-507 - END */
					}
					//ICS-1684 - END
				}
				//System.debug('templateParametersList: ' + templateParametersList);
				templateParametersList.add(templateParametersMap);
                messageParamList.add(msgParam);
			}
			//System.debug('templateParametersList: ' + templateParametersList);
			
			// Serialize the wrapper instance to JSON
			String requestBody = JSON.serialize(new Map<String, Object>{
				'templateParameters' => templateParametersList,
				'cifNumber' => reqVar[0].cifNumber,
				'templateName' => metadataRecords[0].Template_Description__c
			});
					
			System.debug('requestBody: '+ requestBody);
			
			Integer timeoutValue = Integer.valueOf(apiSettings[0].Timeout_in_sec__c *1000);
            
             /* ICS-507 - START */
			history.IC_CIF_Number__c = reqVar[0].cifNumber;
			history.IC_Template_Name__c = metadataRecords[0].Template_Description__c;      
            history.IC_Case__c = reqVar[0].caseId;
			history.IC_Contact_Number__c = reqVar[0].Phone_Number; 
            history.IC_Date_Time_Sent__c = System.now();
            history.IC_Message_Type__c = 'SMS';
            history.IC_Primary_Key__c = pk;
			historyList.add(history);
            /* ICS-507 - END */
            
			try {
				// Callout logic
				Http http = new Http();
				HttpRequest req = new HttpRequest();
				req.setEndpoint(apiSettings[0].Endpoint_URL__c);
				req.setMethod('POST');
				req.setHeader('Content-Type', 'application/json');
				req.setBody(requestBody);
				req.setTimeout(timeoutValue);
				
                System.debug(req);
				HttpResponse res = http.send(req);
				System.debug(res);
                
				if (res.getStatusCode() == 200) {
					System.debug(res.getBody());
                    
                    /* ICS-507 - START */
                    for (IC_Client_Mobile_Engagement_History__c record : historyList) {
                    	record.IC_Message_sent__c = true;
                    }
                    /* ICS-507 - END */
                    
					results.add('Success: ' + res.getBody());
				} else {
					// Handle HTTP errors
					try {
						Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
						if(errorResponse.containsKey('Detail') && !((List<Object>)errorResponse.get('Detail')).isEmpty()) {
							List<Object> details = (List<Object>)errorResponse.get('Detail');
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
					results.add(errorMsg);
				}
			} catch(Exception e) {
				System.debug('Error making HTTP callout: ' + e.getMessage());
				results.add('Error: ' + e.getMessage());
			}
            
            /* ICS-507 - START */
            System.debug('historyList: ' + historyList);
            
            if (!historyList.isEmpty()) {
                insert historyList;
            }
            
            String clientMobileHistoryrecordId;
            for (IC_Message_Parameter__c param : messageParamList) {
                param.IC_Client_Mobile_Engagement_History__c = historyList[0].Id;
            }
            
            System.debug('messageParamList: ' + messageParamList);
		            
            if (!messageParamList.isEmpty()) {
                System.debug('Inside insert messageParamList');
                insert messageParamList;
            }
            /* ICS-507 - END */
		}
		return results;
	}
}