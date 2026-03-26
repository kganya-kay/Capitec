@isTest
public class IC_LivesAssuredController_TEST {
    
    @isTest
    static void test_getLivesAssuredByCaseId() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case testCase = new Case(
            IC_Data_Wash_Service__c = true,
            Event_Date__c = Date.today(),
            IC_Type__c = 'Death',
            Product_Type__c = 'Funeral',
            Sub_Type__c = 'Natural',
            Last_Working_Date__c = Date.today(),
            RecordTypeId = insuranceClaimsRTId,
            Origin = 'Data Wash'
            
        );
        insert testCase;
        
        IC_Policy__c policy = new IC_Policy__c();
        policy.Parent_Case__c = testCase.Id;
        policy.Name = '123456789';
        insert policy;
        
        IC_Policy_Participant__c livesAssured = new IC_Policy_Participant__C();
        livesAssured.IC_Case__c = testCase.Id;
        livesAssured.IC_Policy_Number__c = policy.Id;
        livesAssured.IC_Deceased_Indicator__c = true;
        livesAssured.IC_Relationship__c = 'Child';
        livesAssured.RecordTypeId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Lives_Assured').getRecordTypeId();
        insert livesAssured;
        
        Test.startTest();
        List<IC_Policy_Participant__c> ppList = IC_LivesAssuredController.getLivesAssuredByCaseId(testCase.Id);
        Test.stopTest();
        
        Assert.areEqual(livesAssured.Id, ppList[0].Id);
    }

}