/**
 * Created by Kevin on 20.05.2024
 * Updated by Kevin on 09.01.2025: CEDT-2892
 */

@isTest(seeAllData=false)
public class FlowEmailComposerCtrlTest {

    @TestSetup
    static void setupTestData() {
        // Create a test case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Email'
        );
        insert testCase;

        // Create a test content document and attach it to the case
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        insert cv;

        // Create an email message related to the test case
        EmailMessage emailMessage = new EmailMessage(
            Subject = 'Test Email Subject',
            FromAddress = 'test@gmail.com',
            ToAddress = 'recipient@gmail.com',
            Status = '3',
            RelatedToId = testCase.Id, // Use the case's ID as the RelatedToId
            HtmlBody = 'This is the body of the test email.'
        );
        insert emailMessage;

        // Create an attachment related to the email message
        Attachment attachment = new Attachment(
            ParentId = emailMessage.Id,
            Name = 'TestAttachment.pdf',
            Body = Blob.valueOf('Test Attachment Content')
        );
        insert attachment;
    }

    static testmethod void testGetEmailTemplates() {
        // Query for an existing folder for email templates
        Folder templateFolder = [SELECT Id FROM Folder WHERE Type = 'Email' LIMIT 1];

        // Create a test email template
        EmailTemplate e = new EmailTemplate(
            DeveloperName = 'test_template',
            FolderId = templateFolder.Id,
            TemplateType = 'custom',
            Name = 'Test Email Template',
            Subject = 'Test Email Subject',
            Body = 'This is a test email template body.'
        );
        insert e;

        List<EmailTemplate> emailTemplateList = FlowEmailComposerCtrl.getEmailTemplates();
        System.assert(emailTemplateList.size() > 0, 'Should retrieve at least one email template.');

        // Validate template details
        FlowEmailComposerCtrl.EmailMsg templateDetails = FlowEmailComposerCtrl.getTemplateDetails(e.Id, null, null);
        System.assert(templateDetails != null, 'Template details should not be null.');
    }

    static testmethod void testDeleteFiles() {
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion];

        // Assert that the ContentVersion was created
        System.assertEquals(1, cvList.size(), 'One ContentVersion should be created.');

        // Call the deleteFiles method
        FlowEmailComposerCtrl.deleteFiles(cvList[0].ContentDocumentId);

        // Assert that the ContentDocument has been deleted
        Integer count = [SELECT COUNT() FROM ContentDocument WHERE Id = :cvList[0].ContentDocumentId];
        System.assertEquals(0, count, 'Content Document should be deleted.');
    }

    static testmethod void testSendEmail() {
        // Retrieve the test data created in the @TestSetup method
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion];
        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage LIMIT 1];

        // Ensure we have a ContentVersion and EmailMessage to work with
        System.assertEquals(1, cvList.size(), 'One ContentVersion should be available.');
        System.assertEquals(1, emailMessages.size(), 'One EmailMessage should be available.');

        Test.startTest();
        FlowEmailComposerCtrl.sendAnEmailMsg(
            'test@gmail.com',
            'recipient@gmail.com',
            'cc@gmail.com',
            'bcc@gmail.com',
            'Test Email Subject',
            null, // WhoId is null in this case
            testCase.Id, // WhatId is the case ID
            'This is the body of the test email.',
            'Test Sender',
            new List<String>{cvList[0].ContentDocumentId}, // ContentDocument IDs
            null, // No additional attachment IDs
            new List<String>{emailMessages[0].Id}, // EmailMessage IDs
            true // Create activity
        );

        // Assert that an EmailMessage was created
        List<EmailMessage> emailMessagesAfter = [SELECT Id, Subject FROM EmailMessage WHERE Subject = 'Test Email Subject'];
        System.assert(emailMessagesAfter.size() > 0, 'An EmailMessage should have been created.');

        Test.stopTest();
    }

    static testmethod void testGetEmailMessages() {
        // Retrieve the test data created in the @TestSetup method
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Call the getEmailMessages method to retrieve email messages related to the case
        List<EmailMessage> emailMessages = FlowEmailComposerCtrl.getEmailMessages(testCase.Id);

        // Validate that at least one email message is retrieved
        System.assert(emailMessages.size() > 0, 'At least one EmailMessage should be retrieved.');
        System.assertEquals('Test Email Subject', emailMessages[0].Subject, 'The email subject should match.');
    }
}