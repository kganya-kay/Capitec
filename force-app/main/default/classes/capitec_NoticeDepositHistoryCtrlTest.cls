/**
 * @description       : Test class for capitec_NoticeDepositHistoryController class
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 30-08-2024
 * @last modified by  : Cornelia Smit - CECSF-376
**/
@IsTest
public with sharing class capitec_NoticeDepositHistoryCtrlTest {

    @TestSetup
    static void setup() {

        WebServiceSettings__c webServiceSettings = new WebServiceSettings__c(
                Name = 'NotificationService',
                Scheme__c = 'callout:',
                Named_Credential__c = 'NC_ClientCommsDomain',
                Endpoint_URL__c = '/clientcomms/notification-service/notification/v1/notify'
        );
        insert webServiceSettings;

        QuickText testQuickText = new QuickText(
                Name = 'Test QuickText',
                Template_Id__c = '123',
                Message = 'Hello {!Account.FirstName}, welcome to our service!',
                RecordTypeId = Schema.getGlobalDescribe().get('QuickText').getDescribe().getRecordTypeInfosByDeveloperName().get('Notification_Template').getRecordTypeId()
        );
        insert testQuickText;

        //Create Account
        Account personAccount = new Account();
        personAccount.FirstName = 'John';
        personAccount.LastName = 'Doe';
        personAccount.ID_Type__c = 'SA Id';
        personAccount.Identity_Number__c = 'ID8901234';
        personAccount.Passport_Number__c = 'P12345';
        personAccount.CIF_Number__c = 'CIF12345';
        personAccount.AccountNumber = 'AccNUM1234';
        personAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

        insert personAccount;

        //create case

        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'Phone';
        caseObj.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Client_Escalations').getRecordTypeId();
        caseObj.AccountId = personAccount.Id;
        caseObj.ContactId = personAccount.PersonContactId;
        caseObj.Notice_Deposit_Account_Number__c = '4737746570';
        caseObj.Date_of_Transaction__c = System.today() - 5;
        caseObj.Time_of_Transaction__c = System.now().time();
        caseObj.Requested_Amount__c = 20;
        caseObj.Received_Amount__c = 10;
        caseObj.Disputed_Amount__c = 10;
        caseObj.OwnerId = UserInfo.getUserId();
        caseObj.Primary_Language__c = 'English';
        caseObj.Capitec_Primary_Need__c = 'Save';
        caseObj.Capitec_Specific_Need__c = 'Notice Deposit Withdrawal Enquiry';
        caseObj.CM_Product__c = 'Notice Deposit';

        insert caseObj;
    }


    @IsTest
    static void testNoticeHistoryCalloutSuccess() {
        // Setup mock HTTP response
        Test.setMock(HttpCalloutMock.class, new Capitec_NoticeHistoryMock(true)); //CECSF-376 - add success boolean
        List<Case> lstCases = [SELECT Id, Account.CIF_Number__c, Notice_Deposit_Account_Number__c FROM Case LIMIT 1];

        Test.startTest();

        String response = capitec_NoticeDepositHistoryController.noticeHistoryCallout(lstCases[0].Notice_Deposit_Account_Number__c, lstCases[0].Account.CIF_Number__c);

        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
    }

    //CECSF-376 - test failure response
    @IsTest
    static void testNoticeHistoryCalloutFailure() {
        // Setup mock HTTP response
        Test.setMock(HttpCalloutMock.class, new Capitec_NoticeHistoryMock(false));
        List<Case> lstCases = [SELECT Id, Account.CIF_Number__c, Notice_Deposit_Account_Number__c FROM Case LIMIT 1];

        Test.startTest();

        String response = capitec_NoticeDepositHistoryController.noticeHistoryCallout(lstCases[0].Notice_Deposit_Account_Number__c, lstCases[0].Account.CIF_Number__c);

        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(true, response.contains('Error'), 'Response should include error');
    }

    @IsTest
    static void testGetNoticeStatusMapping() {
        Test.startTest();

        Map<String, String> mapStatuses = capitec_NoticeDepositHistoryController.getNoticeStatusMapping();

        Test.stopTest();

        System.assertNotEquals(null, mapStatuses);
    }

    @IsTest
    static void testUpdateNoticeCallout() {
        Test.setMock(HttpCalloutMock.class, new Capitec_AmendNoticeMock());

        List<Case> lstCases = [SELECT Id, Account.CIF_Number__c, Notice_Deposit_Account_Number__c FROM Case LIMIT 1];

        Test.startTest();

        String response = capitec_NoticeDepositHistoryController.updateNoticeCallout(lstCases[0].Notice_Deposit_Account_Number__c, lstCases[0].Account.CIF_Number__c, 'NoticeRef123');

        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
    }

    @IsTest
    static void testUpdateCaseOutcome() {
        Case caseObj = [SELECT Id, Outcome__c, OwnerId FROM Case LIMIT 1];
        caseObj.OwnerId = UserInfo.getUserId();
        update caseObj;

        Test.startTest();

        String result = capitec_NoticeDepositHistoryController.updateCaseOutcome(caseObj.Id, 'Invalid');

        Test.stopTest();

        Case updatedCase = [SELECT Outcome__c, OwnerId FROM Case WHERE Id = :caseObj.Id];

        System.assertEquals('Success', result);
        System.assertEquals('Invalid', updatedCase.Outcome__c);
    }

    @IsTest
    static void updateCase() {
        Case caseObj = [SELECT Id, Outcome__c, OwnerId FROM Case LIMIT 1];
        caseObj.OwnerId = UserInfo.getUserId();
        update caseObj;

        Test.startTest();

        //CECSF-201 - update result to string
        caseObj.Outcome__c = 'Successful';
        String result = capitec_NoticeDepositHistoryController.updateCase(caseObj);

        Test.stopTest();

        Case updatedCase = [SELECT Outcome__c FROM Case WHERE Id = :caseObj.Id];

        System.assertEquals('Success', result);
        System.assertEquals('Successful', updatedCase.Outcome__c);
    }
}