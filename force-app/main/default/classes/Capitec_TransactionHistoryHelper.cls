/**
 * Created by dawid on 13.04.2023.
 */

public with sharing class Capitec_TransactionHistoryHelper{

    private static final String CIF_PARAMETER = 'cifNumber=';
    private static final String ACC_NUMBER_PARAMETER = 'accountNumber=';
    private static final String START_DATE_PARAMETER = 'startDate=';
    private static final String END_DATE_PARAMETER = 'endDate=';
    private static final String FLAG_TRANSACTIONS_URL = '/transaction-proxy/transaction/v1/flagRisk';
    private static final String UNFLAG_TRANSACTIONS_URL = '/transaction-proxy/transaction/v1/unflagRisk';


    public static List<String> getFinancialAccountsNumbers(String cifNumber){
        List<String> financialAccountsNumbers = new List<String>();
        List<Product__x> finAccounts;

        System.debug(cifNumber);

        try{
            finAccounts = [SELECT Id, accountNumber__c FROM Product__x WHERE relatedAccount__c = :cifNumber];
            for(Product__x finAcc : finAccounts){
                financialAccountsNumbers.add(finAcc.accountNumber__c);
            }
        }catch (ExternalObjectException e){
            System.debug(e);
            financialAccountsNumbers.add('500');
        }

        System.debug(financialAccountsNumbers);
        return financialAccountsNumbers;
    }

    public static TransactionHistoryResponseWrapper getClientTransactionHistory(String finAccountNumber, String cifNumber, Date startDate, Date endDate){

        TransactionHistoryResponseWrapper responseWrapper = new TransactionHistoryResponseWrapper();
        responseWrapper.transactions = new List<TransactionWrapper>();
        Boolean atLeastOneGoodResponse = false;
        HttpResponse httpResponse;

        try{
            httpResponse = Capitec_CalloutHandler.makeGETCalloutWithParameters(
                    Capitec_CalloutHandler.TRANSACTION_HISTORY_LIST_URL,
                    ACC_NUMBER_PARAMETER + finAccountNumber + '&' +
                            START_DATE_PARAMETER + String.valueOf(startDate) +'&' +
                            END_DATE_PARAMETER + String.valueOf(endDate)
            );
        }
        catch(CalloutException e){
            responseWrapper.statusCode = 500;
            responseWrapper.status = '';
            responseWrapper.errorMessage = e.getMessage();

            return responseWrapper;
        }

        try{
            responseWrapper = (TransactionHistoryResponseWrapper)JSON.deserialize(httpResponse.getBody(), TransactionHistoryResponseWrapper.class);
        }
        catch (JSONException e){
            responseWrapper.errorMessage = httpResponse.getBody();
        }
        finally {
            responseWrapper.statusCode = httpResponse.getStatusCode();
            responseWrapper.status = httpResponse.getStatus();
        }
        
        return responseWrapper;
    }

    public static String getCifFromCase(String caseId){
        Case currentCase = [SELECT Id, Account_CIF_Number__c, CIF_Number__c FROM  Case WHERE Id = :caseId LIMIT 1];

        if(currentCase != null){
            if(currentCase.CIF_Number__c != null)
            {
                return currentCase.CIF_Number__c;
            }
            if(currentCase.Account_CIF_Number__c != null)
            {
                return currentCase.Account_CIF_Number__c;
            }
        }
        return null;
    }

    public static CapitecResponseStatus flagTransactions(List<String> flaggedIds, String caseId){
        return sendTransactions(flaggedIds, caseId, FLAG_TRANSACTIONS_URL);
    }

    public static CapitecResponseStatus unflagTransactions(List<String> flaggedIds, String caseId){
        return sendTransactions(flaggedIds, caseId, UNFLAG_TRANSACTIONS_URL);
    }

    public static CapitecResponseStatus sendTransactions(List<String> flaggedIds, String caseId, String apiURL){

        CapitecResponseStatus status = new CapitecResponseStatus();
        FlaggedTransactionWrapper requestWrapper = new FlaggedTransactionWrapper();
        String requestBody;

        requestWrapper.transactionIds = flaggedIds;
        requestWrapper.riskReference = caseId;
        requestBody = JSON.serialize(requestWrapper);

        HttpResponse response = Capitec_CalloutHandler.makePOSTCalloutWithBody(apiURL, requestBody);

        status.statusCode = response.getStatusCode();
        status.status = response.getStatus();
        status.errorMessage = response.getBody();

        return status;
    }



    public static void updateFlaggedTransactionTotalValue(Id caseId, List<String> accountNumberList) {

        if (accountNumberList.size() >= 99) {
            throw new TransactionHistoryControllerException('Number of accounts selected is over limit 99.');
        }

        List<Transaction_History__x> thList = new List<Transaction_History__x>();
        Decimal flaggedValue = 0;

        for (String accNumber : accountNumberList) {
            thList.add([SELECT Id, endDate__c, startDate__c, Amount__c, riskFlagged__c FROM Transaction_History__x
            WHERE startDate__c =: String.valueOf(System.today()-93) AND endDate__c =: String.valueOf(System.today()) AND accountNumber__c =: accNumber LIMIT 50000]);
        }

        for (Transaction_History__x thisTh : thList) {
            if (thisTh.riskFlagged__c == true) {
                flaggedValue += thisTh.Amount__c;
            }
        }

        Case thisCase = [SELECT Flagged_Transaction_Total_Value__c FROM Case WHERE Id =: caseId WITH SECURITY_ENFORCED LIMIT 1];
        thisCase.Flagged_Transaction_Total_Value__c = flaggedValue;

        try {
            update thisCase;
        } catch (Exception ex) {
            throw new TransactionHistoryControllerException('Cannot update Case.');
        }
    }

    public class TransactionHistoryControllerException extends Exception {}

    public class CapitecAccountNumberOnly{
        public String accountNumber;
    }

    public class TransactionWrapper{

        @AuraEnabled public String transactionId;
        @AuraEnabled public String accountNumber;
        @AuraEnabled public String transactionDate;
        @AuraEnabled public String originalDescription;
        @AuraEnabled public String statementDescription;
        @AuraEnabled public String amount;
        @AuraEnabled public String balance;
        @AuraEnabled public String teller;
        @AuraEnabled public String moneyIn;
        @AuraEnabled public String transferAccount;
        @AuraEnabled public String transTypeDesc;
        @AuraEnabled public String branch;
        @AuraEnabled public String channel;
        @AuraEnabled public Boolean riskFlagged;
        @AuraEnabled public Integer transactionCode;

//        {...} many more fields to be possibly mapped
    }
    public class TransactionHistoryResponseWrapper{
        @AuraEnabled public List<TransactionWrapper> transactions;
        @AuraEnabled public String status;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String errorMessage;
    }

    public class FlaggedTransactionWrapper{
        @AuraEnabled public List<String> transactionIds{get;set;}
        @AuraEnabled public String riskReference{get;set;}
    }

    public class CapitecResponseStatus{
        @AuraEnabled public String status;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String errorMessage;
    }

}