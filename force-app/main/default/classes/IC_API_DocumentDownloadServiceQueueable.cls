public class IC_API_DocumentDownloadServiceQueueable implements Finalizer, Queueable, Database.AllowsCallouts {
    
    public static IC_API_Endpoint_Setting__mdt apiConfig = IC_API_Endpoint_Setting__mdt.getInstance('Insure_Document_Service_Download');
    
    @InvocableMethod(label='IC Content Document Download Service')
    public static List<Id> enqueJob(List<FlowRequest> flowRequests) {
        List<Id> results = new List<Id>();
        for(FlowRequest request : flowRequests) {
            ID jobId = System.enqueueJob(new IC_API_DocumentDownloadServiceQueueable(request));
            results.add(jobId);
        }
        return results;
    }
    
    public class FlowRequest {
        @InvocableVariable
        public String caseId;
        @InvocableVariable
        public String externalContentDocumentId;
        @InvocableVariable
        public String documentChecklistItemId;
        @InvocableVariable
        public Date expiryDate;
        @InvocableVariable
        public Boolean notify;
    }
    
    private FlowRequest flowRequest;

    public IC_API_DocumentDownloadServiceQueueable(FlowRequest flowRequest) {
        this.flowRequest = flowRequest;
    }

    public void execute(QueueableContext context) {
        System.attachFinalizer(new IC_API_DocumentDownloadServiceQueueable(flowRequest));
        downloadDocument(flowRequest);
    }
    
    public void execute(FinalizerContext ctx) {
        if (ctx.getResult() != ParentJobResult.SUCCESS) {
            String message = 'Error: ' + ctx.getException().getMessage();
            notifyUser(flowRequest, message);
        }
    }
    
    public static void downloadDocument(FlowRequest flowRequest) {


        Case linkedCase = [SELECT Id, Account.CIF_Number__c, Account.Identity_Number__c FROM Case WHERE Id = :flowRequest.caseId LIMIT 1];
        HttpRequest req = new HttpRequest();
        //This is a comment for commenting purpose
        //ICS-1595 endpoint needs additional URL Parameters: cifNumber and idNumbers
        Case recordCase = [SELECT Id, Account.CIF_Number__c, Account.Identity_Number__c FROM Case WHERE Id = : flowRequest.caseId];
        req.setEndpoint(apiConfig.EndpointURL__c + flowRequest.externalContentDocumentId + '?cifNumber=' + recordCase.Account.CIF_Number__c + '&idNumber=' + recordCase.Account.Identity_Number__c);
        req.setTimeout(120000);
        req.setMethod(apiConfig.Method__c);
        req.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        HttpResponse res = http.send(req);
        String message;

        if (res.getStatusCode() == 200) {
            insertDocument(res.getBody(), flowRequest);
            message = 'File downloaded from Content Domain successfully.';
        } else {
            message = 'Failed to downloaded file from Content Domain. Status code: ' + res.getStatusCode() + ', Response: ' + res.getBody();
        }
        notifyUser(flowRequest, message);
    }
    
    public static void insertDocument(String responseBody, FlowRequest request) {
        System.debug('***************************');
        System.debug(responseBody);
        System.debug('***************************');
        ResponseSuccess response = (ResponseSuccess) JSON.deserialize(responseBody, ResponseSuccess.class);
        System.debug('ResponseBody: '+responseBody);
        ContentVersion cv = new ContentVersion();
        cv.Title = response.metaData.title; 
        cv.PathOnClient = response.metaData.title + '.' + response.metaData.fileExtension;
        cv.VersionData = EncodingUtil.base64Decode(response.documentContent);
        insert cv;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink cl = new ContentDocumentLink();
        cl.LinkedEntityId = request.caseId;
        cl.contentdocumentid = cv.contentdocumentid;
        cl.ShareType = 'V';
        insert cl;
        
        DocumentChecklistItem dc = new DocumentChecklistItem(Id=request.documentChecklistItemId);
        dc.IC_ContentDocumentId__c = cv.contentdocumentid;
        dc.IC_DocumentExpiryDate__c = request.expiryDate;
        dc.IC_DeleteContentDocument__c = true;
        update dc;
    }
    
    public static void notifyUser(FlowRequest request, String message) {
        if (!request.notify) {
            return;
        }
        
        CustomNotificationType nType = [SELECT Id, DeveloperName 
                                        FROM CustomNotificationType 
                                        WHERE DeveloperName='IC_FileUploadedOnCase'];
        
        Messaging.CustomNotification notif = new Messaging.CustomNotification();
        notif.setTitle('Document Download');
        notif.setBody(message);
        notif.setNotificationTypeId(nType.Id);
        notif.setTargetId(request.documentChecklistItemId);
        
        notif.send(new Set<String> {Userinfo.getUserId()});
    }
    
	// Response Wrapper
    public class ResponseSuccess {
        public String author;
        public String channel;
        public Client client;
        public String contentType;
        public String documentId;
        public String documentLocation;
        public String documentSubType;
        public String documentType;
        //Dawid Kuczer
        //ICS-1595 keys are always come as an array
        public Key[] keys;
        public MetaData metaData;
        public String modifiedDateTime;
        public String documentContent;
    }
    
    public class Client {
        public String cifNumber;
        public String idNumber;
    }
    
    public class Key {
        public String caseNumber;
        public String caseId;
    }
    
    public class MetaData {
        public String title;
        public String fileType;
        public String fileExtension;
    }
    
    public class ResponseError {
        public String title;
        public List<String> detail;
        public Integer status;
    }

}