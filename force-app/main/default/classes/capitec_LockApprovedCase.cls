public class capitec_LockApprovedCase {
	
    public class CasesToLockInput{
        @InvocableVariable(Label='caseIds' Required=true)
        public String caseId;
    } 

    @InvocableMethod(label='Lock record' description='Locks a case record from being edited by users' category='Case')
    public static void LockApprovedCaseRecord (List<CasesToLockInput> CaseIds){
        lockCaseRecord(CaseIds);
        lockAnswerRecord(CaseIds);
    }
    
    private static void lockCaseRecord (List<CasesToLockInput> CaseIds){

        Case[] casesToLock = [SELECT Id From Case WHERE Id IN (:CaseIds[0].caseId)];
        Approval.LockResult[] lockResults = Approval.lock(casesToLock, false);

        for(Approval.LockResult lr : lockResults){
            if (lr.isSuccess() == false) {              
                for(Database.Error err : lr.getErrors()) {                  
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }
            }              
        }
    } 
    
    private static void lockAnswerRecord (List<CasesToLockInput> CaseIds){

        Answer__c[] answersToLock = [SELECT Id From Answer__c WHERE Case__c IN (:CaseIds[0].caseId)];
        Approval.LockResult[] lockResults = Approval.lock(answersToLock, false);

        for(Approval.LockResult lr : lockResults){
            if (lr.isSuccess() == false) {
                for(Database.Error err : lr.getErrors()) {                  
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }
}