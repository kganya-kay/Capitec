/*
  @description       : Test class for capitec_ClientCareController
  @author            : Kevin Nundran
  @created on  		 : 20-09-2024
  @last modified on  : 24-01-2025
  @last modified by  : Cornelia Smit
					 : BUGFIX - Updated transferTransactionsAndCloseCase to accommodate Recall Request and added method closeCaseInstantly
                     : CEDT-3559 - Updated 'No transactions' error handling
                     : CEDT-3565 - Add testCloseAgentErrorCase failure unit test
*/
@isTest
private class capitec_ClientCareController_Test {
    static final Id CLIENTCARE_CASE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Client_Care').getRecordTypeId();

    /*
      @description       : Sets up the test data for all test methods.
      @created on        : 20-09-2024
    */
    @testSetup
    static void setup() {
        // Create an Account record
        Account acc = new Account(Name = 'Test Account', CIF_Number__c = '123456');
        insert acc;

        // Create two Case records
        List<Case> caseRecords = new List<Case>{
            new Case(
                Subject = 'Test Case 1',
                Status = 'New',
                capitec_Primary_Need__c = 'Fraud',
                capitec_Specific_Need__c = 'Push Payment',
                CM_Channel__c = 'Contact Centre - chat',
                CM_Product__c = 'Credit Card Account',
                AccountId = acc.Id,
                RecordTypeId = CLIENTCARE_CASE_RECORD_TYPE_ID
            ),
            new Case(
                Subject = 'Test Case 2',
                Status = 'New',
                capitec_Primary_Need__c = 'Fraud',
                capitec_Specific_Need__c = 'Push Payment',
                CM_Channel__c = 'Contact Centre - chat',
                CM_Product__c = 'Credit Card Account',
                AccountId = acc.Id,
                RecordTypeId = CLIENTCARE_CASE_RECORD_TYPE_ID
            ),
            new Case(
                Subject = 'Test Case 3',
                Status = 'New',
                capitec_Primary_Need__c = 'Fraud',
                AccountId = acc.Id,
                RecordTypeId = CLIENTCARE_CASE_RECORD_TYPE_ID
            )
        };
        insert caseRecords;

        // Create FinancialAccountTransaction records associated with the Cases
        List<FinServ__FinancialAccountTransaction__c> transactions = new List<FinServ__FinancialAccountTransaction__c>{
            new FinServ__FinancialAccountTransaction__c(
                Case__c = caseRecords[0].Id,
                FinServ__Amount__c = 100.00,  
                FinServ__TransactionDate__c = System.today()
            ),
            new FinServ__FinancialAccountTransaction__c(
                Case__c = caseRecords[1].Id,
                FinServ__Amount__c = 200.00,  
                FinServ__TransactionDate__c = System.today()
            )
        };
        insert transactions;
    }
    
    
    /*
      @description       : Tests the successful invocation of the invokeMethod function.
      @created on        : 20-09-2024
    */
    @isTest
    static void testInvokeMethodSuccess() {
        // Query the test data and complete DML
        Case caseRecord1 = [SELECT Id FROM Case WHERE Subject = 'Test Case 1' LIMIT 1];
        Case caseRecord2 = [SELECT Id FROM Case WHERE Subject = 'Test Case 2' LIMIT 1];
        
        // Set up the input data
        Map<String, Object> input = new Map<String, Object>{
            'ClientCareCase' => new Map<String, Object>{ 'Id' => caseRecord1.Id },
                'DRId_Case' => caseRecord2.Id
                };
                    List<String> transIds = new List<String>{ '111', '222', '333' };
                        
                        // Set the mock before starting the test
                        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceTHMockResponse());
        
        // Call test code in a test execution context
        Test.startTest();
        Capitec_TransactionHistoryHelper.CapitecResponseStatus responseWrapper = 
            Capitec_TransactionHistoryController.flagTransactions(transIds, caseRecord2.Id);
        
        // Invoke the method with the controller and input
        capitec_ClientCareController controller = new capitec_ClientCareController();
        Boolean result = controller.invokeMethod('transferTransactionsAndCloseCase', input, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();
        
        // Assertions
        System.assertEquals(true, result, 'Expected a successful invocation result.');
    }

    /*
      @description       : Tests the invokeMethod function when no records are found.
      @created on        : 20-09-2024
    */
    @isTest
    static void testInvokeMethodNoRecordsFound() {
        // Create input map with a non-existent Case ID
        Map<String, Object> input = new Map<String, Object>{
            'ClientCareCase' => new Map<String, Object>{ 'Id' => 'nonExistentId' },
            'DRId_Case' => 'nonExistentFraudCaseId'
        };

        // Create an instance of the controller
        capitec_ClientCareController controller = new capitec_ClientCareController();

        List<String> transIds = new List<String>();
        transIds.add('111');
        transIds.add('222');
        transIds.add('333');


        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceTHMockResponse());
        Test.startTest();
        Capitec_TransactionHistoryHelper.CapitecResponseStatus responseWrapper = Capitec_TransactionHistoryController.flagTransactions(transIds, 'nonExistentFraudCaseId');
        // Call the method and capture the result
        Boolean result = controller.invokeMethod('transferTransactionsAndCloseCase', input, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();
        
        // Verify that the result is false when no records are found
        System.assertEquals(false, result, 'The result should be false when no records are found.');
    }

    /*
      @description       : Tests the invokeMethod function's exception handling by passing invalid data.
      @created on        : 20-09-2024
    */
    @isTest
    static void testInvokeMethodExceptionHandling() {
        // Create input map with invalid data to trigger exception
        Map<String, Object> input = new Map<String, Object>{
            'ClientCareCase' => new Map<String, Object>{ 'Id' => null },
            'DRId_Case' => null
        };

        // Create an instance of the controller
        capitec_ClientCareController controller = new capitec_ClientCareController();

        List<String> transIds = new List<String>();
        transIds.add('111');
        transIds.add('222');
        transIds.add('333');


        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceTHMockResponse());
        Test.startTest();
        Capitec_TransactionHistoryHelper.CapitecResponseStatus responseWrapper = Capitec_TransactionHistoryController.flagTransactions(transIds, null);
        // Call the method and capture the result
        Boolean result = controller.invokeMethod('transferTransactionsAndCloseCase', input, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        // Verify that the result is false when an exception is handled
        System.assertEquals(false, result, 'The result should be false when exception is handled.');
    }

    /*
      @description       : Tests the successful update of case taxonomy.
      @created on        : 26-11-2024
    */
    @isTest
    static void testInvokeMethodPopulateTaxonomySuccess() {
        Case caseRecord = [SELECT Id FROM Case WHERE Subject = 'Test Case 3' LIMIT 1];

        Map<String, Object> taxonomyList = new Map<String, Object>{
            'FraudCaseChannel' => 'Contact Centre - chat',
            'FraudCaseDescription' => 'Testing description',
            'FraudCaseProduct' => 'Credit Card Account',
            'FraudCaseSubject' => 'Testing subject',
            'PrimaryNeed' => 'Fraud',
            'SpecificNeed' => 'Push Payment'
        };


        Map<String, Object> input = new Map<String, Object>{
                'DRId_Case' => caseRecord.Id,
                'DepartmentFR' => 'Fraud Investigation',
                'Outcome' => 'Assigned',
                'Step6' => taxonomyList
                };      
        
        capitec_ClientCareController controller = new capitec_ClientCareController();
        Boolean result = controller.invokeMethod('updateCaseTaxonomyFraud', input, new Map<String, Object>(), new Map<String, Object>());
        
        Case caseRecordUpdated = [SELECT Id, Subject, Capitec_Specific_Need__c FROM Case WHERE Subject = 'Testing subject' LIMIT 1];        

        System.assertEquals(true, result, 'Expected a successful invocation result.');
        System.assertEquals('Push Payment', caseRecordUpdated.Capitec_Specific_Need__c, 'Expected the case record to be updated with the taxonomy list.');
    }

    /*
      @description       : Tests the failed update of case taxonomy.
      @created on        : 26-11-2024
    */
    @isTest
    static void testInvokeMethodPopulateTaxonomyError() {
        Case caseRecord = [SELECT Id FROM Case WHERE Subject = 'Test Case 3' LIMIT 1];

        Map<String, Object> taxonomyList = new Map<String, Object>{
            'FraudCaseChannel' => 'Test',
            'FraudCaseDescription' => 'Testing description',
            'FraudCaseProduct' => 'Credit Card Account',
            'FraudCaseSubject' => 'Testing subject',
            'PrimaryNeed' => 'Fraud',
            'SpecificNeed' => 'Push Payment'
        };


        Map<String, Object> input = new Map<String, Object>{
                'DRId_Case' => caseRecord.Id,
                'DepartmentFR' => 'Fraud Investigation',
                'Outcome' => 'Assigned',
                'Step6' => taxonomyList
                };    
        
        capitec_ClientCareController controller = new capitec_ClientCareController();
        Boolean result = controller.invokeMethod('updateCaseTaxonomyFraud', input, new Map<String, Object>(), new Map<String, Object>());      

        System.assertEquals(false, result, 'Expected a failed invocation result.');
    }

    /*
      @description       : Tests successful description.
      @created on        : 27-11-2024
    */
    @isTest
    static void testGenerateTaxonomyDescriptionWithValidInput() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        List<Map<String, Object>> transactions = new List<Map<String, Object>>{
            new Map<String, Object>{
                'TransactionType' => 'Card',
                'TransactionAmount' => -500,
                'TransactionDate' => '2024-11-01T14:13:55.000Z'
            },
            new Map<String, Object>{
                'TransactionType' => 'Voucher',
                'TransactionAmount' => -200,
                'TransactionDate' => '2024-11-06T08:55:12.000Z'
            }
        };
        input.put('FAT', transactions);
        input.put('ClientCareCase', new Map<String, Object>{
            'CreatedDate' => '2024-11-21T06:42:40.000Z'
        });

        capitec_ClientCareController controller = new capitec_ClientCareController();
        Boolean result = controller.invokeMethod('generateTaxonomyDescription', input, output, new Map<String, Object>());

        System.assert(result, 'Expected result to be true');
        System.assert(output.containsKey('FraudCaseDescription'), 'Output should contain FraudCaseDescription');

        String description = (String) output.get('FraudCaseDescription');

        System.assert(description.contains('A case created at Client Care on 11/21/2024 08:42.'), 'Description should include the case creation date');
        System.assert(description.contains('Card for R500 on 11/01/2024 16:13.'), 'Description should include first transaction');
        System.assert(description.contains('Voucher for R200 on 11/06/2024 10:55.'), 'Description should include second transaction');
    }

    /*
      @description       : Tests no transactions in input.
      @created on        : 27-11-2024
    */
    @isTest
    static void testGenerateTaxonomyDescriptionWithNoTransactions() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        
        input.put('FAT', new List<Object>());
        input.put('ClientCareCase', new Map<String, Object>{
            'CreatedDate' => '2024-11-21T06:42:40.000Z'
        });

        capitec_ClientCareController controller = new capitec_ClientCareController();
        Boolean result = controller.invokeMethod('generateTaxonomyDescription', input, output, new Map<String, Object>());

        System.assert(result, 'Expected result to be true');
        System.assert(output.containsKey('cdCaseDescription'), 'Output should contain cdCaseDescription');

        String description = (String) output.get('cdCaseDescription');

        System.assert(description.contains('A case created at Client Care on 11/21/2024 08:42.'), 'Description should include the case creation date');
        System.assertNotEquals(true, description.contains('Disputed transactions:'), 'Description should not contain transactions');
    }

    /*
      @description       : Tests invalid input data.
      @created on        : 27-11-2024
    */
    @isTest
    static void testGenerateTaxonomyDescriptionWithInvalidData() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        input.put('FAT', 'InvalidData');

        capitec_ClientCareController controller = new capitec_ClientCareController();
        Boolean result = controller.invokeMethod('generateTaxonomyDescription', input, output, new Map<String, Object>());

        System.assert(!result, 'Expected result to be false');
        System.assert(output.containsKey('error'), 'Output should contain error');
    }

    /*
      @description       : Tests missing case created date.
      @created on        : 27-11-2024
    */
    @isTest
    static void testGenerateTaxonomyDescriptionWithMissingCreatedDate() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        List<Map<String, Object>> transactions = new List<Map<String, Object>>{
            new Map<String, Object>{
                'TransactionType' => 'Card',
                'TransactionAmount' => -300,
                'TransactionDate' => '2024-11-11T08:12:10.000Z'
            }
        };
        input.put('FAT', transactions);
        input.put('ClientCareCase', new Map<String, Object>());

        capitec_ClientCareController controller = new capitec_ClientCareController();
        Boolean result = controller.invokeMethod('generateTaxonomyDescription', input, output, new Map<String, Object>());

        System.assert(result, 'Expected result to be true');
        String description = (String) output.get('FraudCaseDescription');
        System.assert(description.contains('A case created at Client Care (creation date unavailable).'), 'Description should handle missing creation date');
    }

    /*
      @description       : Tests forced exception.
      @created on        : 27-11-2024
    */
    @isTest
    static void testGenerateTaxonomyDescriptionWithException() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        input.put('FAT', null);
   
        capitec_ClientCareController controller = new capitec_ClientCareController();
        Boolean result = controller.invokeMethod('generateTaxonomyDescription', input, output, new Map<String, Object>());

        System.assert(!result, 'Expected result to be false');
        System.assert(output.containsKey('error'), 'Output should contain error');
        System.assert(((String) output.get('error')).startsWith('Error:'), 'Error message should start with "Error:"');
    }

    /*
      @description       : Tests the scheduleCaseClose method to ensure it schedules a job after 30 seconds.
      @created on        : 20-09-2024
    */
    @isTest
    static void testScheduleCaseCloseIn30Seconds() {
        // Create an instance of the controller
        capitec_ClientCareController controller = new capitec_ClientCareController();

        Test.startTest();
        // Call the schedule method to schedule after 30 seconds
        controller.scheduleCaseClose('5009X00000PP2uzQAD');

        // Fetch the scheduled jobs
        List<CronTrigger> scheduledJobs = [SELECT Id, CronExpression FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Close Client Care Case Job%' LIMIT 1];
        Test.stopTest();

        // Verify the scheduled job exists
        System.assertEquals(1, scheduledJobs.size(), 'The job should be scheduled.');

        // Calculate the expected cron expression for the scheduled job
        Datetime futureTime = Datetime.now().addSeconds(30); // Change to 30 seconds
        String expectedCronExpression = String.format('{0} {1} {2} {3} {4} ? {5}', 
            new List<String>{
                String.valueOf(futureTime.second()),     
                String.valueOf(futureTime.minute()),     
                String.valueOf(futureTime.hour()),       
                String.valueOf(futureTime.day()),        
                String.valueOf(futureTime.month()),      
                String.valueOf(futureTime.year())        
            }
        );
    }

    /*
      @description       : Tests the execution of the case close scheduler to ensure it updates the case status to Closed.
      @created on        : 20-09-2024
    */
    @isTest
    static void testCaseCloseSchedulerExecution() {
        // Create a Case record for testing
        Case caseRecord = new Case(
            Subject = 'Test Case',
            Status = 'New',
            RecordTypeId = CLIENTCARE_CASE_RECORD_TYPE_ID
        );
        insert caseRecord;

        // Create an instance of the scheduler class
        capitec_CCCaseCloseScheduler scheduler = new capitec_CCCaseCloseScheduler(caseRecord.Id, 'Closed');

        Test.startTest();
        // Execute the scheduled job
        scheduler.execute(null);
        Test.stopTest();

        // Verify that the case status is updated to Closed
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :caseRecord.Id];
        System.assertEquals('Closed', updatedCase.Status, 'The case status should be Closed.');
    }

    /*
      @description       : Tests the closeCaseManually method to ensure it updates the case status to Closed.
      @created on        : 20-09-2024
    */
    @isTest
    static void testCloseCaseManually() {
        // Create a Case record for testing
        Case caseRecord = new Case(
            Subject = 'Test Case Close Manually',
            Status = 'New',
            RecordTypeId = CLIENTCARE_CASE_RECORD_TYPE_ID
        );
        insert caseRecord;

        // Abort any existing jobs and close the case manually
        capitec_ClientCareController.closeCaseManually(caseRecord.Id);

        Test.startTest();
        // Fetch the updated case record
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :caseRecord.Id];
        Test.stopTest();

        // Verify that the case status is updated to Closed
        System.assertEquals('Closed', updatedCase.Status, 'The Case should be closed.');
    }

    /*
      @description       : Tests the closeCaseInstantly method to ensure it updates the case status to Closed.
      @created on        : 22-01-2025
    */
    @isTest
    static void testCloseCaseInstantly() {
        // Create a Case record for testing
        Case caseRecord = new Case(
            Subject = 'Test Case Close Manually',
            Status = 'New',
            RecordTypeId = CLIENTCARE_CASE_RECORD_TYPE_ID
        );
        insert caseRecord;

        // Abort any existing jobs and close the case manually
        capitec_ClientCareController.closeCaseInstantly(caseRecord.Id);

        Test.startTest();
        // Fetch the updated case record
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :caseRecord.Id];
        Test.stopTest();

        // Verify that the case status is updated to Closed
        System.assertEquals('Closed', updatedCase.Status, 'The Case should be closed.');
    }

    /*
      @description       : Tests the closeAgentErrorCase method to ensure it handles the case status update correctly.
      @created on        : 20-09-2024
    */
    @isTest
    static void testCloseAgentErrorCasePassCase() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        
        // Fetch the RecordType ID for the "Client_Care" RecordType
        Id clientCareRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Client_Care' AND SObjectType = 'Case' LIMIT 1].Id;
        
        // Create a Case record for testing with the Client_Care RecordType
        Case caseRecord = new Case(
            Subject = 'Test Case Close Agent Error',
            Status = 'New',
            AccountId = accountId,
            RecordTypeId = clientCareRecordTypeId // Set the RecordTypeId
        );
        insert caseRecord;

        Test.startTest();
        // Simulate an agent error scenario
        capitec_ClientCareController.closeAgentErrorCase(accountId, caseRecord.Id);
        Test.stopTest();

        // Fetch the updated case record
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :caseRecord.Id];

        // Verify that the case status is updated to "Agent Error"
        System.assertEquals('Closed', updatedCase.Status, 'The Case should be marked as Agent Error.');
    }

    /*
      @description       : Tests the closeAgentErrorCase method to ensure it handles exceptions correctly.
      @created on        : 24-01-2025
    */
    @isTest
    static void testCloseAgentErrorCaseFailNoRecord() {
        Boolean exceptionCaught = false;
        Id caseId = null;
        Id accountId = null;

        Test.startTest();
        // Simulate an agent error scenario
        try {
            capitec_ClientCareController.closeAgentErrorCase(accountId, caseId);
        } catch (exception e) {
            exceptionCaught = true;
        }
        
        Test.stopTest();

        // Verify that an exception is thrown if no record Id is input
        System.assert(exceptionCaught, 'The method should throw an exception if no record Id is input.');
    }

    /*
      @description       : Tests the closeAgentErrorCase method to ensure it handles the case status update correctly.
      @created on        : 24-01-2025
    */
    @isTest
    static void testCloseAgentErrorCasePassAccount() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id nullCaseId = null;
        
        // Fetch the RecordType ID for the "Client_Care" RecordType
        Id clientCareRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Client_Care' AND SObjectType = 'Case' LIMIT 1].Id;
        
        // Create a Case record for testing with the Client_Care RecordType
        Case caseRecord = new Case(
            Subject = 'Test Case Close Agent Error',
            Status = 'New',
            AccountId = accountId,
            RecordTypeId = clientCareRecordTypeId // Set the RecordTypeId
        );
        insert caseRecord;

        Test.startTest();
        // Simulate an agent error scenario
        capitec_ClientCareController.closeAgentErrorCase(accountId, nullCaseId);
        Test.stopTest();

        // Fetch the updated case record
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :caseRecord.Id];

        // Verify that the case status is updated to "Agent Error"
        System.assertEquals('Closed', updatedCase.Status, 'The Case should be marked as Agent Error.');
    }

    /*
      @description       : Tests the getPicklistValues method to ensure it retrieves correct picklist values.
      @created on        : 20-09-2024
    */
    @isTest
    static void testGetPicklistValues() {
        // Call the method to retrieve picklist values
        Map<String, List<String>> picklistValues = capitec_ClientCareController.getPicklistValues();

        // Verify that the picklist values are not empty
        System.assertNotEquals(null, picklistValues, 'The picklist values should not be null.');
        System.assertNotEquals(0, picklistValues.size(), 'The picklist values should not be empty.');
    }

    /*
      @description       : Tests the saveCaseFields method to ensure it saves the case fields correctly.
      @created on        : 20-09-2024
    */
    @isTest
    static void testSaveCaseFields() {
        // Create a test case record
        Case caseRecord = new Case(
            Subject = 'Test Case Save Fields',
            capitec_Primary_Need__c = 'Fraud',
            Status = 'New',
           	RecordTypeId = CLIENTCARE_CASE_RECORD_TYPE_ID
        );
        insert caseRecord;

        Test.startTest();
        // Call the method to save the case fields
        capitec_ClientCareController.saveCaseFields(caseRecord.Id, 'Abandoned', 'Contact Centre - voice', 'New'); //CEDT-3448 - add case status
        Test.stopTest();

        // Fetch the updated case record
        Case updatedCase = [SELECT Id, Subject, CM_Channel__c, CM_Cancel_Reason__c FROM Case WHERE Id = :caseRecord.Id];

        // Verify the case fields were updated correctly
        System.assertEquals('Contact Centre - voice', updatedCase.CM_Channel__c);
        System.assertEquals('Abandoned', updatedCase.CM_Cancel_Reason__c);
    }

}