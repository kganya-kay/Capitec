/**
 * @description       : IC_Segments controller
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 10-29-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class IC_SegmentsTabController {

     /**
    * @description This method return the segments associated to the Deceased of the related policy to the child case [ICS-1745]
    * @author Samiirah.A@bsky.co.za | 10-02-2024 
    * @param caseId 
    * @return String
    **/
    @AuraEnabled(cacheable=true)
    public static String getSegments(String caseId) {
        List<IC_Segment__c> lstSegments = new List<IC_Segment__c>();

        List<Case> lstCase = [SELECT Id,
                                     IC_Policy_Number_child__c,
                                     ParentId
                              FROM Case
                              WHERE Id =:caseId];
        System.debug('##getSegments lstCase:' + lstCase);
        
        if(!lstCase.isEmpty() && lstCase != null){
            String policyNumber = lstCase[0].IC_Policy_Number_child__c;
            System.debug('##getSegments policyNumber:' + policyNumber);

            if(policyNumber != null){
                   List <IC_Policy_Participant__c> lstParticipant = [SELECT Id, 
                                                                      Name, 
                                                                      IC_Deceased_Indicator__c
                                                                     FROM IC_Policy_Participant__c
                                                                     WHERE IC_Policy_Number__r.Name =:policyNumber
                                                                     AND IC_Deceased_Indicator__c = true
                                                                    ];
                    System.debug('##getSegments lstParticipant:' + lstParticipant);

                if(!lstParticipant.isEmpty() && lstParticipant != null){
                    lstSegments = [ SELECT Id,
                                           Name,
                                           IC_Cover_Amount__c,
                                           IC_Start_Date__c,
                                           IC_End_Date__c
                                    FROM IC_Segment__c
                                    WHERE IC_Policy_Participant__c =: lstParticipant[0].Id
                                  ];
                    System.debug('##getSegments lstSegments:' + lstSegments);
                }
            }
        }

        if(!lstSegments.isEmpty() && lstSegments != null){
            return JSON.serialize(lstSegments);
        }
        else{
            return null;
        }
    }   
}