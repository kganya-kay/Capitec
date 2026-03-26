@isTest
public class IC_API_DocumentDownloadService_Test {
    
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
        
        DocumentChecklistItem dci = new DocumentChecklistItem(
            Name='Test',
            ParentRecordId = cs.Id
        );
        insert dci;
    }

    @isTest
    static void testEnqueJob() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, 
                '{"author":"Test Author","channel":"Test Channel","client":{"cifNumber":"CIF123","idNumber":"ID123"},"contentType":"application/pdf","documentId":"12345","documentLocation":"Test Location","documentSubType":"Test SubType","documentType":"Test Type","keys":[{"caseNumber":"12345","caseId":"67890"}],"metaData":{"title":"Test Document","fileType":"PDF","fileExtension":"pdf"},"modifiedDateTime":"2024-06-25T12:34:56Z","documentContent":"VGVzdCBjb250ZW50"}'
        ));
        List<IC_API_DocumentDownloadServiceQueueable.FlowRequest> requests = new List<IC_API_DocumentDownloadServiceQueueable.FlowRequest>();

        IC_API_DocumentDownloadServiceQueueable.FlowRequest request = new IC_API_DocumentDownloadServiceQueueable.FlowRequest();
        request.caseId = [SELECT Id FROM Case LIMIT 1].Id;
        request.externalContentDocumentId = '12345';
        request.documentChecklistItemId = [SELECT Id FROM DocumentChecklistItem LIMIT 1].Id;
        request.expiryDate = Date.today().addDays(1);
        request.notify = true;
        requests.add(request);

        Test.startTest();
        List<Id> jobIds = IC_API_DocumentDownloadServiceQueueable.enqueJob(requests);
        Test.stopTest();

        System.assertNotEquals(0, jobIds.size(), 'Job ID should not be empty.');
        DocumentChecklistItem dci = [SELECT IC_ContentDocumentId__c FROM DocumentChecklistItem WHERE Id = :request.documentChecklistItemId];
        System.assertNotEquals(null, dci.IC_ContentDocumentId__c, 'Content Document ID should be updated.');

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