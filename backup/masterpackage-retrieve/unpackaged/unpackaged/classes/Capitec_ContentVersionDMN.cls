/**
* Created by dawid on 12.06.2023.
* Updated by knund on 26.06.2024: CEDT-2661
* Updated by evans on 03.09.2024: ICS-397
*/

public without sharing class Capitec_ContentVersionDMN {
    public static final String POST_DOCUMENTUM_FILE_URL = '/content/content-administration-v1/v1/documents/case/';
    public static final Integer FRAUD_HD_DOC_TYP_EID = 67;
    public static final Integer AML_HD_DOC_TYP_EID = 42;
    public static final String IMG_BRANCH_NUMBER = '01001';
    public static final String CASE_SOBJECT_NAME = 'Case';
    public static final String EMAIL_MESSAGE_SOBJECT_NAME = 'EmailMessage';
    public static final String DOCUMENTUM_HEADER_KEY = 'X-Capitec-Channel';
    public static final String DOCUMENTUM_HEADER_VALUE = 'SALESFORCE_FRAUD';
    //COCONV -1976:Added by Samiirah Aujub
    public static final Id CONVERSION_RECORD_TYPEID = Schema.SObjectType.DocumentChecklistItem.getRecordTypeInfosByName().get('Conversion').getRecordTypeId();


    public static void uploadFileToDocumentum(List<ContentVersion> contentVersions) {

        Map<String, Case> casesByIds;
        List<ContentVersion> fullContentVersionFiles;
        List<String> caseIds = new List<String>();
        List<Id> emailMessageIds = new List<Id>();
        List<String> contentVersionsIds = new List<String>();
        List<DocumentChecklistItem> documentItemsToInsert = new List<DocumentChecklistItem>(); //ICS-203
        List<IC_DocumentRequestList__c> requestListToInsert = new List<IC_DocumentRequestList__c>(); //COCONV-2125
        Map<Id, Id> cvIDemIDmap = new Map<Id, Id>(); //ICS-203
        Map<Id, Id> emIDcaseIdmap = new Map<Id, Id>(); //ICS-203


        for (ContentVersion currentContentVersion : contentVersions) {
            System.debug('##currentContentVersion:' + currentContentVersion.FirstPublishLocationId);
            System.debug('##obj name:' + currentContentVersion.FirstPublishLocationId.getSobjectType().getDescribe().getName());
            if (currentContentVersion.FirstPublishLocationId.getSobjectType().getDescribe().getName() == CASE_SOBJECT_NAME) {
                caseIds.add(currentContentVersion.FirstPublishLocationId);
                contentVersionsIds.add(currentContentVersion.Id);
            } else if (currentContentVersion.FirstPublishLocationId.getSobjectType().getDescribe().getName() == EMAIL_MESSAGE_SOBJECT_NAME) {
                emailMessageIds.add(currentContentVersion.FirstPublishLocationId);
                cvIDemIDmap.put(currentContentVersion.Id, currentContentVersion.FirstPublishLocationId);
                contentVersionsIds.add(currentContentVersion.Id);
            }
        }

        for (EmailMessage emailMsg : [SELECT id, RelatedToId FROM EmailMessage WHERE Id in :emailMessageIds]) {
            caseIds.add(emailMsg.RelatedToId);
            emIDcaseIdmap.put(emailMsg.Id, emailMsg.RelatedToId);
        }

        System.debug('##caseIds:' + caseIds);

        List<ContentVersion> contentVersionsToUpdate = new List<ContentVersion>();//ICS-398
        casesByIds = new Map<String, Case>([SELECT Id, RecordType.Name, Account.Identity_Number__c, Account.CIF_Number__c, Account.FirstName, Account.LastName, Account.Salutation, Account.Passport_Number__c FROM Case WHERE Id IN :caseIds]);
        fullContentVersionFiles = [SELECT Id, Title, ContentDocumentId, Documentum_ID__c, VersionData, FileType, FirstPublishLocationId FROM ContentVersion WHERE Id IN :contentVersionsIds];

        System.debug('##fullContentVersionFiles:' + fullContentVersionFiles);

        for (ContentVersion currentContentVersion : fullContentVersionFiles) {
            if (currentContentVersion.FirstPublishLocationId.getSobjectType().getDescribe().getName() == CASE_SOBJECT_NAME) {

                Case relatedCase = casesByIds.get(currentContentVersion.FirstPublishLocationId);
                String documentumId = Capitec_GuidUtils.NewGuid();

                if (relatedCase.RecordType.Name == 'Insurance Claims' || 
                    relatedCase.RecordType.Name == 'Insurance Claims Assessment'){ //ICS-203 //Child RT added for ticket ICS-578

                    // Call the method to create a new DocumentChecklistItem record
                    DocumentChecklistItem newDocRecord = createNewDocumentChecklistRecord(relatedCase, currentContentVersion, documentumId);
                    documentItemsToInsert.add(newDocRecord);
                    currentContentVersion.Documentum_ID__c = documentumId; //ICS-398
                    contentVersionsToUpdate.add(currentContentVersion); //ICS-398
                }
                if(relatedCase.RecordType.Name == 'Conversions' && currentContentVersion.FileType != 'SNOTE') { //COCONV-2125
                    
                    
                    /*DocumentChecklistItem newDocRecord = createNewDocumentChecklistRecord(relatedCase, currentContentVersion, documentumId);
                    newDocRecord.RecordTypeId = CONVERSION_RECORD_TYPEID;
                    documentItemsToInsert.add(newDocRecord);*/

                    //SAU create document request list instead  as unclassified-- to show on screen flow
                    IC_DocumentRequestList__c newRequestItem = createDocumentRequestItem(relatedCase,currentContentVersion);
                    requestListToInsert.add(newRequestItem);

                    //maintain update
                    currentContentVersion.Documentum_ID__c = documentumId;
                    contentVersionsToUpdate.add(currentContentVersion);
                }
                if (relatedCase.RecordType.Name != 'Insurance Claims' && relatedCase.RecordType.Name != 'Insurance Claims Assessment' && relatedCase.RecordType.Name != 'Retail Complaints' && relatedCase.RecordType.Name != 'Retail Complaints Handoff' && relatedCase.RecordType.Name != 'Conversions') {
                    //TODO This needs to be fixed for private connect limits
                    //makeDocumentumPostCallout(createRequestBody(currentContentVersion, relatedCase, documentumId), documentumId, currentContentVersion.Id);
                }
               

            } else if (currentContentVersion.FirstPublishLocationId.getSobjectType().getDescribe().getName() == EMAIL_MESSAGE_SOBJECT_NAME) {
                Case relatedCase = casesByIds.get(emIDcaseIdmap.get(cvIDemIDmap.get(currentContentVersion.Id)));

                String documentumId = Capitec_GuidUtils.NewGuid();
                if (relatedCase.RecordType.Name == 'Insurance Claims') {
                    DocumentChecklistItem newDocRecord = createNewDocumentChecklistRecord(relatedCase, currentContentVersion, documentumId);
                    documentItemsToInsert.add(newDocRecord);
                    currentContentVersion.Documentum_ID__c = documentumId; //ICS-859
                    contentVersionsToUpdate.add(currentContentVersion); //ICS-859
                }
                if (relatedCase.RecordType.Name != 'Insurance Claims' && relatedCase.RecordType.Name != 'Insurance Claims Assessment' && relatedCase.RecordType.Name != 'Retail Complaints' && relatedCase.RecordType.Name != 'Retail Complaints Handoff') {
                    //TODO This needs to be fixed for private connect limits
                    //makeDocumentumPostCallout(createRequestBody(currentContentVersion, relatedCase, documentumId), documentumId, currentContentVersion.Id);
                }
            }
        }

        System.debug('##documentItemsToInsert:' + documentItemsToInsert);
        System.debug('##requestListToInsert:' + requestListToInsert);
        
        if (!documentItemsToInsert.isEmpty()) { //ICS-203
            Database.SaveResult[] insertResults = Database.insert(documentItemsToInsert, false);
        }

        //COCONV-2125
        if(!requestListToInsert.isEmpty()){
            Database.SaveResult[] insertResults = Database.insert(requestListToInsert, false);
        }
        if (!contentVersionsToUpdate.isEmpty()) {//ICS-398
            Database.SaveResult[] updateResults = Database.update(contentVersionsToUpdate, false);
        }

        
    }

    //TODO This needs to be fixed for private connect limits
    /*@Future(Callout=true)
    public static void makeDocumentumPostCallout(String requestBody, String documentumId, String contentVersionId) {

        ContentVersion thisCV = [SELECT Id, Documentum_ID__c, Uploaded_to_Documentum__c FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response;

        request.setMethod('POST');

        if (!Test.isRunningTest()) {
            request.setEndpoint('callout:NC_CapiDoc' + POST_DOCUMENTUM_FILE_URL + documentumId);
        } else {
            request.setEndpoint('callout:NC_CapiDoc' + POST_DOCUMENTUM_FILE_URL + documentumId);
        }

        request.setHeader(DOCUMENTUM_HEADER_KEY, DOCUMENTUM_HEADER_VALUE);
        request.setTimeout(120000);

        request.setBody(requestBody);

        try {
            response = http.send(request);
            if (response.getStatusCode() == 200) {
                thisCV.Uploaded_to_Documentum__c = true;
            }
        } catch (CalloutException e) {
            System.debug(e.getMessage());
        } finally {
            if (thisCV.Documentum_ID__c == null || response.getStatus() == '200') {
                thisCV.Documentum_ID__c = documentumId;
                System.debug(thisCV);
                update thisCV;
            }
        }
    }*/

    //TODO This needs to be fixed for private connect limits
    /*public static String createRequestBody(ContentVersion fileToPost, Case relatedCase, String documentumId) {

        CapitecDocumentumObject fileWrapper = new CapitecDocumentumObject();

        fileWrapper.content = new FileContent();
        fileWrapper.cpCaseDocumentProperties = new CpCaseDocumentProperties();

        fileWrapper.content.contentType = fileToPost.FileType;
        fileWrapper.content.documentId = documentumId;
        //        fileWrapper.content.data = EncodingUtil.base64Encode(fileToPost.VersionData);

        fileWrapper.cpCaseDocumentProperties.caseId = fileToPost.FirstPublishLocationId;
        fileWrapper.cpCaseDocumentProperties.contentType = fileToPost.FileType;

        if (relatedCase.recordType.Name == 'Fraud Record Type') {
            fileWrapper.cpCaseDocumentProperties.hdDocTypeId = FRAUD_HD_DOC_TYP_EID;
        } else if (relatedCase.recordType.Name == 'AML Record Type') {
            fileWrapper.cpCaseDocumentProperties.hdDocTypeId = AML_HD_DOC_TYP_EID;
        }

        fileWrapper.cpCaseDocumentProperties.imgCifNo = relatedCase.Account.CIF_Number__c;
        fileWrapper.cpCaseDocumentProperties.imgClFirstName = relatedCase.Account.FirstName;
        fileWrapper.cpCaseDocumentProperties.imgClSurname = relatedCase.Account.LastName;
        fileWrapper.cpCaseDocumentProperties.imgClTitle = relatedCase.Account.Salutation;
        fileWrapper.cpCaseDocumentProperties.imgDocumentId = documentumId;
        fileWrapper.cpCaseDocumentProperties.imgBranchNumber = IMG_BRANCH_NUMBER;
        fileWrapper.cpCaseDocumentProperties.imgPrimaryAccount = '1234567809';
        if (relatedCase.Account.Identity_Number__c != null || relatedCase.Account.Identity_Number__c != '') {
            fileWrapper.cpCaseDocumentProperties.imgIdPassportNo = relatedCase.Account.Identity_Number__c;
        } else if (relatedCase.Account.Passport_Number__c != null || relatedCase.Account.Passport_Number__c != '') {
            fileWrapper.cpCaseDocumentProperties.imgIdPassportNo = relatedCase.Account.Passport_Number__c;
        }
        fileWrapper.content.data = EncodingUtil.base64Encode(fileToPost.VersionData);

        return (JSON.serialize(fileWrapper));
    }*/

    @TestVisible
    private static DocumentChecklistItem createNewDocumentChecklistRecord(Case relatedCase, ContentVersion contentVersion, String documentumId) {//ICS-203
        // Create a new instance of your custom object and set the fields
        DocumentChecklistItem docRecord = new DocumentChecklistItem();
        docRecord.Name = contentVersion.Title;
        docRecord.IC_Documentum_ID__c = documentumId;
        docRecord.ParentRecordId = relatedCase.Id;

        // Construct the Salesforce URL to the ContentVersion record in Lightning Experience
        String baseUrl = Url.getSalesforceBaseUrl().toExternalForm();
        String documentUrl = baseUrl + '/lightning/r/ContentDocument/' + contentVersion.ContentDocumentId + '/view';
        docRecord.Document_Link__c = documentUrl;
        docRecord.IC_ContentDocumentId__c = contentVersion.ContentDocumentId; //ICS-397

        return docRecord;
    }

    //START - Added by Samiirah Aujub - COCONV 2125
    @TestVisible
    private static  IC_DocumentRequestList__c createDocumentRequestItem(Case relatedCase, ContentVersion contentVersion) { //COCONV - 2125
        IC_DocumentRequestList__c requestList = new IC_DocumentRequestList__c();
        requestList.DocumentName__c = contentVersion.Title;
        requestList.Case__c = relatedCase.Id;
        requestList.CON_Classified__c = false;
        requestList.CON_Content_Document_Id__c = contentVersion.ContentDocumentId;

        return requestList;
    }

    public static void checkDuplication(List<ContentVersion> contentVersions) {
        Set<Id> setCaseIds = new Set<Id>();
        Map<Id, Case> casesByIds;
        Map<Id, Set<String>> caseExistingFileNames = new Map<Id, Set<String>>();

        system.debug('##content versions:' + contentVersions);
    
        for (ContentVersion currentContentVersion : contentVersions) {
            system.debug('##content FirstPublishLocationId:' + currentContentVersion.FirstPublishLocationId);
            if (currentContentVersion.FirstPublishLocationId == null) {
                System.debug('##Skipping: FirstPublishLocationId is null');
                continue;
            }
            if (currentContentVersion.FirstPublishLocationId.getSobjectType().getDescribe().getName() == CASE_SOBJECT_NAME) {
                setCaseIds.add(currentContentVersion.FirstPublishLocationId);
            } 
        }

        System.debug('##checkDuplication setCaseIds:' + setCaseIds);

        casesByIds = new Map<Id, Case>([SELECT Id, 
                                                   RecordType.Name 
                                                   FROM Case 
                                                   WHERE Id IN :setCaseIds]);

        if(casesByIds.size() > 0){
            caseExistingFileNames = getExistingFileNames(casesByIds.keyset());

            for (ContentVersion currentContentVersion : contentVersions) {
                if (currentContentVersion.FirstPublishLocationId == null) {
                    System.debug('##Skipping: FirstPublishLocationId is null');
                    continue;
                }
                if (currentContentVersion.FirstPublishLocationId.getSobjectType().getDescribe().getName() == CASE_SOBJECT_NAME) {
                    Case relatedCase = casesByIds.get(currentContentVersion.FirstPublishLocationId);
                    if(relatedCase.RecordType.Name == 'Conversions' && currentContentVersion.FileType != 'SNOTE') {
                        if(caseExistingFileNames.containsKey(relatedCase.Id)){
                            if(caseExistingFileNames.get(relatedCase.Id).contains(currentContentVersion.Title)){
                                currentContentVersion.addError('A file with the same name already exists on this Case.');
                            }
                        }
                    }
                }
         }
        }
    }

    private static Map<Id, Set<String>> getExistingFileNames(Set<Id> setCaseIds) {
        Map<Id, Set<String>> existingFileNamesMap = new Map<Id, Set<String>>();

        if (setCaseIds.isEmpty()) {
            return existingFileNamesMap;
        }

        for (DocumentChecklistItem dcl : [SELECT Id,
                                                 Name,
                                                 ParentRecordId
                                          FROM DocumentChecklistItem
                                          WHERE ParentRecordId IN :setCaseIds
        ]) {
            if (!existingFileNamesMap.containsKey(dcl.ParentRecordId)) {
                existingFileNamesMap.put(dcl.ParentRecordId, new Set<String>());
            }
            existingFileNamesMap.get(dcl.ParentRecordId)
                                .add(dcl.Name);
        }

        System.debug('##getExistingFileNames existingFileNamesMap:' + existingFileNamesMap);
        return existingFileNamesMap;
    }

    //END - COCONV 2125

    public class CapitecDocumentumObject {
        public FileContent content;
        public CpCaseDocumentProperties cpCaseDocumentProperties;
    }

    public class FileContent {
        public String contentType;
        public String documentId;
        public String data;
    }

    public class CpCaseDocumentProperties {
        public String caseId;
        public String contentType;
        public Integer hdDocTypeId;
        public String imgCifNo;
        public String imgClFirstName;
        public String imgClSurname;
        public String imgClTitle;
        public String imgDocumentId;
        public String imgIdPassportNo;
        public String imgPrimaryAccount;
        public String consultantCpNumber;
        public String imgBranchNumber;
    }
}