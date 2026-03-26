/**
 * Created by Kevin on 20.05.2024
 * Updated by Kevin on 09.01.2025: CEDT-2892
 */

global with sharing class FlowEmailComposerCtrl {
    @AuraEnabled 
    public static List<EmailTemplate> getEmailTemplates(){
        if(Schema.sObjectType.EmailTemplate.isAccessible() && Schema.sObjectType.Attachment.isAccessible()){
            return new List<EmailTemplate>([SELECT Subject,Id, Name,DeveloperName, FolderId, Folder.DeveloperName, Folder.Name, 
                                            (Select Id,Name from Attachments) 
                                            FROM EmailTemplate 
                                            WHERE TemplateType IN ('custom','text','html') ORDER BY FolderId, DeveloperName]);
        }
        return new EmailTemplate[]{};
    }
    
    @AuraEnabled 
    public static EmailMsg getTemplateDetails(string templateId, String whoId, String whatId){
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateId, whoId, WhatId,Messaging.AttachmentRetrievalOption.METADATA_ONLY);
        EmailMsg msg = new EmailMsg();
        msg.subject = email.getSubject();
        msg.body = email.getHtmlBody();
        
        List<Messaging.EmailFileAttachment> attachmentList = email.fileAttachments;
        
        List<FileAttachmentWrapper> fawList = new List<FileAttachmentWrapper>();
        for(Messaging.EmailFileAttachment efa : attachmentList){
            FileAttachmentWrapper faw = new FileAttachmentWrapper();
            faw.attachId = efa.id;
            faw.filename = efa.filename;
            faw.isContentDocument=false;
            fawList.add(faw);
        }
        for(ContentDocumentLink cdl : [Select ContentDocument.Id, ContentDocument.title, ContentDocument.fileExtension
                                       from contentdocumentlink
                                       where linkedEntityId=:templateId]){
                                           FileAttachmentWrapper faw = new FileAttachmentWrapper();
                                           faw.attachId = cdl.ContentDocument.id;
                                           faw.isContentDocument = true;                               
                                           faw.filename = cdl.ContentDocument.title+'.'+cdl.contentdocument.fileextension;
                                           fawList.add(faw);
                                       }
        msg.fileattachments = fawList;
        
        if(String.isblank(msg.body)){
            msg.body = email.getPlainTextBody();
            if(String.isNotBlank(msg.body)){
                msg.body = msg.body.replace('\n', '<br/>');
            }
        }
        return msg;   
    }
    
    @AuraEnabled  
    public static void deleteFiles(string sdocumentId){ 
        if (Schema.sObjectType.ContentDocument.isDeletable()) {
            delete [SELECT Id,Title,FileType from ContentDocument WHERE id=:sdocumentId]; 
        }
    }  
    
    @AuraEnabled
    public static void sendAnEmailMsg(String fromAddress, String toAddressesStr, String ccAddressesStr, String bccAddressesStr, String subject, 
                                      String whoId, String whatId, String body, String senderDisplayName, List<String> contentDocumentIds, 
                                      List<String> attachmentIds, List<String> selectedEmailMessageIds, Boolean createActivity) {
        try {
            if (String.isNotBlank(toAddressesStr)) {
                String formattedToken = EmailMessages.getFormattedThreadingToken(whatId);
                String htmlBody = (body + '<br><br><span style="color:#fff;">' + formattedToken + '</span>');
                String[] toAddresses = toAddressesStr.split(',');
                String[] ccAddresses = String.isNotBlank(ccAddressesStr) ? ccAddressesStr.split(',') : new String[]{};
                String[] bccAddresses = String.isNotBlank(bccAddressesStr) ? bccAddressesStr.split(',') : new String[]{};
                        
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                List<String> cvIds = new List<String>();
                for(ContentVersion cv : [SELECT Id, Title, FileType, VersionData, IsLatest, ContentDocumentId
                                         FROM ContentVersion
                                         WHERE IsLatest = true AND ContentDocumentId IN :contentDocumentIds]) {
                    cvIds.add(cv.Id);
                }
                
                email.setToAddresses(toAddresses);
                email.setCCAddresses(ccAddresses);
                email.setBCCAddresses(bccAddresses);
                email.setSubject(subject);
                email.setHtmlBody(htmlBody);
                email.setUseSignature(false);
                
                if(String.isNotBlank(senderDisplayName)) {
                    email.setSenderDisplayName(senderDisplayName);
                }
                
                List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                
                // Fetch selected email messages
                List<EmailMessage> selectedEmails = [SELECT Id, Subject, TextBody, HtmlBody, FromAddress, ToAddress, CcAddress, BccAddress FROM EmailMessage WHERE Id IN :selectedEmailMessageIds];
                for (EmailMessage selectedEmail : selectedEmails) {
                    Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                    
                    // Construct .eml content with proper headers
                    String emlContent = 'From: ' + selectedEmail.FromAddress + '\n' +
                        'To: ' + selectedEmail.ToAddress + '\n' +
                        (String.isNotBlank(selectedEmail.CcAddress) ? 'Cc: ' + selectedEmail.CcAddress + '\n' : '') +
                        (String.isNotBlank(selectedEmail.BccAddress) ? 'Bcc: ' + selectedEmail.BccAddress + '\n' : '') +
                        'Subject: ' + selectedEmail.Subject + '\n' +
                        'Date: ' + System.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss Z') + '\n' +
                        'MIME-Version: 1.0\n' +
                        'Content-Type: text/html; charset=UTF-8\n' +
                        'Content-Transfer-Encoding: 7bit\n\n' + 
                        (String.isNotBlank(selectedEmail.HtmlBody) ? selectedEmail.HtmlBody : selectedEmail.TextBody) + '\n';
                    
                    emailAttachment.setBody(Blob.valueOf(emlContent));
                    emailAttachment.setFileName(selectedEmail.Subject + '.eml');
                    emailAttachments.add(emailAttachment);
                    
                    // Check for existing attachments and forward them
                    List<Attachment> emailAttachmentsList = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :selectedEmail.Id];
                    for (Attachment attachment : emailAttachmentsList) {
                        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
                        fileAttachment.setBody(attachment.Body);
                        fileAttachment.setFileName(attachment.Name);
                        emailAttachments.add(fileAttachment);
                    }
                }
                
                // Attach Content Versions
                if(!cvIds.isEmpty()) {
                    email.setEntityAttachments(cvIds);
                }
                
                // Attach all gathered attachments to the email
                if (!emailAttachments.isEmpty()) {
                    email.setFileAttachments(emailAttachments);
                }
                
                // Send the email
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                if (results[0].isSuccess()) {
                    if (createActivity) {
                        EmailMessage newEmailMessage = new EmailMessage();
                        newEmailMessage.Subject = subject;
                        newEmailMessage.FromAddress = fromAddress;
                        newEmailMessage.ToAddress = toAddressesStr;
                        newEmailMessage.CcAddress = ccAddressesStr;
                        newEmailMessage.BccAddress = bccAddressesStr;
                        newEmailMessage.HtmlBody = htmlBody;
                        newEmailMessage.relatedToId = String.isNotBlank(whatId) ? whatId : null; 
                        insert newEmailMessage;
                        
                        // Log the attachments
                        List<Attachment> lstAttachments = new List<Attachment>();
                        for (Messaging.EmailFileAttachment fileAttachment : emailAttachments) {
                            Attachment newAttachment = new Attachment();
                            newAttachment.Body = fileAttachment.getBody();
                            newAttachment.Name = fileAttachment.getFileName();
                            newAttachment.ParentId = newEmailMessage.Id;
                            lstAttachments.add(newAttachment);
                        }
                        if (!lstAttachments.isEmpty()) {
                            insert lstAttachments;
                        }
                    }
                } else {
                    System.debug('Email send failed: ' + results[0].getErrors()[0].getMessage());
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Something went wrong: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<EmailMessage> getEmailMessages(Id caseId) {
        return [
            SELECT Id, Subject, TextBody, HtmlBody 
            FROM EmailMessage 
            WHERE ParentId = :caseId
        ];
    }
    
    public class FileAttachmentWrapper{
        @AuraEnabled public String attachId;
        @AuraEnabled public String fileName;
        @AuraEnabled public boolean isContentDocument;
    }
    public class EmailMsg{
        @AuraEnabled public string subject;
        @AuraEnabled public string body;        
        @AuraEnabled public List<FileAttachmentWrapper> fileAttachments;
    }
}