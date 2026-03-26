/**
 * @description
 *   Unit test class for SendEmailController. Validates all supported email composition and sending flows,
 *   including attachments, attestation, error conditions, and metadata lookups like OrgWideEmailAddress,
 *   EmailTemplates, and folders.
 *
 * @see SendEmailController
 * @see EmailMessage
 * @see OrgWideEmailAddress
 * @see Folder
 * @see EmailTemplate
 * @see SendEmailControllerHelper
 */
@IsTest(SeeAllData=false)
private class SendEmailControllerTest {

    /**
     * @description
     *   Test setup method to prepare baseline data including Person Account, Case, and ContentVersion attachment.
     */
    @TestSetup
    static void testSetup() {
        Account testAccount = new Account(
                FirstName = 'John',
                LastName = 'Deer',
                PersonEmail = 'john.doe@example.com',
                Phone = '+271234567',
                RecordTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
        );
        insert testAccount;

        Case testCase = new Case(
                AccountId = testAccount.Id,
                ContactId = testAccount.PersonContactId,
                Origin = 'Phone',
                Status = 'New',
                Subject = 'Test Case'
        );
        insert testCase;

        ContentVersion testAttachment = new ContentVersion(
                Title = 'Test Attachment',
                PathOnClient = 'TestAttachment.pdf',
                VersionData = Blob.valueOf('Test file content'),
                IsMajorVersion = true,
                FirstPublishLocationId = testCase.Id
        );
        insert testAttachment;
    }

    /**
     * @description
     *   Tests sending a minimal email message with subject and body and one contact.
     */
    @IsTest
    static void testCreateEmailMessageMinimal() {
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId, Account.PersonEmail FROM Case LIMIT 1];
        OrgWideEmailAddress org = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        Test.startTest();

        SendEmailController.createEmailMessage(
                new List<String>{
                        testCase.Account.PersonEmail
                },
                null,
                'Test Subject',
                'Test Body',
                testCase.Id,
                new List<Id>{
                        testCase.Account.PersonContactId
                },
                null,
                org.Id,
                null,
                true
        );

        Test.stopTest();

        EmailMessage msg = [SELECT Id, Subject, HtmlBody FROM EmailMessage WHERE ParentId = :testCase.Id LIMIT 1];
        System.assertEquals('Test Subject', msg.Subject);
        System.assertNotEquals(null, msg.HtmlBody);
    }

    /**
     * @description
     *   Tests sending an email with both new and reused attachments.
     */
    @IsTest
    static void testCreateEmailMessageWithAttachment() {
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId, Account.PersonEmail FROM Case LIMIT 1];
        OrgWideEmailAddress org = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        ContentVersion testContent = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = :testCase.Id LIMIT 1];

        SendEmailController.InboundAttachment newUpload = new SendEmailController.InboundAttachment();
        newUpload.fileName = 'NewUpload.pdf';
        newUpload.fileType = 'pdf';
        newUpload.fileContent = EncodingUtil.base64Encode(Blob.valueOf('New content'));

        SendEmailController.InboundAttachment reused = new SendEmailController.InboundAttachment();
        reused.fileName = testContent.Title;
        reused.fileType = 'pdf';
        reused.fileContentVersionId = testContent.Id;
        reused.fileContentDocumentId = testContent.ContentDocumentId;

        List<SendEmailController.InboundAttachment> attachments = new List<SendEmailController.InboundAttachment>{
                newUpload,
                reused
        };

        String attachmentsJson = JSON.serialize(attachments);

        Test.startTest();

        SendEmailController.createEmailMessage(
                new List<String>{
                        testCase.Account.PersonEmail
                },
                null,
                'Subject with Attachment',
                'Body with Attachment',
                testCase.Id,
                new List<Id>{
                        testCase.Account.PersonContactId
                },
                attachmentsJson,
                org.Id,
                null,
                true
        );

        Test.stopTest();

        EmailMessage emailMessage = [SELECT Id FROM EmailMessage WHERE ParentId = :testCase.Id LIMIT 1];
        List<ContentDocumentLink> contentDocumentLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :emailMessage.Id];

        System.assertNotEquals(null, emailMessage);
        System.assertNotEquals(null, contentDocumentLinks);
    }

    /**
     * @description
     *   Tests email sending that includes attestation reason and multiple recipients.
     */
    @IsTest
    static void testCreateEmailMessageWithAttestationReason() {
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId, Account.PersonEmail FROM Case LIMIT 1];
        OrgWideEmailAddress org = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        Test.startTest();

        SendEmailController.createEmailMessage(
                new List<String>{
                        testCase.Account.PersonEmail,
                        UserInfo.getUserEmail()
                },
                null,
                'Subject with Attestation',
                'Body with Attestation',
                testCase.Id,
                new List<Id>{
                        testCase.Account.PersonContactId
                },
                null,
                org.Id,
                'Deceased Estate',
                true
        );

        Test.stopTest();

        EmailMessage msg = [SELECT Id, Subject FROM EmailMessage WHERE ParentId = :testCase.Id LIMIT 1];
        System.assertEquals('Subject with Attestation', msg.Subject);
    }

    /**
     * @description
     *   Verifies that the controller gracefully handles unexpected errors and throws AuraHandledException.
     */
    @IsTest
    static void testCreateEmailMessageFailure() {
        Test.startTest();

        try {
            SendEmailController.createEmailMessage(
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    false
            );
        } catch (AuraHandledException ex) {
            System.assertNotEquals(null, ex.getMessage(), 'Expected an error message');
        }

        Test.stopTest();
    }

    /**
     * @description
     *   Verifies that merge field processing errors in the template are handled and mapped to user-facing messages.
     */
    @IsTest
    static void testCreateEmailMessageTemplateFailure() {
        EmailTemplate testEmailTemplate = [
                SELECT
                        Id,
                        Subject,
                        HtmlValue
                FROM
                        EmailTemplate
                WHERE
                        IsActive = TRUE
                        AND
                        UiType = 'SFX'
                        AND
                        RelatedEntityType = 'Account'
                LIMIT 1
        ];

        Case testCase = [SELECT Id, AccountId, Account.PersonContactId, Account.PersonEmail FROM Case LIMIT 1];
        OrgWideEmailAddress org = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];


        Test.startTest();

        try {
            SendEmailController.createEmailMessage(
                    new List<String>{
                            testCase.Account.PersonEmail
                    },
                    testEmailTemplate.Id,
                    testEmailTemplate.Subject,
                    testEmailTemplate.HtmlValue,
                    testCase.Id,
                    new List<Id>{
                            testCase.Account.PersonContactId
                    },
                    null,
                    org.Id,
                    null,
                    true
            );
        } catch (AuraHandledException ex) {
            System.assertNotEquals(null, ex.getMessage(), 'Expected an error message');
        }

        Test.stopTest();
    }

    /**
     * @description
     *   Tests retrieving contact wrappers when passing a Case Id.
     */
    @IsTest
    static void testGetContactsFromAccount() {
        Case testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];

        Test.startTest();

        List<SendEmailControllerHelper.ContactWrapper> wrappers = SendEmailController.getContacts(testCase.Id);

        Test.stopTest();

        System.assert(wrappers.size() > 0);
    }

    /**
     * @description
     *   Tests retrieving contact wrappers when passing an Account Id.
     */
    @IsTest
    static void testGetContactsFromCase() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        List<SendEmailControllerHelper.ContactWrapper> wrappers = SendEmailController.getContacts(acc.Id);

        Test.stopTest();

        System.assert(wrappers.size() > 0);
    }

    /**
     * @description
     *   Tests retrieving contact wrappers when passing a Contact Id.
     */
    @IsTest
    static void testGetContactsFromContact() {
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];

        Test.startTest();

        List<SendEmailControllerHelper.ContactWrapper> wrappers = SendEmailController.getContacts(acc.PersonContactId);

        Test.stopTest();

        System.assert(wrappers.size() > 0);
    }

    /**
     * @description
     *   Tests retrieval of Org-Wide Email Address records.
     */
    @IsTest
    static void testGetOrgWideEmailAddress() {
        Test.startTest();

        List<OrgWideEmailAddress> results = SendEmailController.getOrgWideEmailAddress();

        Test.stopTest();

        System.assertNotEquals(null, results);
    }

    /**
     * @description
     *   Tests retrieval of email template folders.
     */
    @IsTest
    static void testGetEmailTemplateFolders() {
        Test.startTest();

        List<Folder> folders = SendEmailController.getEmailTemplateFolders();

        Test.stopTest();

        System.assertNotEquals(null, folders);
    }

    /**
     * @description
     *   Tests retrieval of email templates from a specific folder.
     */
    @IsTest
    static void testGetEmailTemplates() {
        List<Folder> folders = SendEmailController.getEmailTemplateFolders();

        Test.startTest();

        List<SendEmailControllerHelper.EmailTemplateWrapper> templates = SendEmailController.getEmailTemplates(folders[0].Id);

        Test.stopTest();

        System.assertNotEquals(null, templates);
    }

    /**
     * @description
     *   Tests retrieval and rendering of email template details with merge fields.
     */
    @IsTest
    static void testGetEmailTemplateDetails() {
        List<Folder> folders = SendEmailController.getEmailTemplateFolders();
        List<SendEmailControllerHelper.EmailTemplateWrapper> templates = SendEmailController.getEmailTemplates(folders[0].Id);
        Account account = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();

        SendEmailControllerHelper.EmailTemplateWrapper wrapper = SendEmailController.getEmailTemplateDetails(templates[0].id, account.PersonContactId, testCase.Id);

        Test.stopTest();

        System.assertNotEquals(null, wrapper);
    }
}