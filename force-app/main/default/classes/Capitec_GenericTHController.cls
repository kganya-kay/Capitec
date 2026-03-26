/*
********************************************************************************************
Apex Class Name    : Capitec_GenericTHController
Created Date       : October 22, 2024
@description       : Cloned and updated from capitec_FraudTHController, by Dawid Kuczer
                     Controller for server-side actions for transaction history
					 components that use the generic 'support' endpoint.
@author            : Cornelia Smit
Modification Log:
Ver   Date         Author                 Modification
1.0   18-11-2024   Cornelia Smit         Initial Version
1.1   12-07-2024   Anil Kandula          added getRecordTypeName method

********************************************************************************************
*/

public with sharing class Capitec_GenericTHController {

    public static final String ACCOUNT_COLUMN = 'accNumberFull';
    public static final String TRAN_ID_COLUMN = 'tranId';
    public static final String TRAN_DATE_COLUMN = 'transactionDateTime';
    public static final String JOURNAL_NR_COLUMN = 'journalNr';
    public static final String TRAN_CODE_COLUMN = 'tranCode';
    public static final String TRAN_GROUP_COLUMN = 'tranGroupType';
    public static final String ACCOUNT_NR_COLUMN = 'accNumberFull'; //Full account number mapped to the selected item
    public static final String AMOUNT_COLUMN = 'amount';
    public static final String CLASS_COLUMN = 'classificationType';
    public static final String TRANHISTORYExample = loadJSONExample('GenericTransactionHistorySampleData');
    public static final String PRODUCTSExample = loadJSONExample('GenericProductsSampleData');

    /**
     * @description  Retrieves a mock data response from a static resource
     * @param        resourceName name of the static resource
     * @return       JSON string mock response
     */
    private static String loadJSONExample(String resourceName) {
        StaticResource resource = [SELECT Body FROM StaticResource WHERE Name = :resourceName];
        return resource.Body.toString();
    }
    
    /**
     * @description  Get recordtypename Name
     * @param        recordid
     * @return       Boolean
     */
    @AuraEnabled(cacheable=true)
    public static string getRecordTypeName(string recordId ){
        case cs = [SELECT id,RecordType.name FROM Case where id =:recordId limit 1];
        return cs.RecordType.name;
    }
    
    /**
     * @description  Retrieves products related to a customer account
     * @param        caseId case Id used to retrieve the customer account CIF number
     * @return       String containing the response JSON with the list of products
     */
    @AuraEnabled
    public static String getProductsByCase(String caseId) {

        //Comment out this line to use test data when no integration is available
        String resultResponse = Capitec_GenericCalloutHandler.getProductsByCIF(Capitec_CaseUtils.getCIFByRecordId(caseId));

        //Uncomment these lines to use the mock response
        //String resultResponse = Capitec_GenericCalloutHandler.appendPositiveStatusToJSON(PRODUCTSExample);

        return resultResponse;
    }

    /**
     * @description  Retrieves the transaction history for a specific product over a time period
     * @param        capiAccountNumber product account number with NO LEADING ZEROS
     * @param        startDate start date for transaction history data
     * @param        endDate end date for transaction history data
     * @return       String containing the response JSON with the list of transaction history lines for the product
     */
    @AuraEnabled
    public static String getTransactionHistory(String capiAccountNumber, String startDate, String endDate) {
        //Comment out this line to use test data when no integration is available
        String resultResponse = Capitec_GenericCalloutHandler.getTransactionsByProduct(capiAccountNumber, startDate, endDate);
//System.debug('--Transactions History --'+json.serializepretty(resultResponse));
        //Uncomment this line to use the mock response
        //String resultResponse = Capitec_GenericCalloutHandler.appendPositiveStatusToJSON(Capitec_GenericCalloutHandler.appendTransactionsNodeToJSON(TRANHISTORYExample, capiAccountNumber));

        return resultResponse;
    }

    /**
     * @description  Retrieves a date range of 3 months prior to today
     * @param        caseId not sure why we need this, might remove it
     * @return       Date that represents a start date
     */
    @AuraEnabled
    public static Date getDateRange(String caseId) {
        return (System.today().addMonths(-3));
    }

    /**
     * @description  Retrieves an consultant's CP
     * @param        recordId required by the utility method to retrieve the consultant's CP
     * @return       String containing the consultant CP
     */
    @AuraEnabled
    public static String getConsultantCP(String recordId) {
        return Capitec_CaseUtils.getConsultantCP(recordId);
    }

    /**
     * @description  Creates related financial account transaction records against a case          
     * @param        caseId case Id to created the related records against
     * @param        selectedItems list of transaction history lines
     * @return       String containing a success or failure message
     */
    @AuraEnabled
    public static String getHandleFlagToCase(String caseId, List< Map<String, Object> > selectedItems) {
        String result = '';
        List<FinServ__FinancialAccountTransaction__c> fAccTransacList = populateFinAccTransactionData(caseId, selectedItems);

        if (fAccTransacList.isEmpty()) {
            return result;
        }

        if (checkDuplicateTransactions(fAccTransacList, caseId)) {
            return insertFinAccTransactionData(fAccTransacList);
        }
        return 'duplicateTransactionId';
    }

    /**
     * @description  Populates data for a financial account transaction record for each tranHistory line           
     * @param        caseId case Id to created the related records against
     * @param        selectedItems list of transaction history lines
     * @return       List of financial account transaction records to be inserted
     */
    @AuraEnabled
    public static List<FinServ__FinancialAccountTransaction__c> populateFinAccTransactionData(String caseId, List< Map<String, Object> > selectedItems) {

        Set<String> accountNumberSet = new Set<String>();

        for (Map<String, Object> selectedRow : selectedItems) {
            if (selectedRow.containsKey(ACCOUNT_COLUMN) && selectedRow.get(ACCOUNT_COLUMN) != null) {
                String accountNumber = (String) String.valueOf(selectedRow.get(ACCOUNT_COLUMN));
                accountNumberSet.add(accountNumber);
            }
        }

        List<FinServ__FinancialAccount__c> fAccs = [
                SELECT Id, FinServ__FinancialAccountNumber__c
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__FinancialAccountNumber__c IN :accountNumberSet
                WITH SECURITY_ENFORCED
        ];

        Map<String, Id> mapAccountNumberToFAcc = new Map<String, Id>();

        for (FinServ__FinancialAccount__c fAcc : fAccs) {
            mapAccountNumberToFAcc.put((String) fAcc.FinServ__FinancialAccountNumber__c, (Id) fAcc.Id);
        }

        List<FinServ__FinancialAccountTransaction__c> fAccTransacList = new List<FinServ__FinancialAccountTransaction__c>();

        for (Map<String, Object> selectedRow : selectedItems) {
            FinServ__FinancialAccountTransaction__c fAccTransac = new FinServ__FinancialAccountTransaction__c();
            fAccTransac.Case__c = caseId;
            fAccTransac.CIF_Number__c = Capitec_CaseUtils.getCIFByRecordId(caseId);

            fAccTransac = applyBasicDataMapping(selectedRow, fAccTransac, mapAccountNumberToFAcc);
            fAccTransacList.add(fAccTransac);
        }

        return fAccTransacList;
    }

    /**
     * @description  Flags a financial account transaction record to the case for each tranHistory line; 
     *               Runs a duplicate check before inserting records           
     * @param        fAccTransacList list of financial account transactions tro be inserted
     * @return       String containing a success or failure message
     */
    public static String insertFinAccTransactionData(List<FinServ__FinancialAccountTransaction__c> fAccTransacList) {
        String result = '';

        try {
            insert fAccTransacList;
            result = 'success';
        } catch (DmlException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                if (e.getDmlType(i) == StatusCode.DUPLICATE_VALUE) {
                    return 'duplicateTransactionId';
                }
            }
            result = e.getMessage();
        }
        return result;
    }

    /**
     * @description  Runs a duplicate check before inserting financial account transactions        
     * @param        fAccTransacList list of financial account transactions tro be inserted
     * @param        caseId case to run duplicate check against
     * @return       Boolean containing a success or failure
     */
    public static Boolean checkDuplicateTransactions(List<FinServ__FinancialAccountTransaction__c> fAccTransacList, String caseId) {
        Set<String> transactionIdSet = new Set<String>();

        for (FinServ__FinancialAccountTransaction__c fAccTransac : fAccTransacList) {
            transactionIdSet.add(fAccTransac.Transaction_Id__c);
        }

        // Fetch existing transactions with the same Transaction IDs
        List<FinServ__FinancialAccountTransaction__c> existingTransactions = [
                SELECT Id, Transaction_Id__c
                FROM FinServ__FinancialAccountTransaction__c
                WHERE Transaction_Id__c
                        IN :transactionIdSet
                WITH SECURITY_ENFORCED
        ];

        // Duplicate check before insert
        if (existingTransactions.size() > 0) {
            return false;
        }
        return true;
    }

    /**
     * @description  Maps financial acccount transaction fields from the transactino history data
     * @param        selectedRow transaction history data row
     * @param        fAccTransac financial account transaction record to be updated
     * @param        mapAccountNumberToFAcc map of financial account numbers to Ids
     * @return       Updated financial account transaction record
     */
    private static FinServ__FinancialAccountTransaction__c applyBasicDataMapping(Map<String, Object> selectedRow, FinServ__FinancialAccountTransaction__c fAccTransac, Map<String, Id> mapAccountNumberToFAcc) {

        setFieldMapping(selectedRow, JOURNAL_NR_COLUMN, fAccTransac, 'Journal_Nr__c');
        setFieldMapping(selectedRow, TRAN_CODE_COLUMN, fAccTransac, 'CC_Transaction_Code__c');
        setFieldMapping(selectedRow, TRAN_GROUP_COLUMN, fAccTransac, 'CC_Spend_Group__c');
        setFieldMapping(selectedRow, ACCOUNT_NR_COLUMN, fAccTransac, 'FinancialAccountNumber__c');
        setFieldMapping(selectedRow, CLASS_COLUMN, fAccTransac, 'Classification_Type__c');
        setFieldMapping(selectedRow, TRAN_ID_COLUMN, fAccTransac, 'Transaction_Id__c');

        if (selectedRow.containsKey(AMOUNT_COLUMN) && selectedRow.get(AMOUNT_COLUMN) != null) {
            fAccTransac.FinServ__Amount__c = (Decimal) selectedRow.get(AMOUNT_COLUMN);
        }

        if (selectedRow.containsKey(TRAN_DATE_COLUMN) && selectedRow.get(TRAN_DATE_COLUMN) != null) {
            fAccTransac.FinServ__TransactionDate__c = (DateTime) JSON.deserialize('"' + (String) selectedRow.get(TRAN_DATE_COLUMN) + '"', DateTime.class);
        }

        if (selectedRow.containsKey(ACCOUNT_COLUMN) && selectedRow.get(ACCOUNT_COLUMN) != null) {
            fAccTransac.FinServ__FinancialAccount__c = mapAccountNumberToFAcc.get(ACCOUNT_COLUMN);
        }

        return fAccTransac;
    }

    /**
     * @description  Maps the value from a map for a specified key to a string
     * @param        sourceMap map containing key-value pairs
     * @param        columnKey key to retrieve value from map
     * @param        record record to update
     * @param        fieldName field to update
     */
    private static void setFieldMapping(Map<String, Object> sourceMap, String columnKey, SObject record, String fieldName) {
        if (sourceMap.containsKey(columnKey) && sourceMap.get(columnKey) != null) {
            record.put(fieldName, String.valueOf(sourceMap.get(columnKey)));
        }
    }
}