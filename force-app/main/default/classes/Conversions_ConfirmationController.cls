/**
 * @description       : Controller for Conversions_Confirmation
 * @author            : Samiirah Aujub
 * @group             : 
 * @last modified on  : 02-04-2026
 * @last modified by  : Samiirah Aujub
**/
public with sharing class Conversions_ConfirmationController {

    @AuraEnabled
    public static Case getCaseInfo(Id caseId){
        if (caseId == null) return null;

        try {
            return [
                SELECT Id,
                       CaseNumber,
                       Owner.Name
                FROM Case
                WHERE Id =: caseId];
            
        } catch (Exception e) {
            System.debug('Error getting case info:' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static Boolean returnCaseToAwaitingDoi(Id caseId) {
        if (caseId == null) {
            return false;
        }
        try{
            Group doiQueue = [SELECT Id
                             FROM Group
                             WHERE Type = 'Queue'
                             AND DeveloperName = 'Awaiting_DOI_Confirmation'
                             LIMIT 1
                            ];

            Case caseRecord = new Case(Id = caseId,
                                       OwnerId = doiQueue.Id
                                   );
            update caseRecord;

            return true;

        }
        catch(Exception ex){
              System.debug('Error updating case info:' + ex.getMessage());
            return false;
            
        }
       
    }
}