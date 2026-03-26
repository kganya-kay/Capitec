/**
 * Created by dawid on 06.11.2023.
 */

 public with sharing class Capitec_FraudTHController {


    @AuraEnabled
    public static String getChasedTransactions(String caseId){
        System.debug(caseId);
        return Capitec_FraudCalloutHandler.getChasedTransactions(caseId);
//        return jsonFlaggedExample;
    }

    @AuraEnabled
    public static String getChasedFlaggedTransactions(String caseId, Boolean findHolds){  //FFSF 448 total amount defrauded API
        System.debug(caseId);
        return Capitec_FraudCalloutHandler.getChasedTransactions(caseId, findHolds);

    }
    
    @AuraEnabled
    public static String getProductsByCase(String caseId){
        System.debug(caseId);
        return Capitec_FraudCalloutHandler.getProductsByCIF(Capitec_CaseUtils.getCIFByRecordId(caseId));
//        return jsonProductsExample;
    }

    @AuraEnabled
    public static String getTransactionHistory(String capiAccountNumber, String caseId, String startDate, String endDate, String accTypeVal){
        System.debug('****' + caseId);
        return Capitec_FraudCalloutHandler.getTransactionsByProduct(capiAccountNumber, caseId, startDate, endDate, accTypeVal);
    }

    @AuraEnabled
    public static String getTransactionHistoryGen(String capiAccountNumber, String caseId, String startDate, String endDate, String accTypeVal){
        System.debug('****' + caseId);
        return Capitec_GenericCalloutHandler.getTransactionsByProduct(capiAccountNumber, startDate, endDate);
    }

    @AuraEnabled
    public static Date getDateRange (String caseId){

        try{
            Case thisCase = [SELECT Id, RecordType.DeveloperName FROM Case WHERE Id = :caseId LIMIT 1];
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
        String responseString = Capitec_FraudCalloutHandler.postApplyActions(jsonString);
        System.debug('##PA1');
        System.debug(jsonString);

        return responseString;
    }

    @AuraEnabled
    public static String postChase (String jsonString){
        String responseString = Capitec_FraudCalloutHandler.postChase(jsonString);

        System.debug(jsonString);

        return responseString;
    }

    @AuraEnabled
    public static String postConfirmHold (String jsonString){
        String responseString = Capitec_FraudCalloutHandler.postConfirmHold(jsonString);

        System.debug(jsonString);

        return responseString;
    }

    @AuraEnabled
    public static String getConsultantCP(String recordId){
        System.debug(Capitec_CaseUtils.getConsultantCP(recordId));
        return Capitec_CaseUtils.getConsultantCP(recordId);
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