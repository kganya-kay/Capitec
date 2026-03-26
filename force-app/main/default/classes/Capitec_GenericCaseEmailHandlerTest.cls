@IsTest(SeeAllData=false)
private class Capitec_GenericCaseEmailHandlerTest {

    @TestSetup
    static void setupTestData() {
        // Create test data for Case, Contact, and Org-Wide Email Address
        Case testCase = new Case(Subject = 'Test Case', Status = 'New');
        insert testCase;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'User', Email = 'testuser@example.com');
        insert testContact;
    }

    @IsTest
    static void testHandleInboundEmail() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Arrange
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'attachments@example.com';
        email.fromName = 'Attachment User';
        email.subject = 'Attachment Subject ' + EmailMessages.getFormattedThreadingToken(testCase.Id);
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
        envelope.fromAddress = 'attachments@example.com';
        envelope.toAddress = 'inbound@example.com; test@gmail.com';

        // Act
        Capitec_GenericCaseEmailHandler handler = new Capitec_GenericCaseEmailHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);

        // Assert
        System.assertNotEquals(null, result, 'Expected result from handling inbound email');
    }

    @IsTest
    static void testProcessInboundEmail() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Arrange
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'attachments@example.com';
        email.fromName = 'Attachment User';
        email.subject = 'Attachment Subject ' + EmailMessages.getFormattedThreadingToken(testCase.Id);
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
        envelope.fromAddress = 'attachments@example.com';
        envelope.toAddress = 'inbound@example.com; test@gmail.com';

        // Act
        Capitec_GenericCaseEmailHandler handler = new Capitec_GenericCaseEmailHandler();
        Messaging.InboundEmailResult result = handler.processInboundEmail(email, envelope);

        // Assert
        System.assertNotEquals(null, result, 'Expected result from processing inbound email');
    }

    @IsTest
    static void testCreateEmailMessage() {
        // Arrange
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'sender@example.com';
        email.fromName = 'Sender Name';
        email.subject = 'Test Subject';
        email.plainTextBody = 'This is the body of the test email.';
        email.toAddresses = new List<String>{
                'support@capitecbank.co.za'
        };
        email.ccAddresses = new List<String>{
                'cc@example.com'
        };

        Capitec_GenericCaseEmailHandler handler = new Capitec_GenericCaseEmailHandler();

        // Act
        EmailMessage emailMessage = handler.createEmailMessage(email, testCase.Id);

        // Assert
        System.assertNotEquals(null, emailMessage.Id, 'Expected EmailMessage record to be created');
        System.assertEquals(testCase.Id, emailMessage.ParentId, 'Expected ParentId to match Case Id');
    }

    @IsTest
    static void testLogEmailAsTask() {
        // Arrange
        Case testCase = [SELECT Id, ContactId FROM Case LIMIT 1];
        EmailMessage emailMessage = new EmailMessage(
                Subject = 'Test Email Subject',
                TextBody = 'Test email body',
                ParentId = testCase.Id
        );
        insert emailMessage;

        Capitec_GenericCaseEmailHandler handler = new Capitec_GenericCaseEmailHandler();

        // Act
        handler.logEmailAsTask(emailMessage, testCase, null);

        // Assert
        Task loggedTask = [SELECT Id, Subject, Description, WhatId, WhoId FROM Task WHERE Subject = 'Test Email Subject' LIMIT 1];
        System.assertEquals('Test Email Subject', loggedTask.Subject, 'Expected task subject to match');
        System.assertEquals(testCase.Id, loggedTask.WhatId, 'Expected WhatId to match Case Id');
    }

    @IsTest
    static void testHandleAttachments() {
        // Arrange
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        EmailMessage emailMessage = new EmailMessage(ParentId = testCase.Id);
        insert emailMessage;

        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'attachments@example.com';
        email.fromName = 'Attachment User';
        email.subject = 'Attachment Subject';
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

        // Add binary attachments
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.fileName = 'binaryAttachment.txt';
        binaryAttachment.body = Blob.valueOf('This is a binary attachment.');
        email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{
                binaryAttachment
        };

        // Add text attachments
        Messaging.InboundEmail.TextAttachment textAttachment = new Messaging.InboundEmail.TextAttachment();
        textAttachment.fileName = 'textAttachment.txt';
        textAttachment.body = 'This is a text attachment.';
        email.textAttachments = new List<Messaging.InboundEmail.TextAttachment>{
                textAttachment
        };
        Test.setMock(HttpCalloutMock.class, new EmailListenerHttpResponseGenerator());

        Capitec_GenericCaseEmailHandler handler = new Capitec_GenericCaseEmailHandler();

        // Act
        handler.handleAttachments(email, emailMessage.Id, testCase.Id);

        // Assert
        List<Attachment> attachments = [SELECT Id, Name FROM Attachment WHERE ParentId = :emailMessage.Id];
        System.assertEquals(2, attachments.size(), 'Expected 2 attachments to be created');
    }

    @IsTest
    static void testSendSingleEmailUsingTemplate() {
        // Arrange
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];
        OrgWideEmailAddress orgWideEmail = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Client Escalations' LIMIT 1];
        EmailTemplate template = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'Clients_Seeking_Feedback_1730788189307' LIMIT 1];

        List<String> toAddresses = new List<String>{
                testContact.Email
        };

        // Act
        Test.startTest();

        Capitec_GenericCaseEmailHandler.sendSingleEmailUsingTemplate(
                testContact.Id,
                testCase.Id,
                toAddresses,
                template.DeveloperName,
                true,
                orgWideEmail.DisplayName
        );

        Test.stopTest();

        // Assert
        // Since sending emails can't be asserted directly, we assume no exceptions means success
        System.assert(true, 'Email sent without exceptions');
    }

    @IsTest
    static void testFromAddressCheck() {
        // Arrange
        String fromAddress1 = 'support@capitecbank.co.za';
        String fromAddress2 = 'user@example.com';

        // Act & Assert
        System.assertEquals(true, Capitec_GenericCaseEmailHandler.FromAddressCheck(fromAddress1), 'Expected to return true for Capitec address');
        System.assertEquals(false, Capitec_GenericCaseEmailHandler.FromAddressCheck(fromAddress2), 'Expected to return false for non-Capitec address');
    }

    @IsTest
    static void testCCAddressCheck() {
        // Arrange
        List<String> ccAddresses = new List<String>{
                'cc1@example.com',
                'cc2@example.com',
                'cc3@example.com'
        };

        Capitec_GenericCaseEmailHandler handler = new Capitec_GenericCaseEmailHandler();

        // Act
        String result = handler.CCAddressCheck(ccAddresses);

        // Assert
        System.assertEquals('cc1@example.com; cc2@example.com; cc3@example.com', result, 'Expected CC addresses to be joined with semicolons');
    }

    @IsTest
    static void testGetCaseIdFromEmailMessage() {
        // Arrange
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Arrange
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'attachments@example.com';
        email.fromName = 'Attachment User';
        email.subject = 'Attachment Subject ' + EmailMessages.getFormattedThreadingToken(testCase.Id);
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
        envelope.fromAddress = 'attachments@example.com';
        envelope.toAddress = 'inbound@example.com; test@gmail.com';

        // Act
        Id caseId = Capitec_GenericCaseEmailHandler.getCaseIdFromEmailMessage(email);

        // Assert
        System.assertNotEquals(null, caseId, 'Expected case ID to be extracted from email');
    }

    @IsTest
    static void testGetCaseNumberFromEmailMessage() {
        // Arrange
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Case 12345678';
        email.plainTextBody = 'Case details';

        // Act
        String caseNumber = Capitec_GenericCaseEmailHandler.getCaseNumberFromEmailMessage(email);

        // Assert
        System.assertEquals('12345678', caseNumber, 'Expected case number to be extracted from email');
    }

    @IsTest
    static void testGetSTrackIncidentNumberFromEmailMessage() {
        // Arrange
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Incident 123456789';
        email.plainTextBody = 'Incident details';

        // Act
        String incidentNumber = Capitec_GenericCaseEmailHandler.getSTrackIncidentNumberFromEmailMessage(email);

        // Assert
        System.assertEquals('123456789', incidentNumber, 'Expected STrack incident number to be extracted from email');
    }

    @IsTest
    static void testFindFirstMatch() {
        // Arrange
        String inputText = 'Case 12345678';
        String regexPattern = '\\b\\d{8,8}\\b';

        // Act
        String match = Capitec_GenericCaseEmailHandler.findFirstMatch(inputText, regexPattern);

        // Assert
        System.assertEquals('12345678', match, 'Expected to find the first match for the given regex pattern');
    }

    public class EmailListenerHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('200');
            res.setBody('{"fileContent":"fakeFileContent"}'); // Simulate successful response
            res.setStatusCode(200);
            return res;
        }
    }
}