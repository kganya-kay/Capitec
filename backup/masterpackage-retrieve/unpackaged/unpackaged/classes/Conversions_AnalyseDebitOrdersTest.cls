/**
 * @description       : Test class for Conversions_AnalyseDebitOrders.cls
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 01-27-2026
 * @last modified by  : Samiirah Aujub
**/
@IsTest
public with sharing class Conversions_AnalyseDebitOrdersTest {

    public static Id CONVERSIONS_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();


    @testSetup
    static void setupTestData() {
        Case testCase = new Case(Subject = 'Test Case',
                                 Status = 'In Progress',
                                 Origin = 'Branch',
                                 RecordTypeId = CONVERSIONS_RECORDID
                                );
        insert testCase;


        Debit_Order_Initiator__c initiator = new Debit_Order_Initiator__c(Name = 'Test Initiator',
                                                                          Preferred_Comms__c = 'CB To Email',
                                                                          DOI_Contact_Email__c = 'testDOI@Capitec.com'
                                                                         );
        insert initiator;

        Debit_Order__c immediateDO = new Debit_Order__c(Name = 'DO-001',
                                                       Amount__c = 100.0,
                                                       From_Account__c = '123456789',
                                                       To_Capitec_Account__c = '987654321',
                                                       Debit_Order_Initiator__c = initiator.Id,
                                                       Debit_OrderDate__c = Date.today(),
                                                       Submitted_Cause_Code__c = 'Client to Action',
                                                       Case__c = testCase.Id,
                                                       Category__c = 'WS debit Order Switch'
        );
        Debit_Order__c immediateDO2 = new Debit_Order__c(Name = 'DO-002',
                                                       Amount__c = 100.0,
                                                       From_Account__c = '123456789',
                                                       To_Capitec_Account__c = '987654321',
                                                       Debit_Order_Initiator__c = initiator.Id,
                                                       Debit_OrderDate__c = Date.today(),
                                                       Submitted_Cause_Code__c = 'Client to Action',
                                                       Case__c = testCase.Id,
                                                       Category__c = 'WS debit Order Switch'
        );


        Debit_Order__c futureDatedDO = new Debit_Order__c(Name = 'DO-003',
                                                         Amount__c = 100.0,
                                                         From_Account__c = '123456789',
                                                         To_Capitec_Account__c = '987654321',
                                                         Debit_Order_Initiator__c = initiator.Id,
                                                         Debit_OrderDate__c = Date.today(),
                                                         Submitted_Cause_Code__c = 'No Client Action',
                                                         Case__c = testCase.Id,
                                                         Category__c = 'FD Debit Order Switch',
                                                         Submission_Date__c = Date.today() + 20);

       
        List<Debit_Order__c> lstDOs = new List<Debit_Order__c>{ immediateDO,immediateDO2, futureDatedDO };
        insert lstDOs;
    }



     @IsTest
    static void test_generateEmailBodyForDebitOrders_withData() {
        
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        Conversions_AnalyseDebitOrders.debitOrderInput inputWrapper = new Conversions_AnalyseDebitOrders.debitOrderInput();
        inputWrapper.caseId = testCase.Id;

        List<Conversions_AnalyseDebitOrders.DebitOrderOutput> results = Conversions_AnalyseDebitOrders.generateEmailBodyForDebitOrders(new List<Conversions_AnalyseDebitOrders.debitOrderInput>{inputWrapper});

        

        Conversions_AnalyseDebitOrders.DebitOrderOutput output = results[0];

        System.assert(output.noActionDebitOrdersText.contains('Test Initiator'), 'Immediate DO should contain initiator name');
        System.assertEquals(1, results.size(), 'One result should be returned');
    }
}