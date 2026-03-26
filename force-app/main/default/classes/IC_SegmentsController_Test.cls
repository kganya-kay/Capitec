@isTest
public class IC_SegmentsController_Test {
   
 @testSetup
    static void setupTestData() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case testParentCase = new Case(
            IC_Data_Wash_Service__c = true,
            Event_Date__c = Date.today(),
            IC_Type__c = 'Death',
            Product_Type__c = 'Funeral',
            Sub_Type__c = 'Natural',
            Last_Working_Date__c = Date.today(),
            RecordTypeId = insuranceClaimsRTId,
            Origin = 'Data Wash'
            
        );
        insert testParentCase;
        
        Case testCase = new Case(
            IC_Data_Wash_Service__c = true,
            Event_Date__c = Date.today(),
            IC_Type__c = 'Death',
            Product_Type__c = 'Funeral',
            Sub_Type__c = 'Natural',
            Last_Working_Date__c = Date.today(),
            RecordTypeId = insuranceClaimsRTId,
            ParentId = testParentCase.Id,
            Origin = 'Data Wash'
            
        );
        insert testCase;
        System.debug('Franco:' + testcase.Id);
        System.debug('Franco0:' + testcase.ParentId);
        
        IC_Policy__c policy = new IC_Policy__c();
        policy.Parent_Case__c = testcase.ParentId;
        policy.Name = '123456789';
        insert policy;
        
        IC_Policy_Participant__c lifeAssured = new IC_Policy_Participant__C();
        lifeAssured.IC_Case__c = testcase.ParentId;
        lifeAssured.IC_Policy_Number__c = policy.Id;
        lifeAssured.IC_Deceased_Indicator__c = true;
        lifeAssured.IC_Relationship__c = 'Child';
        lifeAssured.RecordTypeId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Lives_Assured').getRecordTypeId();
        insert lifeAssured;
        
        /*
        IC_Policy_Participant__c beneficiary = new IC_Policy_Participant__C();
        beneficiary.IC_Case__c = testParentCase.Id;
        beneficiary.IC_Policy_Number__c = policy.Id;
        beneficiary.IC_Deceased_Indicator__c = true;
        beneficiary.IC_Relationship__c = 'Child';
        beneficiary.RecordTypeId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Beneficiaries').getRecordTypeId();
        insert beneficiary;
        */
        
        IC_Segment__c segment = new IC_Segment__c();
        segment.IC_Cover_Amount__c = 20000;
        segment.IC_Start_Date__c = Date.valueOf('2023-02-01');
        segment.IC_End_Date__c = Date.valueOf('2024-05-22');
        segment.IC_Policy_Participant__c = lifeAssured.Id;
        insert segment;
        
    }
    
    
    @isTest
    static void getSegmentsByCaseIdTest() {
    
        Case testCase = [SELECT Id FROM Case WHERE ParentId != null LIMIT 1];
        
        Test.startTest();
           List<IC_Segment__c> sList = IC_SegmentsController.getSegmentsByCaseId(testCase.Id);
        Test.stopTest();
        
        Assert.isFalse(sList.isEmpty());
    }
    
}