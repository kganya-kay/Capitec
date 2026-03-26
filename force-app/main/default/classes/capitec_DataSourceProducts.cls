/**
 * Created by Sebastian on 17.04.2023.
 */

global with sharing class capitec_DataSourceProducts {
    @TestVisible private static final String URL_PRODUCTS = 'client/product-proxy/product/v1/account/list';

    public static List<DataSource.Column> createProductColumns(){
        List<DataSource.Column> productColumns = new List<DataSource.Column>();

        productColumns.add(DataSource.Column.indirectLookup('relatedAccount', 'Account', 'CIF_Number__c'));
        productColumns.add(DataSource.Column.text('accountNumber', 255));
        productColumns.add(DataSource.Column.text('accountName', 255));
        productColumns.add(DataSource.Column.text('accountType', 255));
        productColumns.add(DataSource.Column.text('accountStatus', 255));
        productColumns.add(DataSource.Column.number('currentBalance', 16, 2));
        productColumns.add(DataSource.Column.text('openDate', 255));

        return productColumns;
    }

    public static List<Map<String, Object>> createProductRows(Map<String, Object> productResponse) {
        system.debug('lgo productResponse'+productResponse);
        List<Map<String, Object>> rows = new List<Map<String, Object>>();

        for (Object row : (List<Object>)productResponse.get('accounts')) {
            Map<String, Object> createdRow = createProductRow((Map<String, Object>)row);
            createdRow.put('ExternalId', createdRow.get('ExternalId') + '.' + productResponse.get('cifNumber'));
            createdRow.put('relatedAccount', productResponse.get('cifNumber'));
            rows.add(createdRow);
        }
        system.debug('lgo productResponse rows'+rows);

        return rows;
    }

    private static Map<String, Object> createProductRow(Map<String, Object> productNode) {
        Map<String, Object> row = new Map<String, Object>();

        for (String key : productNode.keySet()) {
            switch on key {
                when 'accountNumber' {
                    row.put('ExternalId', productNode.get(key));
                    row.put('accountNumber', productNode.get(key));
                }
                when 'accountName' {
                    row.put('accountName', productNode.get(key));
                }
                when 'accountType' {
                    row.put('accountType', productNode.get(key));
                }
                when 'accountStatus' {
                    row.put('accountStatus', productNode.get(key));
                }
                when 'currentBalance' {
                    row.put('currentBalance', productNode.get(key));
                }
                when 'openDate' {
                    row.put('openDate', productNode.get(key));
                }
                when 'savingsAccountTerm' {
                    row.put('savingsAccountTerm', productNode.get(key));
                }
            }
        }

        return row;
    }

    public static String getProductUrl(DataSource.Filter filter) {
        if (filter == null) {
            throw new DataSource.DataSourceException('No filter selected');
           //return URL_PRODUCTS + '?cifNumber=' + '';
        }

        if (filter.columnName == 'ExternalId') {
            String accNumber = String.valueOf(filter.columnValue).left(String.valueOf(filter.columnValue).indexOf('.'));
            String cifNum = String.valueOf(filter.columnValue).right(String.valueOf(filter.columnValue).length() - String.valueOf(filter.columnValue).indexOf('.') - 1);

            return URL_PRODUCTS + '?cifNumber=' + cifNum + '&accountNumber=' + accNumber;
        }

        if (filter.columnName == 'relatedAccount') {
            return URL_PRODUCTS + '?cifNumber=' + filter.columnValue;
        }

        if (filter.subfilters != null && filter.subfilters.size() == 1 && filter.subfilters[0].columnName == 'relatedAccount') {
            return URL_PRODUCTS + '?cifNumber=' + filter.subfilters[0].columnValue;
        }

        throw new DataSource.DataSourceException('No endpoint provided for this filter.');
    }

    public static String getProductUrllgo(DataSource.Filter filter) {
        if (filter == null) {
           // throw new DataSource.DataSourceException('No filter selected');
           return URL_PRODUCTS + '?cifNumber='+'';
        }

        if (filter.columnName == 'relatedAccount') {
            return URL_PRODUCTS;
        }


        throw new DataSource.DataSourceException('No endpoint provided for this filter.');
    }
}