/*******************************************************************
* @Class Name        :  IC_LodgeClaimFieldChecker_TEST
* @Author            :  Dhriven
* @Last Modified By  : Samiirah.A@bsky.co.za
* @Version           :  1.0
*
*******************************************************************/

@isTest
public class IC_LodgeClaimFieldChecker_TEST {
    
    @testSetup
    static void setup() {
        IC_TestDataFactory.createSingleCase();

        //ICS-1576 - Samiirah Aujub
        IC_TestDataFactory.createSingleCase_Funeral_Claimant();
        // NOTE: Direct DML operations are not supported on Custom Metadata. So this line is for example purposes only.
        // IC_Lodge_Claim_Mandatory_Fields__mdt records need to be pre-created in target org
    }
    
    @isTest
    static void testMandatoryFieldChecker() {
        // Initialize Request
        String caseNum = [Select CaseNumber from Case LIMIT 1].CaseNumber;
        IC_LodgeClaimFieldChecker.Request req = new IC_LodgeClaimFieldChecker.Request();
        req.caseNumber = caseNum; // Your sample case number that was inserted in @testSetup. Adjust as necessary.
        req.productType = 'Credit Life';
        req.caseType = 'Unemployment/ITEI';
        req.buttonSelected = 'Approve';
        req.caseOrigin = 'Data Wash';
        
        // Call the method
        List<String> missingFields = IC_LodgeClaimFieldChecker.checkMandatoryFields(new List<IC_LodgeClaimFieldChecker.Request>{ req });
        
        // Assertions
        System.assert(missingFields != null, 'Missing fields should not be null.');
        System.assert(!missingFields.isEmpty(), 'There should be at least one missing field.');
    }

    //30/09/2024 -- ICS - 1576 -Added by Samiirah Aujub for Sanlam mandatory field checker

    @isTest
    static void testMandatoryFieldCheckerSanlam() {
        Case caseRecord = [SELECT CaseNumber FROM Case WHERE Product_Type__c = 'Funeral' LIMIT 1];

        List<IC_Policy__c> lstPolicy = IC_TestDataFactory.createPolicies(caseRecord, 1);
        IC_TestDataFactory.createLivesAssured(caseRecord,lstPolicy[0],1);
        IC_TestDataFactory.createBeneficiaries(caseRecord,lstPolicy[0],2);

        IC_LodgeClaimFieldChecker.Request req = new IC_LodgeClaimFieldChecker.Request();
        req.caseNumber = caseRecord.CaseNumber;
        req.productType = 'Funeral';
        req.caseType = 'Death';
        req.buttonSelected = 'Sanlam';
        req.caseOrigin = 'Manual';


        Test.startTest();
            // Call the method
            List<String> missingFields = IC_LodgeClaimFieldChecker.checkMandatoryFields(new List<IC_LodgeClaimFieldChecker.Request>{ req });
        Test.stopTest();
        
        // Assertions
        System.assert(missingFields != null, 'Missing fields should not be null.');
        System.assert(!missingFields.isEmpty(), 'There should be at least one missing field.');
    }
}