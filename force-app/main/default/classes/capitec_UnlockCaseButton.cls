public class capitec_UnlockCaseButton {

    public class CasesToUnLockInput{
        @InvocableVariable(Label='caseIds' Required=true)
        public String caseId;
    }

    @InvocableMethod(label='UnLock record' description='Unlocks a case record to allow editing' category='Case')
    public static void CaseUnlock(List<CasesToUnLockInput> caseList) {

        User user = new User(Id = UserInfo.getUserId());
        capitec_UnlockCaseButton.unLockCaseRecord(caseList);
        capitec_UnlockCaseButton.unLockAnswerRecord(caseList);
    }

    public static void unLockCaseRecord (List<CasesToUnLockInput> caseList){

        Case[] casesToUnLock = [SELECT Id From Case WHERE Id IN (:caseList[0].caseId)];
        Approval.UnlockResult[] unlockResults = Approval.unlock(casesToUnLock, false);

        for(Approval.UnlockResult ulr : unlockResults){
            if (ulr.isSuccess() == false) {              
                for(Database.Error err : ulr.getErrors()) {                  
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }
            }              
        }
    } 
    
    public static void unLockAnswerRecord (List<CasesToUnLockInput> caseList){

        Answer__c[] answersToUnLock = [SELECT Id From Answer__c WHERE Case__c IN (:caseList[0].caseId)];
        Approval.UnlockResult[] unlockResults = Approval.unlock(answersToUnLock, false);

        for(Approval.UnlockResult ulr : unlockResults){
            if (ulr.isSuccess() == false) {
                for(Database.Error err : ulr.getErrors()) {                  
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }
}