@IsTest
public class capitec_ConManGetImageTest {

     @TestSetup
    static void setupTestData() {
        // Create Account and Case records
        Account testAccount = new Account(Name = 'Test Account', CIF_Number__c = '903422347');
        insert testAccount;
        
        Case testCase = new Case(AccountId = testAccount.Id, Status = 'New', capitec_Employee_Code__c = 'CT556777');
        insert testCase;
    }
    @IsTest
    static void testPostRequest() {

        Case testCase = [SELECT Id, CIF_Number__c, capitec_Employee_Code__c FROM Case LIMIT 1];

        // Set the mock callout
        Test.setMock(HttpCalloutMock.class, new capitec_ConManGetDocumentMock());

        String cifValue = testCase.CIF_Number__c;
        String caseId = testCase.Id;

        Test.startTest();
        List<capitec_ConManGetImage.ResponseOutput> responseList = capitec_ConManGetImage.postRequest(cifValue, caseId);


        Test.stopTest();

        System.debug('responseList '+responseList);

        // Verify that the response is not null and has the expected size
        System.assertNotEquals(null, responseList, 'Response should not be null');
        System.assertEquals(1, responseList.size(), 'Response list should contain one item');

        capitec_ConManGetImage.ResponseOutput response = responseList[0];

        // Verify response status code
       System.assertEquals(200, response.statusCode, 'Expected status code 200');

        // Verify response body
       System.assertNotEquals(null, response.responseBody, 'Response body should not be null');

    }
        @IsTest
      static void testPostRequestError() {


        // Set the mock callout
        Test.setMock(HttpCalloutMock.class, new capitec_ConManGetDocumentMock.failedResponse());

        String cifValue = null;
        String caseId = null;

        Test.startTest();
        List<capitec_ConManGetImage.ResponseOutput> responseList = capitec_ConManGetImage.postRequest(cifValue, caseId);


        Test.stopTest();

        System.debug('responseList '+responseList);


        // Verify response status code
       System.assertEquals(500, responseList[0].statusCode, 'Expected status code 500');


    }
    @IsTest
    static void testProcessFile() {

        Case testCase = [SELECT Id, CIF_Number__c, capitec_Employee_Code__c FROM Case LIMIT 1];

        // Set the mock callout
        Test.setMock(HttpCalloutMock.class, new capitec_ConManGetImageMock());

        String documentId = '46503164-dd26-4c54-91e6-4a54a99f4329';
        String caseId = testCase.Id;

        Test.startTest();
        Map<String,String>  response = capitec_ConManGetImage.processFile(documentId, caseId, 'png');


        Test.stopTest();

        System.debug('response '+response);

        // Verify that the response is not null and has the expected size
        System.assertNotEquals(null, response, 'Response should not be null');

        
        
    }
    @isTest
    static void testPostRequestSuccess() {
        // Set mock HTTP response
        Test.setMock(HttpCalloutMock.class, new capitec_ConManGetDocumentMock());

        
        // Test inputs
        String testCifValue = 'testCif';
        String testCaseId = '12345';
        
        // Execute the method
        Test.startTest();
        List<capitec_ConManGetImage.ResponseOutput> outputs = capitec_ConManGetImage.postRequest(testCifValue, testCaseId);
        Test.stopTest();
        
        // Verify outputs
        System.assertNotEquals(null, outputs);
        System.assertEquals(1, outputs.size());
        
        capitec_ConManGetImage.ResponseOutput output = outputs[0];
        System.assertEquals(200, output.statusCode);
        
        // Verify document details
        System.assertNotEquals(null, output.documents);
        System.assertEquals(1, output.documents.size());
        System.assertEquals('86e22c17-0ba1-47f7-9c1c-c474d3b777ea', output.documents[0].documentId);
        System.assertEquals('Identification Document', output.documents[0].documentName);
    }
}