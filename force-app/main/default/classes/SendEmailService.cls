/**
 * @name SendEmailService
 * @description
 * SendEmailService processes EmailMessage records and publishes them as Email_Event__e platform events.
 * It extracts attachments and client identity information by referencing related Case and Account data.
 *
 * @see EmailMessage
 * @see Email_Event__e
 * @see EventBus
 * @see ContentDocumentLink
 * @see ContentVersion
 * @see Case
 * @see Account
 */
public with sharing class SendEmailService {

    /**
     * @description
     * Allowed custom origins for which email events should be published.
     *
     * @see EmailMessage.Origin__c
     */
    public static final Set<String> ALLOWED_EMAIL_ORIGINS = new Set<String>{
            'Attestation'
    };

    /**
     * @description
     * Captures the list of Email_Event__e platform events prepared for publishing. Exposed for testing.
     *
     * @see Email_Event__e
     */
    public static List<Email_Event__e> publishedEvents;

    /**
     * @description
     * Used during test context to mock the platform event publishing result. Exposed for testing.
     *
     * @see Database.SaveResult
     */
    public static List<Database.SaveResult> mockedPublishResults;

    /**
     * @name publishEmailMessageEvent
     * @description
     * Publishes Email_Event__e platform events for the provided EmailMessage records if their Origin__c value is allowed.
     * Populates the event with recipient and sender metadata, body content, attachment links, and the associated client identity.
     *
     * @param emailMessages List of EmailMessage SObjects to process.
     * @throws EventPublishException if any platform event fails to publish.
     *
     * @see Email_Event__e
     * @see EmailMessage
     * @see EventBus.publish
     */
    public static void publishEmailMessageEvent(List<EmailMessage> emailMessages) {
        try {
            publishedEvents = new List<Email_Event__e>();
            Map<Id, Set<Id>> attachmentIds = getAttachmentContentVersionIds(emailMessages);
            Map<Id, String> clientIdsByMessageId = getAccountIdentityNumbers(emailMessages);

            for (EmailMessage emailMessage : emailMessages) {
                if (!ALLOWED_EMAIL_ORIGINS.contains(emailMessage.Origin__c)) continue;

                Set<Id> contentVersionIds = attachmentIds.get(emailMessage.Id);
                String joinedAttachmentIds = (contentVersionIds != null && !contentVersionIds.isEmpty())
                        ? String.join(contentVersionIds, ';')
                        : null;

                publishedEvents.add(new Email_Event__e(
                        BccAddress__c = emailMessage.BccAddress,
                        CcAddress__c = emailMessage.CcAddress,
                        HasAttachment__c = (contentVersionIds != null && !contentVersionIds.isEmpty()),
                        Headers__c = emailMessage.Headers,
                        HtmlBody__c = emailMessage.HtmlBody,
                        Subject__c = emailMessage.Subject,
                        ToAddress__c = emailMessage.ToAddress,
                        FromId__c = emailMessage.FromId,
                        FromName__c = emailMessage.FromName,
                        FromAddress__c = emailMessage.FromAddress,
                        Status__c = emailMessage.Status,
                        ParentId__c = emailMessage.ParentId,
                        Incoming__c = emailMessage.Incoming,
                        Email_Message_Id__c = emailMessage.Id,
                        Email_Attestation__c = emailMessage.Email_Attestation__c,
                        Origin__c = emailMessage.Origin__c,
                        AttachmentLinks__c = joinedAttachmentIds,
                        ClientId__c = clientIdsByMessageId.get(emailMessage.Id)
                ));
            }

            if (!publishedEvents.isEmpty()) {
                List<Database.SaveResult> results;

                // Use mocked results for testing if available
                if (Test.isRunningTest() && mockedPublishResults != null) {
                    results = mockedPublishResults;
                } else {
                    results = EventBus.publish(publishedEvents);
                }

                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        String errorMessages = '';
                        for (Database.Error err : results[i].getErrors()) {
                            errorMessages += 'Event ' + i + ' failed: ' + err.getMessage() + '\n';
                        }
                        throw new EventPublishException('Platform event publish failed:\n' + errorMessages);
                    }
                }
            }

        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error publishing email events: ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, ex);
            throw ex;
        }
    }

    /**
     * @name getAttachmentContentVersionIds
     * @description
     * Retrieves the ContentVersion IDs of attachments related to each EmailMessage via ContentDocumentLink.
     *
     * @param emailMessages List of EmailMessage records.
     * @return Map of EmailMessage.Id to Set of ContentVersion Ids (latest published version).
     *
     * @see ContentDocumentLink
     * @see ContentVersion
     */
    private static Map<Id, Set<Id>> getAttachmentContentVersionIds(List<EmailMessage> emailMessages) {
        Set<Id> emailIds = new Set<Id>();
        for (EmailMessage email : emailMessages) {
            emailIds.add(email.Id);
        }

        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();

        for (ContentDocumentLink contentDocumentLink : [
                SELECT LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :emailIds
        ]) {
            Set<Id> contentVersionIds = result.get(contentDocumentLink.LinkedEntityId);
            if (contentVersionIds == null) {
                contentVersionIds = new Set<Id>();
                result.put(contentDocumentLink.LinkedEntityId, contentVersionIds);
            }

            Id contentVersionId = contentDocumentLink.ContentDocument.LatestPublishedVersionId;
            contentVersionIds.add(contentVersionId);
        }

        return result;
    }

    /**
     * @name getAccountIdentityNumbers
     * @description
     * Maps EmailMessage.Id to the associated Account.Identity_Number__c value using the parent Case.
     *
     * @param emailMessages List of EmailMessage records.
     * @return Map of EmailMessage.Id to corresponding Account identity numbers.
     *
     * @see Case
     * @see Account
     * @see EmailMessage
     */
    private static Map<Id, String> getAccountIdentityNumbers(List<EmailMessage> emailMessages) {
        Map<Id, Id> messageToCaseMap = new Map<Id, Id>();
        for (EmailMessage email : emailMessages) {
            if (email.ParentId != null) {
                messageToCaseMap.put(email.Id, email.ParentId);
            }
        }

        if (messageToCaseMap.isEmpty()) return new Map<Id, String>();

        Map<Id, Case> caseMap = new Map<Id, Case>(
                [SELECT Account.Identity_Number__c FROM Case WHERE Id IN :messageToCaseMap.values()]
        );

        Map<Id, String> result = new Map<Id, String>();
        for (Id messageId : messageToCaseMap.keySet()) {
            Case c = caseMap.get(messageToCaseMap.get(messageId));
            if (c != null && c.Account != null) {
                result.put(messageId, c.Account.Identity_Number__c);
            }
        }

        return result;
    }

    /**
     * @name EventPublishException
     * @description
     * Exception type thrown when Email_Event__e platform events fail to publish.
     *
     * @see Email_Event__e
     * @see EventBus.publish
     */
    public class EventPublishException extends Exception {
    }
}