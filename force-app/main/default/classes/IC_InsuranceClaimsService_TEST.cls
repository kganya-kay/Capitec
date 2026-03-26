/********************************\
    @ Func Area     : IC Insurance Claims Service
    @ Author        : Gerhard de Klerk
    @ Date          : 19 Feb 2025
    @ Description   : REST Service to facilitate Claim Reopening Logic
    @ Related files :
    @ Test File     : IC_InsuranceClaimsService_TEST
                    :
===================================
    @ Last Modified By  :
    @ Last Modified On  :
    @ Modification Description :
	@ -
	@ -
===================================
**********************************/
@IsTest
public with sharing class IC_InsuranceClaimsService_TEST {

/* ================================================================================================================
 *  STATIC VARIABLES
 * ================================================================================================================
 */
    private static final String INSURANCECLAIMSERVICEURI = '/insuranceclaimsmanagement/v1/reopen/';
    private static final Id RT_CASE_INSURANCE_CLAIMS = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId(); //Parent Case

/* ================================================================================================================
 *  TEST SETUP
 * ================================================================================================================
 */
    @TestSetup
    static void setup(){
        List<Case> casesToInsert = new List<Case>();
        Case parentCase_funeral_finalised = generateParentCase('Funeral - Finalised', 'Funeral', 'Finalised');
        Case parentCase_funeral_unclassified = generateParentCase('Funeral - Unclassified','Funeral', 'Unclassified');
        Case parentCase_creditLife = generateParentCase('Credit Life - Finalised','Credit Life','Finalised');

        casesToInsert.add(parentCase_funeral_finalised);
        casesToInsert.add(parentCase_funeral_unclassified);
        casesToInsert.add(parentCase_creditLife);
        insert casesToInsert;

    }

/* ================================================================================================================
 *  TESTS
 * ================================================================================================================
 */
    @isTest
    static void testPostMethod_200(){
        Id caseId = getParentCase('Funeral - Finalised').Id;
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = INSURANCECLAIMSERVICEURI + caseId;
        String JSONMsg = '{}';//{"buyerId" : "'+acc.API_Buyer_Id__c+'","Interested":"true"}';
        req.requestBody = Blob.valueof(JSONMsg);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response= res;
        IC_InsuranceClaimsService.doPost();
        Test.stopTest();
        system.debug(res);

        System.assertEquals(200,res.statusCode,'Unexpected Response code');
    }

    @isTest
    static void testPostMethod_400(){
        Id caseId = getParentCase('Funeral - Finalised').Id;
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = INSURANCECLAIMSERVICEURI;
        String JSONMsg = '{}';//{"buyerId" : "'+acc.API_Buyer_Id__c+'","Interested":"true"}';
        req.requestBody = Blob.valueof(JSONMsg);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response= res;
        IC_InsuranceClaimsService.doPost();
        Test.stopTest();
        system.debug(res);
        System.assertEquals(400,res.statusCode,'Unexpected Response code');
    }

/* ================================================================================================================
 *  HELPER FUNCTIONS
 * ================================================================================================================
 */

    private static Case generateParentCase(String subject, String productType, String status){
        Case parentCase = new Case(
                Subject = subject,
                Sub_Status__c = null,
                //IC_Type__c = 'Unemployment/ITEI',
                //Sub_Type__c = 'Retrenchment',
                RecordTypeId = IC_LongOutstandingClaims_Reopen.RT_CASE_INSURANCE_CLAIMS,
                Product_Type__c = productType,
                IC_Type__c = 'Death',
                Sub_Type__c = 'Natural',
                Sub_Type_Reason__c = 'Other Life',
                IC_UnnaturalDeathType__c = 'Accidental',
                IC_Insurer_Underwriter_at_Event_Date__c = 'Centriq',
                Status = status
                // AccountId = a.Id
        );
        return parentCase;
    }

    private static Case getParentCase(String subject){

        List<String> fields = new List<String>(Case.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
                + ' SELECT ' + String.join(fields, ',')
                + ' FROM  Case'
                + ' WHERE RecordTypeId = :RT_CASE_INSURANCE_CLAIMS'
                + ' AND Subject = :subject'
                + ' ORDER BY CreatedDate DESC ';

        List<Case> cases = Database.query(soql);
        return cases[0];
    }

}