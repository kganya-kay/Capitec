//Author evans : ICS-397
//Updated on 03.09.2024 by evans : ICS-1581
public class IC_API_DocumentUploadServiceQueueable implements Finalizer, Queueable, Database.AllowsCallouts {
    
    public static IC_API_Endpoint_Setting__mdt apiConfig = IC_API_Endpoint_Setting__mdt.getInstance('Insure_Document_Service_Upload');
    
    @InvocableMethod(label='IC Content Document Upload Service')
    public static List<Id> enqueJob(List<FlowRequest> flowRequests) {
        List<Id> results = new List<Id>();
        for(FlowRequest request : flowRequests) {
            ID jobId = System.enqueueJob(new IC_API_DocumentUploadServiceQueueable(request));
            results.add(jobId);
        }
        return results;
    }
    
    public class FlowRequest {
        @InvocableVariable
        public String caseNumber;
        @InvocableVariable
        public String caseId;
        @InvocableVariable
        public String cifNumber;
        @InvocableVariable
        public String idNumber;
        @InvocableVariable
        public String contentDocumentId;
        @InvocableVariable
        public String documentChecklistItemId;
        @InvocableVariable
        public Boolean notify;
        @InvocableVariable
        public Boolean sanlamClaim;
    }
    
    private FlowRequest flowRequest;

    public IC_API_DocumentUploadServiceQueueable(FlowRequest flowRequest) {
        this.flowRequest = flowRequest;
    }

    public void execute(QueueableContext context) {
        System.attachFinalizer(new IC_API_DocumentUploadServiceQueueable(flowRequest));
        uploadDocument(flowRequest);
    }
    
    public void execute(FinalizerContext ctx) {
        if (ctx.getResult() != ParentJobResult.SUCCESS) {
            String message = 'Error: ' + ctx.getException().getMessage();
                notifyUser(flowRequest, message);
        }
    }
    
    public static void uploadDocument(FlowRequest flowRequest) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiConfig.EndpointURL__c);
        req.setMethod(apiConfig.Method__c);
        req.setHeader('Content-Type', 'application/json');
        String payload = buildRequestBody(flowRequest);
        System.debug('Payload: '+payload);
        req.setBody(payload);
        Http http = new Http();
        HttpResponse res = http.send(req);
        String message;
        if (res.getStatusCode() == 200) {
            updateDocumentChecklistItemExternalContentDocumentId(res.getBody(), flowRequest);
            message = 'File uploaded to Content Domain successfully.';
        } else if (res.getStatusCode() == 418) {
            message = 'This document type is not supported for PDF conversion, please convert it manually and upload it. Mark the PDF version as verified, and the non-PDF version as rejected.';
        } else {
            message = 'Failed to upload file to Content Domain. Status code: ' + res.getStatusCode() + ', Response: ' + res.getBody();
        }
        notifyUser(flowRequest, message);
    }
    
    public static String buildRequestBody(FlowRequest request) {
        ContentDocument cd = [SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE Id = :request.contentDocumentId];
        ContentVersion cv = [SELECT Id, Title, ContentDocumentId, FileType, FileExtension, VersionData FROM ContentVersion WHERE Id = :cd.LatestPublishedVersionId];
        
        Client cl = new Client();
        cl.cifNumber = request.cifNumber;
        cl.idNumber = request.idNumber;
        
        Document doc = new Document();
        doc.client = cl;
        doc.documentName = cv.Title;
        doc.documentType = 'Unknown';
        doc.documentSubType = 'Unknown';
        doc.contentType = cv.FileExtension;
        doc.documentStatus = 'ACCEPTED';
        doc.documentContent = EncodingUtil.base64Encode(cv.VersionData);
        doc.keys = new List<Map<String, String>>{ 
            new Map<String, String>{
            	'key' => 'caseNumber',
                'value' => request.caseNumber
            },
            new Map<String, String> {
            	'key' => 'caseId',
                'value' => request.caseId
            }
        };
        doc.metaData = new Map<String, String>{
            'title' => cv.Title,
            'fileType' => cv.FileType,
            'fileExtension' => cv.FileExtension
        };
        doc.convertToPdf = request.sanlamClaim && !'pdf'.equalsIgnoreCase(cv.FileExtension) ? true : false;
        
        return JSON.serialize(doc, true);
    }
    
    public static void updateDocumentChecklistItemExternalContentDocumentId(String responseBody, FlowRequest request) {
        ResponseSuccess response = (ResponseSuccess) JSON.deserialize(responseBody, ResponseSuccess.class);
        DocumentChecklistItem dcl = new DocumentChecklistItem(Id=request.documentChecklistItemId);
        dcl.IC_ExternalContentDocumentId__c = response.id;
        update dcl;
    }
    
    public static void notifyUser(FlowRequest request, String message) {
        if (!request.notify) {
            return;
        }
        
        CustomNotificationType nType = [SELECT Id, DeveloperName 
                                        FROM CustomNotificationType 
                                        WHERE DeveloperName='IC_FileUploadedOnCase'];
        
        Messaging.CustomNotification notif = new Messaging.CustomNotification();
        notif.setTitle('Document Upload');
        notif.setBody(message);
        notif.setNotificationTypeId(nType.Id);
        notif.setTargetId(request.documentChecklistItemId);
        
        notif.send(new Set<String> {Userinfo.getUserId()});
    }
    
	// Request Wrapper
    public class Document {
        public String documentName;
        public String documentType;
        public String documentSubType;
        public String contentType;
        public String documentStatus;
        public String documentContent;
        public Client client;
        public List<Map<String, String>> keys;
        public Map<String, String> metaData;
        public Boolean convertToPdf;
    }
    
    public class Client {
        public String cifNumber;
        public String idNumber;
    }
    
	// Response Wrapper
    public class ResponseSuccess {
        public String id;
    }
    
    public class ResponseError {
        public String title;
        public List<String> detail;
        public Integer status;
    }

}