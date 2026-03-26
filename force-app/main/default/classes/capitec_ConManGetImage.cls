/**
 * Created by BlueSky on 22.10.2024.
 * Purpose: FCO Project - to get latest selfies of client
 */
public class capitec_ConManGetImage {

    public class DocumentInfo {
        @AuraEnabled
        public String documentId;      
        @AuraEnabled
        public String contentType;     
        @AuraEnabled
        public String createdDate;    
        @AuraEnabled
        public Object documentType;  
        @AuraEnabled
        public Object documentSubType;  
        @AuraEnabled
        public Object documentName;  
            
    }
    public class ResponseOutput {
        @AuraEnabled
        public String responseBody;  
        @AuraEnabled
        public Integer statusCode;   
        @AuraEnabled
        public List<DocumentInfo> documents; 
        @AuraEnabled
        public List<DocumentInfo> images; 
        @AuraEnabled
        public List<DocumentInfo> imageprofiles; 
    }
    


    @AuraEnabled
    public static Map<String,String> processFile(String documentId, String caseId, String contentType) {

        String CPNum = '';

        if(Test.isRunningTest()){CPNum = 'Test';
        }else{ 
            CPNum = Capitec_CaseUtils.getConsultantCP(caseId);
        }

        Http http = new Http();

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:FR_Conman/content/bc/api/documents/'+documentId+'/content'); 
            req.setMethod('GET');
            req.setHeader('X-Correlation-Id', generateUUID());
            req.setHeader('X-Channel-Source', 'SALESFORCE'); //Salesforce
            req.setHeader('X-User-Id', CPNum); //CP Number

            System.debug('Send Request '+req);
            
            HttpResponse res = http.send(req);
            System.debug('Response  : ' + res.getBody());


            
            if (res.getStatusCode() == 200) {
                // System.debug('Request  : ' + res.getBody());

                // Query to check if Document already exists

                List<ContentVersion> existingContent = [ SELECT Id , ContentDocumentId FROM ContentVersion  WHERE Title = :('Selfie_' + documentId) AND FirstPublishLocationId = :caseId LIMIT 1];
                if (existingContent.size() > 0) {
                    return new Map<String, String>{
                        'fileUrl' => '/sfc/servlet.shepherd/version/download/' + existingContent[0].Id,
                        'contentDocumentId' => existingContent[0].ContentDocumentId
                    };
                } else {
                    Blob fileBlob = res.getBodyAsBlob();

                    ContentVersion contentVersion = new ContentVersion();
                    contentVersion.Title = 'Selfie_' + documentId;  // Document title
                    contentVersion.PathOnClient = 'Selfie_' + documentId + '.' + contentType;   
                    contentVersion.VersionData = fileBlob;  
                    contentVersion.FirstPublishLocationId = caseId;  
                    contentVersion.IsMajorVersion = true;  
                    insert contentVersion;

                    Case relatedCase = [SELECT Id, IC_Trigger_Finalise_Claim__c FROM Case WHERE Id = :caseId LIMIT 1];
                    // Update the case
                    if (relatedCase.IC_Trigger_Finalise_Claim__c != true) {
                        relatedCase.IC_Trigger_Finalise_Claim__c = true;
                        update relatedCase;
                    }
                    
                    String contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion  WHERE Id = :contentVersion.Id].ContentDocumentId;

                    return new Map<String, String>{
                        'fileUrl' => '/sfc/servlet.shepherd/version/download/' + contentVersion.Id,
                        'contentDocumentId' => contentDocumentId
                    };

                }
            }  else {
                throw new AuraHandledException('Failed to process document with status: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error processing document: ' + e.getMessage());
        }
    }

    //Method to randomly generate unique correlation values
    public static String generateUUID() {
        String uuid = '';
        String chars = '0123456789abcdef';

        Integer[] sections = new Integer[]{8, 4, 4, 4, 12}; // UUID format sections

        for (Integer section : sections) {
            String sectionStr = '';
            for (Integer i = 0; i < section; i++) {
                Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), 16);
                sectionStr += chars.substring(randomIndex, randomIndex + 1);
            }
            uuid += sectionStr + '-';
        }

        return uuid.substring(0, uuid.length() - 1); // Remove the trailing hyphen
    }

    @AuraEnabled(cacheable=false)
    public static List<ResponseOutput> postRequest(String cifValue, String caseId) {
        List<ResponseOutput> responses = new List<ResponseOutput>();
        String CPNum = '';

        if(Test.isRunningTest()){ CPNum = 'Test';
        } else { 
            CPNum = Capitec_CaseUtils.getConsultantCP(caseId);
        }

        ResponseOutput output = new ResponseOutput();
        output.documents = new List<DocumentInfo>();
        output.images = new List<DocumentInfo>();
        output.imageprofiles = new List<DocumentInfo>();

        try {
        // bc/api/v2/
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:FR_Conman/content/bc/api/v2/documents/search');
            req.setMethod('POST');
            req.setHeader('X-Correlation-Id', generateUUID());
            req.setHeader('X-Channel-Source', 'SALESFORCE');
            req.setHeader('X-User-Id', CPNum);
            req.setHeader('Content-Type', 'application/json');

           // String reqBody = '{"identifiers": {"cif": "' + cifValue + '"}, "filters": {}, "documentType": [1, 4, 25, 4001, 4002, 4003, 4004], "maxResults": 5, "sort": {"field": "creationDateTime", "order": "DESC"}}';
            //String reqBody = '{"identifiers": { "individual": {"cif": "' + cifValue + '"}}, "filters": {}, "documentType": [1, 4, 25, 4001, 4002, 4003, 4004], "maxResults": 5, "sort": {"field": "creationDateTime", "order": "DESC"}}';
            String reqBody = '{"identifiers": { "individual": {"cif": "' + cifValue + '"}}, "filters": { "documentType": [1, 4, 25] }, "maxResults": 50, "sort": {"field": "creationDateTime", "order": "DESC"}}';
            
            System.debug('Request Body: ' + reqBody);

            req.setBody(reqBody);

            // Send the HTTP request
            Http http = new Http();
            HttpResponse res = http.send(req);

            // Capture the response
            output.responseBody = res.getBody();
            output.statusCode = res.getStatusCode();
            System.debug('Response Status: ' + res.getStatus());
            System.debug('Response responseBody : ' + res.getBody());

            // Check if the status is successful (200 OK)
            if (res.getStatusCode() == 200) {
                List<Object> jsonList = (List<Object>) JSON.deserializeUntyped(res.getBody());

                for (Object obj : jsonList) {
                    Map<String, Object> documentMap = (Map<String, Object>) obj;
                    System.debug('Response documentMap : ' + documentMap);
                    System.debug('Response documentType : ' + documentMap.get('documentType'));
                   
                        // 4 Identification Document
                        // 4001	SA ID Book
                        // 4002	SA Passport
                        // 4003	Birth Certificate
                        // 4004	Foreign Passport
                        // 4005	ID Card - Front
                        // 4006	ID Card - Back
                    if(documentMap.get('documentType') == 4 ){
                        
                        DocumentInfo docInfo = new DocumentInfo();

                        if (documentMap.containsKey('documentType')) {
                            docInfo.documentType =  documentMap.get('documentType');
                        }
                        if (documentMap.containsKey('documentId')) {
                            docInfo.documentId = (String) documentMap.get('documentId');
                        }
                        if (documentMap.containsKey('contentType')) {
                            docInfo.contentType = (String) documentMap.get('contentType');
                        }
                        if (documentMap.containsKey('creationDateTime')) {
                            docInfo.createdDate = (String) documentMap.get('creationDateTime');
                        }
                        if (documentMap.containsKey('documentSubType')) {
                            docInfo.documentSubType =  documentMap.get('documentSubType');
                        }
                        if(documentMap.get('documentType') == 4) docInfo.documentName = 'Identification Document';
                        if(documentMap.get('documentType') == 4001) docInfo.documentName = 'SA ID Book';
                        if(documentMap.get('documentType') == 4002) docInfo.documentName = 'SA Passport';
                        if(documentMap.get('documentType') == 4003) docInfo.documentName = 'Birth Certificate';
                        if(documentMap.get('documentType') == 4004) docInfo.documentName = 'Foreign Passport';
                        
                        output.documents.add(docInfo);

                    } 
                    //doc 1  // Primary Photo - 1
                    // if (documentMap.get('documentSubType') == 0) {
                    if(documentMap.get('documentType') == 1 ) {
                        DocumentInfo imageInfo = new DocumentInfo();

                        imageInfo.documentSubType = documentMap.get('documentSubType');
                        if (documentMap.containsKey('documentType')) {
                            imageInfo.documentType =  documentMap.get('documentType');
                        }
                        if (documentMap.containsKey('documentId')) {
                            imageInfo.documentId = (String) documentMap.get('documentId');
                        }
                        if (documentMap.containsKey('contentType')) {
                            imageInfo.contentType = (String) documentMap.get('contentType');
                        }
                        if (documentMap.containsKey('creationDateTime')) {
                            imageInfo.createdDate = (String) documentMap.get('creationDateTime');
                        }
                        output.imageprofiles.add(imageInfo);
                    }
                    //doc 25  // Selfie Photo - 25
                    // if (documentMap.get('documentSubType') == 0) {
                    if(documentMap.get('documentType') == 25 ) {
                        DocumentInfo imageInfo = new DocumentInfo();

                        imageInfo.documentSubType = documentMap.get('documentSubType');
                        if (documentMap.containsKey('documentType')) {
                            imageInfo.documentType =  documentMap.get('documentType');
                        }
                        if (documentMap.containsKey('documentId')) {
                            imageInfo.documentId = (String) documentMap.get('documentId');
                        }
                        if (documentMap.containsKey('contentType')) {
                            imageInfo.contentType = (String) documentMap.get('contentType');
                        }
                        if (documentMap.containsKey('creationDateTime')) {
                            imageInfo.createdDate = (String) documentMap.get('creationDateTime');
                        }
                        output.images.add(imageInfo);
                    }
                }
            }
        } catch (Exception e) {
            // Handle exceptions and log the error
            output.responseBody = 'Error: ' + e.getMessage();
            output.statusCode = 500; // Set to 500 for internal error
        }

        // Add the output to the list of responses
        responses.add(output);

        // Return the response list
        return responses;
    }
}