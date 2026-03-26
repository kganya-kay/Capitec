/*******************************************************************
* @Class Name        :  IC_API_ZipFileService
* @Test Class        :  IC_API_ZipFileService_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Evans, 17-Apr-2024, Jira Tickets: ICS-233, ICS-398, ICS-593, ICS-549, ICS-578, ICS-855
* @Last Modified By  :  Dawid, 21-Jun-2024, Jira Tickets: ICS-877
* @Version           :  1.0
*
*******************************************************************/

public without sharing class IC_API_ZipFileService {
    
    static List<IC_Zip_File_API_Settings__mdt> apiSettings = IC_Zip_File_API_Settings__mdt.getAll().values();
    public static CustomNotificationType notificationType; // ICS-855
    
    public class FlowRequest {
        @InvocableVariable
        public String parentCaseId;
        @InvocableVariable
        public String childCaseId;
        @InvocableVariable
        public String password;
        @InvocableVariable
        public String buttonSource;
        @InvocableVariable
        public String emailTemplateSource;
        @InvocableVariable
        public Boolean notify;
    }
    
    @InvocableMethod
    public static List<String> processCaseFiles(List<FlowRequest> requests) {

        List<String> results = new List<String>();
        
        for (FlowRequest request : requests) {
            
            if (String.isNotBlank(request.parentCaseId)) {

                List<String> documentumIds = getVerifiedDocumentumIdsFromParent(request.parentCaseId);
				System.debug('Parent documentumIds: ' + documentumIds);
				
				List<ContentVersion> files = queryFilesOnCaseFromParent(documentumIds, request.parentCaseId);

				List<String> childDocumentumIds;
				List<ContentVersion> childFiles;
                
                System.debug('tmpSource: ' + request.emailTemplateSource);
                System.debug('btnSource: ' + request.buttonSource);
                
				//ICS-578 - Start
				if (request.buttonSource == 'Send Email' &&  (request.emailTemplateSource == 'IC Death OCI Claim' || request.emailTemplateSource == 'IC Unemployment / ITEI or Disability OCI Claim')) {
					
					childDocumentumIds = getVerifiedDocumentumIdsFromChild(request.childCaseId);
					System.debug('Child documentumIds: ' + childDocumentumIds);					

                    childFiles = queryFilesOnCaseFromChild(childDocumentumIds, request.childCaseId);
					System.debug('Child files: ' + childFiles);
					files.addAll(childFiles);
				}
				//ICS-578 - End

                // Now sending all files in a single request
                if (!files.isEmpty()) {
                    //** ICS-855 Changes **//
					String result = '';
                    String zipFileContent = sendFilesToEndpoint(files, request.password);
                    if (zipFileContent.contains('Error')) {
                        // Direct comparison for clarity and to avoid potential null pointer exceptions
						result = 'Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team. An issue occurred during the endpoint callout.';
                    } else if (String.isNotBlank(zipFileContent)) {
                        // Proceed only if zipFileContent is not null and not an empty string
                        boolean fileAttached = attachFileToCase(zipFileContent, request.parentCaseId);
                        if (fileAttached) {
                            String emailResult = sendEmailWithAttachment(request.parentCaseId, request.childCaseId, zipFileContent, 'ZippedDocuments.zip', request.buttonSource,request.emailTemplateSource);
                            // Assuming sendEmailWithAttachment now returns a descriptive result or error message
                            if (emailResult.contains('Error')) {
                                result = 'Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team. Failed to send email.';
                            } else {
                                result = 'Operation has completed successfully.';
                            }
                        } else {
                            result = 'Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team. Failed to attach file to case.';
                        }
                    } else {
                        // Handle case where zipFileContent is blank but not an 'Endpoint Error'
                        result = 'Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team. Zip file content was blank.';
                    }
                    results.add(result);
                    
                    if (request.notify!=null && request.notify) {
                        notifyUser(request.parentCaseId, result);
                    }
                    //** ICS-855 Changes End **//
                }
            }
        }
        return results;
    }
    
    public static List<String> getVerifiedDocumentumIdsFromParent(String parentCaseId) {
        List<String> verifiedIds = new List<String>();
        for (DocumentChecklistItem item : [SELECT IC_Documentum_ID__c FROM DocumentChecklistItem WHERE Status = 'Verified' AND ParentRecordId = :parentCaseId]) {
            verifiedIds.add(item.IC_Documentum_ID__c);
        }
        return verifiedIds;
    }
	
	public static List<String> getVerifiedDocumentumIdsFromChild(String childCaseId) {
        List<String> verifiedIds = new List<String>();
        for (DocumentChecklistItem item : [SELECT IC_Documentum_ID__c FROM DocumentChecklistItem WHERE Status = 'Verified' AND ParentRecordId = :childCaseId]) {
            verifiedIds.add(item.IC_Documentum_ID__c);
        }
        return verifiedIds;
    }
    
	public static List<ContentVersion> queryFilesOnCaseFromParent(List<String> documentumIds, String parentCaseId) {
        
		List<ContentDocumentLink> documentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: parentCaseId];
		
		Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink cdl : documentLinks) {
            contentDocumentIds.add(cdl.ContentDocumentId);
        }
        System.debug('contentDocumentIds: '+contentDocumentIds);
        //if (contentDocumentIds.isEmpty()) {
        //    return new List<ContentVersion>();
        //} Removed in ICS-863 
        
        // Query based on Documentum_ID__c where agent/user manually uploaded a file to the case
        List<ContentVersion> versionsDirectlyFromCase = [
            SELECT Id, ContentDocumentId, Title, VersionData, FileType, FileExtension, Documentum_ID__c
            FROM ContentVersion 
            WHERE ContentDocumentId IN :contentDocumentIds
            AND Documentum_ID__c IN :documentumIds
        ];
		
        // Append versions from EmailMessage attachments
        List<ContentVersion> versionsFromEmailMessages = getContentVersionsFor_E2C_Attachments(parentCaseId, documentumIds);
        
        // Combine both lists
        List<ContentVersion> combinedVersions = new List<ContentVersion>();
        combinedVersions.addAll(versionsDirectlyFromCase);
        combinedVersions.addAll(versionsFromEmailMessages);
        
        return combinedVersions;
    }
	
	public static List<ContentVersion> queryFilesOnCaseFromChild(List<String> documentumIds, String childCaseId) {
        
		List<ContentDocumentLink> documentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: childCaseId];
		
		Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink cdl : documentLinks) {
            contentDocumentIds.add(cdl.ContentDocumentId);
        }
        System.debug('contentDocumentIds: '+contentDocumentIds);
        if (contentDocumentIds.isEmpty()) {
            return new List<ContentVersion>();
        }
        
        // Query based on Documentum_ID__c where agent/user manually uploaded a file to the case
        List<ContentVersion> versionsDirectlyFromCase = [
            SELECT Id, Title, VersionData, FileType, FileExtension, Documentum_ID__c 
            FROM ContentVersion 
            WHERE ContentDocumentId IN :contentDocumentIds
            AND Documentum_ID__c IN :documentumIds
        ];
		
        // Combine both lists
        List<ContentVersion> combinedVersions = new List<ContentVersion>();
        combinedVersions.addAll(versionsDirectlyFromCase);
        
        return combinedVersions;
    }
	
    //E2C refers to Email-To-Case attachments
    public static List<ContentVersion> getContentVersionsFor_E2C_Attachments(String parentCaseId, List<String> documentumIds) {
        // Query EmailMessages related to the Case
        List<Id> emailMessageIds = new List<Id>();
        for (EmailMessage em : [SELECT Id FROM EmailMessage WHERE ParentId = :parentCaseId]) {
            emailMessageIds.add(em.Id);
        }
        System.debug('emailMessageIds: '+emailMessageIds);
        if (emailMessageIds.isEmpty()) {
            return new List<ContentVersion>();
        }
        
        // Assuming a custom process or direct relationship to get ContentDocumentIds from EmailMessages
        List<ContentDocumentLink> documentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :emailMessageIds];
        System.debug('documentLinks: '+documentLinks);
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink cdl : documentLinks) {
            contentDocumentIds.add(cdl.ContentDocumentId);
        }
        System.debug('contentDocumentIds: '+contentDocumentIds);
        if (contentDocumentIds.isEmpty()) {
            return new List<ContentVersion>();
        }
        
        // Query ContentVersion based on ContentDocumentId
        List<ContentVersion> contentVersions = [
            SELECT Id, ContentDocumentId, Title, VersionData, FileType, FileExtension, Documentum_ID__c
            FROM ContentVersion 
            WHERE ContentDocumentId IN :contentDocumentIds
            AND IsLatest = true
            AND Documentum_ID__c IN :documentumIds
        ];
        System.debug('contentVersions: '+contentVersions);
        return contentVersions;
    }
    
    public static String sendFilesToEndpoint(List<ContentVersion> files, String password) {
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiSettings[0].Endpoint_URL__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        Integer timeoutValue = Integer.valueOf(apiSettings[0].Timeout_in_seconds__c *1000);
        req.setTimeout(timeoutValue);
                
        try{
            // Construct the request body with a list of all file details
            List<Map<String, String>> documentDetailsList = new List<Map<String, String>>();
            for (ContentVersion file : files) {
                String fullFileName = file.Title + '.' + file.FileExtension;
                documentDetailsList.add(new Map<String, String>{
                    'documentName' => fullFileName,
                        'documentContent' => EncodingUtil.base64Encode(file.VersionData)
                        });
            }
            
            Map<String, Object> reqBody = new Map<String, Object>{
                'password' => password, 
                    'documentDetails' => documentDetailsList
                    };
                        req.setBody(JSON.serialize(reqBody));
            System.debug('reqBody: '+JSON.serialize(reqBody));
            Http http = new Http();
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('resBody: '+resBody);
                return (String)resBody.get('fileContent');
            } else {
                // Handle the error accordingly
                System.debug('Error: from endpoint: ' + res.getBody());
                return 'Endpoint Error ' + res.getStatusCode() + ': ' + res.getBody();
            }
        } catch (Exception e) {
            // Log the exception details
            System.debug('Error: Exception in sendFilesToEndpoint: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
    
    public static boolean attachFileToCase(String base64EncodedZip, String parentCaseId) {
        
        try{
            Blob zipBlob = EncodingUtil.base64Decode(base64EncodedZip);
            System.debug('zipBlob: '+zipBlob);
            ContentVersion content = new ContentVersion();
            content.Title = 'Zipped Case Files';
            content.PathOnClient = 'ZippedCaseFiles.zip';
            content.VersionData = zipBlob;
            content.FirstPublishLocationId = parentCaseId; // Relates the file to the case
            System.debug('content: '+content);
            insert content;
            return true;
        }
        catch (Exception e) {
            System.debug('Exception in attachFileToCase: ' + e.getMessage());
            return false;
        }
    }
    
    public static String sendEmailWithAttachment(String parentCaseId, String childCaseId, String base64EncodedZip, String fileName, String buttonSource, String emailTemplateSource) {

        try{
            Case childCase;
            Case parentCase;
            
            if(childCaseId != null){ 
                // Query to get the status of the child case
                childCase = [SELECT Id, AccountId, RecordType.Name, IC_Type__c, Product_Type__c, IC_Insurer_Underwriter_at_Event_Date__c, Status,  Sub_Status__c, IC_OCI_Insurer_email_Address__c
                                  FROM Case WHERE Id = :childCaseId 
                                  AND RecordType.Name = 'Insurance Claims Assessment' LIMIT 1];
            }
            if(parentCaseId != null){ 
            parentCase = [SELECT Id, AccountId, RecordType.Name, IC_Type__c, Product_Type__c, IC_Insurer_Underwriter_at_Event_Date__c, Status,  Sub_Status__c
                              FROM Case WHERE Id = :parentCaseId 
                              AND RecordType.Name = 'Insurance Claims' LIMIT 1];
            }
            
            // Set the CC addresses using a custom label and split them         
			String ccAddressesStr = Label.IC_GuardRisk_cc_emails; //ICS-1443
            String[] ccAddresses = ccAddressesStr.split(',');  //ICS-1443
            
            //ICS-233 AC1 & AC2
            if(childCase!= null && childCase.Product_Type__c == 'Credit Life' && childCase.IC_Type__c == 'Unemployment/ITEI' && childCase.IC_Insurer_Underwriter_at_Event_Date__c == 'GuardRisk' && buttonSource != System.Label.IC_Escalate_Assessment_Button){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                //Select email template
                EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE Name = 'IC Guardrisk Decline Email Template' LIMIT 1];
                List<IC_Email_Template_Details__mdt> template = [SELECT Target_Object_ID__c, DeveloperName, From_Address__c FROM IC_Email_Template_Details__mdt WHERE DeveloperName = 'IC_Guardrisk_Decline_Email_Template'];
                
                mail.setTemplateId(et.Id);
                mail.setTargetObjectId(template[0].Target_Object_ID__c); //capitec@guardrisk.co.za
                mail.setCcAddresses(ccAddresses); //ICS-1443
                
                //mail.setWhatId(parentCaseId);
                mail.setWhatId(childCaseId); //ICS-893
                
                OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :template[0].From_Address__c];
                if ( owea.size() > 0 ) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(fileName);
                efa.setBody(EncodingUtil.base64Decode(base64EncodedZip));
                
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                return 'Email conditions met and sent successfully.';
            }//close if
            //ICS-593 AC3 - Start
            else if(childCase!= null && buttonSource == 'Escalate Assessment' &&  emailTemplateSource == 'IC Credit Life Claims forum email template' && childCase.Product_Type__c == 'Credit Life' && childCase.Status == 'Escalated for Review' && childCase.Sub_Status__c == 'Claims Forum'){

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                EmailTemplate emailTempClaimForum = [SELECT Id FROM EmailTemplate WHERE Name =: emailTemplateSource LIMIT 1]; //ICS-593
                List<IC_Email_Template_Details__mdt> template2 = [SELECT Target_Object_ID__c, DeveloperName, From_Address__c FROM IC_Email_Template_Details__mdt WHERE DeveloperName = 'IC_Credit_Life_Claims_Forum_Email_Templa'];
                
                mail.setTemplateId(emailTempClaimForum.Id);

                mail.setTargetObjectId(template2[0].Target_Object_ID__c); //claimsforum@capitec.com
                
                mail.setWhatId(childCaseId);
                
                OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :template2[0].From_Address__c];
                if ( owea.size() > 0 ) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(fileName);
                efa.setBody(EncodingUtil.base64Decode(base64EncodedZip));
                
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                return 'Email conditions met and sent successfully.';                
            }
            //ICS-593 - End   
            //ICS-549 AC2 - Start
            else if(buttonSource == 'Lodge' &&  emailTemplateSource == 'IC Guardrisk Disability email template'){

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                EmailTemplate emailTempDisability = [SELECT Id FROM EmailTemplate WHERE Name =: emailTemplateSource LIMIT 1]; 
                List<IC_Email_Template_Details__mdt> template3 = [SELECT Target_Object_ID__c, DeveloperName, From_Address__c FROM IC_Email_Template_Details__mdt WHERE DeveloperName =: 'IC_Guardrisk_Disability_email_template'];
                
                mail.setTemplateId(emailTempDisability.Id);

                mail.setTargetObjectId(template3[0].Target_Object_ID__c); //capitec@guardrisk.co.za
                mail.setCcAddresses(ccAddresses); //ICS-1443
        
                mail.setWhatId(parentCaseId);
                
                OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :template3[0].From_Address__c];
                if ( owea.size() > 0 ) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                } 
                
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(fileName);
                efa.setBody(EncodingUtil.base64Decode(base64EncodedZip));
                
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                return 'Email conditions met and sent successfully.';                
            }
            //ICS-549 - End  
            //ICS-578 AC3 - Start
            else if(buttonSource == 'Send Email' &&  emailTemplateSource == 'IC Unemployment / ITEI or Disability OCI Claim'){

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                EmailTemplate emailTempDisability = [SELECT Id FROM EmailTemplate WHERE Name =: emailTemplateSource LIMIT 1]; 
                List<IC_Email_Template_Details__mdt> template4 = [SELECT Target_Object_ID__c, DeveloperName, From_Address__c FROM IC_Email_Template_Details__mdt WHERE DeveloperName =: 'IC_Unemployment_ITEI_or_Disability_OCI'];
                              
                mail.setTemplateId(emailTempDisability.Id);
                
                mail.setTargetObjectId(template4[0].Target_Object_ID__c); 
                
        		mail.setToAddresses(new List<String>{childCase.IC_OCI_Insurer_email_Address__c});
        
                mail.setWhatId(childCaseId);
                
                OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :template4[0].From_Address__c];
                if ( owea.size() > 0 ) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                } 
                
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(fileName);
                efa.setBody(EncodingUtil.base64Decode(base64EncodedZip));
                
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                return 'Email conditions met and sent successfully.';                
            }
            //ICS-578 AC3 - End 
            //ICS-578 AC4 - Start
            else if(buttonSource == 'Send Email' &&  emailTemplateSource == 'IC Death OCI Claim'){

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                EmailTemplate emailTempDisability = [SELECT Id FROM EmailTemplate WHERE Name =: emailTemplateSource LIMIT 1]; 
                List<IC_Email_Template_Details__mdt> template5 = [SELECT Target_Object_ID__c, DeveloperName, From_Address__c FROM IC_Email_Template_Details__mdt WHERE DeveloperName =: 'IC_Death_OCI_Claim'];
                
                mail.setTemplateId(emailTempDisability.Id);
                
                mail.setTargetObjectId(template5[0].Target_Object_ID__c); 
                
        		mail.setToAddresses(new List<String>{childCase.IC_OCI_Insurer_email_Address__c});

                mail.setWhatId(childCaseId);
                
                OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :template5[0].From_Address__c];
                if ( owea.size() > 0 ) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                } 
                
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(fileName);
                efa.setBody(EncodingUtil.base64Decode(base64EncodedZip));
                
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                return 'Email conditions met and sent successfully.';                
            }
            //ICS-578 AC4 - End
			//ICS-1490 - Start
            else if(buttonSource == 'Decline_New' &&  emailTemplateSource == 'IC Guardrisk Decline Email Template'){

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                //Select email template
                EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE Name = 'IC Guardrisk Decline Email Template' LIMIT 1];
                List<IC_Email_Template_Details__mdt> template = [SELECT Target_Object_ID__c, DeveloperName, From_Address__c FROM IC_Email_Template_Details__mdt WHERE DeveloperName = 'IC_Guardrisk_Decline_Email_Template'];
                
                mail.setTemplateId(et.Id);
                mail.setTargetObjectId(template[0].Target_Object_ID__c); //capitec@guardrisk.co.za
                mail.setCcAddresses(ccAddresses); //ICS-1443
                
                //mail.setWhatId(parentCaseId);
                mail.setWhatId(childCaseId); //ICS-893
                
                OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :template[0].From_Address__c];
                if ( owea.size() > 0 ) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(fileName);
                efa.setBody(EncodingUtil.base64Decode(base64EncodedZip));
                
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                return 'Email conditions met and sent successfully.';               
            }
			//ICS-1490 - End
			
            /**
            * ICS-877
            * 21.06.2024 Dawid Kuczer
            * AC 1 & 2 & 3
            */
            else if(buttonSource == System.Label.IC_Escalate_Assessment_Button){

                EmailTemplate emailTemplateAssessmentEscalation;
                Messaging.SingleEmailMessage newEmail = new Messaging.SingleEmailMessage();
                String mdtTemplateName;

                try{
                    emailTemplateAssessmentEscalation = [SELECT Id FROM EmailTemplate WHERE DeveloperName LIKE :(emailTemplateSource + '%') ORDER BY LastModifiedDate DESC LIMIT 1];
                }
                catch (QueryException e){
                    return 'Email Template not found. Template name: ' + emailTemplateSource +'. Exception message: ' + e.getMessage();
                }



                if (emailTemplateSource.contains('Fraud')) {
                    mdtTemplateName = 'IC_Assessment_Escalation_Fraud';
                    newEmail.setToAddresses(new String[] {System.Label.IC_Assessment_Escalation_Email_Fraud});
                } else if (emailTemplateSource.contains('Management')) {
                    mdtTemplateName = 'IC_Assessment_Escalation_Management';
                    newEmail.setToAddresses(new String[] {System.Label.IC_Assessment_Escalation_Email_Management});
                } else {
                    mdtTemplateName = 'IC_Assessment_Escalation_Claims_Forum';
                    newEmail.setToAddresses(new String[] {System.Label.IC_Assessment_Escalation_Email_Claims_Forum});
                }


                List<IC_Email_Template_Details__mdt> assessmentEscalationTemplateMdt = [SELECT Target_Object_ID__c, DeveloperName, From_Address__c FROM IC_Email_Template_Details__mdt WHERE DeveloperName = :mdtTemplateName];
                if (assessmentEscalationTemplateMdt.isEmpty()) {
                    return 'Assessment escalation template custom metadata not found. Mdt name: ' + mdtTemplateName;
                }

                newEmail.setTemplateId(emailTemplateAssessmentEscalation.Id);
                newEmail.setTargetObjectId(assessmentEscalationTemplateMdt[0].Target_Object_ID__c);
                newEmail.setTreatTargetObjectAsRecipient(false);
                newEmail.setWhatId(childCaseId);

                OrgWideEmailAddress[] orgWideEmailAddr = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :assessmentEscalationTemplateMdt[0].From_Address__c];
                if (!orgWideEmailAddr.isEmpty()) {
                    newEmail.setOrgWideEmailAddressId(orgWideEmailAddr[0].Id);
                }

                Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                emailAttachment.setFileName(fileName);
                emailAttachment.setBody(EncodingUtil.base64Decode(base64EncodedZip));
                newEmail.setFileAttachments(new Messaging.EmailFileAttachment[] {emailAttachment});

                try {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {newEmail});
                    return 'Email conditions met and sent successfully.';
                } catch (Exception e) {
                    return 'An error occurred: ' + e.getMessage();
                }
            }
            //ICS-877 - End

            //ICS-578 AC4 - End

            /**
            * ICS-541
            * 21.06.2024 Dawid Kuczer
            */
            else if(buttonSource == System.Label.IC_Centriq_Event_Decline_Button_Source){
                
                 System.debug('RIDWAN buttonSource: ' + buttonSource);

                EmailTemplate emailTmplCentriqChildCaseNotification;
                Messaging.SingleEmailMessage newEmail = new Messaging.SingleEmailMessage();
                String mdtTemplateName = 'IC_Centriq_Child_Case_Notify';

                try{
                    emailTmplCentriqChildCaseNotification = [SELECT Id FROM EmailTemplate WHERE DeveloperName LIKE :(emailTemplateSource + '%') ORDER BY LastModifiedDate DESC LIMIT 1];
                }
                catch (QueryException e){
                    return 'Email Template not found. Template name: ' + emailTemplateSource +'. Exception message: ' + e.getMessage();
                }
                newEmail.setToAddresses(System.Label.IC_Centriq_Email_Address.split(','));

                List<IC_Email_Template_Details__mdt> centriqChildCaseNotifyTemplateMdt = [SELECT Target_Object_ID__c, DeveloperName, From_Address__c FROM IC_Email_Template_Details__mdt WHERE DeveloperName = :mdtTemplateName];
                if (centriqChildCaseNotifyTemplateMdt.isEmpty()) {
                    return 'Assessment escalation template custom metadata not found. Mdt name: ' + mdtTemplateName;
                }

                newEmail.setTemplateId(emailTmplCentriqChildCaseNotification.Id);
                newEmail.setTargetObjectId(centriqChildCaseNotifyTemplateMdt[0].Target_Object_ID__c);
                newEmail.setTreatTargetObjectAsRecipient(false);
                newEmail.setWhatId(parentCaseId);

                OrgWideEmailAddress[] orgWideEmailAddr = [SELECT Id FROM OrgWideEmailAddress WHERE Address LIKE :centriqChildCaseNotifyTemplateMdt[0].From_Address__c];
                if (!orgWideEmailAddr.isEmpty()) {
                    newEmail.setOrgWideEmailAddressId(orgWideEmailAddr[0].Id);
                }
                Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                emailAttachment.setFileName(fileName);
                emailAttachment.setBody(EncodingUtil.base64Decode(base64EncodedZip));
                newEmail.setFileAttachments(new Messaging.EmailFileAttachment[] {emailAttachment});

                try {
                    List<Messaging.SendEmailResult> emailResult = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {newEmail});
                    return 'Email conditions met and sent successfully.';
                } catch (Exception e) {
                    System.debug(e.getStackTraceString());
                    return 'An error occurred: ' + e.getMessage();
                }
            }
            //ICS-541 - End
            
            return 'Error: Email sending conditions not met.';
            
        }//try
        catch (Exception e) {
            // Log the exception and return false to indicate failure
            System.debug('Exception in sendEmailWithAttachment: ' + e.getMessage());
            return 'Error: Failed to send email- ' + e.getMessage();
        }        
    }
    
    //ICS-855
    public static void notifyUser(Id caseId, String message) {
        if (notificationType==null) {
            notificationType = [SELECT Id, DeveloperName 
                                FROM CustomNotificationType 
                                WHERE DeveloperName='IC_ZipFileServiceError'];
        }
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('Zip File Service');
        notification.setBody(message);
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(caseId);
        try {
            notification.send(new Set<String> {Userinfo.getUserId()});
        }
        catch (Exception e) {
            System.debug('Error sending notification: ' + e.getMessage());
        }
    }
}