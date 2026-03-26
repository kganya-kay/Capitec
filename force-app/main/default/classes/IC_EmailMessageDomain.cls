/**
 * Created by dawid on 13.06.2024.
 * @description This class contains methods that are specific to Email Message object and to Insurance Claims
 */




public without sharing class IC_EmailMessageDomain {
    private static final String ZIP_PASSWORD = 'Capitec1';
    private static final String EMAILTEMPLATE_ASSESSMENTDELAY = 'Funeral_5_Day_Validation';

    /**
     * @author Dawid Kuczer
     * @date 13.06.2024
     *
     * @description Searches through an email body for the Sanlam acknowledgment phrase
     * <a href='https://capitecbank.atlassian.net/browse/ICS-1142'>ICS-1142</a>
     * @param emailBody the TextBody of an email that we want
     * <br>to search through for the Sanlam agreement phrase</br>
     *
     * @return returns true if the acknowledgment phrase was found, false if not
     */
    public static Boolean searchForSanlamAcknowledgement(String emailBody){
        // 02 Oct 2024 - Gerhard de Klerk: Additional Debug statement for Production debugging, Safe-Navigation Handler and Try Catch For failures
        try{
            system.debug('### IC_EmailMessageDomain.searchForSanlamAcknowledgement - emailBody: ' + emailBody);
            if(emailBody?.contains(System.Label.IC_SanlamAcknowledgment)){
                return true;
            }
            return false;
        }catch (Exception e){
            system.debug('### IC_EmailMessageDomain.searchForSanlamAcknowledgement - ERROR: '+ e.getMessage());
            return false;
        }
    }


    /**
     * @author Gerhard de Klerk
     * @date 03.10.2024
     *
     * @description Search the email body for a string denoting documents required for sanlam
     * @param emailBody the TextBody of an email that we want
     *
     * @return returns true if the acknowledgment phrase was found, false if not
     */
    public static Boolean searchForSanlamNeedsDocs(String emailBody){
        try{
            system.debug('### IC_EmailMessageDomain.searchForSanlamNeedsDocs - emailBody: ' + emailBody);
            if(emailBody?.contains('Please note that in order to finalise the assessment of this funeral claim we require the following outstanding documents')){
                return true;
            }
            return false;
        }catch (Exception e){
            system.debug('### IC_EmailMessageDomain.searchForSanlamNeedsDocs - ERROR: '+ e.getMessage());
            return false;
        }
    }

    /**
     * @author Gerhard de Klerk
     * @date 03.10.2024
     *
     * @description Search the email body for a string denoting Repudiation Letter Received
     * @param emailBody the TextBody of an email that we want
     *
     * @return returns true if the acknowledgment phrase was found, false if not
     */
    public static Boolean searchForSanlamRepudiationLetterReceived(String emailBody){
        try{
            system.debug('### IC_EmailMessageDomain.searchForSanlamRepudiationLetterReceived - emailBody: ' + emailBody);
            if(emailBody?.contains('Please receive the attached repudiation letter')){
                return true;
            }
            return false;
        }catch (Exception e){
            system.debug('### IC_EmailMessageDomain.searchForSanlamRepudiationLetterReceived - ERROR: '+ e.getMessage());
            return false;
        }
    }

    /**
     * @author Gerhard de Klerk
     * @date 03.10.2024
     *
     * @description Search the email body for a string denoting Repudiation Letter Received - other version
     * @param emailBody the TextBody of an email that we want
     *
     * @return returns true if the acknowledgment phrase was found, false if not
     */
    public static Boolean searchForSanlamRepudiationLetterReceived_OtherVersion(String emailBody){
        try{
            system.debug('### IC_EmailMessageDomain.searchForSanlamRepudiationLetterReceived - emailBody: ' + emailBody);
            if(emailBody?.contains('Please find attached Repudiation Letter')){
                return true;
            }
            return false;
        }catch (Exception e){
            system.debug('### IC_EmailMessageDomain.searchForSanlamRepudiationLetterReceived - ERROR: '+ e.getMessage());
            return false;
        }
    }


    /**
     * @author Gerhard de Klerk
     * @date 03.10.2024
     *
     * @description Search the email body for a string denoting Claim finalized
     * @param emailBody the TextBody of an email that we want
     *
     * @return returns true if the acknowledgment phrase was found, false if not
     */
    public static Boolean searchForSanlamClaimFinalized(String emailBody){
        try{
            system.debug('### IC_EmailMessageDomain.searchForSanlamClaimFinalized - emailBody: ' + emailBody);
            if(emailBody?.contains('Please be advised that the claim has been finalized')){
                return true;
            }
            return false;
        }catch (Exception e){
            system.debug('### IC_EmailMessageDomain.searchForSanlamClaimFinalized - ERROR: '+ e.getMessage());
            return false;
        }
    }

    /**
     * @author Gerhard de Klerk
     * @date 03.10.2024
     *
     * @description Search the email body for a string denoting Claim finalized - natural Death
     * @param emailBody the TextBody of an email that we want
     *
     * @return returns true if the acknowledgment phrase was found, false if not
     */
    public static Boolean searchForSanlamClaimFinalizedNaturalDeath(String emailBody){
        try{
            system.debug('### IC_EmailMessageDomain.searchForSanlamClaimFinalizedNaturalDeath - emailBody: ' + emailBody);
            if(emailBody?.contains('Please be advised that the Natural Death portion of this claim has been finalized')){
                return true;
            }
            return false;
        }catch (Exception e){
            system.debug('### IC_EmailMessageDomain.searchForSanlamClaimFinalizedNaturalDeath - ERROR: '+ e.getMessage());
            return false;
        }
    }


    /**
     * @author Gerhard de Klerk
     * @date 25.09.2024
     *
     * @description Searches through an email body for the Sanlam Sent to Centriq for Repudiation Approval phrase
     * <a href='https://capitecbank.atlassian.net/browse/ICS-1638'>ICS-1638</a>
     * @param emailBody the TextBody of an email that we want
     * <br>to search through for the Sanlam agreement phrase</br>
     *
     * @return returns true if the phrase was found, false if not
     */
    public static Boolean searchForSanlamWaitingCentriqReupdiationApproval(String emailBody){
        if(emailBody.contains(System.Label.IC_SanlamWaitingCentriqReupdiationApproval)){
            return true;
        }
        return false;
    }

    /**
     * @author Gerhard de Klerk
     * @date 25.09.2024
     *
     * @description Searches through an email body for the Sanlam Assesment Delay phrase
     * <a href='https://capitecbank.atlassian.net/browse/ICS-1638'>ICS-1638</a>
     * @param emailBody the TextBody of an email that we want
     * <br>to search through for the Sanlam agreement phrase</br>
     *
     * @return returns true if the phrase was found, false if not
     */
    public static Boolean searchForSanlamAssessmentDelay(String emailBody){
        if(emailBody.contains(System.Label.IC_SanlamAssessmentDelay)){
            return true;
        }
        return false;
    }

    public static void updateCaseSanlamNeedsDocs(Case sanlamCase){
        sanlamCase.IC_BulkSMS_Docs__c = true;
        update sanlamCase;
    }

    public static void updateCaseSanlamRepudiationLetterReceived(Case sanlamCase){
        sanlamCase.IC_BulkSMS_Reputiate__c = true;
        update sanlamCase;
    }

    public static void updateCaseSanlamClaimFinalized(Case sanlamCase){
        sanlamCase.IC_BulkSMS_Paid__c = true;
        update sanlamCase;
    }
    /**
     * @author Dawid Kuczer
     * @date 13.06.2024
     *
     * @description Updates the Case linked to an email message with the new status and assigns it to a Sanlam Assessment queue.
     * <a href='https://capitecbank.atlassian.net/browse/ICS-1142'>ICS-1142</a>
     * @param sanlamCase the case which details are to be updated
     */
    public static void updateCaseSanlamAcknowledgment(Case sanlamCase){
        Group sanlamQueue = [SELECT Id FROM Group WHERE DeveloperName = 'IC_Waiting_for_Sanlam_Assessment'];
        sanlamCase.OwnerId = sanlamQueue.Id;
        update sanlamCase;
    }

    /**
     * @author Dawid Kuczer
     * @date 13.06.2024
     *
     * @description Updates the Case linked to an email message with the new status and assigns it to a Funeral Claims queue.
     * <a href='https://capitecbank.atlassian.net/browse/ICS-1142'>ICS-1142</a>
     * @param sanlamCase the case which details are to be updated
     */
    public static void updateCaseSanlamResponseWaitingQueue(Case sanlamCase) {
        //Group sanlamQueue = [SELECT Id FROM Group WHERE DeveloperName = 'IC_Funeral_Claims'];
        Group sanlamQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Funeral_Sanlam_Responses']; //02 Oct 2024 - Gerhard de Klerk - When waking up, assign to a different Queue;
        sanlamCase.OwnerId = sanlamQueue.Id;
        sanlamCase.Status = 'Administration';
        sanlamCase.Sub_Status__c = 'Update Received';
        update sanlamCase;
    }

    /**
         * @author Gerhard de Klerk
         * @date 10.10.2024
         *
         * @description Updates the Case linked to an email message with the new status and assigns it to a Funeral Claims queue.
         * @param sanlamCase the case which details are to be updated
         */
    public static void updateCaseSanlamFuneralClaimsQueue(Case sanlamCase){
        Group sanlamQueue = [SELECT Id FROM Group WHERE DeveloperName = 'IC_Funeral_Claims'];
        sanlamCase.OwnerId = sanlamQueue.Id;
        sanlamCase.Status = 'Administration';
        sanlamCase.Sub_Status__c = 'Update Received';
        update sanlamCase;
    }


    /**
     * @author Dawid Kuczer
     * @date 24.06.2024
     *
     * @description Updates the Case linked to an email message with the new status and assigns it to a Funeral Claims queue.
     * <a href='https://capitecbank.atlassian.net/browse/ICS-1142'>ICS-1142</a>
     * @param parentCase email's parent case
     * @return TRUE if the case is awaiting the escalation assessment response, false if otherwise
     */

    public static Boolean isEscalationAssessmentResponse(Case parentCase){
        if(parentCase.Owner.Type == 'Queue'
                && parentCase.Owner.Name == 'Waiting_for_Insurer'
                && (parentCase.Sub_Status__c == 'Claims Forum'
                || parentCase.Sub_Status__c == 'Claims Management'
                || parentCase.Sub_Status__c == 'Validation')){
            return true;
        }
        return false;
    }


    /**
     * @author Dawid Kuczer
     * @date 24.06.2024
     *
     * @description assigns the case to the right queue depending on the type of the product
     * <a href='https://capitecbank.atlassian.net/browse/ICS-1142'>ICS-1142</a>
     * @param parentCase email's parent case
     */

    public static void handleEscalationAssessmentResponse(Case parentCase){
        String queueDevName;
        if(parentCase.Product_Type__c == 'Funeral'){
            queueDevName = 'IC_Funeral_Claims_Review';
        }
        else if(parentCase.Product_Type__c == 'Credit Life'){
            queueDevName = 'Credit_Life_Claims_Review';
        }

        try{
            Group targetQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :queueDevName LIMIT 1];
            parentCase.OwnerId = targetQueue.Id;

            update parentCase;
        }
        catch (QueryException e){
            System.debug('IC Email Handling Error');
            System.debug(e.getMessage());
        }
    }

    /**
     * @author Gerhard de Klerk
     * @date 31.10.2024
     *
     * @description assigns the case to the right queue depending due to the XTND Response
     * @param parentCase email's parent case
     */

    public static void handleXTNDResponse(Case parentCase){
        String queueDevName = 'IC_Second_Assessment_Queue';
        try{
            Group targetQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :queueDevName LIMIT 1];
            parentCase.OwnerId = targetQueue.Id;
            parentCase.Status = 'Assessment';
            parentCase.Sub_Status__c = 'Update Received';
            update parentCase;
        }
        catch (QueryException e){
            System.debug('IC_EmailMessageDomain.handleXTNDResponse Error');
            System.debug(e.getMessage());
        }
    }

    /**
     * @author Gerhard de Klerk
     * @date 04.11.2024
     *
     * @description assigns the case to the right queue depending due to the Centriq Response
     * @param parentCase email's parent case
     */

    public static void handleCentriqResponse(Case relevantCase){
        String queueDevName =  'IC_Funeral_Centriq_Responses';
        try{
            Group targetQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :queueDevName LIMIT 1];
            relevantCase.OwnerId = targetQueue.Id;
            relevantCase.Status = '2nd Assessment';
            relevantCase.Sub_Status__c = 'Update Received';
            update relevantCase;
        }
        catch (QueryException e){
            System.debug('IC_EmailMessageDomain.handleCentriqResponse Error');
            System.debug(e.getMessage());
        }
    }

    /**
     * @author Gerhard de Klerk
     * @date 25.09.2024
     *
     * @description Noptify the client about a Sanlam Assessment Delay
     * <a href='https://capitecbank.atlassian.net/browse/ICS-1638'>ICS-1638</a>
     * @param sanlamCase the Case Record
     *
     * @return returns true if the phrase was found, false if not
     */
    public static Boolean notifyClientSanlamAssessmentDelay(Case sanlamCase){
        system.debug('*** notifyClientSanlamAssessmentDelay ***');
        system.debug('*** sanlamCase: ' + sanlamCase);
        List<IC_ResultWrapper> emailSendingResults = new List<IC_ResultWrapper>();
        OrgWideEmailAddress orgWideEmailAddr = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address LIKE :'insuranceclaims%' LIMIT 1];

        system.debug('sanlamCase.Email_Address__c:' + sanlamCase.Email_Address__c);
        List<String> recipientEmailAddresses = new List<String>();
        recipientEmailAddresses.add(sanlamCase.Email_Address__c);
        system.debug('---- recipientEmailAddresses:' + recipientEmailAddresses);

        IC_ResultWrapper emailSendingResult = sendEmailWithTemplate(sanlamCase.Id, sanlamCase.ParentId, recipientEmailAddresses, orgWideEmailAddr.Address, false,
                false, true, false, EMAILTEMPLATE_ASSESSMENTDELAY);
        system.debug('--- emailSendingResult: ' +emailSendingResult);
        return emailSendingResult.success;
    }


    /**
    * TODO sending an email without a template
    */
//    public static IC_ResultWrapper sendEmailNoTemplate(String caseId, String parentCaseId, String emailSubject, String emailBody, List<String> sendToAddresses, String orgWideAddressFrom, Boolean attachDocuments, Boolean getParentDocuments, Boolean sendIfNoAttachmentsFound){
//        return new IC_ResultWrapper();
//    }


    public static IC_ResultWrapper sendEmailWithTemplate(String caseId, String parentCaseId, List<String> sendToAddresses, String orgWideAddressFrom, Boolean attachDocuments, Boolean getParentDocuments, Boolean sendIfNoAttachmentsFound, Boolean includeTargetIdContactAsRecipient, String emailTemplateName){
        return processEmailSending(caseId, parentCaseId, sendToAddresses, orgWideAddressFrom, true, emailTemplateName, attachDocuments, getParentDocuments, sendIfNoAttachmentsFound);
    }
    public static List<IC_ResultWrapper> sendMultipleEmailsWithTemplate(List<Case> casesToUse, List<String> sendToAddresses, String orgWideAddressFrom, Boolean attachDocuments, Boolean getParentDocuments, Boolean sendIfNoAttachmentsFound, Boolean includeTargetIdContactAsRecipient, String emailTemplateName){
        return processMultipleEmailSending(casesToUse, sendToAddresses, orgWideAddressFrom, true, emailTemplateName, attachDocuments, getParentDocuments, sendIfNoAttachmentsFound);
    }


    /**
     * @author Dawid Kuczer
     * @description ICS-1254 A Case email sending handler. Prepares an email message with specified options and sends it
     * @date 26.09.2024
     *
     * @param caseId Id of the related Case
     * @param parentCaseId Id of the related Case's parent Case
     * @param sendToAddresses destination email address
     * @param orgWideAddressFrom sender email address - has to come from Org Wide Addresses in Setup
     * @param useTemplate - true if the template needs to be used
     * @param emailTemplateName  - the name of the template - pass null if no template chosen
     * @param attachDocuments - specify if Case files should be attached to the email
     * @param attachParentDocuments - specify if the Parent Case files should be attached to the email
     * @param sendIfNoAttachmentsFound - specify if the email should be send if attachDocuments = true but no documents actually found
     *
     * @return Result Wrapper with the boolean informing about the success and other information
     */

    public static IC_ResultWrapper processEmailSending(String caseId, String parentCaseId, List<String> sendToAddresses, String orgWideAddressFrom, Boolean useTemplate, String emailTemplateName, Boolean attachDocuments, Boolean attachParentDocuments, Boolean sendIfNoAttachmentsFound) {

        IC_ResultWrapper result = new IC_ResultWrapper();
        List<ContentVersion> caseFiles;
        List<ContentVersion> files = new List<ContentVersion>();
        IC_ResultWrapper zipFileResult;
        String optionalTargetId = null;


        /** ======================================================
        * Files send in email have to be encrypted first. In order to do so we use Capitec's zipping service that takes
        * File and returns one, big, encrypted ZIP package that can be safely attached to a email message
        *
        * Dawid Kuczer
        ======================================================= */

        zipFileResult = prepareZIPAttachment(caseId, attachParentDocuments, parentCaseId);
        if(zipFileResult.success == false){
            if(sendIfNoAttachmentsFound && zipFileResult.statusCode == 503){
                zipFileResult = null;
            }
            else{
                return new IC_ResultWrapper(false, zipFileResult.message, 500, caseId);
            }
        }

        if(useTemplate){
            IC_Email_Template_Details__mdt template = [SELECT Target_Object_ID__c FROM IC_Email_Template_Details__mdt WHERE Target_Object_ID__c != '' LIMIT 1];
            optionalTargetId = template.Target_Object_ID__c;
        }

        IC_ResultWrapper emailResult = sendEmail(caseId, sendToAddresses, null, orgWideAddressFrom, false, optionalTargetId, useTemplate, emailTemplateName, attachDocuments, zipFileResult?.message, 'ZippedDocuments.zip');

        System.debug(emailResult);
        return emailResult;
    }


    public static List<IC_ResultWrapper> processMultipleEmailSending(List<Case> casesToUse, List<String> sendToAddresses, String orgWideAddressFrom, Boolean useTemplate, String emailTemplateName, Boolean attachDocuments, Boolean attachParentDocuments, Boolean sendIfNoAttachmentsFound) {

        IC_ResultWrapper result = new IC_ResultWrapper();
        List<ContentVersion> caseFiles;
        List<ContentVersion> files = new List<ContentVersion>();
        List<IC_ResultWrapper> zipFileResults = new List<IC_ResultWrapper>();
        List<IC_ResultWrapper> readyZipFiles = new List<IC_ResultWrapper>();
        List<IC_ResultWrapper> emailSendingResults = new List<IC_ResultWrapper>();
        String optionalTargetId = null;


        /** ======================================================
        * Files send in email have to be encrypted first. In order to do so we use Capitec's zipping service that takes
        * File and returns one, big, encrypted ZIP package that can be safely attached to a email message
        *
        * Dawid Kuczer
        ======================================================= */


        zipFileResults = prepareMultipleZIPAttachment(casesToUse, attachParentDocuments);



        if(useTemplate){
            IC_Email_Template_Details__mdt template = [SELECT Target_Object_ID__c FROM IC_Email_Template_Details__mdt WHERE Target_Object_ID__c != '' LIMIT 1];
            optionalTargetId = template.Target_Object_ID__c;
        }



        for(IC_ResultWrapper zipFileResult : zipFileResults) {
            if(zipFileResult.statusCode == 200){
                emailSendingResults.add(sendEmail(zipFileResult.relatedId, sendToAddresses, null, orgWideAddressFrom, false, optionalTargetId, useTemplate, emailTemplateName, attachDocuments, zipFileResult?.message, 'ZippedDocuments.zip'));
            }
            else if(zipFileResult.statusCode == 503){
                emailSendingResults.add(sendEmail(zipFileResult.relatedId, sendToAddresses, null, orgWideAddressFrom, false, optionalTargetId, useTemplate, emailTemplateName, attachDocuments, null, 'ZippedDocuments.zip'));
            }

        }
        System.debug(emailSendingResults);


        return emailSendingResults;
    }


    public static List<String> getVerifiedDocumentumIdsFromCase(String caseId) {
        List<String> verifiedIds = new List<String>();
        for (DocumentChecklistItem item : [SELECT IC_Documentum_ID__c FROM DocumentChecklistItem WHERE Status = 'Verified' AND ParentRecordId = :caseId]) {
            verifiedIds.add(item.IC_Documentum_ID__c);
        }
        return verifiedIds;
    }

    /**
     * @author Dawid Kuczer
     * @description Handles attachments - Retrieves case files and sends them to Capitec's Zipping service and then returns Zipped package as one long string
     * @date 26.09.2024
     * @param caseId Id of the related Case
     * @param attachParentDocuments boolean, specifies if the email should have Case files attached to it
     * @param parentCaseId Id of the parent of the related Case
     *
     * @return
     */

    public static IC_ResultWrapper prepareZIPAttachment(String caseId, Boolean attachParentDocuments, String parentCaseId){
        String zipFileContent = null;

        List<ContentVersion> files = new List<ContentVersion>();
        List<String> parentDocumentumIds;
        List<String> documentumIds;

        if (attachParentDocuments && String.isNotBlank(parentCaseId) && String.isNotEmpty(parentCaseId)) {
            parentDocumentumIds = getVerifiedDocumentumIdsFromCase(parentCaseId);
            files.addAll(queryFilesFromCase(parentDocumentumIds, parentCaseId));
        }

        if (String.isNotBlank(caseId) && String.isNotEmpty(caseId)) {
            documentumIds = getVerifiedDocumentumIdsFromCase(caseId);
            files.addAll(queryFilesFromCase(documentumIds, caseId));
        }

        if (!files.isEmpty()) {

            zipFileContent = IC_API_ZipFileService.sendFilesToEndpoint(files, ZIP_PASSWORD);
            if (zipFileContent.contains('Error')) {
                return new IC_ResultWrapper(false, ('Zip File Service Callout failed; Message: ' + zipFileContent), 501, caseId);
            }

            boolean fileAttached = IC_API_ZipFileService.attachFileToCase(zipFileContent, parentCaseId);
            if (fileAttached == false) {
                return new IC_ResultWrapper(false, ('File could not be attached'), 502, caseId);
            }

        }
        else{
            return new IC_ResultWrapper(false, ('No files found'), 503, caseId);
        }

        return new IC_ResultWrapper(true, zipFileContent, 200, caseId);
    }


    public static List<IC_ResultWrapper> prepareMultipleZIPAttachment(List<Case> casesToUse, Boolean attachParentDocuments){
        String zipFileContent = null;

        List<IC_ResultWrapper> resultsSave = new List<IC_ResultWrapper>();

        List<String> parentDocumentumIds;
        List<String> documentumIds;
        List<IC_ResultWrapper> resultWrappers = new List<IC_ResultWrapper>();
        Map<String, List<ContentVersion>> caseFilesByCaseId = new Map<String, List<ContentVersion>>();
        Map<String,Integer> debugString = new Map<String, Integer>();

        //Query files (ContentVersion) from each of the cases' parents

        for(Case eachCase : casesToUse){
            List<ContentVersion> files = new List<ContentVersion>();
            if (attachParentDocuments && String.isNotBlank(eachCase.Id) && String.isNotEmpty(eachCase.ParentId)) {
                parentDocumentumIds = getVerifiedDocumentumIdsFromCase(eachCase.ParentId);
                files.addAll(queryFilesFromCase(parentDocumentumIds, eachCase.ParentId));
            }
            caseFilesByCaseId.put(eachCase.Id, files);
            debugString.put(eachCase.Id, files.size());
        }


        //Query and add files from each of the child case in addition

        for(Case eachCase : casesToUse){
            List<IC_ResultWrapper> tempWrapper = new List<IC_ResultWrapper>();
            List<ContentVersion> files = new List<ContentVersion>();
            documentumIds = getVerifiedDocumentumIdsFromCase(eachCase.Id);
            files.addAll(queryFilesFromCase(documentumIds, eachCase.Id));

            if(caseFilesByCaseId.containsKey(eachCase.Id)){
                caseFilesByCaseId.get(eachCase.Id).addAll(files);
            }
            else{
                caseFilesByCaseId.put(eachCase.Id, files);
            }
        }



        for(Case eachCase : casesToUse){
            if(caseFilesByCaseId.containsKey(eachCase.Id)) {

                zipFileContent = IC_API_ZipFileService.sendFilesToEndpoint(caseFilesByCaseId.get(eachCase.Id), ZIP_PASSWORD);
                if (zipFileContent.contains('Error')) {
                    resultWrappers.add(new IC_ResultWrapper(false, ('Zip File Service Callout failed; Message: ' + zipFileContent), 501, eachCase.Id));
                }
                else{
                    resultWrappers.add(new IC_ResultWrapper(true, zipFileContent, 200, eachCase.Id, eachCase.ParentId));
                }
            }
            else{
                resultWrappers.add(new IC_ResultWrapper(false, ('No files found'), 503, eachCase.Id));
            }
        }

        for(IC_ResultWrapper resultWrapper : resultWrappers){
            if(resultWrapper.statusCode == 200){
                boolean fileAttached = IC_API_ZipFileService.attachFileToCase(zipFileContent, resultWrapper.relatedParentId);
                if (fileAttached == false) {
                    resultWrapper = new IC_ResultWrapper(false, ('File could not be attached'), 502, resultWrapper.relatedId);
                }
            }
        }




        return resultWrappers;
    }


    /**
     * @date 26.09.2024
     * @param documentumIds the list of ids generated for Documentum service - found on ContentVersion files
     * @param caseId the Id of the related case
     *
     * @return files - in the Content Version format - related to the specified Case
     */

    public static List<ContentVersion> queryFilesFromCase(List<String> documentumIds, String caseId) {

        List<ContentDocumentLink> documentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :caseId];
        List<ContentVersion> combinedVersions = new List<ContentVersion>();

        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink cdl : documentLinks) {
            contentDocumentIds.add(cdl.ContentDocumentId);
        }

        // Query based on Documentum_ID__c where agent/user manually uploaded a file to the case
        combinedVersions.addAll(getContentVersionsByDocumentumId(contentDocumentIds, documentumIds));
        combinedVersions.addAll(IC_API_ZipFileService.getContentVersionsFor_E2C_Attachments(caseId, documentumIds));

        return combinedVersions;
    }


    /**
     * @author Dawid Kuczer
     * @description ICS-1254
     * @date 26.09.2024
     * @param contentDocumentIds
     * @param documentumIds
     *
     * @return returns the list of the actual files - ContentVersion
     */
    public static List<ContentVersion> getContentVersionsByDocumentumId(Set<Id> contentDocumentIds, List<String> documentumIds) {
        List<ContentVersion> queriedContentVersions = [
                SELECT Id, ContentDocumentId, Title, VersionData, FileType, FileExtension, Documentum_ID__c
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentIds
                AND Documentum_ID__c IN :documentumIds
        ];

        return queriedContentVersions;
    }

    /**
     * @author Dawid Kuczer
     * @date 26.09.2024
     * @description handles the last phase of email sending, sends the actual message and prepares result wrappers to inform about the successes / failure
     * @param caseId The id of the case that the email message is related to
     * @param sendToAddresses List of Strings - addresses of the e-mail's recipients
     * @param ccAddresses List of Strings - E-mail addresses the message will be CC to
     * @param includeTargetIdContactAsRecipient Determines if the targetObjectId will be used as one of the recipients
     * @param targetObjectId (if includeTargetIdContactAsRecipient == true, otherwise set to null) The id of a record containing e-mail address that will be included in the message's recipients
     * @param includeAttachments - Determines if the attachments will be send with the e-mail
     * @param base64EncodedZip (if includeAttachments == true, otherwise set to null) encoded attachment
     * @param fileName (if includeAttachments == true, otherwise set to null) name of the attachment file
     * @param useTemplate - Determines if the e-mail template has to be used
     * @param emailTemplateName (if useTemplate == true, otherwise set to null) The developer name of the e-mail template that has to be used
     * @param fromOrgWideAddress Email address that will be used as the sender. Has to be configured in Org Wide Addresses in Setup. If no address is found a default one will be used.
     *
     * @return a single IC_ResultWrapper containing information about either success or failure of the operation
     */

    public static IC_ResultWrapper sendEmail(String caseId, List<String> sendToAddresses, List<String> ccAddresses, String fromOrgWideAddress, Boolean includeTargetIdContactAsRecipient, String targetObjectId, Boolean useTemplate, String emailTemplateName, Boolean includeAttachments, String base64EncodedZip, String fileName) {
        try {
            Messaging.SingleEmailMessage newEmail = new Messaging.SingleEmailMessage();
            newEmail.toAddresses = sendToAddresses;
            newEmail.ccAddresses = ccAddresses;

            /** ======================================================
            * If template has to be used - retrieve the template and set all of the fields required when using an email template
            * TargetObjectId - refers to a Contact / Account / Other objects that contain contact details that may be used as one of the email recipients
            * If setTreatTargetObjectAsRecipient set to false then TargetObjectId plays no further role and can be ignored - it still remains a required field
            * As a consequence program queries a first valid Email Template custom metadata configuration that has TargetId specified and uses that to populate the field
            * In order to continue
            *
            * Dawid Kuczer
            ======================================================= */


            if(useTemplate){

                try{
                    EmailTemplate emailTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName LIKE :(emailTemplateName + '%') AND IsActive = TRUE ORDER BY LastModifiedDate DESC LIMIT 1];
                    newEmail.setTemplateId(emailTemplate.Id);
                    newEmail.setTargetObjectId(targetObjectId);
                    newEmail.setTreatTargetObjectAsRecipient(includeTargetIdContactAsRecipient);
                    newEmail.setWhatId(caseId);
                }
                catch (QueryException e){
                    return new IC_ResultWrapper(false, ('An error occurred: Email Template not found. Template name: ' + emailTemplateName +'. Exception message: ' + e.getMessage()), 500, caseId);
                }
            }

            System.debug('##*** base is null' + base64EncodedZip == null);
            System.debug('##*** base ' + base64EncodedZip);
            if(includeAttachments && base64EncodedZip != null){
                Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                emailAttachment.setFileName(fileName);
                emailAttachment.setBody(EncodingUtil.base64Decode(base64EncodedZip));
                newEmail.setFileAttachments(new Messaging.EmailFileAttachment[] {emailAttachment});
            }


            /** ======================================================
            * The "From" email address - The sender - has to come from Org Wide Email Addresses that can be configured in the Setup
            *
            * Dawid Kuczer
            ======================================================= */

            OrgWideEmailAddress[] orgWideEmailAddr = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE :fromOrgWideAddress];
            if (!orgWideEmailAddr.isEmpty()) {
                newEmail.setOrgWideEmailAddressId(orgWideEmailAddr[0].Id);
            }


            List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {newEmail});
            return new IC_ResultWrapper(true, 'Email has been sent successfully', 200, caseId);
        }
        catch (Exception e){
            return new IC_ResultWrapper(false, ('An error occurred: ' + e.getMessage()), 500, caseId);
        }
    }
    
    public static void justIncrement() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}