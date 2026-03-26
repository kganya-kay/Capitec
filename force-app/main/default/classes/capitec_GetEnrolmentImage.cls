/**
 * Created by Bluesky on 2024/10/30.
 */
public with sharing class capitec_GetEnrolmentImage {
    @AuraEnabled(cacheable=true)
    public static String getAccountImage(Id caseId) {
        Case caseRecord = [SELECT Id, CIF_Number__c, AccountId FROM Case WHERE Id = :caseId LIMIT 1];
        
        List<ContentDocumentLink> contentLinks = [
            SELECT ContentDocumentId, ContentDocument.Title 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :caseRecord.AccountId
            AND ContentDocument.Title = :caseRecord.CIF_Number__c
            ORDER BY ContentDocument.CreatedDate DESC 
            LIMIT 1
        ];
        
        if (contentLinks.isEmpty()) {
            return null; // No image found
        }
        
        ContentVersion contentVersion = [
            SELECT Id 
            FROM ContentVersion 
            WHERE ContentDocumentId = :contentLinks[0].ContentDocumentId
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        String imageUrl = '/sfc/servlet.shepherd/version/download/' + contentVersion.Id;
        return imageUrl;
    }


}