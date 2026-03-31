/**
 * @description       : Test class for Conversions_EmailTemplatesController.cls
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 01-27-2026
 * @last modified by  : Samiirah Aujub
**/
@isTest
public with sharing class Conversions_EmailTemplatesControllerTest {
    public static Id CONVERSIONS_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();


    @testSetup
    static void setupTestData() {

        Account acc = new Account(Name = 'Test Account',
                                  CIF_Number__c = '12345678');
        insert acc;

        Case testCase = new Case(Subject = 'Test Case',
                                 Status = 'In Progress',
                                 Origin = 'Branch',
                                 AccountId = acc.Id,
                                 RecordTypeId = CONVERSIONS_RECORDID
                                );
        insert testCase;

        Conversion__c conversion = new Conversion__c(
                Case__c = testCase.Id,
                Case_Closure_Reason__c = 'Auto Close'
            );
            insert conversion;

        Debit_Order_Initiator__c initiator = new Debit_Order_Initiator__c(Name = 'Test Initiator',
                                                                          Preferred_Comms__c = 'CB To Email'
                                                                         );
        insert initiator;

        Debit_Order__c debitOrder = new Debit_Order__c(Name = 'DO-001',
                                                       Amount__c = 100.0,
                                                       To_Capitec_Account__c = '987654321',
                                                       Debit_Order_Initiator__c = initiator.Id,
                                                       Debit_OrderDate__c = Date.today(),
                                                       Submitted_Cause_Code__c = 'Client to Action',
                                                       DO_Issue__c = 'DOA invalid',
                                                       Case__c = testCase.Id
        );
        insert debitOrder;
    }


    @isTest
    static void testControllerMethods() {

        Case caseRecord = [SELECT Id FROM Case LIMIT 1];

        Conversions_EmailTemplatesController controller =new Conversions_EmailTemplatesController();
        controller.caseRecordId = caseRecord.Id;

        Case returnedCase = controller.getCaseRecord();
        Conversion__c returnedConv = controller.getConversion();

        System.assertNotEquals(null, returnedCase, 'Case should be returned');
        System.assertEquals(caseRecord.Id, returnedCase.Id, 'Case ID should match');
        System.assertNotEquals(null, returnedConv, 'Conversion record should be returned');
    }


    @isTest
    static void testNoCaseId() {
        Conversions_EmailTemplatesController controller =new Conversions_EmailTemplatesController();

        System.assertEquals(null, controller.getCaseRecord(), 'Case should be null');
        System.assertEquals(null, controller.getConversion(), 'Conversion should be null');
    }

    @isTest
    static void testDebitOrdersWithIssues() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Account acc = [SELECT Id FROM Account LIMIT 1];


        Conversions_EmailTemplatesController controller = new Conversions_EmailTemplatesController();
        controller.caseRecordId = testCase.Id;

        Boolean hasIssues = controller.getHasIssues();
        List<String> issueLines = controller.getDebitOrderIssueLines();

        System.assertEquals(true, hasIssues, 'Case should have debit order issues');
        System.assertEquals(1, issueLines.size(), 'One issue line expected');
    }

}