/**
 * @description Send Email controller helper class to manage DML and utility methods
 */
public with sharing class SendEmailControllerHelper {
    /**
     * @description  Case Object Name
     */
    public static final String OBJECT_CASE = 'Case';

    /**
     * @description Account Object Name
     */
    public static final String OBJECT_ACCOUNT = 'Account';

    /**
     * @description Contact Object Name
     */
    public static final String OBJECT_CONTACT = 'Contact';

    /**
     * @description
     * RelationType value for linking contacts to EmailMessage as recipients.
     */
    public static final String RELATION_TYPE_TO_ADDRESS = 'ToAddress';

    /**
     * @description
     * ShareType value 'I' for inferred sharing on ContentDocumentLink.
     */
    public static final String SHARE_TYPE_INFERRED = 'I';

    /**
     * @description
     * Visibility value to allow access to all users on ContentDocumentLink.
     */
    public static final String VISIBILITY_ALL_USERS = 'AllUsers';

    /**
     * @description
     * Standard HTML line break used when appending the threading token.
     */
    public static final String HTML_LINE_BREAK = '<br><br>';

    /**
     * @description
     * Default enhanced letterhead name used when a template has no letterhead assigned.
     */
    public static final String DEFAULT_LETTERHEAD_NAME = 'Capitec Enhanced Letterhead';

    /**
     * @description
     * OrgWideEmailAddress purpose value that is excluded from selection.
     */
    public static final String PURPOSE_DEFAULT_NOREPLY = 'DefaultNoreply';

    /**
     * @description
     * Folder Type value for Classic Email Templates.
     */
    public static final String FOLDER_TYPE_EMAIL = 'Email';

    /**
     * @description
     * Folder Type value for Lightning Email Templates.
     */
    public static final String FOLDER_TYPE_EMAIL_TEMPLATE = 'EmailTemplate';

    /**
     * @description
     * Supported folder types for email templates (Classic and Lightning).
     */
    public static final Set<String> EMAIL_FOLDER_TYPES = new Set<String>{
            FOLDER_TYPE_EMAIL,
            FOLDER_TYPE_EMAIL_TEMPLATE
    };

    /**
     * @description
     * Template type value for Visualforce email templates.
     */
    public static final String VISUALFORCE_TEMPLATE_TYPE = 'visualforce';

    /**
     * @description
     * Error message for missing template subject or body.
     */
    public static final String ERROR_TEMPLATE_EMPTY = 'Template rendering failed: Template or HTML value is empty.';

    /**
     * @description
     * Error message prefix used when template rendering fails with specific errors.
     */
    public static final String ERROR_TEMPLATE_RENDER = 'Template rendering error: ';

    /**
     * @description Retrieves a list of contacts related to a specific account ID.
     * @param accountId - The ID of the account whose related contacts are to be retrieved.
     * @return A list of Contact objects that are related to the specified account ID.
     */
    public static List<Contact> retrieveContactsByAccountId(Id accountId) {
        return [
                SELECT
                        Id,
                        Name,
                        Email
                FROM
                        Contact
                WHERE
                        AccountId = :accountId
        ];
    }

    /**
     * @description Retrieves a Case record based on its ID.
     * @param caseId - The ID of the Case to be retrieved.
     * @return The Case object that matches the specified ID.
     */
    public static Case retrieveCaseById(Id caseId) {
        return [
                SELECT
                        AccountId
                FROM
                        Case
                WHERE
                        Id = :caseId
        ];
    }

    /**
     * @description Retrieves a list of organization-wide email addresses restricted to users access.
     * @return A list of OrgWideEmailAddress objects.
     */
    public static List<OrgWideEmailAddress> retrieveOrgWideEmailAddresses() {
        return [
                SELECT
                        Id,
                        DisplayName,
                        Address
                FROM
                        OrgWideEmailAddress
                WHERE
                        Id IN (
                                SELECT
                                        OrgWideEmailAddressId
                                FROM
                                        OrgEmailAddressSecurity
                                WHERE
                                        ParentId = :UserInfo.getProfileId()
                        )
                        AND
                        IsVerified = TRUE
                        AND
                        Purpose != :PURPOSE_DEFAULT_NOREPLY
                WITH USER_MODE
        ];
    }

    /**
     * @description Retrieves a list of both Classic and Lightning email template folders.
     * @return A list of Folder objects that represent email template folders.
     */
    public static List<Folder> retrieveTemplateFolders() {
        return [
                SELECT
                        Id,
                        Name
                FROM
                        Folder
                WHERE
                        Type IN :EMAIL_FOLDER_TYPES
                WITH USER_MODE
                ORDER BY
                        Name
        ];
    }

    /**
     * @description Retrieves a list of email templates based on the specified folder name.
     * @param folderId - The Id of the folder to filter email templates by.
     * @return A list of EmailTemplateWrapper objects that represent the email templates in the specified folder.
     */
    public static List<EmailTemplateWrapper> retrieveEmailTemplatesByFolderName(Id folderId) {
        List<EmailTemplateWrapper> emailTemplates = new List<EmailTemplateWrapper>();

        if (folderId != null) {
            for (EmailTemplate template : [
                    SELECT
                            Id,
                            Name,
                            Subject
                    FROM
                            EmailTemplate
                    WHERE
                            IsActive = TRUE
                            AND
                            FolderId = :folderId
            ]) {
                emailTemplates.add(new EmailTemplateWrapper(
                        template.Id,
                        template.Name,
                        template.Subject,
                        null,
                        null
                ));
            }
        }

        return emailTemplates;
    }

    /**
     * @description Retrieves an email template and renders its content based on the provided template ID, who ID, and what ID.
     * @param templateId - The ID of the email template to retrieve.
     * @param whoId - The ID of the recipient (Contact or Lead) for whom the template is being rendered.
     * @param whatId - The ID of the related record (e.g., Case, Account) for whom the template is being rendered.
     * @return An EmailTemplateWrapper object containing the rendered email template details.
     * @throws AuraHandledException if the template is empty or rendering fails.
     */
    public static EmailTemplateWrapper retrieveEmailTemplateWrapperByTemplateId(
            Id templateId,
            Id whoId,
            Id whatId
    ) {
        EmailTemplate template = retrieveTemplateDetailsByTemplateId(templateId);

        // Handle Visualforce templates differently
        if (template.TemplateType == VISUALFORCE_TEMPLATE_TYPE) {
            // Render the Visualforce email template
            Messaging.SingleEmailMessage singleEmailMessage = Messaging.renderStoredEmailTemplate(templateId, whoId, whatId);

            // Collect attachments from the rendered email
            List<EmailTemplateAttachmentWrapper> templateAttachments = new List<EmailTemplateAttachmentWrapper>();

            // Iterate through file attachments and wrap them
            for (Messaging.EmailFileAttachment emailFileAttachment : singleEmailMessage.getFileAttachments()) {
                EmailTemplateAttachmentWrapper wrapper = new EmailTemplateAttachmentWrapper(
                        emailFileAttachment.getId(),
                        emailFileAttachment.getFileName(),
                        emailFileAttachment.getContentType(),
                        EncodingUtil.base64Encode(emailFileAttachment.getBody())
                );
                templateAttachments.add(wrapper);
            }

            // Return the rendered Visualforce template
            return new EmailTemplateWrapper(
                    template.Id,
                    template.Name,
                    singleEmailMessage.getSubject(),
                    singleEmailMessage.getHtmlBody(),
                    templateAttachments
            );
        }
        // Handle Classic and Lightning templates
        else {
            if ((String.isBlank(template.HtmlValue) && String.isBlank(template.Body)) || String.isBlank(template.Subject)) {
                throw new AuraHandledException(ERROR_TEMPLATE_EMPTY);
            }

            List<Messaging.RenderEmailTemplateBodyResult> renderResults = Messaging.renderEmailTemplate(
                    whoId,
                    whatId,
                    new List<String>{
                            template.Subject,
                            template.HtmlValue != null ? template.HtmlValue : template.Body
                    }
            );

            for (Messaging.RenderEmailTemplateBodyResult renderResult : renderResults) {
                if (!renderResult.getSuccess()) {
                    throw new AuraHandledException(ERROR_TEMPLATE_RENDER + renderResult.getErrors());
                }
            }

            List<EmailTemplateAttachmentWrapper> templateAttachments = new List<EmailTemplateAttachmentWrapper>();

            List<ContentDocumentLink> contentLinks = retrieveContentDocumentLinkByLinkedEntityId(templateId);
            Set<Id> contentDocumentIds = new Set<Id>();

            for (ContentDocumentLink link : contentLinks) {
                contentDocumentIds.add(link.ContentDocumentId);
            }

            List<ContentVersion> contentVersions = [
                    SELECT
                            Id,
                            Title,
                            FileType,
                            VersionData,
                            ContentDocumentId
                    FROM
                            ContentVersion
                    WHERE
                            IsLatest = TRUE
                            AND
                            ContentDocumentId IN :contentDocumentIds
            ];

            for (ContentVersion version : contentVersions) {
                EmailTemplateAttachmentWrapper wrapper = new EmailTemplateAttachmentWrapper
                        (
                                version.Id,
                                version.Title,
                                version.FileType,
                                EncodingUtil.base64Encode(version.VersionData)
                        );

                templateAttachments.add(wrapper);
            }

            List<Attachment> classicAttachments = [
                    SELECT
                            Id,
                            Name,
                            Body,
                            ContentType
                    FROM
                            Attachment
                    WHERE
                            ParentId = :templateId
            ];

            for (Attachment att : classicAttachments) {
                EmailTemplateAttachmentWrapper wrapper = new EmailTemplateAttachmentWrapper(
                        att.Id,
                        att.Name,
                        att.ContentType,
                        EncodingUtil.base64Encode(att.Body)
                );
                templateAttachments.add(wrapper);
            }

            // Return the rendered template with attachments
            return new EmailTemplateWrapper(
                    template.Id,
                    template.Name,
                    renderResults[0].getMergedBody(),
                    renderResults[1].getMergedBody(),
                    templateAttachments
            );
        }
    }

    /**
     * @description Retrieves a list of ContentDocumentLink records based on the linked entity ID.
     * @param templateId - The ID of the template to retrieve ContentDocumentLink records for.
     * @return A list of ContentDocumentLink objects that are linked to the specified template ID.
     */
    private static List<ContentDocumentLink> retrieveContentDocumentLinkByLinkedEntityId(Id templateId) {
        return [
                SELECT
                        ContentDocumentId,
                        ContentDocument.Title
                FROM
                        ContentDocumentLink
                WHERE
                        LinkedEntityId = :templateId
        ];
    }

    /**
     * @description Retrieves the details of an email template based on its ID.
     * @param templateId - The ID of the email template to retrieve details for.
     * @return The EmailTemplate object that matches the specified template ID.
     */
    public static EmailTemplate retrieveTemplateDetailsByTemplateId(Id templateId) {
        return [
                SELECT
                        Id,
                        Name,
                        Subject,
                        HtmlValue,
                        Body,
                        Markup,
                        BrandTemplateId,
                        EnhancedLetterheadId,
                        EnhancedLetterhead.LetterheadHeader,
                        EnhancedLetterhead.LetterheadFooter,
                        TemplateType
                FROM
                        EmailTemplate
                WHERE
                        Id = :templateId
        ];
    }

    /**
     * @description Retrieves a Contact record based on its ID.
     * @param contactId - The ID of the Contact to be retrieved.
     * @return The Contact object that matches the specified ID.
     */
    public static Contact retrieveContactById(Id contactId) {
        return [
                SELECT
                        Id,
                        Name,
                        Email
                FROM
                        Contact
                WHERE
                        Id = :contactId
        ];
    }

    /**
     * @description Retrieves a list of contacts related to a specific account ID.
     * @param accountId - The ID of the account whose related contacts are to be retrieved.
     * @return A list of Contact objects that are related to the specified account ID.
     */
    @TestVisible
    private static List<Contact> retrieveRelatedContactsByAccountId(Id accountId) {
        return [
                SELECT
                        Id,
                        Name,
                        Email
                FROM
                        Contact
                WHERE
                        AccountId = :accountId
        ];
    }

    /**
    * @description
    * Builds an HTML email body using the enhanced letterhead if available.
    * If no letterhead is linked to the template, it falls back to a default Capitec Enhanced Letterhead.
    * The email threading token is always appended at the end if it is not already present in the final message body.
    *
    * @param templateId - The ID of the email template (optional).
    * @param body - The main email body content.
    * @param recordId - The ID of the parent record (usually a Case).
    * @return A String containing the final HTML-formatted email body.
    */
    public static String buildHtmlBodyWithLetterhead(Id templateId, String body, Id recordId) {
        String messageBody;
        String threadingToken = EmailMessages.getFormattedThreadingToken(recordId);

        if (templateId != null) {
            EmailTemplate template = SendEmailControllerHelper.retrieveTemplateDetailsByTemplateId(templateId);

            if (template.EnhancedLetterheadId != null) {
                messageBody = template.EnhancedLetterhead.LetterheadHeader + body + template.EnhancedLetterhead.LetterheadFooter;
            } else {
                EnhancedLetterhead enhancedLetterhead = [
                        SELECT
                                LetterheadHeader,
                                LetterheadFooter
                        FROM
                                EnhancedLetterhead
                        WHERE
                                Name = :DEFAULT_LETTERHEAD_NAME
                ];

                messageBody = enhancedLetterhead.LetterheadHeader + body + enhancedLetterhead.LetterheadFooter;
            }
        } else {
            messageBody = body;
        }

        // Append threading token only if not already present
        if (messageBody == null || !messageBody.contains(threadingToken)) {
            messageBody += HTML_LINE_BREAK + threadingToken;
        }

        return messageBody;
    }

    /**
     * @description Attaches files to an EmailMessage record.
     * Supports both newly uploaded base64 files and reused ContentDocument references.
     *
     * @param emailMessage - The EmailMessage record to which files should be attached.
     * @param attachments - A list of inbound attachments to associate with the email.
     */
    public static void attachFilesToEmailMessage(
            EmailMessage emailMessage,
            List<SendEmailController.InboundAttachment> attachments
    ) {
        List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();

        for (SendEmailController.InboundAttachment attachment : attachments) {
            if (attachment.isNewUpload()) {
                contentVersionsToInsert.add(new ContentVersion(
                        Title = attachment.fileName,
                        PathOnClient = attachment.fileName,
                        VersionData = EncodingUtil.base64Decode(attachment.fileContent),
                        FirstPublishLocationId = emailMessage.Id
                ));
            } else if (attachment.isReuse()) {
                contentDocumentLinksToInsert.add(new ContentDocumentLink(
                        ContentDocumentId = attachment.fileContentDocumentId,
                        LinkedEntityId = emailMessage.Id,
                        ShareType = SHARE_TYPE_INFERRED,
                        Visibility = VISIBILITY_ALL_USERS
                ));
            }
        }

        if (!contentVersionsToInsert.isEmpty()) {
            insert contentVersionsToInsert;
        }

        if (!contentDocumentLinksToInsert.isEmpty()) {
            insert contentDocumentLinksToInsert;
        }
    }

    /**
     * @description Creates EmailMessageRelation records linking the given contacts as recipients.
     *
     * @param emailMessageId - The ID of the EmailMessage to link relations to.
     * @param contactIds - A list of Contact record IDs to be related as 'ToAddress'.
     */
    public static void createEmailMessageRelations(Id emailMessageId, List<Id> contactIds) {
        List<EmailMessageRelation> relations = new List<EmailMessageRelation>();

        for (Id contactId : contactIds) {
            relations.add(new EmailMessageRelation(
                    EmailMessageId = emailMessageId,
                    RelationId = contactId,
                    RelationType = RELATION_TYPE_TO_ADDRESS
            ));
        }

        if (!relations.isEmpty()) {
            insert relations;
        }
    }

    /**
     * @description Retrieves an OrgWideEmailAddress record based on its ID.
     *
     * @param id - The ID of the OrgWideEmailAddress to retrieve.
     * @return The OrgWideEmailAddress record matching the given ID.
     */
    public static OrgWideEmailAddress getOrgWideEmailAddress(Id id) {
        return [
                SELECT Id, DisplayName, Address
                FROM OrgWideEmailAddress
                WHERE Id = :id
        ];
    }

    /**
     * PUBLIC WRAPPER CLASSES
     */

    /**
     * @description Wrapper class to return contact data
     */
    public class ContactWrapper {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String email;

        public ContactWrapper(Id id, String name, String email) {
            this.id = id;
            this.name = name;
            this.email = email;
        }
    }

    /**
     * @description Wrapper class to return email template data
     */
    public class EmailTemplateWrapper {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String subject;
        @AuraEnabled
        public String body;
        @AuraEnabled
        public List<EmailTemplateAttachmentWrapper> attachments;

        public EmailTemplateWrapper(Id id, String name, String subject, String body, List<EmailTemplateAttachmentWrapper> attachments) {
            this.id = id;
            this.name = name;
            this.subject = subject;
            this.body = body;
            this.attachments = attachments;
        }
    }

    /**
     * @description Wrapper class to return the attachments data
     */
    public class EmailTemplateAttachmentWrapper {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String fileName;
        @AuraEnabled
        public String fileType;
        @AuraEnabled
        public String fileContent;

        public EmailTemplateAttachmentWrapper(Id id, String fileName, String fileType, String fileContent) {
            this.id = id;
            this.fileName = fileName;
            this.fileType = fileType;
            this.fileContent = fileContent;
        }
    }
}