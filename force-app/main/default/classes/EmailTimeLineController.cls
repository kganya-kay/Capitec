/**
 * @name EmailTimeLineController
 * @description
 * Apex controller for retrieving EmailMessage records and related attachments for a given Case record.
 * Includes logic to determine email direction (inbound/outbound) and attached ContentDocument files.
 *
 * @see EmailMessage
 * @see ContentDocumentLink
 * @see ContentVersion
 * @see SendEmailService
 * @see SendEmailController
 */
public with sharing class EmailTimeLineController {

    /**
     * @description Static base path for generating ContentDocument download URLs.
     *
     */
    private static final String BASE_DOWNLOAD_URL = '/sfc/servlet.shepherd/document/download/';

    /**
     * @description Entry point for loading email messages and associated metadata for a given Case record.
     *
     * @param recordId ID of the Case or Parent object.
     * @return A populated Response instance with email messages, attachments, and applicable contacts.
     */
    @AuraEnabled
    public static Response loadMessages(Id recordId) {
        Response resp = new Response();
        try {
            resp.loadEmails(recordId);
        } catch (Exception ex) {
            resp.handleError(ex);
        }
        return resp;
    }

    /**
     * @description Republishes the platform event for an existing outbound EmailMessage if its origin is allowed.
     *
     * @param emailMessageId ID of the EmailMessage to be resent.
     * @throws AuraHandledException if the email origin is not allowed or an unexpected error occurs.
     * @see SendEmailService
     */
    @AuraEnabled
    public static void redoEmailSend(Id emailMessageId) {
        try {
            EmailMessage emailMessage = [
                    SELECT
                            Id,
                            BccAddress,
                            CcAddress,
                            FromId,
                            FromName,
                            FromAddress,
                            ToAddress,
                            HtmlBody,
                            TextBody,
                            Subject,
                            Headers,
                            Status,
                            ParentId,
                            Incoming,
                            Origin__c,
                            Email_Attestation__c
                    FROM
                            EmailMessage
                    WHERE
                            Id = :emailMessageId
                    LIMIT 1
            ];

            if (emailMessage.Origin__c == null || String.isBlank(emailMessage.Origin__c) ||
                    !SendEmailService.ALLOWED_EMAIL_ORIGINS.contains(emailMessage.Origin__c)) {
                throw new AuraHandledException('This email cannot be resent: Origin is not allowed.');
            }

            SendEmailService.publishEmailMessageEvent(new List<EmailMessage>{
                    emailMessage
            });
        } catch (Exception ex) {
            throw new AuraHandledException('Unexpected error during redo: ' + ex.getMessage());
        }
    }

    /**
     * @description Wrapper class that holds the results of the loadMessages operation,
     * including email data, applicable contacts, and any error encountered.
     *
     * @see SendEmailController
     */
    public class Response {
        /** List of wrapped email messages. */
        @AuraEnabled
        public List<EmailMessageWrapper> emailMessages = new List<EmailMessageWrapper>();

        /** List of applicable contacts from SendEmailController. */
        @AuraEnabled
        public List<SendEmailControllerHelper.ContactWrapper> applicableContacts = new List<SendEmailControllerHelper.ContactWrapper>();

        /** Error message if an exception is thrown. */
        @AuraEnabled
        public String errorMessage;

        /**
         * @description Loads email message records and related attachments for the given parent Case record.
         *
         * @param recordId ID of the Case to fetch emails for.
         * @throws Exception if any data processing fails.
         * @see EmailMessage
         * @see ContentDocumentLink
         * @see ContentVersion
         */
        public void loadEmails(Id recordId) {
            applicableContacts = SendEmailController.getContacts(recordId);

            List<Id> emailIds = new List<Id>();
            Map<Id, EmailMessageWrapper> wrapperMap = new Map<Id, EmailMessageWrapper>();

            for (EmailMessage emailMessage : [
                    SELECT
                            Id,
                            Subject,
                            CreatedDate,
                            CreatedById,
                            CreatedBy.Name,
                            FromAddress,
                            ToAddress,
                            CcAddress,
                            HtmlBody,
                            Incoming,
                            Email_Attestation__r.Other_Email_Reason__c
                    FROM
                            EmailMessage
                    WHERE
                            ParentId = :recordId
                    ORDER BY
                            CreatedDate
                                    DESC
            ]) {
                EmailMessageWrapper wrapper = new EmailMessageWrapper(emailMessage);
                emailMessages.add(wrapper);
                emailIds.add(emailMessage.Id);
                wrapperMap.put(emailMessage.Id, wrapper);
            }

            if (!emailIds.isEmpty()) {
                Map<Id, List<Id>> emailToDocumentIdsMap = new Map<Id, List<Id>>();
                Set<Id> allContentDocumentIds = new Set<Id>();

                for (ContentDocumentLink contentDocumentLink : [
                        SELECT
                                ContentDocumentId,
                                LinkedEntityId
                        FROM
                                ContentDocumentLink
                        WHERE
                                LinkedEntityId IN :emailIds
                ]) {
                    allContentDocumentIds.add(contentDocumentLink.ContentDocumentId);

                    if (!emailToDocumentIdsMap.containsKey(contentDocumentLink.LinkedEntityId)) {
                        emailToDocumentIdsMap.put(contentDocumentLink.LinkedEntityId, new List<Id>());
                    }

                    emailToDocumentIdsMap.get(contentDocumentLink.LinkedEntityId)
                            .add(contentDocumentLink.ContentDocumentId);
                }

                Map<Id, ContentVersion> latestContentVersionsByDocumentId = new Map<Id, ContentVersion>();

                for (ContentVersion contentVersion : [
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
                                ContentDocumentId IN :allContentDocumentIds
                ]) {
                    latestContentVersionsByDocumentId.put(contentVersion.ContentDocumentId, contentVersion);
                }

                for (Id emailMessageId : emailToDocumentIdsMap.keySet()) {
                    List<Id> documentIds = emailToDocumentIdsMap.get(emailMessageId);

                    for (Id contentDocumentId : documentIds) {
                        if (latestContentVersionsByDocumentId.containsKey(contentDocumentId)
                                && wrapperMap.containsKey(emailMessageId)) {

                            ContentVersion version = latestContentVersionsByDocumentId.get(contentDocumentId);

                            wrapperMap.get(emailMessageId).attachments.add(
                                    new AttachmentWrapper(version)
                            );
                        }
                    }
                }
            }
        }

        /**
         * @description Stores the exception message encountered during processing.
         *
         * @param ex The caught exception.
         */
        public void handleError(Exception ex) {
            errorMessage = ex.getMessage();
        }
    }

    /**
     * @description Wrapper for an EmailMessage record with related metadata and attachments.
     *
     * @see EmailMessage
     */
    public class EmailMessageWrapper {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String subject;
        @AuraEnabled
        public Datetime createdDate;
        @AuraEnabled
        public String formattedDate;
        @AuraEnabled
        public String createdById;
        @AuraEnabled
        public String createdByName;
        @AuraEnabled
        public String fromAddress;
        @AuraEnabled
        public String toAddress;
        @AuraEnabled
        public String ccAddress;
        @AuraEnabled
        public String body;
        @AuraEnabled
        public Boolean isInbound;
        @AuraEnabled
        public String otherEmailReason;

        /** List of attachments (ContentDocumentLink) associated with the email. */
        @AuraEnabled
        public List<AttachmentWrapper> attachments = new List<AttachmentWrapper>();

        /**
         * @description Constructor to populate the wrapper using the EmailMessage record.
         *
         * @param emailMessage EmailMessage record.
         */
        public EmailMessageWrapper(EmailMessage emailMessage) {
            this.id = emailMessage.Id;
            subject = emailMessage.Subject;
            createdDate = emailMessage.CreatedDate;
            formattedDate = createdDate.format();
            createdById = emailMessage.CreatedById;
            createdByName = emailMessage.CreatedBy.Name;
            body = emailMessage.HtmlBody;
            fromAddress = emailMessage.FromAddress;
            toAddress = emailMessage.ToAddress;
            ccAddress = emailMessage.CcAddress;
            otherEmailReason = emailMessage.Email_Attestation__r?.Other_Email_Reason__c;
            isInbound = emailMessage.Incoming;
        }
    }

    /**
     * @description Wrapper for ContentDocument linked to an EmailMessage via ContentDocumentLink.
     *
     * @see ContentVersion
     * @see ContentDocument
     * @see ContentDocumentLink
     */
    public class AttachmentWrapper {
        @AuraEnabled
        public String fileContentVersionId;
        @AuraEnabled
        public String fileName;
        @AuraEnabled
        public String fileType;
        @AuraEnabled
        public String fileContentDocumentId;
        @AuraEnabled
        public String fileContent;
        @AuraEnabled
        public String downloadUrl;

        /**
         * @description Constructor to populate the wrapper from a ContentDocumentLink and ContentVersion record.
         *
         * @param contentVersion Latest ContentVersion record for the linked ContentDocument.
         */
        public AttachmentWrapper(ContentVersion contentVersion) {
            fileContentVersionId = contentVersion.Id;
            fileName = contentVersion.Title;
            fileType = contentVersion.FileType;
            fileContentDocumentId = contentVersion.ContentDocumentId;
            fileContent = null;
            downloadUrl = BASE_DOWNLOAD_URL + contentVersion.ContentDocumentId;
        }
    }
}