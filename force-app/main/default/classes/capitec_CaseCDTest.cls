/**
 * Created by Urvashi Ragobur on 27.10.2023.
 */

@isTest
public class capitec_CaseCDTest {
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    static final String CASH_DISPUTES_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Cash_Disputes').getRecordTypeId();
    
    @TestSetup
    static void dataSetup() {
        Account acc = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
                'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                'CIF_Number__c' => '123456789',
                'Identity_Number__c' => '7101180046087'
        });     
        
        Case cse = new Case();
        cse.Status = 'Open';
        cse.Dispute_Type__c = 'Cash Withdrawal';
        cse.Dispute_Category__c = 'Cash Not Dispensed';
        cse.Dispute_Reported_by_3rdparty__c = 'No';
        cse.recordTypeId = CASH_DISPUTES_RECORD_TYPE_ID;
        cse.AccountId = acc.Id;
        cse.Nothing_Received__c = true;
        cse.Date_of_Transaction__c = system.today() - 5;
        cse.Time_of_Transaction__c = system.now().time();
        cse.Requested_Amount__c = 20;
        cse.Received_Amount__c = 10;
        cse.Disputed_Amount__c =10;
        
        insert cse;
    }
    
    @isTest
    static void insertCaseCash_DisputeTeamUser(){
        User usr = [SELECT Id, Username FROM User WHERE Id = :UserInfo.getUserId()];
        usr.CD_Owner_Team__c = 'Cash Dispute Team';
        update usr;
        
        Test.startTest();
        try {
            System.runAs(usr) {
                Case cse = new Case();
                cse.Status = 'Open';
                cse.recordTypeId = CASH_DISPUTES_RECORD_TYPE_ID;
                insert cse;
            }
        } catch(Exception e) {
            String message = e.getMessage();
            system.assert(message.contains('Please complete this field'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void insertCaseCash_InterbankUser() {
        User usr = [SELECT Id, Username FROM User WHERE Id = :UserInfo.getUserId()];
        usr.CD_Owner_Team__c = 'Interbank';
        update usr;
        
        Test.startTest();
        try {
            System.runAs(usr) {
                Case cse = new Case();
                cse.Status = 'Open';
                cse.Dispute_Type__c = 'Cash Withdrawal';
                cse.Dispute_Category__c = 'Cash Not Dispensed';
                cse.Dispute_Reported_by_3rdparty__c = 'No';
                cse.recordTypeId = CASH_DISPUTES_RECORD_TYPE_ID;
                insert cse;
            }
        } catch(Exception e) {
            String message = e.getMessage();
            system.assert(message.contains('This Interbank Dispute Capture field is required'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void insertCaseCash_BusinessBankUser() {
        User usr = [SELECT Id, Username FROM User WHERE Id = :UserInfo.getUserId()];
        usr.CD_Owner_Team__c = 'Business Bank Complaints';
        update usr;
        
        Test.startTest();
        try {
            System.runAs(usr) {
                Case cse = new Case();
                cse.Status = 'Open';
                cse.Dispute_Type__c = 'Cash Withdrawal';
                cse.Dispute_Category__c = 'Cash Not Dispensed';
                cse.Dispute_Reported_by_3rdparty__c = 'Yes';
                cse.recordTypeId = CASH_DISPUTES_RECORD_TYPE_ID;
                insert cse;
            }
        } catch(Exception e) {
            String message = e.getMessage();
            system.assert(message.contains('Please complete this field'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void makePersonOfInterestRequiredTest() {
        Case cse = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        Test.startTest();
        try {
            cse.Cash_Investigation_Person_of_Interest__c = 'Yes';
        	update cse;
        } catch(Exception e) {
            String message = e.getMessage();
            system.assert(message.contains('Provide the details for a main person of interest.'));
        }
        Test.stopTest();
    }

}