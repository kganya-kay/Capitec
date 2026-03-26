/**
 * Capitec_TrackAndTraceFlaggingHandlerTest Class
 *
 * This class is responsible for testing Capitec_TrackAndTraceFlaggingHandler and related classes
 *
 * Created by: Tomasz
 */


@isTest
public class Capitec_TrackAndTraceFlaggingHandlerTest {
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
    static void testSaveFlaggedCoreBankingTransactions() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1]; 
        if (!accounts.isEmpty()) {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String corebankingJSON = '{ "content": [{ "id": "1", "availableBalance": 100.0, "transactionAmount": 50.0, "transactionDate": "2023-10-05", "postDate": "2023-10-05", "authId": "12345", "branchId": "A123", "cardNumber": "1234567890", "creditDebitIndicator": "CR", "journalNumber": "789", "narrative": "Test Transaction", "promoCode": "PROMO123", "accountNumber": "9876543210" }], "caseId": "' + testCase.Id + '" }';
        
        Test.startTest();
        Boolean result = Capitec_TrackAndTraceFlaggingHandler.saveFlaggedCoreBankingTransactions(corebankingJSON);
        Test.stopTest();
        
        System.assertEquals(true, result);
        }else {
            System.debug('No Account records found.');
        }
    }

    @isTest
    static void testSaveFlaggedCardTransactions() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1]; 
        if (!accounts.isEmpty()) {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String cardTransactionJSON = '{ "content": [{ "id": "1", "fromAccountNumber": "9876543210", "officeTransactionNumber": "123456", "siteName": "Test Site", "deviceId": "Device123", "sourceNodeName": "SourceNode", "sinkNodeName": "SinkNode", "cardProduct": "Test Product", "transactionType": "Type1", "responseCode": "RESP123", "retrievalReferenceNumber": "REF123", "authId": "456", "messageType": "MsgType", "systemTraceAuditNumber": "789", "reconBatchNumber": "Batch123", "transactionPostilionOriginated": "true", "transactionDateTime": "2023-10-05T12:34:56", "transactionRequestAmount": 50.0, "transactionResponseAmount": 50.0, "settleAmountImpact": 0.0 }], "caseId": "' + testCase.Id + '" }';
        
        Test.startTest();
        Boolean result = Capitec_TrackAndTraceFlaggingHandler.saveFlaggedCardTransactions(cardTransactionJSON);
        Test.stopTest();
        
        System.assertEquals(false, result);
        }else {
            System.debug('No Account records found.');
        }
    }

    @isTest
    static void testSaveFlaggedCardATMDeviceEvents() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1]; 
        if (!accounts.isEmpty()) {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String atmDeviceEventJSON = '{ "content": [{ "id": "1", "deviceId": "Device123", "eventDateTime": "2023-10-05T12:34:56", "eventMessage": "Test Event", "eventNumber": "123", "originalMessage": "Original Msg" }], "caseId": "' + testCase.Id + '" }';
        
        Test.startTest();
        Boolean result = Capitec_TrackAndTraceFlaggingHandler.saveFlaggedCardATMDeviceEvents(atmDeviceEventJSON);
        Test.stopTest();
        
        System.assertEquals(true, result);
        }else {
            System.debug('No Account records found.');
        }
    }

    @isTest
    static void testSaveFlaggedCardATMTransactionEvents() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1]; 
        if (!accounts.isEmpty()) {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String atmTransactionEventJSON = '{ "content": [{ "id": "1", "deviceId": "Device123", "eventId": "Event123", "entity": "Entity1", "severity": "High", "message": "Test Message", "eventDateTime": "2023-10-05T12:34:56" }], "caseId": "' + testCase.Id + '" }';
        
        Test.startTest();
        Boolean result = Capitec_TrackAndTraceFlaggingHandler.saveFlaggedCardATMTransactionEvents(atmTransactionEventJSON);
        Test.stopTest();
        
        System.assertEquals(true, result);
        }else {
            System.debug('No Account records found.');
        }
    }
    
    @isTest
    static void testselectCDDRIndicatorIds() {
       Case testCase = [SELECT Id FROM Case LIMIT 1];
       Test.startTest();
       List<String> ids = Capitec_TrackAndTraceFlaggingHandler.selectCDDRIndicatorIds(testCase.Id);
       Test.stopTest();
       System.assertEquals(0, ids.size());
	}
    
    @isTest
    static void testselectCardTransactionsIds() {
       Case testCase = [SELECT Id FROM Case LIMIT 1];
       Test.startTest();
       List<String> ids = Capitec_TrackAndTraceFlaggingHandler.selectCardTransactionsIds(testCase.Id);
       Test.stopTest();
       System.assertEquals(0, ids.size()); 
	}
    
    @isTest
    static void testselectATMTransactionEventIds() {
       Case testCase = [SELECT Id FROM Case LIMIT 1];
       Test.startTest();
       List<String> ids = Capitec_TrackAndTraceFlaggingHandler.selectATMTransactionEventIds(testCase.Id);
       Test.stopTest();
       System.assertEquals(0, ids.size());
	}
    
    @isTest
    static void testselectATMDeviceEventsIds() {
       Case testCase = [SELECT Id FROM Case LIMIT 1];
       Test.startTest();
       List<String> ids = Capitec_TrackAndTraceFlaggingHandler.selectATMDeviceEventsIds(testCase.Id);
       Test.stopTest();
       System.assertEquals(0, ids.size()); 
	}
}