/**
 * Created by Sebastian on 20.03.2023.
 */

public with sharing class capitec_MediaSearchController {
    @AuraEnabled(Cacheable=true)
    public static Case getCaseRecord(Id caseId) {
        return [SELECT Media_Search_URL__c FROM Case WHERE Id =: caseId WITH SECURITY_ENFORCED LIMIT 1];
    }

    @AuraEnabled(Cacheable=true)
    public static List<Object> getMediaSearchHistory(Id caseId) {
        List<Object> returnList = new List<Object>();
        List<Media_Search_History__c> mediaSearchHistoriesList = [SELECT Id, Click_Date__c, User__r.Name FROM Media_Search_History__c
                                                                    WHERE Case__c =: caseId WITH SECURITY_ENFORCED ORDER BY Click_Date__c DESC];

        if (mediaSearchHistoriesList.size() > 0) {
            for (Media_Search_History__c thisMediaSearchHistory : mediaSearchHistoriesList) {
                Map<String, Object> mapValues = new Map<String, Object>();
                mapValues.put('id', thisMediaSearchHistory.Id);
                mapValues.put('Click_Date__c', thisMediaSearchHistory.Click_Date__c);
                mapValues.put('User_Name', thisMediaSearchHistory.User__r.Name);
                returnList.add(mapValues);
            }
        }
        return returnList;
    }

    @AuraEnabled
    public static void createMediaSearchHistoryRecord(Id caseId) {

        Media_Search_History__c msh = new Media_Search_History__c(
                User__c = UserInfo.getUserId(),
                Case__c = caseId,
                Click_Date__c = Datetime.now());
        try{
            insert msh;
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}