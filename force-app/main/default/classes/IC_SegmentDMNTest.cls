/**
 * @description       : Test class for IC_SegmentDMN.cls
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 10-11-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
@IsTest
public class IC_SegmentDMNTest {

    @TestSetup
    public static void setupTestData() {
        List<Case> lstChildCases = new List<Case>();
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Insurance_Claims').getRecordTypeId();
        Id insuranceClaimsChildRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Insurance_Claims_Assessment').getRecordTypeId();

        Case parentCase = new Case();
        parentCase.Subject = 'Parent case';
        parentCase.RecordTypeId = insuranceClaimsRTId;

        insert parentCase;

        
        for (Integer i = 0; i < 3; i++) {
            Case testCase = new Case(
                Subject = 'Test Case ' + i,
                parentId =  parentCase.Id,
                RecordTypeId = insuranceClaimsChildRTId
            );
            lstChildCases.add(testCase);
        }
        insert lstChildCases;
    
        List<IC_Policy__c> policies = new List<IC_Policy__c>();
        for (Integer i = 0; i < 3; i++) {
            IC_Policy__c policy = new IC_Policy__c(
                Name = 'POL' + i
            );
            policies.add(policy);
        }
        insert policies;

        List<IC_Policy_Participant__c> participants = new List<IC_Policy_Participant__c>();
        for (Integer i = 0; i < 3; i++) {
            IC_Policy_Participant__c participant = new IC_Policy_Participant__c(
                IC_Calculated_Cover_Amount__c = 0,
                IC_Policy_Number__c = policies[i].Id, 
                IC_Case__c = lstChildCases[i].Id              
            );
            participants.add(participant);
        }
        insert participants;
            
        List<IC_Segment__c> segments = new List<IC_Segment__c>();
        for (IC_Policy_Participant__c participant : participants) {
            IC_Segment__c segment = new IC_Segment__c(
                IC_Policy_Participant__c = participant.Id,
                IC_Cover_Amount__c = 10000.00,
                IC_Start_Date__c = Date.today().addMonths(-2),
                IC_End_Date__c = Date.today().addMonths(2),
                IC_Deceased_Date_of_Death__c = Date.today().addDays(-27),
                IC_Cover_Effective_Date__c = Date.today().addDays(-30),
                IC_Select_to_Pay__c = true,
                IC_Recommendation_to_Pay__c = true
            );
            segments.add(segment);
        }
        insert segments;
        update segments;
    }
    

    @IsTest
    public static void testRecalculateSegments() {
        List<IC_Segment__c> testSegments = [SELECT Id,
                                                   IC_Deceased_Date_of_Death__c,
                                                   IC_Start_Date__c, 
                                                   IC_End_Date__c,
                                                   IC_Policy_Participant__c, 
                                                   IC_Cover_Amount__c,
                                                   IC_Cover_Effective_Date__c,
                                                   IC_In_Force_on_Event_Date__c,
                                                   IC_In_Waiting_Period_on_Event_Date__c,
                                                   IC_Select_to_Pay__c,
                                                   IC_Recommendation_to_Pay__c
                                            FROM IC_Segment__c];

        IC_SegmentDMN.recalculateSegments(testSegments, true);

        List<IC_Policy_Participant__c> participants = [SELECT Id, IC_Calculated_Cover_Amount__c FROM IC_Policy_Participant__c];
    }

    @IsTest
    public static void testRecommendedOutcome() {
        List<IC_Segment__c> testSegments = [SELECT Id, IC_Policy_Participant__c FROM IC_Segment__c];

        IC_SegmentDMN.recommendedOutcome(testSegments);

        List<IC_Policy_Participant__c> participants = [SELECT Id, IC_Recommended_Outcome__c, IC_Recommended_Reason__c FROM IC_Policy_Participant__c];
        
        for (IC_Policy_Participant__c participant : participants) {
            System.assert(participant.IC_Recommended_Outcome__c != null, 'Recommended Outcome should be set.');
        }
    }
/*
    @IsTest
    public static void testRecommendToPaySegment() {
        IC_Segment__c segment = [SELECT Id, IC_Start_Date__c, IC_End_Date__c, IC_Cover_Effective_Date__c FROM IC_Segment__c LIMIT 1];

        Date deceasedDate = Date.today();

        IC_Segment__c updatedSegment = IC_SegmentDMN.recommendToPaySegment(deceasedDate, segment, true);

        System.assert(updatedSegment.IC_Recommendation_to_Pay__c, 'Segment should be recommended to pay.');
        System.assert(updatedSegment.IC_Select_to_Pay__c, 'Segment should be selected to pay.');
    }

    @IsTest
    public static void testCalculateAssuredAmount() {
        List<IC_Segment__c> testSegments = [SELECT  Id,
                                                    IC_Select_to_Pay__c, 
                                                    IC_Cover_Amount__c, 
                                                    IC_Policy_Participant__c, 
                                                    IC_Policy_Participant__r.IC_Case__c,
                                                    IC_Policy_Participant__r.IC_Case__r.IC_Total_Assured_Amount_on_Policy__c,
                                                    IC_Policy_Participant__r.IC_Case__r.RecordTypeId, 
                                                    IC_Policy_Participant__r.IC_Case__r.ParentId
                                            FROM IC_Segment__c];

        if(!testSegments.isEmpty()){
            testSegments[0].IC_Select_to_Pay__c = true;

            update testSegments[0];

            IC_SegmentDMN.calculateAssuredAmount(null, testSegments);

            List<Case> cases = [SELECT Id, IC_Total_Assured_Amount_on_Policy__c 
                                FROM Case
                                WHERE Id=: testSegments[0].IC_Policy_Participant__r.IC_Case__c];

            System.assert(cases[0].IC_Total_Assured_Amount_on_Policy__c > 0, 'Total Assured Amount should be updated on Case.');

        }
    }
*/
}