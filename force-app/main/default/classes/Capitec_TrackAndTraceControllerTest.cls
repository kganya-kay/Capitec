/**
 * Capitec_TrackAndTraceControllerTest Class
 *
 * This class is for testing the Capitec_TrackAndTraceController class and its callouts.
 *
 * Created by: Radek
 */

@isTest
public class Capitec_TrackAndTraceControllerTest {
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
    static void testFetchCoreBankingTransactions() {
        String accountNumber = '12345';
        String startDate = '2023-01-01';
        String endDate = '2023-12-31';
		
        Test.setMock(HttpCalloutMock.class, new Capitec_TrackAndTraceMock());
        Test.startTest();
        String result = Capitec_TrackAndTraceController.fetchCoreBankingTransactions(accountNumber, startDate, endDate);
		Test.stopTest();
        System.assertNotEquals(result, null);
        System.assertNotEquals(result, '{"error": "An error has occurred"}');
    }

    @isTest
    static void testFetchCardTransactions() {
        String fromAccountNumber = '12345';
        String startDateTime = '2023-01-01 00:00:00.000';
        String endDateTime = '2023-12-31 23:59:59.999';
		
        Test.setMock(HttpCalloutMock.class, new Capitec_TrackAndTraceMock());
        Test.startTest();
        String result = Capitec_TrackAndTraceController.fetchCardTransactions(fromAccountNumber, startDateTime, endDateTime);
		Test.stopTest();
        System.assertNotEquals(result, null);
        System.assertNotEquals(result, '{"error": "An error has occurred"}');
    }

    @isTest
    static void testFetchATMTransactionEvents() {
        String deviceId = 'TestDevice';
        String startDateTime = '2023-01-01 00:00:00.000';
        String endDateTime = '2023-12-31 23:59:59.999';
		
        Test.setMock(HttpCalloutMock.class, new Capitec_TrackAndTraceMock());
        Test.startTest();
        String result = Capitec_TrackAndTraceController.fetchATMTransactionEvents(deviceId, startDateTime, endDateTime);
		Test.stopTest();
        System.assertNotEquals(result, null);
        System.assertNotEquals(result, '{"error": "An error has occurred"}');
    }

    @isTest
    static void testFetchATMDeviceEvents() {
        String deviceId = 'TestDevice';
        String startDateTime = '2023-01-01 00:00:00.000';
        String endDateTime = '2023-12-31 23:59:59.999';
		
        Test.setMock(HttpCalloutMock.class, new Capitec_TrackAndTraceMock());
        Test.startTest();
        String result = Capitec_TrackAndTraceController.fetchATMDeviceEvents(deviceId, startDateTime, endDateTime);
		Test.stopTest();
        System.assertNotEquals(result, null);
        System.assertNotEquals(result, '{"error": "An error has occurred"}');
    }
    
    @isTest
    static void testsaveCoreBankingTransactions() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String corebankingJSON = '{ "content": [{ "id": "1", "availableBalance": 100.0, "transactionAmount": 50.0, "transactionDate": "2023-10-05", "postDate": "2023-10-05", "authId": "12345", "branchId": "A123", "cardNumber": "1234567890", "creditDebitIndicator": "CR", "journalNumber": "789", "narrative": "Test Transaction", "promoCode": "PROMO123", "accountNumber": "9876543210" }], "caseId": "' + testCase.Id + '" }';
        
        Test.startTest();
        Capitec_TrackAndTraceController.saveCoreBankingTransactions(corebankingJSON);
		Test.stopTest();
        
        List<CR_DR_Indicator__c> crdrs = [SELECT Id FROM CR_DR_Indicator__c LIMIT 10];
        System.assert(!crdrs.isEmpty());
    }
    
    @isTest
    static void testsaveCardTransactions() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String cardTransactionJSON = '{ "content": [{ "id": "1", "fromAccountNumber": "9876543210", "officeTransactionNumber": "123456", "siteName": "Test Site", "deviceId": "Device123", "sourceNodeName": "SourceNode", "sinkNodeName": "SinkNode", "cardProduct": "Test Product", "transactionType": "Type1", "responseCode": "RESP123", "retrievalReferenceNumber": "REF123", "authId": "456", "messageType": "MsgType", "systemTraceAuditNumber": "789", "reconBatchNumber": "Batch123", "transactionPostilionOriginated": "true", "transactionDateTime": "2023-10-05T12:34:56", "transactionRequestAmount": 50.0, "transactionResponseAmount": 50.0, "settleAmountImpact": 0.0 }], "caseId": "' + testCase.Id + '" }';
        
        Test.startTest();
        Capitec_TrackAndTraceController.saveCardTransactions(cardTransactionJSON);
		Test.stopTest();
        
        List<Card_Transaction__c> result = [SELECT Id FROM Card_Transaction__c LIMIT 10];
        System.assert(result.isEmpty());
    }
    
    @isTest
    static void testsaveATMTransactionEvents() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String atmTransactionEventJSON = '{ "content": [{ "id": "1", "deviceId": "Device123", "eventId": "Event123", "entity": "Entity1", "severity": "High", "message": "Test Message", "eventDateTime": "2023-10-05T12:34:56" }], "caseId": "' + testCase.Id + '" }';
        
        Test.startTest();
        Capitec_TrackAndTraceController.saveATMTransactionEvents(atmTransactionEventJSON);
		Test.stopTest();
        
        List<ATM_Transaction_Event__c> result = [SELECT Id FROM ATM_Transaction_Event__c LIMIT 10];
        System.assert(!result.isEmpty());
    }
    
    @isTest
    static void testsaveATMDeviceEvents() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        String atmDeviceEventJSON = '{ "content": [{ "id": "1", "deviceId": "Device123", "eventDateTime": "2023-10-05T12:34:56", "eventMessage": "Test Event", "eventNumber": "123", "originalMessage": "Original Msg" }], "caseId": "' + testCase.Id + '" }';
        
        Test.startTest();
        Capitec_TrackAndTraceController.saveATMDeviceEvents(atmDeviceEventJSON);
		Test.stopTest();
        
        List<ATM_Device_Event__c> result = [SELECT Id FROM ATM_Device_Event__c LIMIT 10];
        System.assert(!result.isEmpty());
    }
}