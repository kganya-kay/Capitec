/*******************************************************************
* @Class Name        :  IC_API_ZipFileServiceQueueable_TEST
* @Author            :  Evans
* @Last Modified By  :  Evans, 17-Apr-2024, Jira Tickets:  ICS-855
* @Version           :  1.0
*
*******************************************************************/
@isTest
public class IC_API_ZipFileServiceQueueable_TEST {
    
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
    static void testZipFileServiceQueueable() {

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
        request.notify = true;
        
        // Mock callout response if your method does it
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        // Call the method to test
        List<String> results = IC_API_ZipFileServiceQueueable.enqueJob(new List<IC_API_ZipFileService.FlowRequest>{ request });
        IC_API_ZipFileServiceQueueable finalizer = new IC_API_ZipFileServiceQueueable(request);
        finalizer.execute(new MockFinalizerContext(ParentJobResult.UNHANDLED_EXCEPTION));
        Test.stopTest();
    }
    
    /** Mock FinalizerContext impl **/
    private class MockFinalizerContext implements System.FinalizerContext {
        ParentJobResult result;
        public Id getAsyncApexJobId() { // valid Id, or query one 
            return '707000000000000';
        }
        public Exception getException() { return new System.AsyncException('heap breached'); }
        public String getRequestId() { return 'someRequestId'; }
        public ParentJobResult getResult() { return this.result; }
        MockFinalizerContext (ParentJobResult mockResult) {this.result = mockResult;}
    }

}