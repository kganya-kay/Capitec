/* Created by Pako on 16.02.2024.
 * Update by Cornelia on 18.10.2024:	CEDT-3267 & CEDT-3265 - Removed Client Care code and added new Transaction Id field
 * Update by Kevin on 25.10.2024	:	CEDT-3217 - Disable
 * Update by Kevin on 30.10.2024	:	CEDT-3193 - Account Type mapping
 */

 public with sharing class Capitec_RetailComplaintsTHController {


    @AuraEnabled
    public static String getFlaggedTransactions(String caseId){
        //System.debug(caseId);
        return Capitec_RetailComplaintsCalloutHandler.getFlaggedTransactions(caseId);
    }

    @AuraEnabled
    public static String getProductsByCase(String caseId){
        //System.debug(caseId);
        return Capitec_RetailComplaintsCalloutHandler.getProductsByCIF(Capitec_CaseUtils.getCIFByRecordId(caseId));
    }

    @AuraEnabled
    public static String getTransactionHistory(String capiAccountNumber, String caseId, String startDate, String endDate){
        //System.debug('***' + caseId);
        return Capitec_RetailComplaintsCalloutHandler.getTransactionsByProduct(capiAccountNumber, caseId, startDate, endDate);
    }

    @AuraEnabled
    public static Date getDateRange (String caseId){

        try{
            Case thisCase = [SELECT Id, RecordType.DeveloperName FROM Case WHERE Id = :caseId LIMIT 1];
            //System.debug(thisCase.RecordType.DeveloperName);
            if(thisCase.RecordType.DeveloperName == 'Fraud_Record_Type'){
                return (System.today().addDays(-3));
            }
            else{
                return (System.today().addMonths(-3));
            }
        }
        catch (QueryException e){
            System.debug(e.getMessage());
            return null;
        }


    }

    @AuraEnabled
    public static String postApplyActions (String jsonString){
        String responseString = Capitec_RetailComplaintsCalloutHandler.postApplyActions(jsonString);

        //System.debug(jsonString);

        return responseString;
    }

    @AuraEnabled
    public static String getConsultantCP(String recordId){
        //System.debug(Capitec_CaseUtils.getConsultantCP(recordId));
        return Capitec_CaseUtils.getConsultantCP(recordId);
    }

    @AuraEnabled
    public static String gethandleFlagToCase(String caseId, List< Map<String, Object> > selectedItems){
        String result = '';

        Set<String> accountNumberSet = new Set<String>();
        Set<String> transactionIdSet = new Set<String>();

        for (Map<String, Object> selectedRow : selectedItems) {
            if (selectedRow.containsKey('account') && selectedRow.get('account') != null) {
                String accountNumber = (String) String.valueOf(selectedRow.get('account'));
                accountNumberSet.add(accountNumber);
            }
            if (selectedRow.containsKey('transactionId') && selectedRow.get('transactionId') != null) {
                String transactionId = (String) String.valueOf(selectedRow.get('transactionId'));
                transactionIdSet.add(transactionId);
            }
        }

        List<FinServ__FinancialAccount__c> fAccs = new List<FinServ__FinancialAccount__c>([SELECT Id, FinServ__FinancialAccountNumber__c FROM FinServ__FinancialAccount__c WHERE FinServ__FinancialAccountNumber__c IN :accountNumberSet]);

        Map<String, FinServ__FinancialAccount__c> mapAccountNumberToFAcc = new Map<String, FinServ__FinancialAccount__c>();
        for (FinServ__FinancialAccount__c fAcc : fAccs) {
            mapAccountNumberToFAcc.put(fAcc.FinServ__FinancialAccountNumber__c, fAcc);
        }

        // Fetch existing transactions with the same Transaction IDs
        Map<String, FinServ__FinancialAccountTransaction__c> existingTransactionsMap = new Map<String, FinServ__FinancialAccountTransaction__c>();
        if (!transactionIdSet.isEmpty()) {
            //CEDT-3265 - update duplicate logic to include Case
            List<FinServ__FinancialAccountTransaction__c> existingTransactions = [
                SELECT Id, Transaction_Id__c FROM FinServ__FinancialAccountTransaction__c WHERE Transaction_Id__c IN :transactionIdSet AND Case__c = :caseId
            ];
            for (FinServ__FinancialAccountTransaction__c trans : existingTransactions) {
                existingTransactionsMap.put(trans.Transaction_Id__c, trans);
            }
        }

        // Create records and return success or failure message
        List<FinServ__FinancialAccountTransaction__c> fAccTransacList = new List<FinServ__FinancialAccountTransaction__c>();
        for (Map<String, Object> selectedRow : selectedItems) {
            //Map fields
            FinServ__FinancialAccountTransaction__c fAccTransac = new FinServ__FinancialAccountTransaction__c();
            fAccTransac.Case__c = caseId;

            if (selectedRow.containsKey('transactionId') && selectedRow.get('transactionId') != null) {
                String TransactionId = (String) String.valueOf(selectedRow.get('transactionId'));
                // Check if a transaction with this TransactionId already exists
                if (existingTransactionsMap.containsKey(TransactionId)) {
                    return 'duplicateTransactionId'; // Return specific message for duplicate
                }
                fAccTransac.Transaction_Id__c = TransactionId;
            }

            if (selectedRow.containsKey('journalNr') && selectedRow.get('journalNr') != null) {
                String JournalNr = (String) String.valueOf(selectedRow.get('journalNr'));
                fAccTransac.Journal_Nr__c = JournalNr;
            }

            if (selectedRow.containsKey('account') && selectedRow.get('account') != null) {
                String accountNumber = (String) String.valueOf(selectedRow.get('account'));
                fAccTransac.FinServ__FinancialAccount__c = mapAccountNumberToFAcc.get(accountNumber)?.Id;
                fAccTransac.FinancialAccountNumber__c = accountNumber;
            }

            if (selectedRow.containsKey('amount') && selectedRow.get('amount') != null) {
                fAccTransac.FinServ__Amount__c = (Decimal)selectedRow.get('amount');
            }

            if (selectedRow.containsKey('transactionDate') && selectedRow.get('transactionDate') != null) {
                Datetime dt = (DateTime)JSON.deserialize('"' + (String) selectedRow.get('transactionDate') + '"', DateTime.class);
                fAccTransac.FinServ__TransactionDate__c = dt;
            }

            fAccTransacList.add(fAccTransac);
        }

        // Additional duplicate check before insert
        Set<String> newTransactionIds = new Set<String>();
        for (FinServ__FinancialAccountTransaction__c trans : fAccTransacList) {
            if (newTransactionIds.contains(trans.Transaction_Id__c)) {
                return 'duplicateTransactionId'; // Duplicate found in new list
            }
            newTransactionIds.add(trans.Transaction_Id__c);
        }

        if (!fAccTransacList.isEmpty()) {
            try {
                insert fAccTransacList;
                result = 'success';
            } catch (DmlException e) {
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    if (e.getDmlType(i) == StatusCode.DUPLICATE_VALUE) {
                        return 'duplicateTransactionId'; // Handle duplicates found during insert
                    }
                }
                result = e.getMessage();
            }
        }

        return result;
    }

    private static final String jsonProductsExample = '{\n' +
            '  "cifNumber" : "394331346",\n' +
            '  "accounts" : [ {\n' +
            '    "accountNumber" : "00000001268091276",\n' +
            '    "accountName" : "SAVINGS PLAN",\n' +
            '    "accountProduct" : null,\n' +
            '    "accountType" : "0200",\n' +
            '    "accountStatus" : "OPEN",\n' +
            '    "availableBalance" : 10720.260,\n' +
            '    "currentBalance" : 10720.260,\n' +
            '    "creditCardArrears" : null,\n' +
            '    "maturityDate" : null,\n' +
            '    "fixingDate" : null,\n' +
            '    "lastFinancialTransactionDate" : null,\n' +
            '    "openDate" : "2023-10-24",\n' +
            '    "savingsAccountTerm" : 0,\n' +
            '    "moneyIn" : true,\n' +
            '    "moneyOut" : true\n' +
            '  }, {\n' +
            '    "accountNumber" : "00000002173375314",\n' +
            '    "accountName" : "SAVINGS ACCOUNT",\n' +
            '    "accountProduct" : null,\n' +
            '    "accountType" : "0300",\n' +
            '    "accountStatus" : "OPEN",\n' +
            '    "availableBalance" : 14495.180,\n' +
            '    "currentBalance" : 14525.180,\n' +
            '    "creditCardArrears" : null,\n' +
            '    "maturityDate" : null,\n' +
            '    "fixingDate" : null,\n' +
            '    "lastFinancialTransactionDate" : null,\n' +
            '    "openDate" : "2023-10-24",\n' +
            '    "savingsAccountTerm" : 0,\n' +
            '    "moneyIn" : true,\n' +
            '    "moneyOut" : true\n' +
            ' }, {\n' +
            '    "accountNumber" : "blablabla",\n' +
            '    "accountName" : "SAVINGS ACCOUNT",\n' +
            '    "accountProduct" : null,\n' +
            '    "accountType" : "0300",\n' +
            '    "accountStatus" : "OPEN",\n' +
            '    "availableBalance" : 14495.180,\n' +
            '    "currentBalance" : 14525.180,\n' +
            '    "creditCardArrears" : null,\n' +
            '    "maturityDate" : null,\n' +
            '    "fixingDate" : null,\n' +
            '    "lastFinancialTransactionDate" : null,\n' +
            '    "openDate" : "2023-10-24",\n' +
            '    "savingsAccountTerm" : 0,\n' +
            '    "moneyIn" : true,\n' +
            '    "moneyOut" : true\n' +
            '  } ]\n' +
            '}';


    private static final String jsonFlaggedExample = '[\n' +
            '  {\n' +
            '    "fraudFlagged": false,\n' +
            '    "holdFlagged": false,\n' +
            '    "caseId": "654985a3bc58faee701cbfd5",\n' +
            '    "spendGroup": "UNA",\n' +
            '    "account": 3417403509585,\n' +
            '    "transactionDate": "2008-02-15T06:27:11.151Z",\n' +
            '    "processDate": "1985-11-11T00:09:20.318Z",\n' +
            '    "holdLiftedAt": "1994-05-20T21:35:31.752Z",\n' +
            '    "holdAmount": 220.76,\n' +
            '    "moneyIn": false,\n' +
            '    "toAccount": 1601903952916,\n' +
            '    "fromAccount": 8181437335641,\n' +
            '    "consultantIdentifier": "654985a3bf6f6b247c8ffae3"\n' +
            '  },\n' +
            '  {\n' +
            '    "fraudFlagged": false,\n' +
            '    "holdFlagged": false,\n' +
            '    "caseId": "654985a330c96ed327fb6256",\n' +
            '    "chase": "consectetur",\n' +
            '    "spendGroup": "CardSubscription",\n' +
            '    "account": 6623981494248,\n' +
            '    "transactionDate": "1987-04-13T21:05:07.605Z",\n' +
            '    "processDate": "1989-07-17T17:33:16.659Z",\n' +
            '    "holdLiftedAt": "2003-10-06T19:14:17.124Z",\n' +
            '    "holdAmount": 188.25,\n' +
            '    "moneyIn": false,\n' +
            '    "toAccount": 3824044614765,\n' +
            '    "fromAccount": 6932586718357,\n' +
            '    "consultantIdentifier": "654985a38512a6d1d119295b"\n' +
            '  },\n' +
            '  {\n' +
            '    "fraudFlagged": true,\n' +
            '    "holdFlagged": false,\n' +
            '    "caseId": "654985a3e45a39262a35997f",\n' +
            '    "chase": "aliquip",\n' +
            '    "spendGroup": "SendCash",\n' +
            '    "account": 3398078224580,\n' +
            '    "transactionDate": "1985-09-19T20:40:49.543Z",\n' +
            '    "processDate": "1972-06-10T19:13:21.525Z",\n' +
            '    "holdLiftedAt": "2009-10-05T04:10:13.309Z",\n' +
            '    "holdAmount": 729.08,\n' +
            '    "moneyIn": false,\n' +
            '    "toAccount": 9879976026064,\n' +
            '    "fromAccount": 1349691197030,\n' +
            '    "consultantIdentifier": "654985a3c36346f430427ce0"\n' +
            '  },\n' +
            '  {\n' +
            '    "fraudFlagged": false,\n' +
            '    "holdFlagged": false,\n' +
            '    "caseId": "654985a30ae580b26ce5433c",\n' +
            '    "chase": "minim",\n' +
            '    "spendGroup": "Vouchers",\n' +
            '    "account": 2608020300403,\n' +
            '    "transactionDate": "2020-06-08T10:27:56.245Z",\n' +
            '    "processDate": "1999-01-14T17:18:54.235Z",\n' +
            '    "holdLiftedAt": "1970-06-07T21:10:47.729Z",\n' +
            '    "holdAmount": 859.37,\n' +
            '    "moneyIn": true,\n' +
            '    "toAccount": 6036031850142,\n' +
            '    "fromAccount": 1126300755544,\n' +
            '    "consultantIdentifier": "654985a3579e08b97501b69d"\n' +
            '  }\n' +
            ']';

    private static final String jsonTransactionExample = '[\n' +
            '  {\n' +
            '    "fraudFlagged": false,\n' +
            '    "holdFlagged": false,\n' +
            '    "caseId": "654985a3bc58faee701cbfd5",\n' +
            '    "spendGroup": "UNA",\n' +
            '    "account": 3417403509585,\n' +
            '    "transactionDate": "2008-02-15T06:27:11.151Z",\n' +
            '    "processDate": "1985-11-11T00:09:20.318Z",\n' +
            '    "holdLiftedAt": "1994-05-20T21:35:31.752Z",\n' +
            '    "holdAmount": 220.76,\n' +
            '    "moneyIn": false,\n' +
            '    "toAccount": 1601903952916,\n' +
            '    "fromAccount": 8181437335641,\n' +
            '    "consultantIdentifier": "654985a3bf6f6b247c8ffae3"\n' +
            '  },\n' +
            '  {\n' +
            '    "fraudFlagged": false,\n' +
            '    "holdFlagged": false,\n' +
            '    "caseId": "654985a330c96ed327fb6256",\n' +
            '    "chase": "consectetur",\n' +
            '    "spendGroup": "CardSubscription",\n' +
            '    "account": 6623981494248,\n' +
            '    "transactionDate": "1987-04-13T21:05:07.605Z",\n' +
            '    "processDate": "1989-07-17T17:33:16.659Z",\n' +
            '    "holdLiftedAt": "2003-10-06T19:14:17.124Z",\n' +
            '    "holdAmount": 188.25,\n' +
            '    "moneyIn": false,\n' +
            '    "toAccount": 3824044614765,\n' +
            '    "fromAccount": 6932586718357,\n' +
            '    "consultantIdentifier": "654985a38512a6d1d119295b"\n' +
            '  },\n' +
            '  {\n' +
            '    "fraudFlagged": true,\n' +
            '    "holdFlagged": false,\n' +
            '    "caseId": "654985a3e45a39262a35997f",\n' +
            '    "chase": "aliquip",\n' +
            '    "spendGroup": "SendCash",\n' +
            '    "account": 3398078224580,\n' +
            '    "transactionDate": "1985-09-19T20:40:49.543Z",\n' +
            '    "processDate": "1972-06-10T19:13:21.525Z",\n' +
            '    "holdLiftedAt": "2009-10-05T04:10:13.309Z",\n' +
            '    "holdAmount": 729.08,\n' +
            '    "moneyIn": false,\n' +
            '    "toAccount": 9879976026064,\n' +
            '    "fromAccount": 1349691197030,\n' +
            '    "consultantIdentifier": "654985a3c36346f430427ce0"\n' +
            '  },\n' +
            '  {\n' +
            '    "fraudFlagged": false,\n' +
            '    "holdFlagged": false,\n' +
            '    "caseId": "654985a30ae580b26ce5433c",\n' +
            '    "chase": "minim",\n' +
            '    "spendGroup": "Vouchers",\n' +
            '    "account": 2608020300403,\n' +
            '    "transactionDate": "2020-06-08T10:27:56.245Z",\n' +
            '    "processDate": "1999-01-14T17:18:54.235Z",\n' +
            '    "holdLiftedAt": "1970-06-07T21:10:47.729Z",\n' +
            '    "holdAmount": 859.37,\n' +
            '    "moneyIn": true,\n' +
            '    "toAccount": 6036031850142,\n' +
            '    "fromAccount": 1126300755544,\n' +
            '    "consultantIdentifier": "654985a3579e08b97501b69d"\n' +
            '  }\n' +
            ']';
}