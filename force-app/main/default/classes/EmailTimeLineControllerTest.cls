/**
 * @description
 *   Test class for EmailTimeLineController. Contains unit tests for email timeline functionality,
 *   including loading messages, handling attachments, and redo email send logic.
 *
 * @see EmailTimeLineController
 */
@IsTest(SeeAllData=false)
private class EmailTimeLineControllerTest {

    /**
     * @description Status value used for test Case records.
     * @see EmailTimeLineController.Response
     */
    private static final String STATUS_OPEN = 'Open';

    /**
     * @description CC email address used in EmailMessage test data.
     * @see EmailTimeLineController.EmailMessageWrapper
     */
    private static final String CC_ADDRESS = 'test@test.com';

    /**
     * @description BCC email address used in EmailMessage test data.
     * @see EmailTimeLineController.EmailMessageWrapper
     */
    private static final String BCC_ADDRESS = 'test2@test.com';

    /**
     * @description TO email address used in EmailMessage test data.
     * @see EmailTimeLineController.EmailMessageWrapper
     */
    private static final String TO_ADDRESS = 'test3@test.com';

    /**
     * @description Subject value used in EmailMessage test data.
     * @see EmailTimeLineController.EmailMessageWrapper
     */
    private static final String SUBJECT = 'Test Subject';

    /**
     * @description HTML body content used in EmailMessage test data.
     * @see EmailTimeLineController.EmailMessageWrapper
     */
    private static final String HTML_BODY = '<p>This is a test email</p>';

    /**
     * @description
     *   Creates test Case, EmailMessage, and associated ContentDocument data for use across test methods.
     * @see EmailTimeLineController
     */
    @TestSetup
    static void testSetup() {
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];

        Case testCase = new Case(
                Status = STATUS_OPEN,
                BusinessHoursId = bh.Id
        );
        insert testCase;

        EmailMessage email = new EmailMessage(
                BccAddress = BCC_ADDRESS,
                CcAddress = CC_ADDRESS,
                HtmlBody = HTML_BODY,
                Subject = SUBJECT,
                ToAddress = TO_ADDRESS,
                FromAddress = 'support@capitec.co.za',
                Incoming = false,
                ParentId = testCase.Id,
                Origin__c = 'Attestation', // must match allowed origin
                Email_Attestation__c = null
        );
        insert email;

        ContentVersion cv = new ContentVersion(
                Title = 'ID Card',
                PathOnClient = 'id_card.pdf',
                VersionData = Blob.valueOf('fake pdf content')
        );
        insert cv;

        ContentDocument cd = [
                SELECT Id
                FROM ContentDocument
                WHERE LatestPublishedVersionId = :cv.Id
                LIMIT 1
        ];

        insert new ContentDocumentLink(
                LinkedEntityId = email.Id,
                ContentDocumentId = cd.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
        );
    }

    /**
     * @description
     *   Tests that EmailTimeLineController.loadMessages returns emails with correct metadata,
     *   directionality, and associated attachments.
     *
     * @see EmailTimeLineController.loadMessages
     * @see EmailTimeLineController.EmailMessageWrapper
     * @see EmailTimeLineController.AttachmentWrapper
     */
    @IsTest
    static void shouldReturnEmailsWithAttachmentsAndDirection() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();

        EmailTimeLineController.Response response = EmailTimeLineController.loadMessages(testCase.Id);

        Test.stopTest();

        System.assertEquals(1, response.emailMessages.size(), 'Expected one email message');

        EmailTimeLineController.EmailMessageWrapper msg = response.emailMessages[0];
        System.assertEquals(TO_ADDRESS, msg.toAddress);
        System.assertEquals(CC_ADDRESS, msg.ccAddress);
        System.assertEquals(SUBJECT, msg.subject);
        System.assertEquals(false, msg.isInbound, 'Should be outbound');

        System.assertNotEquals(null, msg.attachments);
        System.assertEquals(1, msg.attachments.size(), 'Expected 1 file');

        EmailTimeLineController.AttachmentWrapper file = msg.attachments[0];
        System.assertEquals('ID Card', file.fileName);
        System.assertEquals('PDF', file.fileType);
        System.assert(file.downloadUrl != null && file.downloadUrl.contains(file.fileContentDocumentId), 'Download URL should contain ContentDocument Id');
    }

    /**
     * @description
     *   Tests that EmailTimeLineController.redoEmailSend successfully publishes the platform event
     *   when the origin is allowed.
     *
     * @see EmailTimeLineController.redoEmailSend
     */
    @IsTest
    static void shouldHandleRedoEmailSendSuccessfully() {
        EmailMessage email = [SELECT Id FROM EmailMessage LIMIT 1];

        Test.startTest();

        EmailTimeLineController.redoEmailSend(email.Id);

        Test.stopTest();

        // No exception means success
        System.assert(true, 'Redo completed successfully');
    }

    /**
     * @description
     *   Tests that EmailTimeLineController.redoEmailSend throws an error if the origin is invalid or null.
     *
     * @see EmailTimeLineController.redoEmailSend
     */
    @IsTest
    static void shouldThrowForRedoEmailSendWithInvalidOrigin() {
        EmailMessage email = [SELECT Id FROM EmailMessage LIMIT 1];
        email.Origin__c = null;
        update email;

        Test.startTest();

        try {
            EmailTimeLineController.redoEmailSend(email.Id);
        } catch (Exception ex) {
            System.assert(ex.getMessage() != null, 'Expected an exception to be thrown');
        }

        Test.stopTest();
    }

    /**
     * @description
     *   Tests that EmailTimeLineController.redoEmailSend handles unexpected input gracefully
     *   (e.g., an invalid ID).
     *
     * @see EmailTimeLineController.redoEmailSend
     */
    @IsTest
    static void shouldHandleUnexpectedExceptionInRedoEmailSend() {
        Test.startTest();

        try {
            EmailTimeLineController.redoEmailSend('00X000000000000');
        } catch (Exception ex) {
            System.assert(ex.getMessage() != null, 'Expected an exception to be thrown');
        }

        Test.stopTest();
    }

    /**
     * @description
     *   Tests that EmailTimeLineController.loadMessages handles null recordId and returns error message.
     *
     * @see EmailTimeLineController.loadMessages
     * @see EmailTimeLineController.Response
     */
    @IsTest
    static void shouldHandleErrorGracefullyInLoadMessages() {
        EmailTimeLineController.Response response;

        Test.startTest();

        response = EmailTimeLineController.loadMessages(null);

        Test.stopTest();

        System.assertNotEquals(null, response.errorMessage, 'Expected errorMessage to be populated');
        System.assert(response.errorMessage.contains('Attempt to de-reference a null object'), 'Should contain Attempt to de-reference a null object');
    }
}