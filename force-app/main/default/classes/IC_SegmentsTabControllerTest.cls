/**
 * @description       : Test class for IC_SegmentsTabController
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 11-01-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
@IsTest
private class IC_SegmentsTabControllerTest {

    @TestSetup
    static void setupTestData(){
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Insurance_Claims').getRecordTypeId();
        Id insuranceClaimsChildRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Insurance_Claims_Assessment').getRecordTypeId();
        Id livesAssuredRTId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Lives_Assured').getRecordTypeId();

        Case parentCase = new Case();
        parentCase.Subject = 'Parent case';
        parentCase.RecordTypeId = insuranceClaimsRTId;

        insert parentCase;

        Case testCase = new Case(
            Subject = 'Test Child Case ',
            parentId =  parentCase.Id,
            IC_Policy_Number_child__c = 'Test Policy',
            RecordTypeId = insuranceClaimsChildRTId
        );
        insert testCase;          
    

        IC_Policy__c policy = new IC_Policy__c(Name = 'Test Policy');
        insert policy;

        List<IC_Policy_Participant__c> participants = new List<IC_Policy_Participant__c>();
        for (Integer i = 0; i < 3; i++) {
            IC_Policy_Participant__c participant = new IC_Policy_Participant__c(
                IC_Calculated_Cover_Amount__c = 0,
                IC_Policy_Number__c = policy.Id,
                IC_Case__c = testCase.Id,
                RecordTypeId = livesAssuredRTId              
            );
            participants.add(participant);
        }

        participants[0].IC_Deceased_Indicator__c= true;
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
        
    }

    @IsTest
    static void testGetSegments() {
        Id insuranceClaimsChildRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Insurance_Claims_Assessment').getRecordTypeId();

        List<Case> lstCase = [SELECT Id FROM Case WHERE RecordTypeId =:insuranceClaimsChildRTId];

        // Step 2: Call the method and verify
        Test.startTest();
        String resultJson = IC_SegmentsTabController.getSegments(lstCase[0].Id);
        Test.stopTest();

        if(resultJson != null){
            List<IC_Segment__c> segmentsList = (List<IC_Segment__c>) JSON.deserialize(resultJson, List<IC_Segment__c>.class);
            System.assertNotEquals(null, segmentsList, 'The list should not be null');
        }

    }
}