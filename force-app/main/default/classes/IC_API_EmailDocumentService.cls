/*******************************************************************
* @Class Name        :  IC_API_EmailDocumentService
* @Test Class        :  IC_API_EmailDocumentService_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 29-July-2023, Jira Tickets: ICS-1368 
* @Version           :  1.0
*
*******************************************************************/

public class IC_API_EmailDocumentService {
    
    @InvocableMethod(label='Send Document Email' description='Send document email based on External Content Document Id')
    public static void sendDocumentEmail(List<Request> requestList) {
        
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE Name = 'IC Funeral Plan Claims Note Template' LIMIT 1];
        List<IC_Email_Template_Details__mdt> template = [SELECT Target_Object_ID__c, From_Address__c FROM IC_Email_Template_Details__mdt WHERE DeveloperName = 'IC_Funeral_Plan_Claims_Note_Template'];
        
        for (Request req : requestList) {
            sendFuneralPlanClaimsNote(req.documentId, req.recipientEmail, req.parentCaseId, et, template);
        }
    }
    
    private static void sendFuneralPlanClaimsNote(String documentId, String recipientEmail, String parentCaseId, EmailTemplate et, List<IC_Email_Template_Details__mdt> template) {
        Case thisCase = [SELECT Id, Account.Identity_Number__c, Account.CIF_Number__c FROM Case WHERE Id = :parentCaseId];
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:NC_CapiInsure/insure/document/v1/' + documentId +'?cifNumber=' + thisCase?.Account.CIF_Number__c + '&idNumber=' + thisCase?.Account.Identity_Number__c);
        req.setMethod('GET');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String documentContent = (String) responseMap.get('documentContent');
            
            Map<String, Object> metaDataMap = (Map<String, Object>) responseMap.get('metaData');
            //String title = (String) metaDataMap.get('title');
            //String fileExtension = (String) metaDataMap.get('fileExtension');
            
            System.debug('documentContent: ' +documentContent);
            //System.debug('title: ' +title);
            //System.debug('fileExtension: ' +fileExtension);
            
            
            if (documentContent != null) {
                Blob decodedContent = EncodingUtil.base64Decode(documentContent);
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                email.setTemplateId(et.Id);
                email.setTargetObjectId(template[0].Target_Object_ID__c);
                email.setToAddresses(new String[] { recipientEmail });
                email.setTreatTargetObjectAsRecipient(false);
                email.setWhatId(parentCaseId);
                
                
                OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :template[0].From_Address__c];
                if ( owea.size() > 0 ) {
                    email.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                
                // Create the attachment with the filename from metadata
                String fileName = 'Claim Note.pdf';
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(fileName);
                attachment.setBody(decodedContent);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                
                // Send the email
                try {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                } catch (Exception e) {
                    System.debug('Email sending failed: ' + e.getMessage());
                }
                
                
            } else {
                System.debug('Document content or metadata could not be retrieved.');
            }
        } else {//not 200
            System.debug('Document content could not be retrieved.');
        }
    }
    
    public class Request {
        @InvocableVariable(label='Document Id' description='External Content Document Id')
        public String documentId;
        
        @InvocableVariable(label='Recipient Email' description='Recipient Email')
        public String recipientEmail;
        
        @InvocableVariable(label='Parent Case ID' description='Parent Case ID')
        public String parentCaseId;
    }
}