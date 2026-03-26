/**
 * @description This class handles inbound emails and processes them to create or update cases and log email activities.
 * @implements Messaging.InboundEmailHandler
 */
public virtual class Capitec_GenericCaseEmailHandler implements Messaging.InboundEmailHandler {
    /**
     * @description Entry point for handling inbound emails.
     * @param email The inbound email message.
     * @param envelope The envelope containing the inbound email.
     * @return Messaging.InboundEmailResult The result of processing the inbound email.
     */
    public virtual Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        return processInboundEmail(email, envelope);
    }

    /**
    * @description Main method to process the inbound email.
    * @param email The inbound email message.
    * @param envelope The envelope containing the inbound email.
    * @return Messaging.InboundEmailResult The result of processing the inbound email.
    */
    public virtual Messaging.InboundEmailResult processInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        Id caseId = getCaseIdFromEmailMessage(email);
        Case relatedCase = [SELECT Id, Subject, Status, IsClosed, RecordTypeId, OwnerId, AccountId, ContactId FROM Case WHERE Id = :caseId];

        if (relatedCase != null) {
            EmailMessage emailMessage = createEmailMessage(email, relatedCase.Id);
            logEmailAsTask(emailMessage, relatedCase, null);
            handleAttachments(email, emailMessage.Id, relatedCase.Id);
        }

        return result;
    }

    /**
    * @description Checks and joins CC addresses into a single string.
    * @param ccAddresses List of CC addresses.
    * @return String Joined CC addresses.
    */
    public virtual String CCAddressCheck(List<String> ccAddresses) {
        return String.join(ccAddresses, '; ');
    }

    /**
    * @description Creates a new EmailMessage object for the inbound email.
    * @param email The inbound email message.
    * @param caseId The ID of the related case.
    * @return EmailMessage The created EmailMessage object.
    */
    public virtual EmailMessage createEmailMessage(Messaging.InboundEmail email, Id caseId) {
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.FromAddress = email.fromAddress;
        emailMessage.FromName = email.fromName;
        emailMessage.Subject = email.subject;
        emailMessage.TextBody = email.plainTextBody;
        emailMessage.HtmlBody = email.htmlBody;
        emailMessage.RelatedToId = caseId;
        emailMessage.ParentId = caseId;
        emailMessage.MessageIdentifier = email.messageId;
        emailMessage.Incoming = true;
        emailMessage.ToAddress = String.join(email.toAddresses, '; ');

        if (email.ccAddresses != null) {
            emailMessage.CcAddress = CCAddressCheck(email.ccAddresses);
        }

        insert emailMessage;
        return emailMessage;
    }

    /**
    * @description Logs the email message as a task activity.
    * @param emailMessage The EmailMessage object.
    * @param relatedCase The related Case object.
    * @param recordTypeDeveloperName The task record type.
    */
    public virtual void logEmailAsTask(EmailMessage emailMessage, Case relatedCase, String recordTypeDeveloperName) {
        Task task = new Task();
        task.Subject = emailMessage.Subject;
        task.Description = emailMessage.TextBody;
        task.ActivityDate = Date.today();
        task.Status = 'Completed';
        task.Priority = 'Normal';
        task.Type = 'Email';
        task.TaskSubtype = 'Email';
        task.WhoId = relatedCase.ContactId;
        task.WhatId = relatedCase.Id;
        if (recordTypeDeveloperName != null) {
            task.RecordTypeId = Schema.getGlobalDescribe().get('Task').getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId();
        }

        insert task;
    }

    /**
    * @description Handles attachments in the inbound email.
    * @param email The inbound email message.
    * @param emailMessageId The ID of the EmailMessage object.
    * @param caseId The ID of the related case.
    */
    public virtual void handleAttachments(
            Messaging.InboundEmail email,
            Id emailMessageId,
            Id caseId
    ) {
        List<Attachment> attachments = new List<Attachment>();
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        if (email.binaryAttachments != null) {
            for (Messaging.InboundEmail.BinaryAttachment attachment : email.binaryAttachments) {
                addAttachmentAndContent(attachment.fileName, attachment.body, emailMessageId, caseId, attachments, contentVersions);
            }
        }

        if (email.textAttachments != null) {
            for (Messaging.InboundEmail.TextAttachment attachment : email.textAttachments) {
                addAttachmentAndContent(attachment.fileName, Blob.valueOf(attachment.body), emailMessageId, caseId, attachments, contentVersions);
            }
        }

        insert attachments;
        insert contentVersions;
    }

    /**
    * @description Helper method to add attachments and content versions.
    * @param name The name of the attachment.
    * @param body The body of the attachment.
    * @param parentId The ID of the parent object.
    * @param caseId The ID of the related case.
    * @param attachments List of Attachment objects.
    * @param contentVersions List of ContentVersion objects.
    */
    private static void addAttachmentAndContent(
            String name, Blob body, Id parentId, Id caseId,
            List<Attachment> attachments,
            List<ContentVersion> contentVersions
    ) {
        Attachment attachment = new Attachment(Name = name, Body = body, ParentId = parentId);
        attachments.add(attachment);

        ContentVersion content = new ContentVersion(
                Title = name,
                VersionData = body,
                FirstPublishLocationId = caseId,
                PathOnClient = '/' + name
        );
        contentVersions.add(content);
    }

    /**
    * @description Extracts the case ID from the email message.
    * @param email The inbound email message.
    * @return Id The extracted case ID.
    */
    public static Id getCaseIdFromEmailMessage(Messaging.InboundEmail email) {
        Id caseId = EmailMessages.getRecordIdFromEmail(email.subject, email.plainTextBody, email.htmlBody);

        // If the above method returns null, fallback to extracting from headers
        return (caseId != null)
                ? caseId
                : Cases.getCaseIdFromEmailHeaders(email.headers);
    }

    /**
    * @description Extracts the case number from the email message.
    * @param email The inbound email message.
    * @return String The extracted case number.
    */
    public static String getCaseNumberFromEmailMessage(Messaging.InboundEmail email) {
        String caseNumber = findFirstMatch(email.subject, '\\b\\d{8,8}\\b');

        // If the above method returns null, fallback to extracting from plainTextBody
        return (caseNumber != null)
                ? caseNumber
                : findFirstMatch(email.plainTextBody, '\\b\\d{8,8}\\b');
    }

    /**
    * @description Extracts the STrack incident number from the email message.
    * @param email The inbound email message.
    * @return String The extracted STrack incident number.
    */
    public static String getSTrackIncidentNumberFromEmailMessage(Messaging.InboundEmail email) {
        String caseNumber = findFirstMatch(email.subject, '\\b\\d{9,9}\\b');

        // If the above method returns null, fallback to extracting from plainTextBody
        return (caseNumber != null)
                ? caseNumber
                : findFirstMatch(email.plainTextBody, '\\b\\d{9,9}\\b');
    }

    /**
    * @description Finds the first match for a given regex pattern in the input text.
    * @param inputText The text to search within.
    * @param regexPattern The regex pattern to match.
    * @return String The first match found.
    */
    public static String findFirstMatch(String inputText, String regexPattern) {
        // Compile the provided regex pattern
        Pattern pattern = Pattern.compile(regexPattern);
        Matcher matcher = pattern.matcher(inputText);

        // Check if a match is found
        if (matcher.find()) {
            String match = matcher.group(0); // Get the entire matched string
            return match;
        }
        return null; // Return null if no match is found
    }

    /**
    * @description Sends a single email using a template.
    * @param targetObjectId The ID of the target object.
    * @param whatId The ID of the related object.
    * @param toAddresses List of recipient email addresses.
    * @param templateDeveloperName The developer name of the email template.
    * @param saveAsActivity Boolean flag to save the email as an activity.
    * @param displayName The display name of the sender.
    */
    public static void sendSingleEmailUsingTemplate(Id targetObjectId, Id whatId, List<String> toAddresses, String templateDeveloperName, Boolean saveAsActivity, String displayName) {

        EmailTemplate emailTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateDeveloperName LIMIT 1];
        OrgWideEmailAddress orgWideEmailAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = :displayName LIMIT 1];

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        email.setTemplateId(emailTemplate.Id);
        email.setTargetObjectId(targetObjectId);
        email.setWhatId(whatId);
        email.setOrgWideEmailAddressId(orgWideEmailAddress.Id);
        email.setToAddresses(toAddresses);
        email.setSaveAsActivity(saveAsActivity);

        Messaging.sendEmail(new List<Messaging.Email>{
                email
        });
    }

    /**
    * @description Checks if the from address contains '@capitecbank.co.za'.
    * @param sFromAddress The from address to check.
    * @return Boolean True if the address contains '@capitecbank.co.za', otherwise false.
    */
    public static Boolean FromAddressCheck(String sFromAddress) {
        try {
            Boolean sContainsCapitec = sFromAddress.contains('@capitecbank.co.za');
            if (sContainsCapitec == true) {
                return true;
            } else {
                return false;
            }
        } catch (Exception e) {
            System.debug('Exception in FromAddressCheck: ' + e.getMessage());
            return false;
        }
    }
}