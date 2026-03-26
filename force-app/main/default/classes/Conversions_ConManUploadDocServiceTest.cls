/**
 * @description       : Test Class for Conversions_ConManUploadDocService
 * @author            : Samiirah Aujub
 * @group             : 
 * @last modified on  : 03-06-2026
 * @last modified by  : Samiirah Aujub
**/
@IsTest
private class Conversions_ConManUploadDocServiceTest {

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id":"DOC12345","hash":"ABCDEF","timestamp":"2026-03-06T10:00:00Z"}');

            System.assertEquals('POST', req.getMethod());
            System.assertEquals('application/json', req.getHeader('Content-Type'));
            System.assertEquals('SALESFORCE', req.getHeader('X-Channel-Source'));
            System.assertEquals('BASE64', req.getHeader('X-Accept-Hash-Encoding'));
            System.assertNotEquals(null, req.getHeader('X-Correlation-Id'));
            System.assertNotEquals(null, req.getHeader('X-User-Id'));
            System.assertNotEquals(null, req.getBody());

            return res;
        }
    }

    private class FailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    private class OCRMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id":"OCR123","hash":"XYZ","timestamp":"2026-03-06T10:00:00Z"}');

            System.assertEquals('true', req.getHeader('performOcr'));
            System.assertEquals('POST', req.getMethod());
            System.assertNotEquals(null, req.getBody());

            return res;
        }
    }

    private static Case createTestCase() {
        Case caseRec = new Case( Subject = 'Test Case',
                                 Status = 'New',
                                 Origin = 'Phone',
                                 CD_ClientCIFNumber__c = 'CIF123456'
                                );
        insert caseRec;
        return caseRec;
    }

    private static ContentVersion createTestContentVersion() {
        return new ContentVersion(Title = 'Test Document',
                                  PathOnClient = 'TestDocument.pdf',
                                  VersionData = Blob.valueOf('Dummy PDF content')
                                 );
    }

    @IsTest
    static void testSendDocumentSuccess() {
        Case testCase = createTestCase();
        ContentVersion cv = createTestContentVersion();

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        String documentId = Conversions_ConManUploadDocService.sendDocument(cv, testCase.Id);
        Test.stopTest();

        System.assertEquals('DOC12345', documentId);
    }

    @IsTest
    static void testSendDocumentFailure() {
        Case testCase = createTestCase();
        ContentVersion cv = createTestContentVersion();

        Test.setMock(HttpCalloutMock.class, new FailureMock());

        Test.startTest();
        String documentId = Conversions_ConManUploadDocService.sendDocument(cv, testCase.Id);
        Test.stopTest();

        System.assertEquals(null, documentId);
    }

    @IsTest
    static void testSendDocumentWithNullCaseId() {
        ContentVersion cv = createTestContentVersion();

        Test.startTest();
        String documentId = Conversions_ConManUploadDocService.sendDocument(cv, null);
        Test.stopTest();

        System.assertEquals(null, documentId);
    }

    @IsTest
    static void testPerformOCR() {
        ContentVersion cv = createTestContentVersion();

        Test.setMock(HttpCalloutMock.class, new OCRMock());

        Test.startTest();
        Conversions_ConManUploadDocService.performOCR(cv);
        Test.stopTest();

        System.assert(true, 'performOCR executed successfully');
    }

    @IsTest
    static void testGetCaseRecord() {
        Case testCase = createTestCase();

        Test.startTest();
        Case result = Conversions_ConManUploadDocService.getCaseRecord(testCase.Id);
        Test.stopTest();

        System.assertEquals(testCase.Id, result.Id);
        System.assertEquals('CIF123456', result.CD_ClientCIFNumber__c);
    }

    @IsTest
    static void testGenerateUUID() {
        Test.startTest();
        String uuid = Conversions_ConManUploadDocService.generateUUID();
        Test.stopTest();

        System.assertNotEquals(null, uuid);
        System.assertEquals(36, uuid.length());
        System.assertEquals('-', uuid.substring(8, 9));
        System.assertEquals('-', uuid.substring(13, 14));
        System.assertEquals('-', uuid.substring(18, 19));
        System.assertEquals('-', uuid.substring(23, 24));
    }
}