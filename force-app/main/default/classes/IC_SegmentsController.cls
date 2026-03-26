/*******************************************************************
* @Class Name        :  IC_SegmentsController
* @Test Class        :  IC_SegmentsController_TEST
* @Author            :  Franco Pieterse
* @Last Modified By  :  
* @Version           :  1.0
*
*******************************************************************/

public class IC_SegmentsController {
    
    
    private static Id getLivesAssuredByCaseId(String caseId) {
        System.debug('Franco1:' + caseId);
        Case cse = [SELECT parentId FROM Case WHERE Id=:caseId];
        Id parentId = cse.parentId;
        System.debug('Franco2:' + parentId);
        
        return [SELECT Id
                FROM IC_Policy_Participant__c 
                WHERE IC_Case__c = :parentId 
                AND RecordType.Developername = 'Lives_Assured'
                AND IC_Deceased_Indicator__c = true LIMIT 1].Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<IC_Segment__c> getSegmentsByCaseId(String caseId) {

        Id deathLifeAssured = getLivesAssuredByCaseId(caseId);
        List<IC_Segment__c> returnSegments = new List<IC_Segment__c>();
        
        returnSegments = [SELECT Id, Name, IC_Cover_Amount__c,IC_Start_Date__c,IC_End_Date__c
                FROM IC_Segment__c
                WHERE IC_Policy_Participant__c = :deathLifeAssured];
        return returnSegments;
    }    
    
}