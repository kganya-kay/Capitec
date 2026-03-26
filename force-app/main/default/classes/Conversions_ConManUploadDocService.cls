/**
 * @description       : Service class for Document Storage ConMan [Conversions]
 * @author            : Samiirah Aujub
 * @group             : Central Conversions
 * @last modified on  : 03-06-2026
 * @last modified by  : Samiirah Aujub
**/
public with sharing class Conversions_ConManUploadDocService {

    public static String sendDocument(ContentVersion cv, Id caseId) {

        if(caseId == null){
            return null;
        }

        Case caseRecord = getCaseRecord(caseId);

        requestWrapper requestWrapper = buildRequest(cv, caseRecord);

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('encodedFile', EncodingUtil.base64Encode(cv.VersionData));
        payload.put('document', requestWrapper.document);

        String jsonBody = JSON.serialize(payload);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:FR_Conman/content/bc/api/v2/documents/encoded');
        req.setMethod('POST');
        req.setHeader('X-Correlation-Id', generateUUID());
        req.setHeader('X-Channel-Source', 'SALESFORCE');
        req.setHeader('X-Accept-Hash-Encoding', 'BASE64');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-User-Id', UserInfo.getUserName());

        req.setBody(jsonBody);

        Http http = new Http();
        HttpResponse response = http.send(req);

        System.debug('## status: ' + response.getStatus());
        System.debug('## statusCode: ' + response.getStatusCode());
        System.debug('## response: ' + response.getBody());

        if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
            responseWrapper responseObj =  (responseWrapper) JSON.deserialize( response.getBody(), responseWrapper.class);
            return responseObj.id;
        }
        else{
            return null;
        }
    }

    public static void performOCR(ContentVersion cv) {

        requestWrapper requestWrapper = buildRequest(cv, null);

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('encodedFile', EncodingUtil.base64Encode(cv.VersionData));
        payload.put('document', requestWrapper.document);

        String jsonBody = JSON.serialize(payload);

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:FR_Conman/content/bc/api/v2/documents/encoded');
        req.setMethod('POST');
        req.setHeader('X-Correlation-Id', generateUUID());
        req.setHeader('X-Channel-Source', 'SALESFORCE');
        req.setHeader('X-Accept-Hash-Encoding', 'BASE64');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-User-Id', UserInfo.getUserName());
        req.setHeader('performOcr', 'true'); // to perform OCR

        req.setBody(jsonBody);

        Http http = new Http();
        HttpResponse response = http.send(req);

        System.debug('## status: ' + response.getStatus());
        System.debug('## statusCode: ' + response.getStatusCode());
        System.debug('## response: ' + response.getBody());
    }

    public static Case getCaseRecord(Id caseId){
        return [ SELECT Id,
                        CaseNumber,
                        CD_ClientCIFNumber__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
        ];
    }

    private static requestWrapper buildRequest(ContentVersion cv, Case caseRecord) {

        requestWrapper wrapper = new requestWrapper();

        wrapper.document = new V2Document();
        wrapper.document.documentType = 511; //Represents PDF
        wrapper.document.document_sub_type = 51102;
        wrapper.document.documentStatus = 'ACCEPTED';
        wrapper.document.content_type = 'application/pdf';

        wrapper.document.entity = new Entity();
        wrapper.document.entity.description = 'Manual Document Upload on Salesforce';
        wrapper.document.entity.individual = new Individual();
        wrapper.document.entity.individual.cif = (caseRecord != null) ? caseRecord.CD_ClientCIFNumber__c : '';

        return wrapper;
    }

    public static String generateUUID() {
        String uuid = '';
        String chars = '0123456789abcdef';
        Integer[] sections = new Integer[]{8, 4, 4, 4, 12};

        for (Integer section : sections) {
            String sectionStr = '';
            for (Integer i = 0; i < section; i++) {
                Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), 16);
                sectionStr += chars.substring(randomIndex, randomIndex + 1);
            }
            uuid += sectionStr + '-';
        }
        return uuid.substring(0, uuid.length() - 1);
    }

    public class requestWrapper {
        public V2Document document;
    }

    public class V2Document {
        //public String documentId;
        public Integer documentType;
        public Integer document_sub_type;
        public String documentStatus;
        public String content_type;
        public Entity entity;
    }

    public class Entity {
        public Individual individual;
        public String description;
    }

    public class Individual {
        public String cif;
    }

    public class responseWrapper {
        public String id;
        public String hash;
        public String timestamp;
    }
}