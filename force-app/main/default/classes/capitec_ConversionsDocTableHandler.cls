/**
 * @description       : Handler for capitec_ConversionsDocTable LWC
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 05-22-2025
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class capitec_ConversionsDocTableHandler {

    @AuraEnabled(cacheable=true)
    public static string fetchDocs(String recordId) {
        List<DocumentWrapper> lstDocsToDisplay = new List<DocumentWrapper>();

        if (String.isBlank(recordId)) return null;

        for (DocumentChecklistItem item : [SELECT Id, 
                                                  Name, 
                                                  IC_DocumentLink__c, 
                                                  CreatedBy.Name, 
                                                  CreatedDate
                                            FROM DocumentChecklistItem
                                            WHERE ParentRecordId = :recordId]) 
        {
            DocumentWrapper wrapper = new DocumentWrapper();
            wrapper.title = item.Name;
            wrapper.url = item.IC_DocumentLink__c;
            wrapper.createdByName = item.CreatedBy.Name;
            wrapper.createdDate = item.CreatedDate;

            lstDocsToDisplay.add(wrapper);
        }

        String result = JSON.serialize(lstDocsToDisplay);

        return result;          
    }


    @AuraEnabled(cacheable=true)
    public static String fetchNotes(String recordId) {
        List<DocumentWrapper> lstNotesToDisplay = new List<DocumentWrapper>();

        if (String.isBlank(recordId)) return null;

        for (ContentDocumentLink link : [SELECT ContentDocumentId, 
                                                LinkedEntityId,
                                                ContentDocument.Title,
                                                ContentDocument.CreatedDate,
                                                ContentDocument.CreatedBy.Name
                                         FROM ContentDocumentLink
                                         WHERE LinkedEntityId = :recordId
                                         AND ContentDocument.FileType = 'SNOTE']) 
        {
            DocumentWrapper wrapper = new DocumentWrapper();
            wrapper.title = link.ContentDocument.Title;
            wrapper.url = '/' + link.ContentDocumentId;
            wrapper.createdByName = link.ContentDocument.CreatedBy.Name;
            wrapper.createdDate = link.ContentDocument.CreatedDate;
            
            lstNotesToDisplay.add(wrapper);
        }

        String result = JSON.serialize(lstNotesToDisplay);

        return result;          
    }


    public class DocumentWrapper {
        @AuraEnabled public String title;
        @AuraEnabled public String url;
        @AuraEnabled public String createdByName;
        @AuraEnabled public DateTime createdDate;
    }

    
    
}