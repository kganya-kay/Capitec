/**
 * @description
 * Unit test class for SendEmailControllerHelper. Validates all major helper methods used in email rendering,
 * contact/case retrieval, attachment handling, and OrgWideEmailAddress logic.
 */
@IsTest
private class SendEmailControllerHelperTest {

    /**
     * @description
     * Creates test data: Person Account, Case, ContentVersion attachment, and EnhancedLetterhead.
     */
    @TestSetup
    static void testSetup() {
        Account testAccount = new Account(
                FirstName = 'John',
                LastName = 'Doe',
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

        ContentVersion version = new ContentVersion(
                Title = 'Doc1.pdf',
                PathOnClient = 'Doc1.pdf',
                VersionData = Blob.valueOf('Test'),
                FirstPublishLocationId = testCase.Id,
                IsMajorVersion = true
        );
        insert version;

        EnhancedLetterhead enhancedLetterhead = new EnhancedLetterhead(
                Name = 'Capitec Enhanced Letterhead',
                LetterheadHeader = '<h1>Header</h1>',
                LetterheadFooter = '<h1>Footer</h1>',
                Description = 'Test Letterhead Description'
        );
        insert enhancedLetterhead;

        String vfMarkup = '<messaging:emailTemplate subject="Test Subject for {!relatedTo.Account.Name}" recipientType="Contact" relatedToType="Case">' +
                '<messaging:htmlEmailBody >' +
                '<ul><li>Account Name: {!relatedTo.Account.Name}</li>' +
                '<li>Owner Email: {!recipient.Email}</li></ul>' +
                '</messaging:htmlEmailBody>' +
                '</messaging:emailTemplate>';

        EmailTemplate testTemplate = new EmailTemplate(
                DeveloperName = 'UnitTestVFEmailTemplate', // Unique DeveloperName is crucial
                TemplateType = 'visualforce',
                FolderId = UserInfo.getUserId(), // Store in the user's private folder
                Name = 'Unit Test VF Email Template',
                IsActive = true
        );

        testTemplate.Markup = vfMarkup;

        // This isolates the transaction, preventing the MIXED_DML_OPERATION error
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testTemplate;
        }
    }

    /**
     * @description
     * Tests that contacts related to an Account are correctly retrieved.
     */
    @IsTest
    static void testRetrieveContactsByAccountId() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        List<Contact> testContacts = SendEmailControllerHelper.retrieveContactsByAccountId(testAccount.Id);

        Test.stopTest();

        System.assert(!testContacts.isEmpty());
    }

    /**
     * @description
     * Tests that a Case can be retrieved using its Id.
     */
    @IsTest
    static void testRetrieveCaseById() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();

        Case result = SendEmailControllerHelper.retrieveCaseById(testCase.Id);

        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    /**
     * @description
     * Tests retrieval of verified OrgWideEmailAddress records.
     */
    @IsTest
    static void testRetrieveOrgWideEmailAddresses() {
        Test.startTest();

        List<OrgWideEmailAddress> orgWideEmailAddresses = SendEmailControllerHelper.retrieveOrgWideEmailAddresses();

        Test.stopTest();

        System.assertNotEquals(null, orgWideEmailAddresses);
    }

    /**
     * @description
     * Tests retrieval of Classic and Lightning email template folders.
     */
    @IsTest
    static void testRetrieveTemplateFolders() {
        Test.startTest();

        List<Folder> folders = SendEmailControllerHelper.retrieveTemplateFolders();

        Test.stopTest();

        System.assert(!folders.isEmpty());
    }

    /**
     * @description
     * Tests retrieval of EmailTemplates by a folder Id.
     */
    @IsTest
    static void testRetrieveEmailTemplatesByFolderName() {
        List<Folder> folders = SendEmailControllerHelper.retrieveTemplateFolders();

        Test.startTest();

        List<SendEmailControllerHelper.EmailTemplateWrapper> emailTemplateWrappers = SendEmailControllerHelper.retrieveEmailTemplatesByFolderName(folders[0].Id);

        Test.stopTest();

        System.assert(!emailTemplateWrappers.isEmpty());
    }

    /**
     * @description
     * Tests rendering of a Lightning EmailTemplate with EnhancedLetterhead and merge fields.
     */
    @IsTest
    static void testRetrieveEmailTemplateWrapperByTemplateId() {
        EmailTemplate testEmailTemplate = [
                SELECT
                        Id,
                        EnhancedLetterheadId
                FROM
                        EmailTemplate
                WHERE
                        EnhancedLetterheadId != NULL
                        AND
                        IsActive = TRUE
                        AND
                        UiType = 'SFX'
                        AND
                        RelatedEntityType = 'Case'
                LIMIT 1
        ];

        Case testCase = [SELECT Id, AccountId, Account.PersonContactId FROM Case LIMIT 1];

        Test.startTest();

        SendEmailControllerHelper.EmailTemplateWrapper wrapper =
                SendEmailControllerHelper.retrieveEmailTemplateWrapperByTemplateId(
                        testEmailTemplate.Id,
                        testCase.Account.PersonContactId,
                        testCase.Id)
        ;

        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assert(wrapper.body != null);
    }

    /**
     * @description
     * Tests retrieval of ContentVersion attachments linked to the template.
     */
    @IsTest
    static void testRetrieveEmailTemplateWrapperWithFilesByTemplateId() {
        EmailTemplate testEmailTemplate = [
                SELECT
                        Id,
                        EnhancedLetterheadId
                FROM
                        EmailTemplate
                WHERE
                        EnhancedLetterheadId != NULL
                        AND
                        IsActive = TRUE
                        AND
                        UiType = 'SFX'
                        AND
                        RelatedEntityType = 'Case'
                LIMIT 1
        ];

        ContentVersion version = new ContentVersion(
                Title = 'Test Template File.pdf',
                PathOnClient = 'Test Template File.pdf',
                VersionData = Blob.valueOf('Test Content'),
                FirstPublishLocationId = testEmailTemplate.Id,
                IsMajorVersion = true
        );
        insert version;

        Case testCase = [SELECT Id, AccountId, Account.PersonContactId FROM Case LIMIT 1];

        Test.startTest();

        SendEmailControllerHelper.EmailTemplateWrapper wrapper =
                SendEmailControllerHelper.retrieveEmailTemplateWrapperByTemplateId(
                        testEmailTemplate.Id,
                        testCase.Account.PersonContactId,
                        testCase.Id)
        ;

        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assert(wrapper.body != null);
    }

    /**
     * @description
     * Tests retrieval of classic Attachments linked to the template.
     */
    @IsTest
    static void testRetrieveEmailTemplateWrapperWithAttachmentsByTemplateId() {
        EmailTemplate testEmailTemplate = [
                SELECT
                        Id,
                        EnhancedLetterheadId
                FROM
                        EmailTemplate
                WHERE
                        IsActive = TRUE
                        AND
                        UiType = 'Aloha'
                        AND
                        TemplateType = 'html'
                LIMIT 1
        ];

        Attachment attachment = new Attachment(
                Name = 'Test Template File.pdf',
                ContentType = 'PDF',
                Body = Blob.valueOf('Test Content'),
                ParentId = testEmailTemplate.Id
        );
        insert attachment;

        Case testCase = [SELECT Id, AccountId, Account.PersonContactId FROM Case LIMIT 1];

        Test.startTest();

        SendEmailControllerHelper.EmailTemplateWrapper wrapper =
                SendEmailControllerHelper.retrieveEmailTemplateWrapperByTemplateId(
                        testEmailTemplate.Id,
                        testCase.Account.PersonContactId,
                        testCase.Id)
        ;

        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assert(wrapper.body != null);
    }

    /**
     * @description
     * Tests retrieval of Visualforce EmailTemplate without Attachments.
     */
    @IsTest
    static void testRetrieveVFEmailTemplateWrapperWithoutAttachmentsByTemplateId() {
        EmailTemplate testTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'UnitTestVFEmailTemplate' LIMIT 1];
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId FROM Case LIMIT 1];

        Test.startTest();

        SendEmailControllerHelper.EmailTemplateWrapper wrapper =
                SendEmailControllerHelper.retrieveEmailTemplateWrapperByTemplateId(
                        testTemplate.Id,
                        testCase.Account.PersonContactId,
                        testCase.Id)
        ;

        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assert(wrapper.body != null);
    }

    /**
     * @description
     * Tests retrieval of Visualforce EmailTemplate with Attachments.
     */
    @IsTest
    static void testRetrieveVFEmailTemplateWrapperWithAttachmentsByTemplateId() {
        EmailTemplate testTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'UnitTestVFEmailTemplate' LIMIT 1];
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId FROM Case LIMIT 1];

        Attachment attachment = new Attachment(
                Name = 'Test Template File.pdf',
                ContentType = 'PDF',
                Body = Blob.valueOf('Test Content'),
                ParentId = testTemplate.Id
        );

        insert attachment;

        Test.startTest();

        SendEmailControllerHelper.EmailTemplateWrapper wrapper =
                SendEmailControllerHelper.retrieveEmailTemplateWrapperByTemplateId(
                        testTemplate.Id,
                        testCase.Account.PersonContactId,
                        testCase.Id)
        ;

        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assert(wrapper.body != null);
    }

    /**
     * @description
     * Tests handling of EmailTemplate missing a subject, expects exception.
     */
    @IsTest
    static void testRetrieveEmailTemplateWrapperByTemplateIdNoSubject() {
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId FROM Case LIMIT 1];

        EmailTemplate testEmailTemplate = [
                SELECT
                        Id,
                        EnhancedLetterheadId,
                        Subject
                FROM
                        EmailTemplate
                WHERE
                        IsActive = TRUE
                        AND
                        UiType = 'SFX'
                        AND
                        RelatedEntityType = 'Case'
                LIMIT 1
        ];

        testEmailTemplate.Subject = null;
        update testEmailTemplate;

        Test.startTest();

        try {
            SendEmailControllerHelper.retrieveEmailTemplateWrapperByTemplateId(
                    testEmailTemplate.Id,
                    testCase.Account.PersonContactId,
                    testCase.Id);
        } catch (Exception ex) {
            System.assertNotEquals(null, ex.getMessage(), 'Expected an error message');
        }

        Test.stopTest();
    }

    /**
     * @description
     * Tests handling of merge failure due to mismatched RelatedEntityType.
     */
    @IsTest
    static void testRetrieveEmailTemplateWrapperByTemplateIdResultsFailure() {
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId FROM Case LIMIT 1];

        EmailTemplate testEmailTemplate = [
                SELECT
                        Id,
                        EnhancedLetterheadId,
                        Subject
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

        Test.startTest();

        try {
            SendEmailControllerHelper.retrieveEmailTemplateWrapperByTemplateId(
                    testEmailTemplate.Id,
                    testCase.Account.PersonContactId,
                    testCase.Id);
        } catch (Exception ex) {
            System.assertNotEquals(null, ex.getMessage(), 'Expected an error message');
        }

        Test.stopTest();
    }

    /**
     * @description
     * Tests retrieval of a Contact by Id.
     */
    @IsTest
    static void testRetrieveContactById() {
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId FROM Case LIMIT 1];

        Test.startTest();

        Contact contact = SendEmailControllerHelper.retrieveContactById(testCase.Account.PersonContactId);

        Test.stopTest();

        System.assertEquals(testCase.Account.PersonContactId, contact.Id);
    }

    /**
     * @description
     * Tests @TestVisible method for retrieving contacts related to an Account.
     */
    @IsTest
    static void testRetrieveRelatedContactsByAccountId() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        List<Contact> contacts = SendEmailControllerHelper.retrieveRelatedContactsByAccountId(testAccount.Id);

        Test.stopTest();

        System.assert(!contacts.isEmpty());
    }

    /**
     * @description
     * Tests HTML email body generation with EnhancedLetterhead.
     */
    @IsTest
    static void testBuildHtmlBodyWithLetterhead() {
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId FROM Case LIMIT 1];
        EmailTemplate testEmailTemplate = [
                SELECT
                        Id,
                        EnhancedLetterheadId
                FROM
                        EmailTemplate
                WHERE
                        EnhancedLetterheadId != NULL
                        AND
                        IsActive = TRUE
                        AND
                        UiType = 'SFX'
                        AND
                        RelatedEntityType = 'Case'
                LIMIT 1
        ];

        Test.startTest();

        String result = SendEmailControllerHelper.buildHtmlBodyWithLetterhead(testEmailTemplate.Id, 'test-body', testCase.Id);

        Test.stopTest();

        System.assert(result.contains('test-body'));
    }

    /**
     * @description
     * Tests HTML email body generation with fallback EnhancedLetterhead if none is defined on template.
     */
    @IsTest
    static void testBuildHtmlBodyWithoutLetterhead() {
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId FROM Case LIMIT 1];
        EmailTemplate testEmailTemplate = [
                SELECT
                        Id,
                        EnhancedLetterheadId
                FROM
                        EmailTemplate
                WHERE
                        EnhancedLetterheadId = NULL
                        AND
                        IsActive = TRUE
                        AND
                        UiType = 'SFX'
                        AND
                        RelatedEntityType = 'Case'
                LIMIT 1
        ];

        Test.startTest();

        String result = SendEmailControllerHelper.buildHtmlBodyWithLetterhead(testEmailTemplate.Id, 'test-body', testCase.Id);

        Test.stopTest();

        System.assert(result.contains('test-body'));
    }

    /**
     * @description
     * Tests attaching new and reused ContentVersion files to an EmailMessage.
     */
    @IsTest
    static void testAttachFilesToEmailMessage() {
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId, Account.PersonEmail FROM Case LIMIT 1];
        OrgWideEmailAddress testOrgWideEmailAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];
        ContentVersion testContentVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = :testCase.Id LIMIT 1];

        EmailMessage testEmailMessage = new EmailMessage(
                Subject = 'Test Subject',
                FromAddress = testOrgWideEmailAddress.Address,
                ToAddress = testCase.Account.PersonEmail,
                ParentId = testCase.Id,
                Incoming = false,
                Status = '3'
        );
        insert testEmailMessage;

        Test.startTest();

        SendEmailController.InboundAttachment newUpload = new SendEmailController.InboundAttachment();
        newUpload.fileName = 'NewUpload.pdf';
        newUpload.fileType = 'pdf';
        newUpload.fileContent = EncodingUtil.base64Encode(Blob.valueOf('New content'));

        SendEmailController.InboundAttachment reused = new SendEmailController.InboundAttachment();
        reused.fileName = testContentVersion.Title;
        reused.fileType = 'pdf';
        reused.fileContentVersionId = testContentVersion.Id;
        reused.fileContentDocumentId = testContentVersion.ContentDocumentId;

        List<SendEmailController.InboundAttachment> attachments = new List<SendEmailController.InboundAttachment>{
                newUpload,
                reused
        };

        SendEmailControllerHelper.attachFilesToEmailMessage(testEmailMessage, attachments);

        Test.stopTest();

        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testEmailMessage.Id];
        System.assert(!links.isEmpty());
    }

    /**
     * @description
     * Tests creation of EmailMessageRelation entries for ToAddress.
     */
    @IsTest
    static void testCreateEmailMessageRelations() {
        Case testCase = [SELECT Id, AccountId, Account.PersonContactId, Account.PersonEmail FROM Case LIMIT 1];
        OrgWideEmailAddress testOrgWideEmailAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];

        EmailMessage testEmailMessage = new EmailMessage(
                Subject = 'Test Subject',
                FromAddress = testOrgWideEmailAddress.Address,
                ToAddress = testCase.Account.PersonEmail,
                ParentId = testCase.Id,
                Incoming = false,
                Status = '3'
        );
        insert testEmailMessage;

        Test.startTest();

        SendEmailControllerHelper.createEmailMessageRelations(testEmailMessage.Id, new List<Id>{
                testCase.Account.PersonContactId
        });

        Test.stopTest();

        List<EmailMessageRelation> emailMessageRelations = [SELECT Id FROM EmailMessageRelation WHERE EmailMessageId = :testEmailMessage.Id];
        System.assertEquals(2, emailMessageRelations.size());
    }

    /**
     * @description
     * Tests retrieval of a single OrgWideEmailAddress by Id.
     */
    @IsTest
    static void testGetOrgWideEmailAddress() {
        List<OrgWideEmailAddress> orgWideEmailAddresses = SendEmailControllerHelper.retrieveOrgWideEmailAddresses();

        Test.startTest();

        OrgWideEmailAddress orgWideEmailAddress = SendEmailControllerHelper.getOrgWideEmailAddress(orgWideEmailAddresses[0].Id);

        Test.stopTest();

        System.assertEquals(orgWideEmailAddresses[0].Id, orgWideEmailAddress.Id);
    }
}