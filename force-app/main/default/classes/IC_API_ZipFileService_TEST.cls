/*******************************************************************
* @Class Name        :  IC_API_ZipFileService_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Ridwan, 8-Feb-2024, Jira Tickets: ICS-233, ICS-398, ICS-593
* @Version           :  1.0
*
*******************************************************************/

@isTest
private class IC_API_ZipFileService_TEST {
   
    @isTest
    static void testProcessCaseFilesSuccess() {

		// Setup test data
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account a = new Account(
            LastName = 'Test Case - ICS-398',
            CIF_Number__c = '123456',
            RecordTypeId = personAccountRTId
        );
        insert a;
        
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case parentCase = new Case(
            Subject = 'Test Parent Case - ICS-398',
            Status = 'New',
            Sub_Status__c = 'Unclassified',
            IC_Type__c = 'Unemployment/ITEI',
            Sub_Type__c = 'Retrenchment',
            //Sub_Type_Reason__c = 'New Technology',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Credit Life',
            AccountId = a.Id
        );
        
        insert parentCase;
        
        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Case childCase = new Case(
            Subject = 'Test Child Case - ICS-398',
            Status = '2nd Assessment',
            Sub_Status__c = 'Preliminary Declined',
            IC_Type__c = 'Unemployment/ITEI',
            Sub_Type__c = 'Retrenchment',
            //Sub_Type_Reason__c = 'New Technology',
            RecordTypeId = insuranceClaimsAssessmentRTId,
            Product_Type__c = 'Credit Life',
            IC_Insurer_Underwriter_at_Event_Date__c = 'GuardRisk',
            ParentId = parentCase.Id,
            AccountId = a.Id
        );
        insert childCase;
        
        // Create and link a file to the parentCase
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.jpg', // The file name and extension
            VersionData = Blob.valueOf('Test data'), // Simulate file content
            IsMajorVersion = true,
            FirstPublishLocationId = parentCase.Id // Directly relates the file to the case on creation
        );
        insert cv;
        
        List<DocumentType> retrenchmentLetterDocType = [SELECT Id FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];
        DocumentChecklistItem checklistItem = [
            SELECT Id, Status, IC_Documentum_ID__c
            FROM DocumentChecklistItem
            WHERE ParentRecordId = :parentCase.Id
            LIMIT 1
        ];
        checklistItem.Status = 'Verified';
        checklistItem.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem;
        // Setup test data
        
        // Prepare your FlowRequest
        IC_API_ZipFileService.FlowRequest request = new IC_API_ZipFileService.FlowRequest();
       
        request.parentCaseId = parentCase.Id;
        request.childCaseId = childCase.Id;
        
        // Mock callout response if your method does it
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        // Call the method to test
        List<String> results = IC_API_ZipFileService.processCaseFiles(new List<IC_API_ZipFileService.FlowRequest>{ request });
        Test.stopTest();
    }
    
    @isTest
    static void testProcessCaseFilesSuccess593() {

		// Setup test data
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account a = new Account(
            LastName = 'Test Case - ICS-593',
            CIF_Number__c = '1234567',
            RecordTypeId = personAccountRTId
        );
        insert a;
        
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case parentCase = new Case(
            Subject = 'Test Parent Case - ICS-593',
            Status = 'New',
            Sub_Status__c = 'Unclassified',
            IC_Type__c = 'Unemployment/ITEI',
            Sub_Type__c = 'Retrenchment',
            //Sub_Type_Reason__c = 'New Technology',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Credit Life',
            AccountId = a.Id
        );
        
        insert parentCase;
        
        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Case childCase = new Case(
            Subject = 'Test Child Case - ICS-593',
            Status = 'Escalated for Review',
            Sub_Status__c = 'Claims Forum',
            IC_Type__c = 'Unemployment/ITEI',
            Sub_Type__c = 'Retrenchment',
            //Sub_Type_Reason__c = 'New Technology',
            RecordTypeId = insuranceClaimsAssessmentRTId,
            Product_Type__c = 'Credit Life',
            IC_Insurer_Underwriter_at_Event_Date__c = 'Capitec Life',
            ParentId = parentCase.Id,
            AccountId = a.Id
        );
        insert childCase;
        
        // Create and link a file to the parentCase
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.jpg', // The file name and extension
            VersionData = Blob.valueOf('Test data'), // Simulate file content
            IsMajorVersion = true,
            FirstPublishLocationId = parentCase.Id // Directly relates the file to the case on creation
        );
        insert cv;
        
        List<DocumentType> retrenchmentLetterDocType = [SELECT Id FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];
        DocumentChecklistItem checklistItem = [
            SELECT Id, Status, IC_Documentum_ID__c
            FROM DocumentChecklistItem
            WHERE ParentRecordId = :parentCase.Id
            LIMIT 1
        ];
        checklistItem.Status = 'Verified';
        checklistItem.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem;
        // Setup test data
        
        // Prepare your FlowRequest
        IC_API_ZipFileService.FlowRequest request = new IC_API_ZipFileService.FlowRequest();
       
        request.parentCaseId = parentCase.Id;
        request.childCaseId = childCase.Id;
        request.buttonSource = 'Escalate Assessment';
        request.emailTemplateSource = 'IC Credit Life Claims forum email template';
        
        // Mock callout response if your method does it
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        // Call the method to test
        List<String> results = IC_API_ZipFileService.processCaseFiles(new List<IC_API_ZipFileService.FlowRequest>{ request });
        Test.stopTest();
    }
    
    //ICS-549
     @isTest
    static void testProcessCaseFilesSuccess_Disability() {

		// Setup test data
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account a = new Account(
            LastName = 'Test Case - ICS-549',
            CIF_Number__c = '12345678',
            RecordTypeId = personAccountRTId
        );
        insert a;
        
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case parentCase = new Case(
            Subject = 'Test Parent Case - ICS-549',
            Status = 'New',
            Sub_Status__c = 'Unclassified',
            IC_Type__c = 'Disability ',
            Sub_Type__c = 'Temporary',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Credit Life',
            AccountId = a.Id
        );
        
        insert parentCase;
        
        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Case childCase = new Case(
            Subject = 'Test Child Case - ICS-549',
            Status = 'New',
            IC_Type__c = 'Disability ',
            Sub_Type__c = 'Temporary',
            RecordTypeId = insuranceClaimsAssessmentRTId,
            Product_Type__c = 'Credit Life',
            IC_Insurer_Underwriter_at_Event_Date__c = 'Capitec Life',
            ParentId = parentCase.Id,
            AccountId = a.Id
        );
        insert childCase;
        
        // Create and link a file to the parentCase
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.jpg', // The file name and extension
            VersionData = Blob.valueOf('Test data'), // Simulate file content
            IsMajorVersion = true,
            FirstPublishLocationId = parentCase.Id // Directly relates the file to the case on creation
        );
        insert cv;
        
        List<DocumentType> retrenchmentLetterDocType = [SELECT Id FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];
        DocumentChecklistItem checklistItem = [
            SELECT Id, Status, IC_Documentum_ID__c
            FROM DocumentChecklistItem
            WHERE ParentRecordId = :parentCase.Id
            LIMIT 1
        ];
        checklistItem.Status = 'Verified';
        checklistItem.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem;
        // Setup test data
        
        // Prepare your FlowRequest
        IC_API_ZipFileService.FlowRequest request = new IC_API_ZipFileService.FlowRequest();
       
        request.parentCaseId = parentCase.Id;
        request.childCaseId = childCase.Id;
        request.buttonSource = 'Lodge';
        request.emailTemplateSource = 'IC Guardrisk Disability email template';
        
        // Mock callout response if your method does it
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        // Call the method to test
        List<String> results = IC_API_ZipFileService.processCaseFiles(new List<IC_API_ZipFileService.FlowRequest>{ request });
        Test.stopTest();
    }
    
    //ICS-578
     @isTest
    static void testProcessCaseFilesSuccess_OCI_Death() {

		// Setup test data
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account a = new Account(
            LastName = 'Test Case - ICS-578',
            CIF_Number__c = '133456789',
            RecordTypeId = personAccountRTId
        );
        insert a;
        
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case parentCase = new Case(
            Subject = 'Test Parent Case - ICS-578',
            Status = 'New',
            Sub_Status__c = 'Unclassified',
            IC_Type__c = 'Death ',
            Sub_Type__c = 'Natural',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Credit Life',
            AccountId = a.Id
        );
        
        insert parentCase;
        
        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Case childCase = new Case(
            Subject = 'Test Child Case - ICS-78',
            Status = 'New',
            IC_Type__c = 'Death ',
            Sub_Type__c = 'Natural',
            RecordTypeId = insuranceClaimsAssessmentRTId,
            Product_Type__c = 'Credit Life',
            IC_Insurer_Underwriter_at_Event_Date__c = 'Unknown',
            ParentId = parentCase.Id,
            AccountId = a.Id
        );
        insert childCase;
        
        // Create and link a file to the parentCase
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.jpg', // The file name and extension
            VersionData = Blob.valueOf('Test data'), // Simulate file content
            IsMajorVersion = true,
            FirstPublishLocationId = parentCase.Id // Directly relates the file to the case on creation
        );
        insert cv;
        
        List<DocumentType> retrenchmentLetterDocType = [SELECT Id FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];
        DocumentChecklistItem checklistItem = [
            SELECT Id, Status, IC_Documentum_ID__c
            FROM DocumentChecklistItem
            WHERE ParentRecordId = :parentCase.Id
            LIMIT 1
        ];
        checklistItem.Status = 'Verified';
        checklistItem.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem;
        // Setup test data
        
        // Prepare your FlowRequest
        IC_API_ZipFileService.FlowRequest request = new IC_API_ZipFileService.FlowRequest();
       
        request.parentCaseId = parentCase.Id;
        request.childCaseId = childCase.Id;
        request.buttonSource = 'Send Email';
        request.emailTemplateSource = 'IC Death OCI Claim';
        
        // Mock callout response if your method does it
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        // Call the method to test
        List<String> results = IC_API_ZipFileService.processCaseFiles(new List<IC_API_ZipFileService.FlowRequest>{ request });
        Test.stopTest();
    }
    
    //ICS-578
     @isTest
    static void testProcessCaseFilesSuccess_OCI_Disability() {

		// Setup test data
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account a = new Account(
            LastName = 'Test Case - ICS-578',
            CIF_Number__c = '123456789',
            RecordTypeId = personAccountRTId
        );
        insert a;
        
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case parentCase = new Case(
            Subject = 'Test Parent Case - ICS-578',
            Status = 'New',
            Sub_Status__c = 'Unclassified',
            IC_Type__c = 'Disability ',
            Sub_Type__c = 'Temporary',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Credit Life',
            AccountId = a.Id
        );
        
        insert parentCase;
        
        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Case childCase = new Case(
            Subject = 'Test Child Case - ICS-78',
            Status = 'New',
            IC_Type__c = 'Disability ',
            Sub_Type__c = 'Temporary',
            RecordTypeId = insuranceClaimsAssessmentRTId,
            Product_Type__c = 'Credit Life',
            IC_Insurer_Underwriter_at_Event_Date__c = 'Unknown',
            ParentId = parentCase.Id,
            AccountId = a.Id
        );
        insert childCase;
        
        // Create and link a file to the parentCase
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.jpg', // The file name and extension
            VersionData = Blob.valueOf('Test data'), // Simulate file content
            IsMajorVersion = true,
            FirstPublishLocationId = parentCase.Id // Directly relates the file to the case on creation
        );
        insert cv;
        
        // Create and link a file to the parentCase
        ContentVersion cv_child = new ContentVersion(
            Title = 'TestFile2',
            PathOnClient = 'TestFile2.jpg', // The file name and extension
            VersionData = Blob.valueOf('Test data2'), // Simulate file content
            IsMajorVersion = true,
            FirstPublishLocationId = childCase.Id // Directly relates the file to the case on creation
        );
        insert cv_child;
        
        List<DocumentType> retrenchmentLetterDocType = [SELECT Id FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];
        DocumentChecklistItem checklistItem = [
            SELECT Id, Status, IC_Documentum_ID__c
            FROM DocumentChecklistItem
            WHERE ParentRecordId = :parentCase.Id
            LIMIT 1
        ];
        checklistItem.Status = 'Verified';
        checklistItem.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem;
        
        DocumentChecklistItem checklistItem_child = [
            SELECT Id, Status, IC_Documentum_ID__c
            FROM DocumentChecklistItem
            WHERE ParentRecordId = :childCase.Id
            LIMIT 1
        ];
        checklistItem_child.Status = 'Verified';
        checklistItem_child.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem_child;
        // Setup test data
        
        // Prepare your FlowRequest
        IC_API_ZipFileService.FlowRequest request = new IC_API_ZipFileService.FlowRequest();
       
        request.parentCaseId = parentCase.Id;
        request.childCaseId = childCase.Id;
        request.buttonSource = 'Send Email';
        request.emailTemplateSource = 'IC Unemployment / ITEI or Disability OCI Claim';
        
        // Mock callout response if your method does it
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        // Call the method to test
        List<String> results = IC_API_ZipFileService.processCaseFiles(new List<IC_API_ZipFileService.FlowRequest>{ request });
        Test.stopTest();
    }


    //ICS-578
    @isTest
    static void testProcessCaseFilesSuccess_EscalateAssessment() {

        // Setup test data
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        Account a = new Account(
                LastName = 'Test Case - ICS-877',
                CIF_Number__c = '123456789',
                RecordTypeId = personAccountRTId
        );
        insert a;

        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case parentCase = new Case(
                Subject = 'Test Parent Case - ICS-877',
                Status = 'New',
                Sub_Status__c = 'Unclassified',
                IC_Type__c = 'Disability ',
                Sub_Type__c = 'Temporary',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Credit Life',
                AccountId = a.Id
        );

        insert parentCase;

        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Case childCase = new Case(
                Subject = 'Test Child Case - ICS-877',
                Status = 'New',
                IC_Type__c = 'Disability ',
                Sub_Type__c = 'Temporary',
                RecordTypeId = insuranceClaimsAssessmentRTId,
                Product_Type__c = 'Credit Life',
                IC_Insurer_Underwriter_at_Event_Date__c = 'Unknown',
                ParentId = parentCase.Id,
                AccountId = a.Id
        );
        insert childCase;

        // Create and link a file to the parentCase
        ContentVersion cv = new ContentVersion(
                Title = 'TestFile',
                PathOnClient = 'TestFile.jpg', // The file name and extension
                VersionData = Blob.valueOf('Test data'), // Simulate file content
                IsMajorVersion = true,
                FirstPublishLocationId = parentCase.Id // Directly relates the file to the case on creation
        );
        insert cv;

        // Create and link a file to the parentCase
        ContentVersion cv_child = new ContentVersion(
                Title = 'TestFile2',
                PathOnClient = 'TestFile2.jpg', // The file name and extension
                VersionData = Blob.valueOf('Test data2'), // Simulate file content
                IsMajorVersion = true,
                FirstPublishLocationId = childCase.Id // Directly relates the file to the case on creation
        );
        insert cv_child;

        List<DocumentType> retrenchmentLetterDocType = [SELECT Id FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];
        DocumentChecklistItem checklistItem = [
                SELECT Id, Status, IC_Documentum_ID__c
                FROM DocumentChecklistItem
                WHERE ParentRecordId = :parentCase.Id
                LIMIT 1
        ];
        checklistItem.Status = 'Verified';
        checklistItem.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem;

        DocumentChecklistItem checklistItem_child = [
                SELECT Id, Status, IC_Documentum_ID__c
                FROM DocumentChecklistItem
                WHERE ParentRecordId = :childCase.Id
                LIMIT 1
        ];
        checklistItem_child.Status = 'Verified';
        checklistItem_child.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem_child;
        // Setup test data

        // Prepare your FlowRequest
         List<IC_API_ZipFileService.FlowRequest> requests877 = new List<IC_API_ZipFileService.FlowRequest>();

        IC_API_ZipFileService.FlowRequest requestForum = new IC_API_ZipFileService.FlowRequest();

        requestForum.parentCaseId = parentCase.Id;
        requestForum.childCaseId = childCase.Id;
        requestForum.buttonSource = System.Label.IC_Escalate_Assessment_Button;
        requestForum.emailTemplateSource = 'IC_Escalate_To_Claims_Forum_Template';

        IC_API_ZipFileService.FlowRequest requestManagement = new IC_API_ZipFileService.FlowRequest();

        requestManagement.parentCaseId = parentCase.Id;
        requestManagement.childCaseId = childCase.Id;
        requestManagement.buttonSource = System.Label.IC_Escalate_Assessment_Button;
        requestManagement.emailTemplateSource = 'IC_Escalate_To_Management_Template';

        IC_API_ZipFileService.FlowRequest requestFraud = new IC_API_ZipFileService.FlowRequest();

        requestFraud.parentCaseId = parentCase.Id;
        requestFraud.childCaseId = childCase.Id;
        requestFraud.buttonSource = System.Label.IC_Escalate_Assessment_Button;
        requestFraud.emailTemplateSource = 'Ic_Escalate_To_Fraud_Template';

        requests877.add(requestForum);
        requests877.add(requestManagement);
        requests877.add(requestFraud);

        // Mock callout response if your method does it
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        // Call the method to test
        List<String> results = IC_API_ZipFileService.processCaseFiles(requests877);
        Test.stopTest();
    }


    //ICS-541
    @isTest
    static void testProcessCaseFilesSuccess_NotifyCentriq() {

        // Setup test data
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        Account a = new Account(
                LastName = 'Test Case - ICS-541',
                CIF_Number__c = '123456789',
                RecordTypeId = personAccountRTId
        );
        insert a;

        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case parentCase = new Case(
                Subject = 'Test Parent Case - ICS-541',
                Status = 'New',
                Sub_Status__c = 'Unclassified',
                IC_Type__c = 'Disability ',
                Sub_Type__c = 'Temporary',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Credit Life',
                AccountId = a.Id
        );

        insert parentCase;

        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Case childCase = new Case(
                Subject = 'Test Child Case - ICS-541',
                Status = 'New',
                IC_Type__c = 'Disability ',
                Sub_Type__c = 'Temporary',
                RecordTypeId = insuranceClaimsAssessmentRTId,
                Product_Type__c = 'Credit Life',
                IC_Insurer_Underwriter_at_Event_Date__c = 'Unknown',
                ParentId = parentCase.Id,
                AccountId = a.Id
        );
        insert childCase;

        // Create and link a file to the parentCase
        ContentVersion cv = new ContentVersion(
                Title = 'TestFile',
                PathOnClient = 'TestFile.jpg', // The file name and extension
                VersionData = Blob.valueOf('Test data'), // Simulate file content
                IsMajorVersion = true,
                FirstPublishLocationId = parentCase.Id // Directly relates the file to the case on creation
        );
        insert cv;

        // Create and link a file to the parentCase
        ContentVersion cv_child = new ContentVersion(
                Title = 'TestFile2',
                PathOnClient = 'TestFile2.jpg', // The file name and extension
                VersionData = Blob.valueOf('Test data2'), // Simulate file content
                IsMajorVersion = true,
                FirstPublishLocationId = childCase.Id // Directly relates the file to the case on creation
        );
        insert cv_child;

        List<DocumentType> retrenchmentLetterDocType = [SELECT Id FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];
        DocumentChecklistItem checklistItem = [
                SELECT Id, Status, IC_Documentum_ID__c
                FROM DocumentChecklistItem
                WHERE ParentRecordId = :parentCase.Id
                LIMIT 1
        ];
        checklistItem.Status = 'Verified';
        checklistItem.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem;

        DocumentChecklistItem checklistItem_child = [
                SELECT Id, Status, IC_Documentum_ID__c
                FROM DocumentChecklistItem
                WHERE ParentRecordId = :childCase.Id
                LIMIT 1
        ];
        checklistItem_child.Status = 'Verified';
        checklistItem_child.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem_child;
        // Setup test data

        // Prepare your FlowRequest
        List<IC_API_ZipFileService.FlowRequest> requests841 = new List<IC_API_ZipFileService.FlowRequest>();

        IC_API_ZipFileService.FlowRequest requestCentriq = new IC_API_ZipFileService.FlowRequest();

        requestCentriq.parentCaseId = parentCase.Id;
        requestCentriq.childCaseId = childCase.Id;
        requestCentriq.buttonSource = System.Label.IC_Centriq_Event_Decline_Button_Source;
        requestCentriq.emailTemplateSource = 'Centriq_Child_Case_Created';

        requests841.add(requestCentriq);


        // Mock callout response if your method does it
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        // Call the method to test
        List<String> results = IC_API_ZipFileService.processCaseFiles(requests841);
        Test.stopTest();
    }

    
    // Mock class for HttpCallout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"fileContent":"fakeZipFileContent"}'); // Simulate successful response
            res.setStatusCode(200);
            return res;
        }
    }
}