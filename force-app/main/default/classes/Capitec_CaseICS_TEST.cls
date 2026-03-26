/**
* Author           Ridwan Moosuddee
* Company          BlueSky
* Date             15/11/2023
* Description      Test Class for Capitec_CaseICS
**/
@isTest
public class Capitec_CaseICS_TEST {

    static final Id CASE_ICSchild_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Insurance_Claims_Assessment').getRecordTypeId();
    static final Set<Id> caseIdSetToProcess = new Set<Id>();

    @IsTest
    static void checkDueDiligenceTEST() {

        // Mock the HttpRequest and HttpResponse using HttpCalloutMock interface


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockFinaliseApproveCallout());
        Case case1 = IC_TestDataFactory.createSingleChildCase();
        caseIdSetToProcess.add(case1.Id);
        capitec_CaseICS.checkDueDiligence(caseIdSetToProcess);
        Test.stopTest();
    }

    // Mock for HTTP callout
    public class MockFinaliseApproveCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"count":1,"items":[{"idNumber":"12345","policyNumber":"PolNumber12345", "cifNumber":"12345"}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    // This mock class simulates an HTTP error response with a specific format
    private class MockPolicyCalloutError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            // Simulate an error response body in the specified format
            res.setBody('{' +
                    '"Title": "Bad Request",' +
                    '"Detail": [' +
                    '{' +
                    '"PropertyName": "CifNumber",' +
                    '"ErrorMessage": "\'Cif Number\' must not be empty."' +
                    '}' +
                    '],' +
                    '"Status": 400' +
                    '}');
            res.setStatusCode(400);
            return res;
        }
    }

    @IsTest
    static void test_makePolicyCallout_HttpError() {

        // Mock the HttpRequest and HttpResponse using HttpCalloutMock interface


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockPolicyCalloutError());
        Case case1 = IC_TestDataFactory.createSingleChildCaseWithoutAccount();
        caseIdSetToProcess.add(case1.Id);
        capitec_CaseICS.checkDueDiligence(caseIdSetToProcess);
        Test.stopTest();
    }


    @isTest
    static void zipFileAndQueueUpdate() {

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
                AccountId = a.Id,
                IC_Decline_Reason__c = 'Resigned'
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

        Group testGroup = new Group(Name = 'Waiting for Insurer', Type = 'Queue');
        insert testGroup;


        // Mock callout response if your method does it
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        capitec_CaseICS.zipFileAndQueueUpdate(new List<Id>{
                childCase.Id
        });
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

    @isTest
    static void testParentCaseWithOpenChildren() {
        // Arrange: Create the parent and child cases with the appropriate record types
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case parentCase = new Case(
                Subject = 'Test Parent Case - ICS-609',
                Status = 'New',
                RecordTypeId = insuranceClaimsRTId
        );
        insert parentCase;

        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Case childCase = new Case(
                Subject = 'Test Child Case - ICS-609',
                Status = 'Assessment',
                RecordTypeId = insuranceClaimsAssessmentRTId,
                ParentId = parentCase.Id
        );
        insert childCase;

        // Arrange: Create a map to represent the old state of the cases
        Map<Id, Case> oldCaseMap = new Map<Id, Case>{
                parentCase.Id => parentCase.clone()
        }; // Clone the case to simulate the old state

        // Act: Attempt to close the parent case, which should fail due to open child case
        Test.startTest();
        parentCase.Status = 'Closed';
        Database.SaveResult saveResult = Database.update(parentCase, false);
        Test.stopTest();

        // Assert: Ensure that the update operation failed
        System.assert(!saveResult.isSuccess(), 'Update should not have been successful because child cases are not closed.');

        // Assert: Ensure the error message is correct
        String expectedErrorMessage = 'Please update the child case(s) to Status Finalised or Closed, where applicable. This case will be closed automatically once all child cases have been Finalised or Closed.';
        System.assertEquals(expectedErrorMessage, saveResult.getErrors()[0].getMessage(), 'Expected error message should match the actual one.');

        // Assert: Optionally, confirm that the parent case status did not change by re-querying from the database
        parentCase = [SELECT Status FROM Case WHERE Id = :parentCase.Id];
        System.assertNotEquals('Closed', parentCase.Status, 'Parent case should not have been closed.');
    }

    @isTest
    static void test_call_IC_API_PolicyServiceQueueable() {

        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        Account a = new Account(
                LastName = 'Test Case - ICS-426',
                CIF_Number__c = '123456',
                RecordTypeId = personAccountRTId
        );
        insert a;

        // Create test data
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case testCase = new Case(
                AccountId = a.Id,
                IC_Data_Wash_Service__c = true,
                Event_Date__c = Date.today(),
                IC_Type__c = 'Death',
                Product_Type__c = 'Funeral',
                Sub_Type__c = 'Natural',
                Last_Working_Date__c = Date.today(),
                RecordTypeId = insuranceClaimsRTId,
                Origin = 'Data Wash'

        );
        insert testCase;

        // Call the method under test
        Test.startTest();
        Capitec_CaseICS.call_IC_API_PolicyServiceQueueable(new List<Case>{
                testCase
        });
        Test.stopTest();

        // Assert that the job has been enqueued
        System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = 'IC_API_PolicyServiceQueueable'], 'Expected one job to be enqueued');
    }
}