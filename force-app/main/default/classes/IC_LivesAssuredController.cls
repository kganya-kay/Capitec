public class IC_LivesAssuredController {
    
    @AuraEnabled(cacheable=true)
    public static List<IC_Policy_Participant__c> getLivesAssuredByCaseId(String caseId) {
        
        return [SELECT Id, IC_Policy_Number__c, IC_Policy_Number__r.Name, 
                IC_Name__c, IC_Surname__c, IC_Date_of_Birth__c, 
                IC_Identity_Number__c, IC_Relationship__c, 
                IC_Cover_Amount__c, IC_Calculated_Cover_Amount__c, 
                IC_In_Waiting_Period__c, IC_Deceased_Indicator__c 
                FROM IC_Policy_Participant__c 
                WHERE IC_Case__c = :caseId 
                AND RecordType.Developername = 'Lives_Assured'];
    }

}