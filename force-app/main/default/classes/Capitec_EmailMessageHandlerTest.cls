/**
 * @description       : Test class for Capitec_EmailMessageHandler
 * @author            : Samiirah Aujub
 * @group             : 
 * @last modified on  : 06-06-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
@isTest
public class Capitec_EmailMessageHandlerTest {

    @testSetup
    static void setupTestData() {
        //Create Account
        Account personAccount = new Account();
        personAccount.FirstName = 'John';
        personAccount.LastName = 'Doe';
        personAccount.ID_Type__c = 'SA Id';
        personAccount.Identity_Number__c = 'ID8901234';
        personAccount.Passport_Number__c = 'P12345';
        personAccount.CIF_Number__c = 'CIF12345';
        personAccount.AccountNumber = 'AccNUM1234';
        
        insert personAccount;

        //create case
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Client_Escalations').getRecordTypeId();

        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin ='Phone';
        caseObj.recordTypeId = caseRecordTypeId;
        caseObj.AccountId = personAccount.Id;
        caseObj.Notice_Deposit_Account_Number__c = '473774657';
        caseObj.Date_of_Transaction__c = system.today() - 5;
        caseObj.Time_of_Transaction__c = system.now().time();
        caseObj.Requested_Amount__c = 20;
        caseObj.Received_Amount__c = 10;
        caseObj.Disputed_Amount__c =10;
        caseObj.Assignment_Reason__c = 'Technical issue with submitting notice';
        
        insert caseObj;
    }

    @isTest
    static void testHandleVerifyAttachments() {
        List<Case> lstCases = [SELECT Id, Assignment_Reason__c FROM Case];

        Test.startTest();
        Boolean exceptionThrown = false;
            try {
                // Create EmailMessage record without attachments
                EmailMessage email = new EmailMessage(
                    ParentId = lstCases[0].Id,
                    ToAddress = 'test@example.com; dlsave@capitecbank.co.za'
                );
                insert email;
            } catch (DmlException e) {
                exceptionThrown = true;
                System.assert(e.getMessage().contains('Cannot send an email without attachments when assignment reason is "Technical issue with submitted notice" or "Technical issue with submitting notice".'), 'Expected validation error was not thrown');
            }
        Test.stopTest();
    }
}