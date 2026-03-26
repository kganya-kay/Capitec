/**
 * Created by dawid on 17.04.2023.
 */

public with sharing class Capitec_DataSourceTransactionHistory {

    public static List<Map<String, Object>> createTransactionHistoryRowsList(Map<String, Object> productResponse) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();

        for (Object row : (List<Object>)productResponse.get('transactions')) {
            Map<String, Object> createdRow = createTransactionHistoryRow((Map<String, Object>)row);
            rows.add(createdRow);
        }
        return rows;
    }

    public static Map<String, Object> createTransactionHistoryRow(Map<String, Object> productNode) {
        Map<String, Object> row = new Map<String, Object>();

        for (String key : productNode.keySet()) {
            switch on key {
                when 'accountNumber' {
                    row.put('ExternalId', productNode.get(key));
                    row.put('accountNumber__c', productNode.get(key));
                    row.put('accountNumber', productNode.get(key));
                }
                when 'transactionDate' {
                    row.put('Transaction_Date', productNode.get(key));
                }
                when 'transactionId' {
                    row.put('Transaction_Id', productNode.get(key));
                }
                when 'originalDescription' {
                    row.put('Original_Description', productNode.get(key));
                }
                when 'cardNumber' {
                    row.put('Card_Number', productNode.get(key));
                }
                when 'teller' {
                    row.put('Teller', productNode.get(key));
                }
                when 'balance' {
                    row.put('Current_Balance', productNode.get(key));
                }
                when 'transferAccount' {
                    row.put('Transfer_Account', productNode.get(key));
                }
            }
        }

        return row;
    }

    public static List<DataSource.Column> createTransactionalHistoryColumns(){
        List<DataSource.Column> transactionalHistoryColumns = new List<DataSource.Column>();

        transactionalHistoryColumns.add(DataSource.Column.text('accountNumber', 255));

        return transactionalHistoryColumns;
    }

    public static String getTransactionHistoryListUrl(DataSource.Filter filter, String URL_TRANSACTION_HISTORY) {
        if (filter != null) {
            if(filter.subfilters != null){
                String composedUrl = URL_TRANSACTION_HISTORY + '?';
                for(DataSource.Filter currentFilter: filter.subfilters){
                    composedUrl += currentFilter.columnName + '=';
                    composedUrl += currentFilter.columnValue + '&';
                }
                return composedUrl;
            }
            else{
                String composedUrl = URL_TRANSACTION_HISTORY + '?';
                composedUrl += 'accountNumber=' + filter.columnValue;
                composedUrl += '&startDate=' + String.valueOf(System.today()-31);
                composedUrl += '&endDate=' + String.valueOf(System.today());
                return composedUrl;
            }
        }

        throw new DataSource.DataSourceException('No endpoint provided for this filter.');
    }
}