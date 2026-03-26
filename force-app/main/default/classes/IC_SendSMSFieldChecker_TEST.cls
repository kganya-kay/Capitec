/**
* Author           Ridwan Moosuddee
* Company          BlueSky
* Date             07/02/2024
* Description      Test Class for IC_SendSMSFieldChecker
**/

@isTest
public class IC_SendSMSFieldChecker_TEST {
	
    @testSetup
    static void setup() {
        IC_TestDataFactory.createSingleCase();
    }
    
    @isTest
    static void testMandatoryFieldChecker() {
 
        String caseNum = [Select CaseNumber from Case LIMIT 1].CaseNumber;
        IC_SendSMSFieldChecker.Request req = new IC_SendSMSFieldChecker.Request();
        req.caseNumber = caseNum; 
        req.productType = 'Credit Life'; 
        req.templateDescription = 'Case Submission';
        
        // Call the method
        List<String> missingFields = IC_SendSMSFieldChecker.checkMandatoryFields(new List<IC_SendSMSFieldChecker.Request>{ req });
        
        // Assertions
        System.assert(missingFields != null, 'Missing fields should not be null.');
        System.assert(!missingFields.isEmpty(), 'There should be at least one missing field.');
    }
}