/**
 * @description       : Test class for Capitec_DebitOrderController.cls
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 03-09-2026
 * @last modified by  : Samiirah Aujub
**/
@isTest
private class Capitec_DebitOrderControllerTest {

    public static Id CONVERSIONS_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();


    @testSetup
    static void setupTestData() {
        Case testCase = new Case(Subject = 'Test Case',
                                 Status = 'In Progress',
                                 Origin = 'Branch',
                                 RecordTypeId = CONVERSIONS_RECORDID
                                );
        insert testCase;

        Conversion__c conversion = new Conversion__c(Case__c = testCase.Id,
                                                     Old_Account_Number__c = '111222333'
                                                     );
        insert conversion;

        Debit_Order_Initiator__c initiator = new Debit_Order_Initiator__c(Name = 'Test Initiator',
                                                                          Preferred_Comms__c = 'Client to Switch'
                                                                         );
        insert initiator;

        Debit_Order__c debitOrder = new Debit_Order__c(Name = 'DO-001',
                                                       Amount__c = 100.0,
                                                       From_Account__c = '123456789',
                                                       To_Capitec_Account__c = '987654321',
                                                       Debit_Order_Initiator__c = initiator.Id,
                                                       Debit_OrderDate__c = Date.today(),
                                                       Submitted_Cause_Code__c = 'Client to Action',
                                                       Case__c = testCase.Id
        );
        insert debitOrder;

        IC_DocumentRequestList__c doc = new IC_DocumentRequestList__c(Case__c = testCase.Id,
                                                                      CON_Classified__c = false
                                        );
        insert doc;

    }

    @isTest
    static void testGetDebitOrders() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        List <Debit_Order__c> lstDOs = [SELECT Id,
                                               Debit_Order_Initiator__r.Preferred_Comms__c
                                        FROM Debit_Order__c];

        Test.startTest();
            Boolean result = Capitec_DebitOrderController.caseSubmission(testCase.Id, lstDOs);
        Test.stopTest();

        System.assertEquals(true, result,'caseSubmission should return true for valid inputs');
    }

    @isTest
    static void testCaseSubmission() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        Capitec_DebitOrderController.CaseWrapper result = Capitec_DebitOrderController.getCaseInfo(testCase.Id);
        Test.stopTest();

        System.assertEquals(testCase.Id, result.caseRecord.Id, 'Returned case should match input case');
    }

    @isTest
    static void testUpdateCaseStatus() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
       		Capitec_DebitOrderController.updateCaseStatus(testCase.Id, 'Confirmed');
        Test.stopTest();

        Case updatedCase = [SELECT Status FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('Confirmed', updatedCase.Status, 'Status should be updated');
    }

     @isTest
    static void testgetDOIDetails() {
        Debit_Order_Initiator__c debitOrderInit = [SELECT Id FROM Debit_Order_Initiator__c LIMIT 1];

        Test.startTest();
            Debit_Order_Initiator__c fetchedDOI = Capitec_DebitOrderController.getDOIDetails(debitOrderInit.Id);
        Test.stopTest();

        System.assertEquals(debitOrderInit.Id, fetchedDOI.Id, 'Case status update should succeed');
    }

    @isTest
    static void testGetHolidays() {
        Test.startTest();
            List<String> holidays = Capitec_DebitOrderController.getHolidays();
        Test.stopTest();

        System.assert(!holidays.isEmpty(), 'Holidays list should not be empty');
    }

    @isTest
    static void testGetOrgWideEmailAddress() {
        Test.startTest();
            Id resultId = Capitec_DebitOrderController.getOrgWideEmailAddress();
        Test.stopTest();

        System.assertNotEquals(null, resultId, 'Method should return OrgWideEmailAddress Id');
    }

    @isTest
    static void testGetConversionRecord() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
            Conversion__c conv = Capitec_DebitOrderController.getConversionRecord(testCase.Id);
        Test.stopTest();

        System.assertNotEquals(null, conv, 'Conversion record should be returned');
        System.assertEquals('111222333',conv.Old_Account_Number__c,'Old account number should match');
    }

    @isTest
    static void testGetUnclassifiedFiles() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
            Boolean result = Capitec_DebitOrderController.getUnclassifiedFiles(testCase.Id);
        Test.stopTest();

        System.assertEquals(true, result);

    }
}