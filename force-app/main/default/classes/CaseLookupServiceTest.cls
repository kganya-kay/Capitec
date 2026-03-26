@istest
public class CaseLookupServiceTest {
	@testsetup
    static void dataSetup() {
        // Create test data
        Account testAccount = IC_TestDataFactory.createSingleAccount();
        testAccount = [select id,CIF_Number__c,Name,PersonEmail from account where id=:testAccount.id];
        
         IC_Policy__c testPolicy = new IC_Policy__c(Name = 'PN123', IC_Date_Opened__c = Date.today(),IC_Refund_Amount__c=500);
        insert testPolicy;
        
        Case testCaseFuneral = IC_TestDataFactory.createSingleCase_Funeral();

        testCaseFuneral.AccountId = testAccount.Id;
        testCaseFuneral.IC_Deceased_Date_of_Death__c = Date.today();
        testCaseFuneral.IC_Lodge_Date__c = Date.today();
        testCaseFuneral.Description = 'Test Description';

        update testCaseFuneral;
		
        IC_Policy_Participant__c policyParticipant = new IC_Policy_Participant__c(
                IC_BenefitAmount__c = 100,
                IC_Cover_Amount__c = 200,
                IC_Policy_Number__c = testPolicy.Id,
            	IC_Calculated_Cover_Amount__c = 300,
                IC_Case__c = testCaseFuneral.Id,
            	IC_Relationship__c='Main Life'
        );
        insert policyParticipant;
        
        Case testCaseFuneralClaimant = IC_TestDataFactory.createSingleCase_Funeral_Claimant();

        testCaseFuneralClaimant.AccountId = testAccount.Id;
        testCaseFuneralClaimant.IC_Policy_Number_child__c = 'PN123';
        testCaseFuneralClaimant.IC_Claim_Number__c = 'CL123';
        testCaseFuneralClaimant.IC_Insurer_Claim_Reference__c = 'REF123';
        //testCaseFuneralClaimant.IC_RecommendedPayoutAmount__c = 5000;
        testCaseFuneralClaimant.IC_Decline_Reason__c = 'Decline Reason';
		testCaseFuneralClaimant.IC_Beneficiary__c = policyParticipant.Id;
        update testCaseFuneralClaimant;
        
		testCaseFuneralClaimant = [select id,IC_2nd_Decline_Reason__c,IC_Policy_Number_child__c,IC_Claim_Number__c,casenumber,IC_Insurer_Claim_Reference__c,IC_Decline_Reason__c,IC_RecommendedPayoutAmount__c from case where id=:testCaseFuneralClaimant.id];
       

        List<DocumentType> retrenchmentLetterDocType = [SELECT Id, MasterLabel FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];

        List<DocumentChecklistItem> docChecklistItems = IC_TestDataFactory.createDocumentChecklistItems(new Map<Case, List<DocumentType>>{
                testCaseFuneral => retrenchmentLetterDocType
        });

        
    }
    @isTest static void testPostMethodInterestedFalse(){

        Test.startTest();

         List<Case> cases = [SELECT Id, CIF_Number__c FROM Case];

        RestRequest req = new RestRequest(); 

        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/CaseLookup/'+cases.get(0).CIF_Number__c;

        req.httpMethod = 'GET';

        RestContext.request = req;

        RestContext.response= res;

        CaseLookupService.getCasesByCIF();

        Test.stopTest();

    }
}