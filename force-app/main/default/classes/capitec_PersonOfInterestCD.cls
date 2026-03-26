public class capitec_PersonOfInterestCD {
    private static final String CASH_DISPUTES_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Cash_Disputes').getRecordTypeId();
    
    public static void checkIfMainPOIPresent(List<Persons_of_Interest__c> poiList) {
        List<Id> caseIds = new List<Id>();
        Map<Id, Persons_of_Interest__c> mapCaseId_POI = new Map<Id, Persons_of_Interest__c>();
        
        for(Persons_of_Interest__c poi : poiList) {
            caseIds.add(poi.Case__c);
        }
        
        for(Persons_of_Interest__c pinterest : [SELECT Id, Name, Case__c, Main_Person_of_Interest__c FROM Persons_of_Interest__c WHERE Case__c IN :caseIds AND Main_Person_of_Interest__c = True]) {
            mapCaseId_POI.put(pinterest.Case__c, pinterest);
        }
        
        for(Persons_of_Interest__c personOfInt : poiList) {
            if(mapCaseId_POI.containsKey(personOfInt.Case__c) && personOfInt.Main_Person_of_Interest__c) {
                personOfInt.Main_Person_of_Interest__c.addError('The cash dispute currently has a main person of interest. To select this person of interest, you must unselect the other person of interest.');
            }
        }
    }

}