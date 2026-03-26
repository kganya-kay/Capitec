public class capitec_PersonOfInterestTRH extends TriggerHandler {
    private Map<Id, Persons_of_Interest__c> oldPOIMap;
    private Map<Id, Persons_of_Interest__c> newPOIMap;
    private List<Persons_of_Interest__c> oldPOIList;
    private List<Persons_of_Interest__c> newPOIList;
    
    public capitec_PersonOfInterestTRH() {
        oldPOIMap = (Map<Id, Persons_of_Interest__c>)Trigger.oldMap;
        newPOIMap = (Map<Id, Persons_of_Interest__c>)Trigger.newMap;
        oldPOIList = (List<Persons_of_Interest__c>)Trigger.old;
        newPOIList = (List<Persons_of_Interest__c>)Trigger.new;
    }
    
    public override void beforeInsert() {
       capitec_PersonOfInterestCD.checkIfMainPOIPresent(newPOIList);
    }
    
    public override void beforeUpdate() {
        capitec_PersonOfInterestCD.checkIfMainPOIPresent(newPOIList);
    }

}