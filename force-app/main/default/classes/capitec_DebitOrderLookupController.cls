public with sharing class capitec_DebitOrderLookupController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> searchDOIs(String searchKey) {
        String key = '%' + String.escapeSingleQuotes(searchKey) + '%';
        List<Debit_Order_Initiator__c> dois = [
            SELECT Id, Name
            FROM Debit_Order_Initiator__c
            WHERE Name LIKE :key
            ORDER BY Name ASC
            LIMIT 50
        ];
        
        List<Map<String,String>> results = new List<Map<String,String>>();
        for(Debit_Order_Initiator__c doi : dois){
            results.add(new Map<String,String>{'Id' => doi.Id, 'Name' => doi.Name});
        }
        return results;
    }
}