public with sharing class capitec_LookupController {
    public capitec_LookupController() {

    }
    @AuraEnabled(cacheable=true)
    public static List<SObject> searchRecords(String sObjectApiName, String searchKey, String fieldApiName) {
        if(String.isBlank(searchKey)) return new List<SObject>();

        String query = 'SELECT Id, ' + fieldApiName + ' FROM ' + sObjectApiName + 
                       ' WHERE ' + fieldApiName + ' LIKE \'%' + String.escapeSingleQuotes(searchKey) + '%\' LIMIT 5';
        return Database.query(query);
    }
}