/**
 * @description
 * Handles inbound email messages for an Insurance Claims routing address.
 * This class mimics the Email-to-Case functionality and extends it by the ability to link the related case
 * through the case number. It converts attachments to ContentVersion objects, and process
 * specific emails from the Sanlam organization.
 * <a href='https://capitecbank.atlassian.net/browse/ICS-891'>ICS-891</a>
 *
 * @author Dawid Kuczer
 * @date 13.06.2024
 *
 */
global class IC_CaseEmailHandler implements Messaging.InboundEmailHandler {


    private static final String INSURANCE_CLAIMS_REC_TYPE_DEV_NAME = 'Insurance_Claims';
    private static final String INSURANCE_CLAIMS_ASSESSMENT_REC_TYPE_DEV_NAME = 'Insurance_Claims_Assessment';
    private static final String INSURANCE_CLAIMS_QUEUE_DEV_NAME = 'Credit_Life_Unclassified';
    private static final String OWNERTYPE_QUEUE = 'Group';


    /**
     * Handles the inbound email message.
     * <a href='https://capitecbank.atlassian.net/browse/ICS-891'>ICS-891</a>
     *
     * @param email The inbound email message.
     * @param envelope The envelope of the inbound email message.
     *
     * @return The result of the email handling process.
     *
     * @author Caleb Govender
     * Dawid Kuczer
     */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        EmailMessage emailMessage = new EmailMessage();

        emailMessage.FromAddress = email.fromAddress;
        emailMessage.FromName = email.fromName;
        emailMessage.Subject = email.subject;
        emailMessage.TextBody = email.plainTextBody;
        emailMessage.HtmlBody = email.htmlBody;
        emailMessage.MessageIdentifier = email.messageId;
        emailMessage.ToAddress = (email.toAddresses == null? '' : String.join(email.toAddresses, ','));
        emailMessage.CcAddress = (email.ccAddresses == null? '' : String.join(email.ccAddresses, ','));
        emailMessage.Incoming = true;


        //Try-Catch-Finally logic to Insert Email even if Case-linking processing fails to aid debugging visibility within  Salesforce - 01 Oct 2024 - Gerhard de Klerk
        Id caseId = null;
        try{
            //Additional debugs for production debugging purpose
            //ICS-1504 Dawid Kuczer

            System.debug(email.subject);

            //Change retrieval order - Check for Salesforce Thread ID before using the Subject with REGEX - 01 Oct 2024 - Gerhard de Klerk
            //SEARCH WITH CASE THREAD ID IN BODY
            caseId = EmailMessages.getRecordIdFromEmail(email.subject, email.plainTextBody, email.htmlBody);
            System.debug('Case Id from Id from Email: ' + caseId);

            //SEARCH WITH CASE ID  / STRACK IN SUBJECT
            if (caseId == null){
                caseId = IC_EmailCaseServices.returnCaseIdPatternSearch(email.subject);
                System.debug('Case Id from pattern: ' + caseId);
            }

            //SEARCH WITH CASE NUMBER IN SUBJECT (STARTING WITH CF)
            if (caseId == null) {
                //Search using the Case Number CF12345678
                caseId = IC_EmailCaseServices.returnCaseIdPatternSearchPolicyNumber(email.subject);
                System.debug('Case Id from Case Number pattern: ' + caseId);
            }

            //SEARCH WITH ID NUMBER IN SUBJECT
            if (caseId == null){
                caseId = IC_EmailCaseServices.returnCaseIdPatternSearchIDNumber(email.subject);
                System.debug('Case Id from pattern: ' + caseId);
            }

            /**********************************************************************************
             * ICS-1638 - 26 Sept 2024 - Temporary workaround to wake up case rather than create a new one
             **********************************************************************************
            if (caseId != null) {
                Case foundCase = [SELECT Id, Status FROM Case WHERE Id = :caseId];
                if (foundCase.Status == 'Finalised' || foundCase.Status == 'Closed') {
                    System.debug('Case closed - creating a new one');
                    caseId = null;
                }
            }
            */

            if (caseId == null) {
                System.debug('No existing case found, creating a new case');
                caseId = IC_EmailCaseServices.customEmailToCase(emailMessage, INSURANCE_CLAIMS_REC_TYPE_DEV_NAME, INSURANCE_CLAIMS_QUEUE_DEV_NAME);
            }

            //Set the Case
            emailMessage.ParentId = caseId;

        }catch (Exception e){
            System.debug('IC_CaseEmailHandler.handleInboundEmail ERROR');
            System.debug(e.getMessage());
            String errorSubject = '[LINK TO CASE FAILURE] ' + emailMessage.Subject + ' [STACKTRACE:: ' + e.getMessage();
            emailMessage.Subject = errorSubject.left(3000); //ENSURE THE STRING FITS IN THE DESIGNATED FIELD
        }finally{
            insert emailMessage;
            system.debug('***IC_CaseEmailHandler: insert emailMessage: ' + emailMessage);
        }

        //IF NO CASE WAS FOUND, EXIT THE METHOD
        if(caseId == NULL){
            return result;
        }

        /**
         * **********************************************************************************
         *  Case found or created, now time for the attachments and files
         * **********************************************************************************
        */


        List<Attachment> attachmentsFromEmail = new List<Attachment>();
        List<ContentVersion> caseFilesFromAttachments = new List<ContentVersion>();


        // Create Attachment records for each binary attachment
        if (email.binaryAttachments != null) {
            for (Messaging.InboundEmail.BinaryAttachment bAttachment : email.binaryAttachments) {

                Attachment newAttachment = generateSalesforceAttachment(bAttachment, emailMessage.Id);
                ContentVersion newContentVersion = generateFilesFromAttachment(newAttachment, caseId);

                attachmentsFromEmail.add(newAttachment);
                caseFilesFromAttachments.add(newContentVersion);
            }
        }


        // Create Attachment records for each text attachment
        if (email.textAttachments != null) {
            for (Messaging.InboundEmail.TextAttachment tAttachment : email.textAttachments) {

                Attachment newAttachment = generateSalesforceAttachment(tAttachment, emailMessage.Id);
                ContentVersion newContentVersion = generateFilesFromAttachment(newAttachment, caseId);

                attachmentsFromEmail.add(newAttachment);
                caseFilesFromAttachments.add(newContentVersion);
            }
        }

        insert attachmentsFromEmail;
        insert caseFilesFromAttachments;


        /**
         * **********************************************************************************
         *  Recognition and handling of responses to the cases
         * **********************************************************************************
        */


        //handleResponses(emailMessage, caseId);
        //Reopening of Case - check for attachment
        Boolean hasAttachment = null;
        if (caseFilesFromAttachments.size()>0){
            hasAttachment = true;
        }
        handleResponses(emailMessage, caseId, hasAttachment);

        return result;
    }


    /**
     * Generates a ContentVersion object from an Attachment object.
     * <a href='https://capitecbank.atlassian.net/browse/ICS-891'>ICS-891</a>
     *
     * @param attachment The Attachment object.
     * @param caseId The ID of the related case.
     *
     * @return The generated ContentVersion object.
     *
     * @author Dawid Kuczer
     */
    private static ContentVersion generateFilesFromAttachment(Attachment attachment, String caseId) {
        ContentVersion newContentVersion = new ContentVersion();
        newContentVersion.Title = attachment.Name;
        newContentVersion.PathOnClient = '/' + attachment.Name;
        newContentVersion.VersionData = attachment.Body;
        newContentVersion.FirstPublishLocationId = caseId;

        return newContentVersion;
    }

    /**
     * Generates a Salesforce Attachment object from a binary attachment.
     * <a href='https://capitecbank.atlassian.net/browse/ICS-891'>ICS-891</a>
     *
     * @param bAttachment The binary attachment.
     * @param emailId The ID of the related email message.
     *
     * @return The generated Attachment object.
     *
     * @author Dawid Kuczer
     */
    private static Attachment generateSalesforceAttachment(Messaging.InboundEmail.BinaryAttachment bAttachment, String emailId) {
        Attachment attachment = new Attachment();
        attachment.Name = bAttachment.fileName;
        attachment.Body = bAttachment.body;
        attachment.ParentId = emailId;

        return attachment;
    }


    /**
     * Generates a Salesforce Attachment object from a text attachment.
     * <a href='https://capitecbank.atlassian.net/browse/ICS-891'>ICS-891</a>
     *
     * @param tAttachment The text attachment.
     * @param emailId The ID of the related email message.
     *
     * @return The generated Attachment object.
     *
     * @author Dawid Kuczer
     */
    private static Attachment generateSalesforceAttachment(Messaging.InboundEmail.TextAttachment tAttachment, String emailId) {
        Attachment attachment = new Attachment();
        attachment.Name = tAttachment.fileName;
        attachment.Body = Blob.valueOf(tAttachment.body);
        attachment.ParentId = emailId;

        return attachment;
    }


    /**
     * Handles specific email messages from the Sanlam organization. <br>
     * Originally: <a href='https://capitecbank.atlassian.net/browse/ICS-1142'>ICS-1142</a> <br>
     * Additionally: ICS-877
     *
     * @param emailMsg The email message.
     * @param caseId The ID of the related case.
     *
     * @author Dawid Kuczer
     *
     * @date 24.06.2024
     */
    @TestVisible
    private static void handleResponses(EmailMessage emailMsg, String caseId, Boolean hasAttachment) {
        Case parentCase = [
                SELECT Id, Status, Sub_Status__c, IC_Sanlam_Claim__c, Owner.Name, Owner.Type, Email_Address__c, IC_Insurer_Underwriter_at_Event_Date__c
                FROM Case
                WHERE Id = :caseId
                AND RecordType.DeveloperName IN ('Insurance_Claims', 'Insurance_Claims_Assessment')
        ];


        Id ownerId = parentCase.OwnerId;
        String ownerType = String.valueof(ownerId.getSobjectType());
        String ownerName = null;
        switch on ownerType{
            when 'User'{
                User u = [SELECT Id, Name FROM User WHERE Id =: ownerId LIMIT 1];
                system.debug(u);
                ownerName = u.Name;
            }
            when 'Group'{
                Group g = [SELECT Id, Name FROM Group WHERE Id =: ownerId LIMIT 1];
                system.debug(g);
                ownerName = g.Name;
            }
        }

        system.debug('%%%parentCase.Owner?.Type: ' + parentCase.Owner?.Type);
        system.debug('%%%OwnerName: ' + ownerName);
        system.debug('%%%OwnerType: ' + ownerType);


        String initialCaseStatus = parentCase.Status;

        /**
        * ********************************************************
        * ICS-1142; Sanlam responses handling; Dawid Kuczer 21.06.2024
        * ********************************************************
        */
        String emailMessageBody = null;
        if (emailMsg.TextBody != NULL){
            system.debug('***IC_CaseEmailHandler.handleResponses: emailMsg.TextBody != null');
            emailMessageBody = emailMsg.TextBody;
        }else if(emailMsg.HtmlBody != NULL){
            system.debug('***IC_CaseEmailHandler.handleResponses: emailMsg.HtmlBody != NULL');
            emailMessageBody = emailMsg.HtmlBody;
        }


        /*
         * NOTE - this has been deprecated on 09 Nov 2024 - New repudiation process - Gerhard de Klerk && Werner Wassermann
         * if(parentCase.IC_Insurer_Underwriter_at_Event_Date__c == 'Centriq'){
            if(parentCase.Status == 'Assessment' || parentCase.Status == 'Assessment Pending'){
                Group funeralAssessmentQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'IC_Second_Assessment_Queue'];
                parentCase.OwnerId = funeralAssessmentQueue.Id;
                parentCase.Sub_Status__c = 'Update Received';

                update parentCase;
            }
        }
        else */
        if (parentCase.IC_Sanlam_Claim__c) {
            Boolean isAcknowledgement = IC_EmailMessageDomain.searchForSanlamAcknowledgement(emailMessageBody);
            Boolean isAwaitingCentriqRepudiationApproval = IC_EmailMessageDomain.searchForSanlamWaitingCentriqReupdiationApproval(emailMessageBody);
            //Boolean isAssessmentDelay = IC_EmailMessageDomain.searchForSanlamAssessmentDelay(emailMessageBody); // 04 Oct 2024 - This feature will be rolled out at a later stage - Gerhard de Klerk

            //AC 2
            if ((isAcknowledgement || isAwaitingCentriqRepudiationApproval) && emailMsg.FromAddress.contains(System.Label.IC_Sanlam_Email_Identificator)){ // 02 Oct 2024 - Gerhard de Klerk: //&& parentCase.Owner.Name == 'Waiting for Sanlam Assessment') {
                //IC_EmailMessageDomain.updateCaseSanlamAcknowledgment(parentCase); //08 Oct 2024 - Gerhard de Klerk - The acknowledgement should not wake the Case, NOR change the owner
            }
            else if (emailMsg.FromAddress.contains(System.Label.IC_FMScenta_Identifier) ){
                //Any emails from FMSCenta should not wake the case
            }
            //AC 3
            else if (!isAcknowledgement && ownerType == OWNERTYPE_QUEUE && ownerName.contains('Sanlam')) {
                IC_EmailMessageDomain.updateCaseSanlamResponseWaitingQueue(parentCase);
            }
            else if (!isAcknowledgement && ownerType == OWNERTYPE_QUEUE && ownerName.contains('Wait')) {
                IC_EmailMessageDomain.updateCaseSanlamFuneralClaimsQueue(parentCase); //Funeral Claims
            }

            // 03 Oct 2024 - Gerhard de Klerk - Additional Email parsing logic
            Boolean isSanlamNeedsDocs = IC_EmailMessageDomain.searchForSanlamNeedsDocs(emailMessageBody);
            Boolean isSanlamRepudiationLetterReceived = IC_EmailMessageDomain.searchForSanlamRepudiationLetterReceived(emailMessageBody);
            Boolean isSanlamRepudiationLetterReceived_Other = IC_EmailMessageDomain.searchForSanlamRepudiationLetterReceived_OtherVersion(emailMessageBody);
            Boolean isSanlamClaimFinalized = IC_EmailMessageDomain.searchForSanlamClaimFinalized(emailMessageBody);
            Boolean isSanlamClaimFinalizedNaturalDeath = IC_EmailMessageDomain.searchForSanlamClaimFinalizedNaturalDeath(emailMessageBody);

            if (isSanlamNeedsDocs){
                IC_EmailMessageDomain.updateCaseSanlamNeedsDocs(parentCase);
            }
            if (isSanlamRepudiationLetterReceived || isSanlamRepudiationLetterReceived_Other){
                IC_EmailMessageDomain.updateCaseSanlamRepudiationLetterReceived(parentCase);
            }
            if (isSanlamClaimFinalized || isSanlamClaimFinalizedNaturalDeath){
                IC_EmailMessageDomain.updateCaseSanlamClaimFinalized(parentCase);
            }

            /* ******************************************************************************
             * 25 Sept 2024 - Sanlam Response automations - ICS-1638
             * ******************************************************************************
             // 04 Oct 2024 - This feature will be rolled out at a later stage - Gerhard de Klerk
            if (isAssessmentDelay){
                system.debug('*** isAssessmentDelay ***');
                if(parentCase.Email_Address__c != null){
                    IC_EmailMessageDomain.notifyClientSanlamAssessmentDelay(parentCase);
                }

                else if(parentCase.Mobile_Number__c != null ){
                    //SEND SMS
                }
            }

            */

        }


        /**
         * XTND RESPONSE - 31 Oct 2024 - Gerhard de Klerk
         */
        else if (
                        emailMsg.FromAddress.contains(System.Label.IC_XTND_Status_Report_Email) &&
                                ownerType == OWNERTYPE_QUEUE &&
                                ownerName.contains('XTND')
                ) {
            IC_EmailMessageDomain.handleXTNDResponse(parentCase);
        }
        /*
         * Centriq response - 04 Nov 204 - Gerhard de Klerk
         */
        else if (
                        emailMsg.FromAddress.contains(System.Label.IC_CentriqResponseEmailIdentifier) &&
                                ownerType == OWNERTYPE_QUEUE &&
                                ownerName.contains('Wait')
        ) {
            system.debug('%%% IC_CaseEmailHandler - centriq response');
            IC_EmailMessageDomain.handleCentriqResponse(parentCase);
        }
        /**
        * ********************************************************
        * ICS-877; Escalation responses handling; Dawid Kuczer 21.06.2024
        * ********************************************************
        */

        else if (IC_EmailMessageDomain.isEscalationAssessmentResponse(parentCase)) {
            IC_EmailMessageDomain.handleEscalationAssessmentResponse(parentCase);
        }


        //ICS-2006 - LongOutstandingClaim (LOC) Reopen Case logic
        String finalCaseStatus = parentCase.Status;

        System.debug('&&&& initialCaseStatus: ' + initialCaseStatus);
        System.debug('&&&& finalCaseStatus: ' + finalCaseStatus);

        if ((initialCaseStatus == 'Closed' || initialCaseStatus == 'Finalised') &&
                finalCaseStatus != initialCaseStatus ){
            //Case has been reopened
            if(hasAttachment == true){
                //The email that woke the case had an attachment
                try{
                    IC_LongOutstandingClaims_Reopen.reopenClaim(caseId,'Email',true);
                }catch (Exception e){
                System.debug('An exception occurred with the email handler while reopening the claim: ' + e.getMessage());
                }
            }

        }

    }
}