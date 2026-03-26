/********************************\
    @ Func Area     : IC Long Outstanding Claims (LOC)
    @ Author        : Gerhard de Klerk
    @ Date          : 11 Feb 2025
    @ Description   : LOC Logic for REOPENING
    @ Related files :
    @ Test File     : IC_LongOutstandingClaims_Reopen_TEST
                    :
===================================
    @ Last Modified By  :
    @ Last Modified On  :
    @ Modification Description: 
	@ -
	@ -
===================================
**********************************/
@IsTest
public with sharing class IC_LongOutstandingClaims_Reopen_TEST {

    public static final Id RT_CLAIMSUPPORT_LOC = IC_LongOutstandingClaims_Reopen.RT_CLAIMSUPPORT_LOC;
    public static final Id RT_CASE_INSURANCE_CLAIMS = IC_LongOutstandingClaims_Reopen.RT_CASE_INSURANCE_CLAIMS;

    public static final String CASE_STATUS_CLOSED = 'Finalised';
    public static final String CASE_STATUS_OPEN = 'Unclassified';


    @TestSetup
    static void setup(){

        List<Case> casesToInsert = new List<Case>();
        Case parentCase_funeral_finalised = generateParentCase('Funeral - Closed', 'Funeral', CASE_STATUS_CLOSED);
        Case parentCase_funeral_unclassified = generateParentCase('Funeral - Open','Funeral', CASE_STATUS_OPEN);
        Case parentCase_creditLife = generateParentCase('Credit Life - Closed','Credit Life',CASE_STATUS_CLOSED);

        casesToInsert.add(parentCase_funeral_finalised);
        casesToInsert.add(parentCase_funeral_unclassified);
        casesToInsert.add(parentCase_creditLife);
        insert casesToInsert;

    }

    /**
     * @description Test 1 - Reopen Funeral Case
     * Parent Case Status: Finalized
     * ClaimSupport: No existing
     *
     * EXPECTED OUTCOME:
     * - CSR Created
     * - ParentCase
     *    - Status Updated - Administration
     *    - Owner Changed
     */
    @IsTest
    static void test1(){
        String subject = 'Funeral - Closed';
        Case parentCase = getParentCase(subject);

        String reopenEvent = 'Test Class - reopen)';
        Test.startTest();
        IC_LongOutstandingClaims_Reopen.reopenClaim(parentCase.Id,reopenEvent,false);
        Test.stopTest();

        //GET RECORDS FOR EVALUATION
        Case parentCaseAfter = getParentCase(subject);
        List<IC_ClaimSupport__c> claimSupports = getClaimSupportRecords(parentCase.Id);

        //ASSERTS
        System.assertEquals(1,claimSupports.size(), 'Unexpected number of Claim Support Records');
        System.assertEquals('Active',claimSupports[0].IC_Status__c, 'Unexpected Claim Support Record Status');
        System.assertEquals(parentCase.Id,claimSupports[0].IC_ParentCase__c, 'Unexpected Claim Support Record Parent Case');
        System.assertEquals(reopenEvent,claimSupports[0].IC_LOC_Claim_Reopen_Event__c, 'Unexpected Claim Support Record reopen Event');
        System.assertNotEquals(null,claimSupports[0].IC_LOC_ClaimReopenDate__c, 'Unexpected Claim Support Record reopen date');

        System.assertEquals('Administration',parentCaseAfter.Status, 'Unexpected Parent Case Status');
        System.assertEquals('Update Received',parentCaseAfter.Sub_Status__c, 'Unexpected Parent Case Sub Status');
        System.assertNotEquals(System.UserInfo.getUserId(),parentCaseAfter.OwnerId, 'Unexpected Parent Case Owner');

    }

    /**
     * @description Test 2 - Reopen Credit Life Case
     * Parent Case Status: Finalised
     * ClaimSupport: No existing
     *
     * EXPECTED OUTCOME:
     * No CSR
     * Case not changed
     */
    @IsTest
    static void test2(){
        String subject = 'Credit Life - Closed';
        Case parentCase = getParentCase(subject);
        String reopenEvent = 'Test Class - reopen)';
        Test.startTest();
        IC_LongOutstandingClaims_Reopen.reopenClaim(parentCase.Id,reopenEvent,false);
        Test.stopTest();

        //GET RECORDS FOR EVALUATION
        Case parentCaseAfter = getParentCase(subject);
        List<IC_ClaimSupport__c> claimSupports = getClaimSupportRecords(parentCase.Id);

        //ASSERTS
        System.assertEquals(0,claimSupports.size(), 'Unexpected number of Claim Support Records');

        System.assertEquals(CASE_STATUS_CLOSED,parentCaseAfter.Status, 'Unexpected Parent Case Status');
        System.assertEquals(null,parentCaseAfter.Sub_Status__c, 'Unexpected Parent Case Sub Status');
        System.assertEquals(System.UserInfo.getUserId(),parentCaseAfter.OwnerId, 'Unexpected Parent Case Owner');

    }

    /**
     * @description Test 3 - Reopen Funeral Case - invalid Case id
     * Parent Case Status: Finalized
     * ClaimSupport: No existing
     *
     * EXPECTED OUTCOME:
     * Error to be thrown
     */
    @IsTest
    static void test3(){
        String subject = 'Funeral - Closed';
        //Case parentCase = getParentCase(subject);

        String reopenEvent = 'Test Class - reopen)';
        Test.startTest();
        //USE THE RUNNING USER ID RATHER THAN THE CASE
        try {
            IC_LongOutstandingClaims_Reopen.reopenClaim(System.UserInfo.getUserId(), reopenEvent, false);
        }catch (Exception e){
            System.assertNotEquals(null,e,'Unexpected Case Error');
        }
        Test.stopTest();

    }

    /**
     * @description Test 4 - Reopen Funeral Case (Already Open)
     * Parent Case Status: Unclassified
     * ClaimSupport: No existing
     *
     * EXPECTED OUTCOME:
     * Error to be thrown
     */
    @IsTest
    static void test4(){
        String subject = 'Funeral - Open';
        Case parentCase = getParentCase(subject);

        String reopenEvent = 'Test Class - reopen)';
        Test.startTest();
        try{
            IC_LongOutstandingClaims_Reopen.reopenClaim(parentCase.Id,reopenEvent,false);
        }catch (Exception e){
            System.assertNotEquals(null,e,'Unexpected Case Error');
        }

        Test.stopTest();

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


    private static List<IC_ClaimSupport__c> getClaimSupportRecords(Id parentCaseId){
        List<String> fields = new List<String>(IC_ClaimSupport__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
                + ' SELECT ' + String.join(fields, ',')
                + ' FROM  IC_ClaimSupport__c'
                + ' WHERE IC_Status__c = \'Active\''
                + ' AND RecordTypeId = :RT_CLAIMSUPPORT_LOC'
                + ' AND IC_ParentCase__c = :parentCaseId'
                + ' ORDER BY CreatedDate DESC ';

        List<IC_ClaimSupport__c> claimSupportRecords = Database.query(soql);
        return claimSupportRecords;
    }

    private static List<IC_Client_Mobile_Engagement_History__c> getCommunicationHistories(Id parentCaseId){
        List<String> fields = new List<String>(IC_Client_Mobile_Engagement_History__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
                + ' SELECT ' + String.join(fields, ',')
                + ' FROM  IC_Client_Mobile_Engagement_History__c'
                + ' WHERE IC_Case__c = :parentCaseId'
                + ' ORDER BY CreatedDate DESC ';

        List<IC_Client_Mobile_Engagement_History__c> clientMobileEngagementHistories = Database.query(soql);
        return clientMobileEngagementHistories;
    }


}