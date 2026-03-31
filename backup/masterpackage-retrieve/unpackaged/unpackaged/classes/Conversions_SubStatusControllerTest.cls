/**
 * @description       : Test class for Conversions_SubStatusController.cls
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 10-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public with sharing class Conversions_SubStatusControllerTest {

    public static Id CONVERSIONS_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();
    public static final String CONVERSION_PROFILE = 'Conversions Agent';
    public static final String CONVERSION_ROLE = 'Conversions';

    @TestSetup
    static void setupData() {
        Profile conProfile = [SELECT Id FROM Profile WHERE Name =: CONVERSION_PROFILE LIMIT 1];
        UserRole conRole = [SELECT Id FROM UserRole WHERE DeveloperName =: CONVERSION_ROLE LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Africa/Johannesburg',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = conProfile.Id,
            UserRoleId = conRole.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        System.runAs(testUser) {
            Case testCase = new Case(
                Subject = 'Test Case',
                Status = 'In Progress',
                Origin = 'Branch',
                OwnerId = testUser.Id,
                RecordTypeId = CONVERSIONS_RECORDID
            );
            insert testCase;

            Conversion__c conversion = new Conversion__c(
                Case__c = testCase.Id,
                Case_Closure_Reason__c = 'Auto Close'
            );
            insert conversion;
        }
    }

    @IsTest
    static void testGetCaseInfo() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
            Case caseRecord = Conversions_SubStatusController.getCaseInfo(testCase.Id);
        Test.stopTest();

        System.assertNotEquals(null, caseRecord, 'Case record should not be null');
    }

    @IsTest
    static void testGetConversionInfo() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
            Conversion__c conversionRecord = Conversions_SubStatusController.getConversionInfo(testCase.Id);
        Test.stopTest();

        System.assertNotEquals(null, conversionRecord, 'Conversion record should not be null');
        System.assertEquals(testCase.Id, conversionRecord.Case__c, 'Conversion should be linked to the test case');
    }

    @IsTest
    static void testCreateTask_Success() {
        Case testCase = [SELECT Id, OwnerId FROM Case LIMIT 1];

        Test.startTest();
        Boolean isCreated = Conversions_SubStatusController.createTask('Follow Up',
                                                                       'This is a test task',
                                                                        System.today().addDays(2),
                                                                        testCase.Id,
                                                                        testCase.OwnerId
                                                                    );
        Test.stopTest();
        System.assertEquals(true, isCreated, 'Task should be created successfully');

        Task task = [SELECT Subject, WhatId FROM Task WHERE WhatId = :testCase.Id LIMIT 1];
        System.assertEquals('Follow Up', task.Subject, 'Task subject should match input');
    }
}