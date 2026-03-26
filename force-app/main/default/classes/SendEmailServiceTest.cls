/**
 * @name SendEmailServiceTest
 * @description
 * Unit tests for SendEmailService class.
 * Covers platform event publishing, client ID linking via Case & Account, and exception handling.
 *
 * @see SendEmailService
 * @see Email_Event__e
 * @see EmailMessage
 * @see ContentDocumentLink
 * @see ContentVersion
 * @see Account
 * @see Case
 * @see EventBus
 */
@IsTest
private class SendEmailServiceTest {

    /**
     * @description CC email address used in test data.
     * @see EmailMessage
     */
    private static final String CC_ADDRESS = 'test@test.com';

    /**
     * @description BCC email address used in test data.
     * @see EmailMessage
     */
    private static final String BCC_ADDRESS = 'test2@test.com';

    /**
     * @description TO email address used in test data.
     * @see EmailMessage
     */
    private static final String TO_ADDRESS = 'test3@test.com';

    /**
     * @description Headers value used in test data.
     * @see EmailMessage
     */
    private static final String HEADERS = 'headers';

    /**
     * @description Subject line used in test data.
     * @see EmailMessage
     */
    private static final String SUBJECT = 'subject';

    /**
     * @description HTML body content used in test data.
     * @see EmailMessage
     */
    private static final String HTML_BODY = 'body';

    /**
     * @description Valid Origin__c value used to trigger event publishing.
     * @see SendEmailService.ALLOWED_EMAIL_ORIGINS
     */
    private static final String ORIGIN = 'Attestation';

    /**
     * @description Client identity number used for Account test data.
     * @see Account.Identity_Number__c
     */
    private static final String CLIENT_ID = '1234567891234';

    /**
     * @description Invalid Origin__c value used to verify filtering behavior.
     * @see SendEmailService.ALLOWED_EMAIL_ORIGINS
     */
    private static final String INVALID_ORIGIN = 'InvalidOrigin';

    /**
     * @description
     * Tests successful platform event publishing for EmailMessage without client ID (no linked Case).
     *
     * @see SendEmailService.publishEmailMessageEvent
     * @see Email_Event__e
     */
    @IsTest
    private static void shouldSendPlatformEvent() {
        EmailMessage email = (EmailMessage) insertEmailMessage(null);

        Test.startTest();

        SendEmailService.publishEmailMessageEvent(new List<SObject>{
                email
        });

        Test.stopTest();

        System.assertEquals(1, SendEmailService.publishedEvents.size(), 'Expected one published event');
        Email_Event__e emailEvent = SendEmailService.publishedEvents[0];
        System.assertEquals(TO_ADDRESS, emailEvent.ToAddress__c);
        System.assertEquals(CC_ADDRESS, emailEvent.CcAddress__c);
        System.assertEquals(BCC_ADDRESS, emailEvent.BccAddress__c);
        System.assertEquals(HEADERS, emailEvent.Headers__c);
        System.assertEquals(HTML_BODY, emailEvent.HtmlBody__c);
        System.assertEquals(SUBJECT, emailEvent.Subject__c);
        System.assertEquals(ORIGIN, emailEvent.Origin__c);
        System.assertEquals(null, emailEvent.ClientId__c, 'Client ID should be null when no case is linked');
    }

    /**
     * @description
     * Tests platform event publishing when a client ID is linked via Case → Account.
     *
     * @see SendEmailService.publishEmailMessageEvent
     * @see Email_Event__e
     * @see Case
     * @see Account
     */
    @IsTest
    private static void shouldSendPlatformEventWithClientId() {
        Id caseId = insertCaseWithAccount();
        EmailMessage email = (EmailMessage) insertEmailMessage(caseId);

        Test.startTest();

        SendEmailService.publishEmailMessageEvent(new List<SObject>{
                email
        });

        Test.stopTest();

        System.assertEquals(1, SendEmailService.publishedEvents.size());
        Email_Event__e emailEvent = SendEmailService.publishedEvents[0];
        System.assertEquals(CLIENT_ID, emailEvent.ClientId__c, 'Client ID should be populated from Account');
    }

    /**
     * @description
     * Tests that emails with invalid origins are filtered out.
     *
     * @see SendEmailService.publishEmailMessageEvent
     */
    @IsTest
    private static void shouldNotPublishEventForInvalidOrigin() {
        EmailMessage email = (EmailMessage) insertEmailMessage(null);
        email.Origin__c = INVALID_ORIGIN;

        Test.startTest();

        SendEmailService.publishEmailMessageEvent(new List<SObject>{
                email
        });

        Test.stopTest();

        System.assertEquals(0, SendEmailService.publishedEvents.size(), 'No events should be published for invalid origin');
    }

    /**
     * @description
     * Tests attachments are properly included in the event.
     *
     * @see SendEmailService.publishEmailMessageEvent
     * @see ContentVersion
     * @see ContentDocumentLink
     */
    @IsTest
    private static void shouldIncludeAttachmentLinks() {
        EmailMessage email = (EmailMessage) insertEmailMessage(null);

        // Create test attachment
        ContentVersion cv = new ContentVersion(
                Title = 'Test',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
        );
        insert cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId = email.Id,
                ContentDocumentId = cv.ContentDocumentId,
                ShareType = 'V'
        );
        insert cdl;

        Test.startTest();

        SendEmailService.publishEmailMessageEvent(new List<SObject>{
                email
        });

        Test.stopTest();

        System.assertEquals(1, SendEmailService.publishedEvents.size());
        Email_Event__e emailEvent = SendEmailService.publishedEvents[0];
        System.assertEquals(true, emailEvent.HasAttachment__c);
        ContentDocumentLink contentDocumentLink = [SELECT Id, LinkedEntityId, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE LinkedEntityId = :email.Id];
        System.assert(emailEvent.AttachmentLinks__c.contains(contentDocumentLink.ContentDocument.LatestPublishedVersionId), 'Attachment Ids should be present');
    }

    /**
     * @description
     * Simulates a failure in EventBus.publish() and asserts that EventPublishException is thrown.
     *
     * @see SendEmailService.EventPublishException
     * @see SendEmailService.publishEmailMessageEvent
     * @see EventBus
     */
    @IsTest
    private static void shouldThrowExceptionWhenPublishFails() {
        // Create test data
        EmailMessage email = (EmailMessage) insertEmailMessage(null);

        // Mock the published events list that will be processed
        SendEmailService.publishedEvents = new List<Email_Event__e>{
                new Email_Event__e(Subject__c = 'Test')
        };

        // Create a mock failure response
        List<Database.SaveResult> mockResults = new List<Database.SaveResult>();
        Database.SaveResult mockFailure = (Database.SaveResult) JSON.deserialize(
                '{"success":false,"errors":[{"message":"Test error","statusCode":"INVALID_OPERATION"}]}',
                Database.SaveResult.class
        );
        mockResults.add(mockFailure);

        // Mock the EventBus.publish call
        SendEmailService.mockedPublishResults = mockResults;

        Test.startTest();

        Boolean exceptionThrown = false;
        try {
            // This will use our mocked publish results
            SendEmailService.publishEmailMessageEvent(new List<SObject>{
                    email
            });
        } catch (SendEmailService.EventPublishException ex) {
            exceptionThrown = true;
            System.assert(ex.getMessage().contains('Platform event publish failed'),
                    'Exception message should indicate publish failure');
        }

        Test.stopTest();

        System.assert(exceptionThrown, 'Expected EventPublishException to be thrown');
    }

    /**
     * @description
     * Creates a test Case with an Account having a client identity number.
     *
     * @return Id of the inserted Case record.
     * @see Case
     * @see Account
     */
    private static Id insertCaseWithAccount() {
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
        Account acc = (Account) TestDataFactory.createSObject('Account', new Map<String, Object>{
                'Identity_Number__c' => CLIENT_ID
        });

        Case testCase = (Case) TestDataFactory.createSObject('Case', new Map<String, Object>{
                'AccountId' => acc.Id,
                'BusinessHoursId' => bh.Id
        });
        return testCase.Id;
    }

    /**
     * @description
     * Creates a test EmailMessage SObject with optional parent Case Id.
     *
     * @param parentId Id of the Case to relate the EmailMessage to, or null.
     * @return EmailMessage SObject.
     * @see EmailMessage
     */
    private static SObject insertEmailMessage(Id parentId) {
        return TestDataFactory.createSObject('EmailMessage', new Map<String, Object>{
                'BccAddress' => BCC_ADDRESS,
                'CcAddress' => CC_ADDRESS,
                'Headers' => HEADERS,
                'HtmlBody' => HTML_BODY,
                'Subject' => SUBJECT,
                'ToAddress' => TO_ADDRESS,
                'Origin__c' => ORIGIN,
                'ParentId' => parentId,
                'Incoming' => true,
                'Status' => '0'
        });
    }
}