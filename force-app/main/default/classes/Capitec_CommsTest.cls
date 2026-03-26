/**
 * Created by Vignesh on 02.01.2024.
 */

@IsTest
public class Capitec_CommsTest {

    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    static final String COMPLAINTS_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Retail_Complaints').getRecordTypeId();

    @TestSetup
    static void dataSetup() {
        Account acc = new Account();
        acc.RecordTypeId = PERSONAL_ACCOUNT_RECORD_TYPE_ID;
        acc.CIF_Number__c = '123456789';
        acc.Identity_Number__c = '7101180046087';
        acc.LastName = 'UnitTest';

        insert acc;

        Case cse = new Case();
        cse.Status = 'New';
        cse.recordTypeId = COMPLAINTS_RECORD_TYPE_ID;
        cse.AccountId = acc.Id;
        cse.Date_of_Transaction__c = system.today() - 5;
        cse.Time_of_Transaction__c = system.now().time();
        cse.Requested_Amount__c = 20;
        cse.Received_Amount__c = 10;
        cse.Disputed_Amount__c =10;

        insert cse;
    }

    @IsTest
    static void ClientCommsWorking() {
        Test.setMock(HttpCalloutMock.class, new capitec_CommsMock());

        case cs = [SELECT Id, CaseNumber, Name_of_Account__c FROM Case LIMIT 1];

        capitec_CommsController.NotifyCaseStatusUpdateRequest input = new capitec_CommsController.NotifyCaseStatusUpdateRequest();
        input.updatedCase = cs;
        input.sourceSystem = 'Salesforce_Complaints';
        input.templateID = '288';
        input.channel = 'Sms';
        input.templateParams = new List<string>{cs.CaseNumber, cs.Name_of_Account__c};
        Boolean gotError = false;

        Test.startTest();

        try {
            capitec_CommsController.NotifyCaseStatusUpdate(new List<capitec_CommsController.NotifyCaseStatusUpdateRequest>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_CommsController.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_CommsController.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }

        Test.stopTest();

        System.assertEquals(false, gotError, 'Exception has not been throw.');
    }

    @IsTest
    static void ClientCommsNotWorking() {
        Test.setMock(HttpCalloutMock.class, new capitec_CommsMock());

        case cs = [SELECT Id, CaseNumber, Name_of_Account__c FROM Case LIMIT 1];

        capitec_CommsController.NotifyCaseStatusUpdateRequest input = new capitec_CommsController.NotifyCaseStatusUpdateRequest();
        input.updatedCase = cs;
        input.sourceSystem = 'Salesforce_Complaints';
        input.templateID = '';
        input.channel = 'Sms';
        input.templateParams = new List<string>{cs.CaseNumber, cs.Name_of_Account__c};
        Boolean gotError = false;

        Test.startTest();
        try {
            capitec_CommsController.NotifyCaseStatusUpdate(new List<capitec_CommsController.NotifyCaseStatusUpdateRequest>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_CommsController.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_CommsController.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, gotError, 'Exception has been throw.');
    }
}