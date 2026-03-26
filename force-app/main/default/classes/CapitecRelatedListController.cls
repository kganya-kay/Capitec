public with sharing class CapitecRelatedListController {

    public CapitecRelatedListController() {
        // Constructor for future initialization if needed
    }

    /**
     * Fetch related records dynamically
     */
    @AuraEnabled(cacheable=true)
    public static List<sObject> getRelatedRecords(String objectApiName, String lookupFieldApiName, Id parentRecordId) {
        if(String.isBlank(objectApiName) || String.isBlank(lookupFieldApiName) || parentRecordId == null){
            return new List<sObject>();
        }

        String query = 'SELECT Id, Name FROM ' + objectApiName +
                       ' WHERE ' + lookupFieldApiName + ' = :parentRecordId ' +
                       ' ORDER BY CreatedDate DESC';

        return Database.query(query);
    }
}