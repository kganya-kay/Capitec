@isTest
public class IC_API_DocumentUploadService_Test {
    
    @testSetup
    static void setup() {
        Id icRId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case cs = new Case(
            Subject = 'Test Case',
            Status = 'Administration',
            Sub_Status__c = 'Allocated',
            IC_Template_Description__c = 'Request Document from Client',
            IC_Document_Type_required__c= 'Certificate of Service',
            IC_Type__c = 'Unemployment/ITEI',
            Sub_Type__c = 'Retrenchment',
            Sub_Type_Reason__c = 'New Technology',
            RecordTypeId = icRId,
            Product_Type__c = 'Credit Life'
        );
        insert cs;

        ContentVersion cv = new ContentVersion(
            Title='Test Document',
            PathOnClient = 'Test Document.txt',
            VersionData=Blob.valueOf('Test Data')
        );
        insert cv;
        
        DocumentChecklistItem dci = new DocumentChecklistItem(
            Name='Test',
            ParentRecordId = cs.Id
        );
        insert dci;
    }

    @isTest
    static void testEnqueJob() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"id":"123"}'));
        
        List<IC_API_DocumentUploadServiceQueueable.FlowRequest> requests = new List<IC_API_DocumentUploadServiceQueueable.FlowRequest>();

        IC_API_DocumentUploadServiceQueueable.FlowRequest request = new IC_API_DocumentUploadServiceQueueable.FlowRequest();
        request.caseNumber = '12345';
        request.caseId = [SELECT Id FROM Case LIMIT 1].Id;
        request.cifNumber = 'CIF123';
        request.idNumber = 'ID123';
        request.contentDocumentId = [SELECT Id FROM ContentDocument LIMIT 1].Id;
        request.documentChecklistItemId = [SELECT Id FROM DocumentChecklistItem LIMIT 1].Id;
        request.notify = true;
        request.sanlamClaim = false;
        requests.add(request);

        Test.startTest();
        List<Id> jobIds = IC_API_DocumentUploadServiceQueueable.enqueJob(requests);
        Test.stopTest();

        System.assertNotEquals(0, jobIds.size(), 'Job ID should not be empty.');

        DocumentChecklistItem dci = [SELECT IC_ExternalContentDocumentId__c FROM DocumentChecklistItem WHERE Id = :request.documentChecklistItemId];
        System.assertEquals('123', dci.IC_ExternalContentDocumentId__c, 'External Content Document ID should be updated.');
    }

    private class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public MockHttpResponse(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
}