/*
  @description       : CEDT-2932 - Controller to manage Client Care cases and related operations
  @author            : Kevin Nundran
  @created on  		 : 20-09-2024
  @last modified on  : 04-02-2025
  @last modified by  : Kevin Nundran
                     : BUGFIX - Updated transferTransactionsAndCloseCase to accommodate Recall Request and added method closeCaseInstantly
					 : CEDT-3559 - Updated 'No transactions' error handling
                     : CEDT-3565 - Update closeAgentErrorCase to include case Id as input
                     : CEDT-3560 - Fix Invalid conversion from runtime type capitec_ClientCareController to System.Callable
*/
global class capitec_ClientCareController implements Omnistudio.VlocityOpenInterface, System.Callable {
    //Variable can be overridden in input to invocable method to update status
    public String closingStatus = 'Closed';
    public String handOverType = 'Fraud';

    /*
      @description       : Implemented to prevent error: Invalid conversion from runtime type capitec_ClientCareController to System.Callable
      @param action  	 : Action is mainly invokeMethod
      @param args        : Map containing input, output and optional data
      @return            : Object
      @throws            : Exception if any error occurs during the process
      @created on        : 04-02-2025
    */    
    global Object call(String action, Map<String, Object> args) {
        // Handle method invocation based on action
        if (action == 'invokeMethod') {
            return invokeMethod(
                (String) args.get('methodName'),
                (Map<String, Object>) args.get('input'),
                (Map<String, Object>) args.get('output'),
                (Map<String, Object>) args.get('option')
            );
        }
        return null;
    }

    /*
      @description       : Invokes the specified method to process client care case updates and manage financial account transactions.
                           This method updates the Case__c field in related transactions and schedules case closure.
      @param methodName  : Name of the method to be invoked (not used in this implementation)
      @param input       : Map containing input data, including ClientCareCase and DRId_Case (fraud case ID)
      @param output      : Map to store output data (not used in this implementation)
      @param option      : Map to store additional options (not used in this implementation)
      @return            : Boolean indicating whether the operation succeeded or not
      @throws            : Exception if any error occurs during the process
      @created on        : 20-09-2024
    */
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> option) {
        Boolean result = false;

        switch on methodName {
            when  'transferTransactionsAndCloseCase'{
                result = transferTransactionsAndCloseCase(input, output);
            }
            when 'generateTaxonomyDescription' {
                result = generateTaxonomyDescription(input, output);
            }
            when 'updateCaseTaxonomyFraud' {
                result = updateCaseTaxonomyFraud(input, output);
            }
            when else {
                output.put('error', 'No method name supplied');
            }
        }

        return result;
    }

    /*
      @description       : Processes client care case updates and manages financial account transactions.
      @param input       : Map containing input data, including ClientCareCase and DRId_Case (fraud case ID)
      @param output      : Map to store output data
      @created on        : 20-09-2024
    */
    private boolean transferTransactionsAndCloseCase(Map<String, Object> input, Map<String, Object> output) {
        Boolean result = false;
        
        // Extract input parameters
        Map<String, Object> clientCareCase = (Map<String, Object>) input.get('ClientCareCase');
        String clientCareCaseId = String.valueOf(clientCareCase.get('Id'));
        String fraudCaseId = String.valueOf(input.get('DRId_Case'));
        this.closingStatus = input.containsKey('closedStatus') ? String.valueOf(input.get('closedStatus')) : 'Closed';

        try {
            if(fraudCaseId != null && fraudCaseId != ''){
                // Query the financial account transactions related to the Client Care case
                List<FinServ__FinancialAccountTransaction__c> lstFinancialAccountTransaction = [
                    SELECT Id, Case__c 
                    FROM FinServ__FinancialAccountTransaction__c 
                    WHERE Case__c = :clientCareCaseId
                ];
                
                // Perform the update if there are transactions to update
                if (!lstFinancialAccountTransaction.isEmpty()) {
                    
                    // Update the Case__c field for each transaction to the fraud case ID
                    for (FinServ__FinancialAccountTransaction__c fat : lstFinancialAccountTransaction) {
                        fat.Case__c = fraudCaseId;
                    }
                    
                    Database.update(lstFinancialAccountTransaction, false);
                    result = true; // Indicate success
                } else {
                    result = false; // No transactions to update
                }
            }
        } catch (Exception ex) {
            // Log the exception and rethrow it
            System.debug('Error occurred: ' + ex.getMessage());
            result = false;
            throw ex;
        } finally {
            this.handOverType = input.containsKey('handOverType') ? String.valueOf(input.get('handOverType')) : 'Fraud';

            if (this.handOverType == 'Cash Disputes') {
                closeCaseManually(clientCareCaseId);
            } else if (this.handOverType == 'Recall Request') {
                closeCaseInstantly(clientCareCaseId);
            } else {
                // Schedule the case close operation after the process
                scheduleCaseClose(clientCareCaseId);
            }
            return result;
        }

        return result;
    }
    
    /*
      @description       : CEDT-3340 - Generates a taxonomy description for client care cases based on flagged transactions
      @param input       : Map containing input data, including ClientCareCase and DRId_Case (fraud case ID)
      @param output      : Map to store output data
      @created on        : 25-11-2024
    */
    private static boolean generateTaxonomyDescription(Map<String, Object> input, Map<String, Object> output) {
        try {

            List<Map<String, Object>> transactionsList = new List<Map<String, Object>>();

            //CEDT-3559 - if no transactions flagged, skip
            if(input.containsKey('FAT')) {
                Object transactionData = input.get('FAT');
                
                if (!((List<Object>) transactionData).isEmpty()) {
                    // Check if FAT is a list
                    if (transactionData instanceof List<Object>) {
                        for (Object item : (List<Object>) transactionData) {
                            if (item instanceof Map<String, Object>) {
                            transactionsList.add((Map<String, Object>) item);
                            } 
                        }
                    } else if (transactionData instanceof Map<String, Object>) {
                        transactionsList.add((Map<String, Object>) transactionData);
                    }
                }
            }
            
            Map<String, Object> clientCareCaseMap = (Map<String, Object>) input.get('ClientCareCase');
            String createdDate = clientCareCaseMap != null && clientCareCaseMap.containsKey('CreatedDate') 
                ? formatTHDateDisplay((String) clientCareCaseMap.get('CreatedDate')) 
                : null;
    
            String taxonomyDescription = '';
            if (createdDate != null) {
                taxonomyDescription = 'A case created at Client Care on ' + createdDate + '.\n';
            } else {
                taxonomyDescription = 'A case created at Client Care (creation date unavailable).\n';
            }

            if(input.containsKey('FAT') && (transactionsList.size()) > 0) {
                taxonomyDescription += '\nDisputed transactions:\n';

                // Loop through each transaction and build the description
                for (Map<String, Object> transactionMap : transactionsList) {
                    String transactionType = transactionMap.containsKey('TransactionType') 
                        ? (String) transactionMap.get('TransactionType') 
                        : 'Transaction';
                    String transactionAmount = transactionMap.containsKey('TransactionAmount') 
                        ?  String.valueOf(math.abs((Decimal) transactionMap.get('TransactionAmount'))) 
                        : 'Unknown Amount';
                    String transactionDate = transactionMap.containsKey('TransactionDate') 
                        ? formatTHDateDisplay((String) transactionMap.get('TransactionDate'))
                        : 'Unknown Date';
                    taxonomyDescription +=  transactionType + ' for ' + 
                                            'R' + transactionAmount + ' on ' + 
                                            transactionDate + '.' + '\n';                            
                }
            }
    
            taxonomyDescription += '\n' + 'Additional Comments:';
            output.put('FraudCaseDescription', taxonomyDescription);
            output.put('cdCaseDescription', taxonomyDescription);
            return true;
        } catch (Exception ex) {
            output.put('error', 'Error: ' + ex.getMessage());
            return false;
        }
    }


    
    public static String formatTHDateDisplay(String dateString) {
        String cleanedDateString = (dateString.substring(0, 19)).replace('T', ' ');
        
        DateTime dateObj = DateTime.valueOfGmt(cleanedDateString);

        Datetime adjustedDateObj = dateObj.addHours(2);

        String formattedDateString = adjustedDateObj.formatGMT('MM/dd/yyyy HH:mm');
        
        return formattedDateString;
    }
            
    
    /*
      @description       : Updates the taxonomy data on a client care case
      @param input       : Map containing input data, including ClientCareCase and DRId_Case (fraud case ID)
      @param output      : Map to store output data
      @created on        : 26-11-2024
    */
    private static boolean updateCaseTaxonomyFraud(Map<String, Object> input, Map<String, Object> output) {
        Map<String, Object> taxonomyList = (Map<String, Object>) input.get('Step6');
        String caseId = (String) input.get('DRId_Case');
        
        if(caseId == Null) {
            output.put('error', 'No caseId');
            return false;
        }

        Case caseToUpdate = new Case();
        caseToUpdate.Id = caseId;
        caseToUpdate.CM_Department__c = (String) input.get('DepartmentFR');
        caseToUpdate.CM_Outcome__c = (String) input.get('Outcome');
        caseToUpdate.CM_Channel__c = (String) taxonomyList.get('FraudCaseChannel');
        caseToUpdate.Description = (String) taxonomyList.get('FraudCaseDescription');
        caseToUpdate.CM_Product__c = (String) taxonomyList.get('FraudCaseProduct');
        caseToUpdate.Subject = (String) taxonomyList.get('FraudCaseSubject');
        caseToUpdate.Capitec_Primary_Need__c = (String) taxonomyList.get('PrimaryNeed');
        caseToUpdate.Capitec_Specific_Need__c = (String) taxonomyList.get('SpecificNeed');

        try {
            update caseToUpdate;
        } catch (Exception ex) {
            output.put('error', 'Error updating case: ' + ex.getMessage());
            System.debug('Error occurred: ' + ex.getMessage());
            return false;
        }

        return true;
    }

    /*
      @description       : Manually closes a Client Care case by aborting any scheduled close jobs and updating the case status.
      @param caseId      : The ID of the case to be closed
      @created on        : 20-09-2024
    */
    @AuraEnabled
    public static void closeCaseManually(Id caseId) {
        // Construct the job name using the case ID
        String jobName = 'Close Client Care Case Job - ' + caseId;
        
        // Query any scheduled jobs related to this case and abort them
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
        for (CronTrigger job : jobs) {
            System.abortJob(job.Id); // Abort the scheduled job
        }

        // Query the case record and update its status to 'Closed'
        List<Case> caseToUpdate = [SELECT Id, Status FROM Case WHERE Id = :caseId];
        if (!caseToUpdate.isEmpty()) {
            caseToUpdate[0].Status = 'Closed'; // Set the status to 'Closed'
            update caseToUpdate; // Perform the update
        }
    }

    /*
      @description       : Manually closes a Client Care case by updating the case status.
      @param caseId      : The ID of the case to be closed instantly without timer
      @created on        : 20-09-2024
    */
    @AuraEnabled
    public static void closeCaseInstantly(Id caseId) {
        // Query the case record and update its status to 'Closed'
        List<Case> caseToUpdate = [SELECT Id, Status FROM Case WHERE Id = :caseId];
        if (!caseToUpdate.isEmpty()) {
            caseToUpdate[0].Status = 'Closed'; // Set the status to 'Closed'
            update caseToUpdate; // Perform the update
        }
    }

    /*
      @description       : Closes a Client Care case created today with a status of 'New' and a specific record type, setting the cancel reason to 'Agent Error'.
      @param recordId    : The account ID associated with the case to be closed
      @param caseId      : The case ID associated with the case to be closed
      @throws            : AuraHandledException if the record ID is null or if no matching case is found
      @created on        : 20-09-2024
    */
    @AuraEnabled
    public static void closeAgentErrorCase(Id recordId, Id caseId) {

        System.debug('Attempting to close case');
        // Check if the record ID is provided
        if (caseId == null && recordId == null) {
            throw new AuraHandledException('Record ID cannot be null.');
        }

        Case caseToUpdate = new Case();

        try {
            if (caseId != null) {
                // Query the Client Care case using the case Id
                 caseToUpdate = [SELECT Id, CM_Cancel_Reason__c, Status FROM Case 
                                         WHERE Id = :caseId
                                         AND Status != 'Closed'
                                         AND RecordType.DeveloperName = 'Client_Care'
                                         LIMIT 1]; 
             } else {
                 // Query the most recent 'New' Client Care case created today for the account
                 caseToUpdate = [SELECT Id, CM_Cancel_Reason__c, Status FROM Case 
                                         WHERE AccountId = :recordId 
                                         AND CreatedDate = TODAY
                                         AND Status != 'Closed'
                                         AND RecordType.DeveloperName = 'Client_Care' ORDER BY CreatedDate DESC LIMIT 1];
             }
        } catch (Exception e) {
             throw new AuraHandledException('Case not found for the provided record ID: ' +  e.getMessage());
        }

        try {
            // Set the cancel reason and update the case status to 'Closed'
            caseToUpdate.Status = 'Closed'; // Set status to closed
            update caseToUpdate; // Perform the update
        } catch (DmlException e) {
            throw new AuraHandledException('Failed to close the case: ' + e.getMessage());
        }
    }

    /*
      @description       : Schedules the automatic closure of a Client Care case 30 seconds in the future.
      @param caseId      : The ID of the case to be closed
      @created on        : 20-09-2024
    */
    public void scheduleCaseClose(String caseId) {
        // Schedule the closure to happen 30 seconds from now
        Datetime futureTime = Datetime.now().addSeconds(30);//CEDT-3061

        // Create a cron expression for the scheduled time
        String cronExpression = String.format(
            '{0} {1} {2} {3} {4} ? {5}', 
            new List<String>{
                String.valueOf(futureTime.second()),     // Seconds
                String.valueOf(futureTime.minute()),     // Minutes
                String.valueOf(futureTime.hour()),       // Hours
                String.valueOf(futureTime.day()),        // Day of month
                String.valueOf(futureTime.month()),      // Month
                String.valueOf(futureTime.year())        // Year
            }
        );

        // Create an instance of the schedulable class to close the case
        capitec_CCCaseCloseScheduler scheduler = new capitec_CCCaseCloseScheduler(caseId, this.closingStatus);

        // Schedule the job to run at the specified time
        System.schedule('Close Client Care Case Job - ' + caseId, cronExpression, scheduler);
    }
    
    /**
     * @description  Fetches picklist values for CM_Cancel_Reason__c and CM_Channel__c fields of the Case object.
     *               The method is cacheable to optimize performance by storing the results in the Lightning Data Service cache.
     * @return       A map where the keys are the field names ('CM_Cancel_Reason__c', 'CM_Channel__c') 
     *               and the values are lists of picklist values for each field.
     * @AuraEnabled  The method is exposed to Lightning components and can be used in LWC or Aura components.
     * @cacheable    true to enable caching and reduce server calls.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistValues() {
        // Create a map to store the picklist values
        Map<String, List<String>> picklistValuesMap = new Map<String, List<String>>();

        // Get picklist values for CM_Cancel_Reason__c
        List<String> cancelReasonValues = getPicklistValuesForField(Case.SObjectType, 'CM_Cancel_Reason__c');
        picklistValuesMap.put('CM_Cancel_Reason__c', cancelReasonValues);

        // Get picklist values for CM_Channel__c
        List<String> channelValues = getPicklistValuesForField(Case.SObjectType, 'CM_Channel__c');
        picklistValuesMap.put('CM_Channel__c', channelValues);

        return picklistValuesMap;
    }

    /**
     * @description  Fetches picklist values for a specified field of a given SObject type.
     * @param        sObjectType The SObject type (e.g., Case) for which to retrieve picklist values.
     * @param        fieldName The API name of the field (e.g., 'CM_Cancel_Reason__c') to retrieve picklist values from.
     * @return       A list of active picklist values for the specified field.
     * @private      This method is internal and used by the getPicklistValues method to retrieve values for specific fields.
     */
    private static List<String> getPicklistValuesForField(Schema.SObjectType sObjectType, String fieldName) {
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = sObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        List<String> allowedChannelValues = new List<String>{'Contact Centre - chat', 'Contact Centre - voice'};

        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                if(fieldName == 'CM_Channel__c'){
                    if(allowedChannelValues.contains(entry.getValue())){
                        picklistValues.add(entry.getValue());
                    }
                }else{
                    picklistValues.add(entry.getValue());
                }
            }
        }
        return picklistValues;
    }

    /**
     * @description  Updates the specified Case record with new values for CM_Cancel_Reason__c and CM_Channel__c fields.
     *               Throws an exception if the update operation fails.
     * @param        caseId The Id of the Case record to be updated.
     * @param        cancelReason The new value for the CM_Cancel_Reason__c field.
     * @param        channel The new value for the CM_Channel__c field.
     * @AuraEnabled  The method is exposed to Lightning components to be invoked from the client-side.
     * @throws       AuraHandledException if there is an error during the update operation.
     */
    @AuraEnabled
    public static void saveCaseFields(Id caseId, String cancelReason, String channel, String status) {
        //try {
            //CEDT-3263
            List<Capitec_Transaction_Type__mdt> lstTransactionType = [SELECT Id, Classification_Type__c, SpendGroup__c, Primary_Need__c, Specific_Need__c FROM Capitec_Transaction_Type__mdt];
            Map<String, String> mapClassAndGroup = new Map<String, String>();
            for(Capitec_Transaction_Type__mdt ctt : lstTransactionType){
                mapClassAndGroup.put(ctt.Classification_Type__c + ctt.SpendGroup__c, ctt.Specific_Need__c);
            }
            
            List<FinServ__FinancialAccountTransaction__c> lstFAT = [SELECT Id, Classification_Type__c, CC_Spend_Group__c FROM FinServ__FinancialAccountTransaction__c WHERE Case__c = :caseId];
			
            Case caseRecord = [SELECT Id, CM_Cancel_Reason__c, CM_Channel__c, Capitec_Specific_Need__c FROM Case WHERE Id = :caseId LIMIT 1 FOR UPDATE];
            caseRecord.CM_Cancel_Reason__c = cancelReason;
            caseRecord.CM_Channel__c = channel;
            caseRecord.Status = status; //CEDT-3448 - add case status
            
            if(lstFAT.size() > 0){
                if(lstFAT.size() > 1){
                    
                }else{
                    caseRecord.Capitec_Specific_Need__c = mapClassAndGroup.get(lstFAT[0].Classification_Type__c + lstFAT[0].CC_Spend_Group__c);
                }
            }
        
        	SYstem.debug(caseRecord);
            
            update caseRecord;
        /*} catch (Exception e) {
            System.debug(e);
            throw new AuraHandledException('Failed to update case fields: ' + e.getMessage());
        }*/
    }
}