@isTest
public class IC_ParticipantsController_TEST {

    @testSetup
    static void setupTestData() {
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
        
        IC_Policy_Participant__c lifeAssured = new IC_Policy_Participant__C();
        lifeAssured.IC_Case__c = testCase.Id;
        lifeAssured.IC_Policy_Number__c = policy.Id;
        lifeAssured.IC_Deceased_Indicator__c = true;
        lifeAssured.IC_Relationship__c = 'Child';
        lifeAssured.RecordTypeId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Lives_Assured').getRecordTypeId();
        insert lifeAssured;
        
        IC_Policy_Participant__c beneficiary = new IC_Policy_Participant__C();
        beneficiary.IC_Case__c = testCase.Id;
        beneficiary.IC_Policy_Number__c = policy.Id;
        beneficiary.IC_Deceased_Indicator__c = true;
        beneficiary.IC_Relationship__c = 'Child';
        beneficiary.RecordTypeId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Beneficiaries').getRecordTypeId();
        insert beneficiary;
        
        IC_Claim_Participant__c claimParticipant = new IC_Claim_Participant__c();
        claimParticipant.IC_Case__c = testCase.Id;
        claimParticipant.IC_Claim_Participant_FirstName__c = 'Claim Participant';
        claimParticipant.IC_Claim_Participant_Surname__c = 'Test';
        claimParticipant.IC_Claim_Participant_ID_Number__c = '0123456789';
        insert claimParticipant;
    }
    
    @isTest
    static void test_getLivesAssuredByCaseId() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        String ppList = IC_ParticipantsController.getLivesAssuredByCaseId(testCase.Id);
        Test.stopTest();
        
        Assert.isFalse(ppList == '');
    }
    
    @isTest
    static void test_getBeneficiariesByCaseId() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        String ppList = IC_ParticipantsController.getBeneficiariesByCaseId(testCase.Id);
        Test.stopTest();
        
        Assert.isFalse(ppList == '');
    }
    
    @isTest
    static void test_getClaimParticipantsByCaseId() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        List<IC_Claim_Participant__c> cpList = IC_ParticipantsController.getClaimParticipantsByCaseId(testCase.Id);
        Test.stopTest();
        
        Assert.isFalse(cpList.isEmpty());
    }

}