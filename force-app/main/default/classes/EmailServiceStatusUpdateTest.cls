/**
 * @name EmailServiceStatusUpdateTest
 * @description
 * Unit test class for the EmailServiceStatusUpdate REST service.
 * Validates correct behavior for successful updates, missing required fields, and exception handling.
 *
 * @see EmailServiceStatusUpdate
 */
@IsTest
private class EmailServiceStatusUpdateTest {

    /**
     * @description
     * Sets up a valid EmailMessage record used for status update scenarios.
     */
    @TestSetup
    static void testSetup() {
        EmailMessage email = new EmailMessage(
                Subject = 'Status Update Test',
                FromAddress = 'noreply@example.com',
                ToAddress = 'user@example.com',
                Status = '3',
                Incoming = false
        );
        insert email;
    }

    /**
     * @description
     * Tests the successful status update scenario.
     * Asserts that the EmailMessage fields are updated and response wrapper is correct.
     */
    @IsTest
    static void testUpdateStatusSuccess() {
        EmailMessage original = [SELECT Id FROM EmailMessage LIMIT 1];

        EmailServiceStatusUpdate.EmailServiceStatusUpdateWrapper wrapper = new EmailServiceStatusUpdate.EmailServiceStatusUpdateWrapper();
        wrapper.emailMessageId = original.Id;
        wrapper.statusCode = 202;
        wrapper.status = 'Queued';
        wrapper.correlationId = 'abc123';
        wrapper.error = null;

        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/emailService/statusUpdate/';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(wrapper));
        RestContext.response = new RestResponse();

        Test.startTest();

        EmailServiceStatusUpdate.updateStatus();

        Test.stopTest();

        EmailMessage updated = [
                SELECT Status_Code__c, Email_Service_Status__c, Correlation_Id__c, Error_Message__c
                FROM EmailMessage
                WHERE Id = :original.Id
        ];

        System.assertEquals(202, updated.Status_Code__c);
        System.assertEquals('Queued', updated.Email_Service_Status__c);
        System.assertEquals('abc123', updated.Correlation_Id__c);
        System.assertEquals(null, updated.Error_Message__c);

        // Parse the response
        EmailServiceStatusUpdate.EmailServiceStatusUpdateResponseWrapper response =
                (EmailServiceStatusUpdate.EmailServiceStatusUpdateResponseWrapper)
                        JSON.deserialize(RestContext.response.responseBody.toString(), EmailServiceStatusUpdate.EmailServiceStatusUpdateResponseWrapper.class);

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(original.Id, response.emailMessageId);
        System.assertEquals(200, response.statusCode);
        System.assertEquals('abc123', response.correlationId);
        System.assertEquals(null, response.error);
    }

    /**
     * @description
     * Tests the behavior when the incoming payload is missing the emailMessageId.
     * Asserts that the response status is 400 and proper error message is returned.
     */
    @IsTest
    static void testMissingId() {
        EmailServiceStatusUpdate.EmailServiceStatusUpdateWrapper wrapper = new EmailServiceStatusUpdate.EmailServiceStatusUpdateWrapper();
        wrapper.emailMessageId = null;
        wrapper.statusCode = 400;
        wrapper.status = 'Bad';
        wrapper.correlationId = 'none';
        wrapper.error = 'Missing ID';

        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/emailService/statusUpdate/';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(wrapper));
        RestContext.response = new RestResponse();

        Test.startTest();

        EmailServiceStatusUpdate.updateStatus();

        Test.stopTest();

        EmailServiceStatusUpdate.EmailServiceStatusUpdateResponseWrapper response =
                (EmailServiceStatusUpdate.EmailServiceStatusUpdateResponseWrapper)
                        JSON.deserialize(RestContext.response.responseBody.toString(), EmailServiceStatusUpdate.EmailServiceStatusUpdateResponseWrapper.class);

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(null, response.emailMessageId);
        System.assertEquals(400, response.statusCode);
        System.assertEquals('none', response.correlationId);
        System.assertEquals('Missing emailMessageId.', response.error);
    }

    /**
     * @description
     * Tests that the controller properly handles unexpected exceptions (e.g., EmailMessage record not found).
     * Asserts that the response status is 500 and the error field is populated.
     */
    @IsTest
    static void testExceptionBlock() {
        EmailMessage original = [SELECT Id FROM EmailMessage LIMIT 1];
        delete original;

        EmailServiceStatusUpdate.EmailServiceStatusUpdateWrapper wrapper = new EmailServiceStatusUpdate.EmailServiceStatusUpdateWrapper();
        wrapper.emailMessageId = original.Id;
        wrapper.statusCode = 500;
        wrapper.status = 'Crashed';
        wrapper.correlationId = 'error-500';
        wrapper.error = 'Simulated failure';

        RestContext.request = new RestRequest();
        RestContext.request.requestURI = '/services/apexrest/emailService/statusUpdate/';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(wrapper));
        RestContext.response = new RestResponse();

        Test.startTest();

        EmailServiceStatusUpdate.updateStatus();

        Test.stopTest();

        EmailServiceStatusUpdate.EmailServiceStatusUpdateResponseWrapper response =
                (EmailServiceStatusUpdate.EmailServiceStatusUpdateResponseWrapper)
                        JSON.deserialize(RestContext.response.responseBody.toString(), EmailServiceStatusUpdate.EmailServiceStatusUpdateResponseWrapper.class);

        System.assertEquals(500, RestContext.response.statusCode);
        System.assertEquals(null, response.emailMessageId);
        System.assertEquals(null, response.correlationId);
    }
}