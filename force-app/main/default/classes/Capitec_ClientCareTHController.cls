/*
********************************************************************************************
Apex Class Name    : Capitec_ClientCareTHController
Created Date       : October 22, 2024
@description       : Applies additional transaction history data mapping to the 
                     mapping retrieved from Capitec_GenericTHController
@author            : Cornelia Smit
Modification Log:
Ver   Date         Author                 Modification
1.0   19-11-2024   Cornelia Smit         Initial Version
********************************************************************************************
*/

public with sharing class Capitec_ClientCareTHController {
    private static final String CLASS_COLUMN = Capitec_GenericTHController.CLASS_COLUMN;
    private static final String TRAN_GROUP_COLUMN = Capitec_GenericTHController.TRAN_GROUP_COLUMN;
    private static final String ACC_TYPE_VAL = 'BOTH';
    
    /**
     * @description  Creates related financial account transaction records against a case, with 
     *               additional mapping applied
     * @param        caseId case Id to created the related records against
     * @param        selectedItems list of transaction history lines
     * @return       String containing a success or failure message
     */
    @AuraEnabled
    public static String getHandleFlagToCase(String caseId, List< Map<String, Object> > selectedItems){
        String result = 'Error flagging transaction';
        List<FinServ__FinancialAccountTransaction__c> fAccTransacList = Capitec_GenericTHController.populateFinAccTransactionData(caseId, selectedItems);
        
        if (fAccTransacList.isEmpty()) {
            return result;
        }

        Map<String, String> transactionTypeMap = retrieveTransactionTypeMap();
        Map<String, String> accountTypeMap = retrieveAccountTypeMap();

        Map<String, Object> mapAccountProduct = new Map<String, Object>();

        String productJSON = '';

        if (!Test.isRunningTest()) {
            productJSON = Capitec_GenericTHController.getProductsByCase(caseId);
        } else {
            productJSON = Capitec_GenericCalloutHandler.appendPositiveStatusToJSON(Capitec_GenericTHController.PRODUCTSExample);
        }

        Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(productJSON);
             
        if(!(parsedJSON.get('statusCode') == 200)){
            return result;
        }

        List<Object> accounts = (List<Object>) parsedJson.get('accounts');
               
        for (Object accountObj : accounts) {
            Map<String, Object> accountMap = (Map<String, Object>) accountObj;
            mapAccountProduct.put(String.valueOf(accountMap.get('accountNumber')), String.valueOf(accountMap.get('accountType')));
        }

        for (FinServ__FinancialAccountTransaction__c fAccTransac : fAccTransacList) {
            Map<String, Object> selectedRow = new Map<String, Object>();
            fAccTransac = applyAdditionalDataMapping(transactionTypeMap, accountTypeMap, mapAccountProduct, fAccTransac, caseId, selectedItems);
        }

        if(checkDuplicateTransactions(fAccTransacList, caseId)) {
            return Capitec_GenericTHController.insertFinAccTransactionData(fAccTransacList);
        }

        return 'duplicateTransactionId';
    }

    /**
     * @description  Retrieves the transaction history for a specific product, with additional mapping
     * @param        capiAccountNumber product account number with NO LEADING ZEROS
     * @param        startDate start date for transaction history data
     * @param        endDate end date for transaction history data
     * @param        processType string that identifies the process as Fraud or Generic to split the logic
     * @return       String containing the updated response JSON with the list of transaction history lines for the product
     */
    @AuraEnabled
     public static String getTransactionHistory(String capiAccountNumber, String caseId, String startDate, String endDate, String processType) {
        String resultResponse = '';
        
        if(processType == 'Fraud') {
            resultResponse = Capitec_FraudTHController.getTransactionHistory(capiAccountNumber, caseId, startDate, endDate, ACC_TYPE_VAL);
            
            Map<String, Object> jsonResponse = new Map<String, Object>();
            jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(resultResponse);
            jsonResponse.put('accountNumber', capiAccountNumber);

            resultResponse = JSON.serialize(jsonResponse);
        }
        else {
            resultResponse = Capitec_GenericTHController.getTransactionHistory(capiAccountNumber, startDate, endDate);
        }
        
        String updatedJSONResponse = getTransactionHistoryTypeMapping(resultResponse);
        return updatedJSONResponse;
     }

     /**
     * @description  Runs a duplicate check before inserting financial account transactions        
     * @param        fAccTransacList list of financial account transactions tro be inserted
     * @param        caseId ID of the client care case
     * @return       Boolean containing a success or failure
     */
    public static Boolean checkDuplicateTransactions(List<FinServ__FinancialAccountTransaction__c> fAccTransacList, String caseId){
        Set<String> transactionIdSet = new Set<String>();

        for (FinServ__FinancialAccountTransaction__c fAccTransac : fAccTransacList) {
            transactionIdSet.add(fAccTransac.Transaction_Id__c);
        }

        // Fetch existing transactions with the same Transaction IDs linked to the same case
        List<FinServ__FinancialAccountTransaction__c> existingTransactions = [SELECT Id, Transaction_Id__c 
                                                                                FROM FinServ__FinancialAccountTransaction__c 
                                                                                WHERE Transaction_Id__c 
                                                                                IN :transactionIdSet
                                                                                AND Case__c =: caseId
                                                                                WITH SECURITY_ENFORCED
        ];

        // Duplicate check before insert
        if(existingTransactions.size() > 0) {
            return false;
        }
        return true;
    }

    /**
     * @description  Adds a transaction type column to the tranHistory data
     * @param        tranHistoryJSON string containing the full transaction history data response
     * @return       Updated tranHistory response string
     */
    private static String getTransactionHistoryTypeMapping(String tranHistoryJSON) {
       
        Map<String, String> mapClassAndGroup = retrieveTransactionTypeMap();
        Map<String, Object> parsedJson = (Map<String, Object>) JSON.deserializeUntyped(tranHistoryJSON);
        List<Object> transactions = (List<Object>) parsedJson.get('transactions');
 
        if(transactions == null) {
            return tranHistoryJSON;
        }
        
        for (Object transactionObj : transactions) {
            Map<String, Object> transactionMap = (Map<String, Object>) transactionObj;
            String tranClassAndGroup = createConcatenatedString(transactionMap, CLASS_COLUMN, TRAN_GROUP_COLUMN);
 
            
            if(mapClassAndGroup.get(tranClassAndGroup) != null){
                transactionMap.put('transactionType', String.valueOf(mapClassAndGroup.get(tranClassAndGroup)));
            }
        }
        
        return JSON.serialize(parsedJson);
    }

    /**
     * @description  Adds the Transaction Type field to a financial account transaction record
     * @param        transactionTypeMap transaction type custom metadata mapping to match the transaction type
     * @param        accountTypeMap account type map custom metadata mapping to match the account type
     * @param        mapAccountProduct account product mapping to match the account type
     * @param        fAccTransac financial acc transaction record to map the transaction type field to
     * @param        caseId string case Id
     * @return       Updated financial account transaction record
     */
     public static FinServ__FinancialAccountTransaction__c applyAdditionalDataMapping(Map<String, String> transactionTypeMap, Map<String, String> accountTypeMap, Map<String, Object> mapAccountProduct,FinServ__FinancialAccountTransaction__c fAccTransac, String caseId, List< Map<String, Object> > selectedItems){
        
         if(transactionTypeMap.get(String.valueOf(fAccTransac.Classification_Type__c) + String.valueOf(fAccTransac.CC_Spend_Group__c)) != null){
            fAccTransac.Transaction_Type__c = transactionTypeMap.get(fAccTransac.Classification_Type__c + fAccTransac.CC_Spend_Group__c);
        }

        String accountKey = fAccTransac.FinancialAccountNumber__c.leftPad(17, '0');
        if(mapAccountProduct.containsKey(accountKey)){
            fAccTransac.CC_Account_Type__c = accountTypeMap.containsKey(String.valueOf(mapAccountProduct.get(accountKey))) ? 
            accountTypeMap.get(String.valueOf(mapAccountProduct.get(accountKey))) : accountTypeMap.get(String.valueOf(mapAccountProduct.get(accountKey)).substring(1));
        }
         
         for(Map<String, Object> selectedItem : selectedItems){
             if(fAccTransac.Transaction_Id__c == String.valueOf(selectedItem.get('tranId'))){
                 fAccTransac.CC_To_Account_Number__c = (String) String.valueOf(selectedItem.get('transferAccountNr'));
             }
         }

        return fAccTransac;
     }

    /**
     * @description  Creates a map of transaction types
     * @return       Custom metadata map with group&class as the key and primary need as the value
     */
    public static Map<String, String> retrieveTransactionTypeMap() {
        List<Capitec_Transaction_Type__mdt> transactionTypes = [
            SELECT Classification_Type__c, Transaction_Type_Category__c, Primary_Need__c 
            FROM Capitec_Transaction_Type__mdt
            WITH SECURITY_ENFORCED
        ];
        
        Map<String, String> typeMap = new Map<String, String>();
        for (Capitec_Transaction_Type__mdt type : transactionTypes) {
            String key = String.format('{0}{1}', new List<String>{type.Classification_Type__c, type.Transaction_Type_Category__c});
            typeMap.put(key, type.Primary_Need__c);
        }
        return typeMap;
    }

    /**
     * @description  Creates a map of account types
     * @return       Custom metadata map with account types for transaction history
     */
    public static Map<String, String> retrieveAccountTypeMap() {
        List<Capitec_Account_Type__mdt> accountTypes = [
            SELECT Id, Account_Type_Number__c, Account_Type_Name__c 
            FROM Capitec_Account_Type__mdt
            WITH SECURITY_ENFORCED
        ];

        Map<String, String> typeMap = new Map<String, String>();
        for(Capitec_Account_Type__mdt type : accountTypes){
            typeMap.put(type.Account_Type_Number__c, type.Account_Type_Name__c);
        }
        return typeMap;     
    }

    /**
     * @description  Creates a concatenated string using values retrieved from a map
     * @param        stringObjectMap map to extract string values from
     * @param        firstKey first string key
     * @param        secondKey second string key
     * @return       Concatenated string
     */
    private static String createConcatenatedString( Map<String, Object> stringObjectMap, String firstKey, String secondKey) {
        return String.format('{0}{1}', new List<String>{String.valueOf(stringObjectMap.get(firstKey)), String.valueOf(stringObjectMap.get(secondKey))});
    }
}