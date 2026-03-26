/**
 * @name SendEmailController
 * @description Send Email controller used to create and render an email message based on a template
 *              and the related object Id.
 *
 * @see SendEmailControllerHelper
 * @see EmailTemplate
 * @see OrgWideEmailAddress
 * @see EmailMessage
 * @see Email_Attestation__c
 * @see SendEmailService
 */
public with sharing class SendEmailController {

    /**
     * @description Internal exception tag for identifying merge field template errors.
     */
    private static final String EXCEPTION_PROCESSING_EMAIL = 'EMAIL_TEMPLATE_PROCESSING_ERROR';

    /**
     * @description User-facing error message for merge field issues in email templates.
     */
    private static final String ERROR_PROCESSING_TEMPLATE = 'The selected template has unsupported or unassociated merge fields, Please Review.';

    /**
     * @description Format string for send failure errors.
     */
    private static final String ERROR_SEND_FAILED_FMT = 'Failed to send email: {0}';

    /**
     * @description Semicolon separator for joining email addresses.
     */
    @TestVisible
    private static final String STRING_SEMICOLON = ';';

    /**
     * @description Status value used to mark emails as sent.
     * @see EmailMessage.Status
     */
    private static final String STATUS_SENT = '3';

    /**
     * @description Static origin value used to classify Attestation emails.
     * @see EmailMessage.Origin__c
     */
    private static final String ORIGIN_ATTESTATION = 'Attestation';

    /**
     * @name getContacts
     * @description Return a list of ContactWrapper items based on the object type and related record ID.
     *
     * @param recordId The Id of the record used to determine type and retrieve the records.
     * @return The wrapped list of related contact records.
     *
     * @see SendEmailControllerHelper.ContactWrapper
     */
    @AuraEnabled(Cacheable=true)
    public static List<SendEmailControllerHelper.ContactWrapper> getContacts(Id recordId) {
        String objectName = recordId.getSobjectType().getDescribe().getName();
        List<SendEmailControllerHelper.ContactWrapper> contacts = new List<SendEmailControllerHelper.ContactWrapper>();

        if (objectName == SendEmailControllerHelper.OBJECT_ACCOUNT) {
            List<Contact> relatedContacts = SendEmailControllerHelper.retrieveContactsByAccountId(recordId);
            for (Contact con : relatedContacts) {
                contacts.add(new SendEmailControllerHelper.ContactWrapper(con.Id, con.Name, con.Email));
            }
        } else if (objectName == SendEmailControllerHelper.OBJECT_CONTACT) {
            Contact con = SendEmailControllerHelper.retrieveContactById(recordId);
            contacts.add(new SendEmailControllerHelper.ContactWrapper(con.Id, con.Name, con.Email));
        } else if (objectName == SendEmailControllerHelper.OBJECT_CASE) {
            Case caseRecord = SendEmailControllerHelper.retrieveCaseById(recordId);
            if (caseRecord.AccountId != null) {
                List<Contact> relatedContacts = SendEmailControllerHelper.retrieveContactsByAccountId(caseRecord.AccountId);
                for (Contact con : relatedContacts) {
                    contacts.add(new SendEmailControllerHelper.ContactWrapper(con.Id, con.Name, con.Email));
                }
            }
        }
        return contacts;
    }

    /**
     * @name getOrgWideEmailAddress
     * @description Retrieves a list of organization-wide email addresses.
     *
     * @return A list of OrgWideEmailAddress objects.
     *
     * @see OrgWideEmailAddress
     */
    @AuraEnabled(Cacheable=true)
    public static List<OrgWideEmailAddress> getOrgWideEmailAddress() {
        return SendEmailControllerHelper.retrieveOrgWideEmailAddresses();
    }

    /**
     * @name getEmailTemplateFolders
     * @description Retrieves email template folders for both classic and lightning.
     *
     * @return A list of Folder objects that represent email template folders.
     *
     * @see Folder
     */
    @AuraEnabled(Cacheable=true)
    public static List<Folder> getEmailTemplateFolders() {
        return SendEmailControllerHelper.retrieveTemplateFolders();
    }

    /**
     * @name getEmailTemplates
     * @description Retrieves email templates with pagination and metadata for a given folder.
     *
     * @param folderId The ID of the template folder.
     * @return A list of EmailTemplateWrapper objects.
     *
     * @see SendEmailControllerHelper.EmailTemplateWrapper
     */
    @AuraEnabled(Cacheable=true)
    public static List<SendEmailControllerHelper.EmailTemplateWrapper> getEmailTemplates(Id folderId) {
        return SendEmailControllerHelper.retrieveEmailTemplatesByFolderName(folderId);
    }

    /**
     * @name getEmailTemplateDetails
     * @description Renders and returns email template details with merge fields and attachments.
     *
     * @param templateId ID of the EmailTemplate to render.
     * @param whoId Optional ID of the Contact/Lead/User for merge fields.
     * @param whatId Optional ID of the primary object (e.g., Case, Opportunity).
     * @return A fully populated EmailTemplateWrapper.
     *
     * @see SendEmailControllerHelper.EmailTemplateWrapper
     */
    @AuraEnabled
    public static SendEmailControllerHelper.EmailTemplateWrapper getEmailTemplateDetails(
            Id templateId,
            Id whoId,
            Id whatId
    ) {
        return SendEmailControllerHelper.retrieveEmailTemplateWrapperByTemplateId(
                templateId,
                whoId,
                whatId
        );
    }

    /**
     * @name createEmailMessage
     * @description
     * Creates and sends an EmailMessage using the specified template and attachments. The message is also published
     * as a platform event via SendEmailService.
     *
     * @param toAddresses List of TO email addresses.
     * @param templateId EmailTemplate ID used for formatting.
     * @param subject Email subject line.
     * @param body Email body HTML.
     * @param recordId ID of the related Case/Record.
     * @param selectedContactIds Contact Ids to associate with the message.
     * @param attachments Serialized InboundAttachment list (JSON).
     * @param fromAddressId ID of the OrgWideEmailAddress to send from.
     * @param otherEmailReason Optional reason if no contact is selected.
     * @param attestationAccepted Whether attestation has been accepted.
     *
     * @throws AuraHandledException if any error occurs during processing or merge fields are invalid.
     *
     * @see Email_Attestation__c
     * @see EmailMessage
     * @see OrgWideEmailAddress
     * @see SendEmailService.publishEmailMessageEvent
     */
    @AuraEnabled
    public static void createEmailMessage(
            List<String> toAddresses,
            Id templateId,
            String subject,
            String body,
            Id recordId,
            List<Id> selectedContactIds,
            String attachments,
            Id fromAddressId,
            String otherEmailReason,
            Boolean attestationAccepted
    ) {
        try {
            Email_Attestation__c emailAttestation = new Email_Attestation__c(
                    Other_Email_Reason__c = otherEmailReason,
                    Attestation_Accepted__c = attestationAccepted
            );
            insert emailAttestation;

            EmailMessage emailMessage = new EmailMessage();
            emailMessage.Subject = subject;
            emailMessage.HtmlBody = SendEmailControllerHelper.buildHtmlBodyWithLetterhead(templateId, body, recordId);
            emailMessage.Email_Attestation__c = emailAttestation.Id;
            emailMessage.Origin__c = ORIGIN_ATTESTATION;
            emailMessage.ToIds = selectedContactIds;
            emailMessage.ToAddress = (toAddresses != null && !toAddresses.isEmpty()) ? String.join(toAddresses, STRING_SEMICOLON) : null;
            emailMessage.Status = STATUS_SENT;
            if (recordId.getSobjectType().toString() == 'Case') {
                emailMessage.ParentId = recordId;
            } else {
                emailMessage.RelatedToId = recordId;
            }
            emailMessage.Incoming = false;

            OrgWideEmailAddress fromAddress = SendEmailControllerHelper.getOrgWideEmailAddress(fromAddressId);
            emailMessage.FromAddress = fromAddress.Address;
            emailMessage.FromName = fromAddress.DisplayName;

            insert emailMessage;

            if (!selectedContactIds.isEmpty()) {
                SendEmailControllerHelper.createEmailMessageRelations(emailMessage.Id, selectedContactIds);
            }

            if (attachments != null) {
                List<InboundAttachment> inboundAttachments = (List<InboundAttachment>) JSON.deserialize(
                        attachments, List<InboundAttachment>.class
                );
                SendEmailControllerHelper.attachFilesToEmailMessage(emailMessage, inboundAttachments);
            }

            SendEmailService.publishEmailMessageEvent(new List<EmailMessage>{
                    emailMessage
            });

        } catch (Exception e) {
            String errorMessage = e.getMessage().contains(EXCEPTION_PROCESSING_EMAIL)
                    ? ERROR_PROCESSING_TEMPLATE
                    : String.format(ERROR_SEND_FAILED_FMT, new List<String>{
                            e.getMessage()
                    });

            throw new AuraHandledException(errorMessage);
        }
    }

    /**
     * @name InboundAttachment
     * @description
     * Represents an attachment uploaded or selected for reuse in the email sending process.
     */
    public class InboundAttachment {
        public String fileName;
        public String fileType;
        public String fileContent;
        public Id fileContentVersionId;
        public Id fileContentDocumentId;

        /**
         * @name isNewUpload
         * @description
         * Indicates whether the file was uploaded as new content.
         * @return True if file content and name are populated.
         */
        public Boolean isNewUpload() {
            return fileContent != null && fileName != null &&
                    String.isNotBlank(fileContent) && String.isNotBlank(fileName);
        }

        /**
         * @name isReuse
         * @description
         * Indicates whether the file is an existing ContentVersion being reused.
         * @return True if version and document IDs are populated.
         */
        public Boolean isReuse() {
            return fileContentVersionId != null && fileContentDocumentId != null &&
                    String.isNotBlank(fileContentVersionId) && String.isNotBlank(fileContentDocumentId);
        }
    }
}