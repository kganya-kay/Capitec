/**
 * Created by Johan Langenhoven on 2024/11/06.
 */
@IsTest(SeeAllData=false)
private class Capitec_ClientEscalationCaseEHTest {
    @TestSetup
    static void setupTestData() {
        Account account = new Account();

        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        account.CIF_Number__c = '123456789';
        account.Identity_Number__c = '7101180046087';
        account.FirstName = 'Test';
        account.LastName = 'User';
        account.PersonEmail = 'testuser@example.com';

        insert account;

        // Create test data for Case, Contact, and Org-Wide Email Address
        Case testCase = new Case
                (
                        Subject = 'Test Case',
                        Status = 'New',
                        AccountId = account.Id,
                        ContactId = account.PersonContactId,
                        Strack_Incident_Number__c = '123456789'
                );

        insert testCase;
    }

    @IsTest
    static void testProcessInboundEmailWithOpenCase() {
        Account account = [SELECT Id, PersonContactId, PersonEmail FROM Account LIMIT 1];
        Case testCase = [SELECT Id, Subject, CaseNumber, Status, AccountId, ContactId, ContactEmail FROM Case LIMIT 1];
        testCase.ContactId = account.PersonContactId;
        update testCase;

        System.debug('testCase: ' + testCase);

        // Arrange
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = testCase.ContactEmail;
        email.subject = 'Case ' + testCase.CaseNumber;
        email.plainTextBody = 'This email has attachments.';
        email.headers = new List<Messaging.InboundEmail.Header>();
        email.htmlBody = '<p>This email has attachments.</p>';
        email.messageId = 'attachmentMessageId';
        email.inReplyTo = 'attachmentReplyTo@example.com';
        email.replyTo = 'attachmentReplyTo@example.com';
        email.headers = new List<Messaging.InboundEmail.Header>();
        email.toAddresses = new List<String>();
        email.toAddresses.add('recipient1@example.com');
        email.toAddresses.add('recipient2@example.com');
        email.toAddresses.add('recipient3@example.com');
        email.ccAddresses = new List<String>();
        email.ccAddresses.add('ccrecipient1@example.com');
        email.ccAddresses.add('ccrecipient2@example.com');
        email.ccAddresses.add('ccrecipient3@example.com');

        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Date';
        header.value = 'Thu, 14 Jun 2024 12:34:56 -0700';
        email.headers.add(header);

        // Create a test Messaging.InboundEnvelope object
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = testCase.ContactEmail;
        envelope.toAddress = 'inbound@example.com';

        // Act
        Capitec_ClientEscalationCaseEmailHandler handler = new Capitec_ClientEscalationCaseEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);

        // Assert
        System.assertNotEquals(null, result, 'Expected result from processing inbound email with open case');
    }

    @IsTest
    static void testProcessInboundEmailWithClosedCase() {
        Account account = [SELECT Id, PersonContactId, PersonEmail FROM Account LIMIT 1];

        Case testCase = new Case(Subject = 'Test Case', Status = 'Closed', AccountId = account.Id, ContactId = account.PersonContactId);
        insert testCase;

        // Arrange
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = testCase.ContactEmail;
        email.subject = 'Case ' + EmailMessages.getFormattedThreadingToken(testCase.Id);
        email.plainTextBody = 'This email has attachments.';
        email.headers = new List<Messaging.InboundEmail.Header>();
        email.htmlBody = '<p>This email has attachments.</p>';
        email.messageId = 'attachmentMessageId';
        email.inReplyTo = 'attachmentReplyTo@example.com';
        email.replyTo = 'attachmentReplyTo@example.com';
        email.headers = new List<Messaging.InboundEmail.Header>();
        email.toAddresses = new List<String>();
        email.toAddresses.add('recipient1@example.com');
        email.toAddresses.add('recipient2@example.com');
        email.toAddresses.add('recipient3@example.com');
        email.ccAddresses = new List<String>();
        email.ccAddresses.add('ccrecipient1@example.com');
        email.ccAddresses.add('ccrecipient2@example.com');
        email.ccAddresses.add('ccrecipient3@example.com');

        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Date';
        header.value = 'Thu, 14 Jun 2024 12:34:56 -0700';
        email.headers.add(header);

        // Create a test Messaging.InboundEnvelope object
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = testCase.ContactEmail;
        envelope.toAddress = 'inbound@example.com';

        // Act
        Capitec_ClientEscalationCaseEmailHandler handler = new Capitec_ClientEscalationCaseEmailHandler();
        Messaging.InboundEmailResult result = handler.processInboundEmail(email, envelope);

        // Assert
        System.assertNotEquals(null, result, 'Expected result from processing inbound email with closed case');
    }

    @IsTest
    static void testProcessInboundEmailWithAwaitingClientFeedback() {
        Account account = [SELECT Id, PersonContactId, PersonEmail FROM Account LIMIT 1];

        Case testCase = new Case(Subject = 'Test Case', Status = 'Awaiting Client feedback', AccountId = account.Id, ContactId = account.PersonContactId, Strack_Incident_Number__c = '123456780');
        insert testCase;

        // Arrange
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'attachments@example.com';
        email.fromName = 'Attachment User';
        email.subject = 'Attachment Subject ' + testCase.Strack_Incident_Number__c;
        email.plainTextBody = 'This email has attachments.';
        email.htmlBody = '<p>This email has attachments.</p>';
        email.messageId = 'attachmentMessageId';
        email.inReplyTo = 'attachmentReplyTo@example.com';
        email.replyTo = 'attachmentReplyTo@example.com';
        email.headers = new List<Messaging.InboundEmail.Header>();
        email.toAddresses = new List<String>();
        email.toAddresses.add('recipient1@example.com');
        email.toAddresses.add('recipient2@example.com');
        email.toAddresses.add('recipient3@example.com');
        email.ccAddresses = new List<String>();
        email.ccAddresses.add('ccrecipient1@example.com');
        email.ccAddresses.add('ccrecipient2@example.com');
        email.ccAddresses.add('ccrecipient3@example.com');
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Date';
        header.value = 'Thu, 14 Jun 2024 12:34:56 -0700';
        email.headers.add(header);

        // Create a test Messaging.InboundEnvelope object
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = testCase.ContactEmail;
        envelope.toAddress = 'inbound@example.com';

        // Act
        Capitec_ClientEscalationCaseEmailHandler handler = new Capitec_ClientEscalationCaseEmailHandler();
        Messaging.InboundEmailResult result = handler.processInboundEmail(email, envelope);

        // Assert
        System.assertNotEquals(null, result, 'Expected result from processing inbound email with awaiting client feedback case');
    }

    @IsTest
    static void testProcessInboundEmailWithNoCaseId() {
        Account account = [SELECT Id, PersonContactId, PersonEmail FROM Account LIMIT 1];

        // Arrange
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = account.PersonEmail;
        email.subject = 'No Case Id';
        email.plainTextBody = 'This email has no case id.';
        email.headers = new List<Messaging.InboundEmail.Header>();

        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Date';
        header.value = 'Thu, 14 Jun 2024 12:34:56 -0700';
        email.headers.add(header);

        // Create a test Messaging.InboundEnvelope object
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = account.PersonEmail;
        envelope.toAddress = 'inbound@example.com; test@gmail.com';

        // Act
        Capitec_ClientEscalationCaseEmailHandler handler = new Capitec_ClientEscalationCaseEmailHandler();
        Messaging.InboundEmailResult result = handler.processInboundEmail(email, envelope);

        // Assert
        System.assertNotEquals(null, result, 'Expected result from processing inbound email with no case id');
    }

    @IsTest
    static void testProcessInboundEmailWithNonCapitecFromAddress() {
        Account account = [SELECT Id, PersonContactId, PersonEmail FROM Account LIMIT 1];

        // Arrange
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = account.PersonEmail;
        email.subject = 'No Case Id';
        email.plainTextBody = 'This email has no case id.';
        email.headers = new List<Messaging.InboundEmail.Header>();

        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Date';
        header.value = 'Thu, 14 Jun 2024 12:34:56 -0700';
        email.headers.add(header);

        // Create a test Messaging.InboundEnvelope object
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = account.PersonEmail;
        envelope.toAddress = 'inbound@example.com; test@gmail.com';

        // Act
        Capitec_ClientEscalationCaseEmailHandler handler = new Capitec_ClientEscalationCaseEmailHandler();
        Messaging.InboundEmailResult result = handler.processInboundEmail(email, envelope);

        // Assert
        System.assertNotEquals(null, result, 'Expected result from processing inbound email with non-Capitec from address');
    }
}