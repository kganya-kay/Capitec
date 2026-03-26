/**
* @description Apex class for handling the update of child case owners in Retail Complaints.
* @date Created: 10.10.2024
* @author Kevin Nundran
* @updated Updated by Barend van der Walt on 14.08.2024 to only update owner of open retail complaints child cases.
*/
public class capitec_CaseRC {
    private static final String RETAIL_COMPLAINTS_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Retail_Complaints').getRecordTypeId();
    private static final String RETAIL_COMPLAINTS_HANDOFF_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Retail_Complaints_Handoff').getRecordTypeId();

    /**
    * @description Updates the owner of child cases when the owner of the parent case (Retail Complaints) changes.
    * @param oldCaseMap Map of old Case records (before update).
    * @param newCaseMap Map of new Case records (after update).
    */
    public static void updateChildCaseOwner(Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap) {
        Set<Id> setCaseIdToCheck = new Set<Id>();
        for(Case c : newCaseMap.values()){
            if(c.OwnerId != oldCaseMap.get(c.Id).OwnerId && c.RecordTypeId == RETAIL_COMPLAINTS_RECORD_TYPE_ID){
                setCaseIdToCheck.add(c.Id);
            }
        }
        
        if(!setCaseIdToCheck.isEmpty()){
            
            List<Case> lstChildCase = [SELECT Id, OwnerId, ParentId FROM Case WHERE ParentId IN :setCaseIdToCheck AND RecordTypeId = :RETAIL_COMPLAINTS_HANDOFF_RECORD_TYPE_ID AND isClosed = False AND Owner.Type != 'Queue'];
            System.debug('OLD: ' + lstChildcase);
            if(!lstChildCase.isEmpty()){
                for(Case childCase : lstChildCase){
                    childCase.OwnerId = newCaseMap.get(childCase.ParentId).OwnerId;
                }
            }
        	System.debug('NEW: ' + lstChildcase);
            Database.update(lstChildcase);
        }
    }
}