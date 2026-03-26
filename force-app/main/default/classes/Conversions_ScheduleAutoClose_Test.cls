/**
 * @description       : Test class for Conversions_ScheduleAutoClose.cls
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 10-15-2025
 * @last modified by  : Samiirah.A@bsky.co.za
**/
@IsTest
private class Conversions_ScheduleAutoClose_Test {
    public static Id CONVERSIONS_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();
    
    @TestSetup
    static void setupData() {
        Case testCase = new Case(Subject = 'Test Case',
                                 Status = 'In Progress',
                                 Origin = 'Branch',
                                 RecordTypeId = CONVERSIONS_RECORDID
                                );
        insert testCase;
    }

    @IsTest
    static void testScheduleAutoClose_Success() {
        Case testCase = [SELECT Id, SLA_Time__c FROM Case LIMIT 1];

        Conversions_ScheduleAutoClose.inputReq input = new Conversions_ScheduleAutoClose.inputReq();
        input.caseId = testCase.Id;
        input.days = 2;

        Test.startTest();
        Conversions_ScheduleAutoClose.ScheduleAutoClose(new List<Conversions_ScheduleAutoClose.inputReq>{ input });
        Test.stopTest();

        Case updatedCase = [SELECT Id, SLA_Time__c FROM Case WHERE Id = :testCase.Id];
        System.assertNotEquals(null, updatedCase.SLA_Time__c, 'SLA_Time__c should be populated');
    }

    @IsTest
    static void testScheduleAutoClose_NullDays() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Conversions_ScheduleAutoClose.inputReq input = new Conversions_ScheduleAutoClose.inputReq();
        input.caseId = testCase.Id;
        input.days = 0;

        Test.startTest();
        Conversions_ScheduleAutoClose.ScheduleAutoClose(new List<Conversions_ScheduleAutoClose.inputReq>{ input });
        Test.stopTest();
        Case result = [SELECT SLA_Time__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(null, result.SLA_Time__c, 'SLA_Time__c should remain null when days = 0');
    }

    @IsTest
    static void testGetDaysInBusinessHours() {
        Id bhId = [SELECT Id FROM BusinessHours WHERE Name = 'Conversions Business Hours' LIMIT 1].Id;

        Datetime result = Conversions_ScheduleAutoClose.getDaysInBusinessHours(2, bhId);
        System.assertNotEquals(null, result, 'Deadline should be calculated for valid days input');
    }

    @IsTest
    static void testGetConversionBH() {
        Id bhId = Conversions_ScheduleAutoClose.getConversionBH();
        System.assertNotEquals(null, bhId, 'Business Hours ID should be returned');
    }
}