/**
 * @description       : Test class for Conversions_ConfirmationController
 * @author            : Samiirah Aujub
 * @group             : 
 * @last modified on  : 02-06-2026
 * @last modified by  : Samiirah Aujub
**/
@IsTest
public with sharing class Conversions_ConfirmationController_Test {
public static Id CONVERSIONS_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();

    @testSetup
    static void setupTestData() {
        Case testCase = new Case(Subject = 'Test Case',
                                 Status = 'In Progress',
                                 Origin = 'Branch',
                                 Claim_Number__c = '12345679',
                                 RecordTypeId = CONVERSIONS_RECORDID
                                );
        insert testCase;

        Conversion__c conversion = new Conversion__c(Case__c = testCase.Id,
                                                     Old_Account_Number__c = '111222333'
                                                     );
        insert conversion;
    }

    @IsTest
    static void testGetCaseInfo() {
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];
    
        Test.startTest();
            Case result = Conversions_ConfirmationController.getCaseInfo(caseRecord.Id);
        Test.stopTest();

    }

    @IsTest
    static void testGetCaseInfoError() {
        Id fakeCaseId = '500000000000000AAA';

        Test.startTest();
            Case result = Conversions_ConfirmationController.getCaseInfo(fakeCaseId);
        Test.stopTest();

        System.assertEquals(null, result,'Method should return null when case does not exist');
    }


    @IsTest
    static void testReturnCaseToAwaitingDoi() {
        Case caseRecord = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
            Boolean result = Conversions_ConfirmationController.returnCaseToAwaitingDoi(caseRecord.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Expected true on successful update');
    }

        @IsTest
    static void testReturnCaseToAwaitingDoiError() {
        Id fakeCaseId = '500000000000000AAA';

        Test.startTest();
            Boolean result = Conversions_ConfirmationController.returnCaseToAwaitingDoi(fakeCaseId);
        Test.stopTest();

        System.assertEquals(false, result,'Method should return null when case does not exist');
    }


}