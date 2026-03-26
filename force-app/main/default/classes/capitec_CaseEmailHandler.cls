/**
 * This global class implements the Messaging.InboundEmailHandler interface to handle inbound emails in Salesforce.
 * It processes the email, extracts necessary information, and creates an EmailMessage record. If a related Case can be identified from the email subject or headers, the EmailMessage is associated with that Case. If no related Case can be found, it calls the CustomEmailToCase method from the capitec_CaseEmailHandlerFunctions class to create a new Case and associate the EmailMessage with it.
 *
 * @author Caleb Govender
 * @author Dawid Kuczer
 * @date 23.04.2024
 *
 * @LastModified 21.01.2025
 * @LastModifiedBy Dhriven Hamlall
 */
global class capitec_CaseEmailHandler implements Messaging.InboundEmailHandler {

    private static final String FRAUD_QUEUE_DEV_NAME = 'Fraud_Email_Cases';

    /**
     * This method is triggered when an inbound email is received in Salesforce.
     * It processes the inbound email, extracts necessary information, and creates an EmailMessage record.
     * If a related Case can be identified from the email subject or headers, the EmailMessage is associated with that Case.
     * If no related Case can be found, it calls the CustomEmailToCase method from the capitec_CaseEmailHandlerFunctions class to create a new Case and associate the EmailMessage with it.
     * The method returns a Messaging.InboundEmailResult object.
     * 
     * <a href='https://capitecbank.atlassian.net/browse/FFSF-525'>FFSF-525</a>
     * <a href='https://capitecbank.atlassian.net/browse/FFSF-791'>FFSF-791</a>
     * <a href='https://capitecbank.atlassian.net/browse/FFSF-792'>FFSF-792</a>
     * <a href='https://capitecbank.atlassian.net/browse/FFSF-793'>FFSF-793</a>
     * <a href='https://capitecbank.atlassian.net/browse/FFSF-834'>FFSF-834</a>
     * <a href='https://capitecbank.atlassian.net/browse/FFSF-808'>FFSF-808</a>
     * <a href='https://capitecbank.atlassian.net/browse/FFSF-846'>FFSF-846</a>
     * <a href='https://capitecbank.atlassian.net/browse/FFSF-867'>FFSF-867</a>
     * <a href='https://capitecbank.atlassian.net/browse/FCO-84'>FCO-84</a>
     * <a href='https://capitecbank.atlassian.net/browse/FCO-81'>FCO-81</a>
     * <a href='https://capitecbank.atlassian.net/browse/FCO-92'>FCO-92</a>
     *
     * @author Caleb Govender
     * @LastModified 15.10.2024
     * @param email The inbound email received in Salesforce.
     * @param envelope The envelope of the inbound email.
     * @return A Messaging.InboundEmailResult object indicating the result of the email handling process.
     */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        String sCCAddress = '';
        String sToAddress = '';
        String sCaseQueue = '';
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        EmailMessage emailMessage = new EmailMessage();

        emailMessage.FromAddress = email.fromAddress;
        emailMessage.FromName = email.fromName;
        emailMessage.Subject = email.subject;
        emailMessage.TextBody = email.plainTextBody;
        emailMessage.HtmlBody = email.htmlBody;
        emailMessage.MessageIdentifier = email.messageId;

        if(email.toAddresses.size() > 1){ //FFSF-867 Added to capture all To Addresses
            for (String toAddress : email.toAddresses) {
                sToAddress += toAddress + '; ';
            }
            emailMessage.ToAddress = sToAddress;
        }else{
            emailMessage.ToAddress = email.toAddresses[0];
        }

        if(email.ccAddresses != null){ //FFSF-867 Added to capture all CC Addresses FCO-84 PRD Bug Fix
            sCCAddress = capitec_CaseEmailHandlerFunctions.CCAddressCheck(email.ccAddresses); //FCO-92
            emailMessage.CcAddress = sCCAddress;
        }
        emailMessage.Incoming = true;

        Id caseId = EmailMessages.getRecordIdFromEmail(email.subject, email.plainTextBody, email.htmlBody);
        String caseRecordType = capitec_CaseEmailHandlerFunctions.getRecordTypeWithFromAddress(email.fromAddress);

        if (caseId == null) {
            caseId = Cases.getCaseIdFromEmailHeaders(email.headers);
        }
        
		if (caseId != null) {
            caseId = capitec_CaseEmailHandlerFunctions.CaseStatusCheck(caseId, emailMessage);
		} 

        if (caseId == null) {
                caseId = capitec_CaseEmailHandlerFunctions.LikeCaseIdSearch(email.subject,emailMessage); //FFSF-791 Added to enable LIKE Search for Case Number
        }
        if (caseId == null) {
                caseId = capitec_CaseEmailHandlerFunctions.returnCaseIdPatternSearch(email.subject, caseRecordType, emailMessage);
        }

        sCaseQueue = capitec_CaseEmailHandlerFunctions.CaseQueueCheck(email.subject);
        if (sCaseQueue == null  || sCaseQueue == '') {
            sCaseQueue = capitec_CaseEmailHandlerFunctions.FromAddressCaseQueueCheck(email.fromAddress);
        }

        if (caseId == null) {
            caseId = capitec_CaseEmailHandlerFunctions.CustomEmailToCase(emailMessage, caseRecordType, sCaseQueue,'','Medium');
        }

        //FFSF-792,FFSF-793 Added to link the case to the account using ID
        capitec_CaseEmailHandlerFunctions.CaseIdNumberAccountAndContactLinking(email.subject,caseId); //FFSF-834 Added Contact Linking

        emailMessage.RelatedToId = caseId;
        insert emailMessage;

        List<Attachment> attachmentsFromEmail = new List<Attachment>();
        List<ContentVersion> caseFilesFromAttachments = new List<ContentVersion>();


        // Create Attachment records for each binary attachment
        if(email.binaryAttachments != null){
            for (Messaging.InboundEmail.BinaryAttachment bAttachment : email.binaryAttachments) {

                Attachment newAttachment = generateSalesforceAttachment(bAttachment, emailMessage.Id);
                ContentVersion newContentVersion = generateFilesFromAttachment(newAttachment, caseId);

                attachmentsFromEmail.add(newAttachment);
                caseFilesFromAttachments.add(newContentVersion);
            }
        }


        // Create Attachment records for each text attachment
        if(email.textAttachments != null){
            for (Messaging.InboundEmail.TextAttachment tAttachment : email.textAttachments) {

                Attachment newAttachment = generateSalesforceAttachment(tAttachment, emailMessage.Id);
                ContentVersion newContentVersion = generateFilesFromAttachment(newAttachment, caseId);

                attachmentsFromEmail.add(newAttachment);
                caseFilesFromAttachments.add(newContentVersion);
            }
        }

        insert attachmentsFromEmail;
        insert caseFilesFromAttachments;

        return result;
    }

    /**
    * @description
    * Generates a ContentVersion object from an Attachment object.
    * @author Caleb Govender
    * @author Dawid Kuczer
    *
    * @param attachment The Attachment object.
    * @param caseId     The ID of the related case.
    * @return The generated ContentVersion object.
     */
    private static ContentVersion generateFilesFromAttachment(Attachment attachment, String caseId){
        ContentVersion newContentVersion = new ContentVersion();
        newContentVersion.Title = attachment.Name;
        newContentVersion.PathOnClient = '/' + attachment.Name;
        newContentVersion.VersionData = attachment.Body;
        newContentVersion.FirstPublishLocationId = caseId;

        return newContentVersion;
    }

    /**
     * @description
     * Generates a Salesforce Attachment object from a binary attachment.
     * @author Caleb Govender
     * @author Dawid Kuczer
     *
     * @param bAttachment The binary attachment.
     * @param emailId     The ID of the related email message.
     * @return The generated Attachment object.
     */
    private static Attachment generateSalesforceAttachment(Messaging.InboundEmail.BinaryAttachment bAttachment, String emailId){
        Attachment attachment = new Attachment();
        attachment.Name = bAttachment.fileName;
        attachment.Body = bAttachment.body;
        attachment.ParentId = emailId;

        return attachment;
    }


    /**
     * @description
     * Generates a Salesforce Attachment object from a text attachment.
     * @author Caleb Govender
     * @author Dawid Kuczer
     *
     * @param tAttachment The text attachment.
     * @param emailId     The ID of the related email message.
     * @return The generated Attachment object.
     */
    private static Attachment generateSalesforceAttachment(Messaging.InboundEmail.TextAttachment tAttachment, String emailId){
        Attachment attachment = new Attachment();
        attachment.Name = tAttachment.fileName;
        attachment.Body = Blob.valueOf(tAttachment.body);
        attachment.ParentId = emailId;

        return attachment;
    }
}