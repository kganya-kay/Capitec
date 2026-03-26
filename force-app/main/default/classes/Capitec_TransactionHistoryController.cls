/**
 * Created by dawid on 13.04.2023.
 */

public with sharing class Capitec_TransactionHistoryController {


    @AuraEnabled
    public static List<String> getFinancialAccountsNumbers (String caseId){

        List<String> finAccNumber = Capitec_TransactionHistoryHelper.getFinancialAccountsNumbers(Capitec_TransactionHistoryHelper.getCifFromCase(caseId));

        return  finAccNumber;
    }

    @AuraEnabled
    public static Capitec_TransactionHistoryHelper.TransactionHistoryResponseWrapper getClientTransactionHistory(String finAccountNumber, String caseId, Date startDate, Date endDate){

        Capitec_TransactionHistoryHelper.TransactionHistoryResponseWrapper responseWrapper;
        responseWrapper = Capitec_TransactionHistoryHelper.getClientTransactionHistory(finAccountNumber, caseId, startDate, endDate);

        return  responseWrapper;
    }

    @AuraEnabled
    public static Capitec_TransactionHistoryHelper.CapitecResponseStatus flagTransactions(List<String> flaggedIds, String caseId){

        return  Capitec_TransactionHistoryHelper.flagTransactions(flaggedIds, caseId);
    }

    @AuraEnabled
    public static Capitec_TransactionHistoryHelper.CapitecResponseStatus unflagTransactions(List<String> flaggedIds, String caseId){

        return  Capitec_TransactionHistoryHelper.unflagTransactions(flaggedIds, caseId);
    }

    @AuraEnabled
    public static void updateFlaggedTransactionTotalValue(Id caseId, List<String> accountNumberList) {
        try{
            Capitec_TransactionHistoryHelper.updateFlaggedTransactionTotalValue(caseId, accountNumberList);
        }
        catch (QueryException e){
            System.debug('Stuff not working');
        }

    }

    @AuraEnabled
    public static Date getDateRange (String caseId){
        Case thisCase = [SELECT Id, RecordType.DeveloperName FROM Case WHERE Id = :caseId LIMIT 1];
        if(thisCase.RecordType.DeveloperName == 'Fraud_Record_Type'){
            return (System.today().addDays(-3));
        }
        else{
            return (System.today().addMonths(-3));
        }
    }


    public class TransactionHistoryControllerException extends Exception {}
}