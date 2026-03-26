/**
* Author           Ridwan Moosuddee
* Company          BlueSky
* Date             19/02/2024
* Description      Test Class for IC_Automatic_FollowUp_Batch
**/

@isTest
public class IC_Automatic_FollowUp_Batch_TEST {
	
    @isTest
    static void testBatchExecution() {
        
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account a = new Account(
            FirstName = 'Test',
            LastName = 'Account',
            PersonEmail = 'testaccount@example.com',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount'].Id
        );
        insert a;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User queueUser = new User(
            FirstName = 'Waiting',
            LastName = 'for Insurer',
            Email = 'waitingforinsurer@example.com',
            Username = 'waitingforinsurer@example.com',
            Alias = 'wfi',
            ProfileId = p.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US'
        );
        insert queueUser;
        
        Case testCase = new Case(
            Subject = 'Test Case',
            OwnerId = queueUser.Id,
            IC_Insurer_Underwriter_at_Event_Date__c = 'Unknown',
            IC_Last_Response_Received_Date__c = Date.today().addDays(-7),
            IC_From_Email_Address__c = 'waitingforinsurer@example.com',
            AccountId = a.Id
        );
        insert testCase;

        Test.startTest();
            IC_Automatic_FollowUp_Batch batch = new IC_Automatic_FollowUp_Batch();
            Database.executeBatch(batch);
        Test.stopTest();
    }
}