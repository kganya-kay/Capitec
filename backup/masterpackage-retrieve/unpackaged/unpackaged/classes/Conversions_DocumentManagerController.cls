/**
 * @description       : Apex class for Document Manager LWC
 * @author            : Samiirah Aujub
 * @group             : 
 * @last modified on  : 03-09-2026
 * @last modified by  : Samiirah Aujub
**/
public with sharing class Conversions_DocumentManagerController {

    @AuraEnabled(cacheable=true)
    public static List<IC_DocumentRequestList__c> getRequestItems(Id caseId) {
        Set<Id> setDocIds = new Set<Id>();

        if (caseId == null) {
            return new List<IC_DocumentRequestList__c>();
        }

        for(ContentDocumentLink link : [SELECT Id,
                                               ContentDocumentId
                                        FROM ContentDocumentLink
                                        WHERE LinkedEntityId =: caseId
                                        AND ContentDocument.FileType != 'SNOTE'])
        {
            setDocIds.add(link.ContentDocumentId);

        }

        if(!setDocIds.isEmpty()){
            return [
                SELECT Id,
                    DocumentName__c,
                    Case__c,
                    CON_Classified__c,
                    CON_Content_Document_Id__c,
                    CreatedDate,
                    LastModifiedDate
                FROM IC_DocumentRequestList__c
                WHERE CON_Content_Document_Id__c IN: setDocIds
                AND Case__c = :caseId
                AND CON_Classified__c = false
                ORDER BY CreatedDate DESC
            ];

        }
        else{
            return new List<IC_DocumentRequestList__c>();
        }

        
    }


    @AuraEnabled
    public static Boolean createDocChecklistItem(Id caseId, Id requestId, Id contentDocId, String docType) {
        if (caseId == null || contentDocId == null) {
            System.debug('##createDocChecklistItem : caseId or contentDocId null');
            return false;
        }

        ContentVersion contentVersion = [SELECT Id, 
                                                Title,
                                                VersionData,
                                                FileExtension
                                         FROM ContentVersion 
                                         WHERE ContentDocumentId  = :contentDocId
                                         ORDER BY VersionNumber DESC
                                         LIMIT 1];


       if(contentVersion == null){
            System.debug('##createDocChecklistItem : contentVersion not found');
            return false;
       }

        try{
            DocumentChecklistItem docRecord = new DocumentChecklistItem();
            docRecord.Name = contentVersion.Title;
            docRecord.ParentRecordId = caseId;
            docRecord.CON_Document_Type__c = docType;
            docRecord.IC_ContentDocumentId__c = contentDocId;

            System.debug('##createDocChecklistItem docRecord initialised:' + docRecord);

            String externalDocId = executeCallout(contentVersion, caseId);

            if(externalDocId != null){
                docRecord.IC_ExternalContentDocumentId__c = externalDocId;
            }
            insert docRecord;

            IC_DocumentRequestList__c requestItem = new IC_DocumentRequestList__c();
            requestItem.Id = requestId;
            requestItem.CON_Classified__c = true;

            update requestItem;
            System.debug('##createDocChecklistItem docRecord created:' + docRecord);

            return true;

        }
        catch(Exception ex){
             System.debug('##createDocChecklistItem : Exception:' + ex);
            return null;
        }
    }

    public static String executeCallout(ContentVersion contentVersion, Id caseId){
        if(Test.isRunningTest()){
            return 'TEST_DOC_ID';
        }
        try{
            //Call conMan webservice for Upload
            String externalDocId = Conversions_ConManUploadDocService.sendDocument(contentVersion, caseId);
            System.debug('##executeCallout CONMAN Id:' + externalDocId);

            return externalDocId;
        }
        catch(Exception e){
            System.debug('##executeCallout : Exception:' + e);
            return null;
        }
    }
}