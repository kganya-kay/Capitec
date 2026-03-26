/**
 * Created by Oumesh Jhundoo on 06/06/2023.
 */

global with sharing class capitec_DataSourceCashSendVouchers {
    @TestVisible private static final String URL_ORDER_HISTORY_LIST = 'client/account-action-service/v1/send-cash/order-history';
    @TestVisible private static final String URL_ORDER_HISTORY_DETAILS = 'client/account-action-service/v1/send-cash/order-detail';
    @TestVisible private static final String CIF_NUMBER_FILTER_NAME = 'relatedAccount';
    @TestVisible private static final String DETAILS_FILTER_NAME = 'ExternalId';

    public static List<DataSource.Column> createVoucherColumns() {
        List<DataSource.Column>voucherColumns = new List<DataSource.Column>();

        voucherColumns.add(DataSource.Column.indirectLookup('relatedAccount', 'Account', 'CIF_Number__c'));
        voucherColumns.add(DataSource.Column.text('ledgerIndicator', 255));
        voucherColumns.add(DataSource.Column.number('sendAmount', 16, 2));
        voucherColumns.add(DataSource.Column.text('sentFrom', 255));
        voucherColumns.add(DataSource.Column.text('status', 255));
        voucherColumns.add(DataSource.Column.text('voucherNumber', 255));
        voucherColumns.add(DataSource.Column.text('dateCreated', 255));
        voucherColumns.add(DataSource.Column.text('dateModified', 255));

        return voucherColumns;
    }

    public static List<Map<String, Object>> createVoucherRowsList(Map<String, Object> voucherResponse, DataSource.QueryContext context) {
        List<Map<String, Object>> rows;
        DataSource.Filter currentFilter = context.tableSelection.filter;

        System.debug('\n *** *** voucherResponse *** ***');
        System.debug(voucherResponse);
        System.debug('\n');

        if (currentFilter.subfilters != null && currentFilter.subfilters[0].columnName == CIF_NUMBER_FILTER_NAME) {
            rows = handleListViewRows(voucherResponse, currentFilter);
        } else if (currentFilter.columnName == DETAILS_FILTER_NAME) {
            rows = handleDetailsViewRows(voucherResponse, currentFilter);
        }
        return rows;
    }

    private static List<Map<String, Object>> handleListViewRows(Map<String, Object> voucherResponse, DataSource.Filter currentFilter) {

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        String cifNumber = String.valueOf(currentFilter.subfilters[0].columnValue);

        for (Object row : (List<Object>) voucherResponse.get('senderOrders')) {
            Map<String, Object> createdRow = createVoucherListRow((Map<String, Object>) row);
            createdRow.put('ExternalId', createdRow.get('ExternalId') + '.' + cifNumber);
            createdRow.put('relatedAccount', cifNumber);
            rows.add(createdRow);
        }
        return rows;
    }

    private static List<Map<String, Object>> handleDetailsViewRows(Map<String, Object> voucherResponse, DataSource.Filter currentFilter) {

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Map<String, Object> createdRow = new Map<String, Object>();

        Map<String, Object> order = (Map<String, Object>) voucherResponse.get('order');
        Map<String, Object> amount = (Map<String, Object>) order.get('amount');
        Map<String, Object> payment = (Map<String, Object>) voucherResponse.get('payment');
        Map<String, Object> paymentAmount = (Map<String, Object>) payment.get('amount');

        createdRow.put('ExternalId', (order.get('reference') + '.' + payment.get('customerId')));
        createdRow.put('relatedAccount', payment.get('customerId'));
        createdRow.put('ledgerIndicator', paymentAmount.get('ledgerIndicator'));
        createdRow.put('sendAmount', paymentAmount.get('amount'));
        createdRow.put('sentFrom', payment.get('origin'));
        createdRow.put('status', order.get('state'));
        createdRow.put('voucherNumber', order.get('reference'));

        try {
            createdRow.put('dateCreated', Datetime.valueOfGmt((String.valueOf(order.get('datetimeCreated')).replaceFirst('T', ' '))));
        } catch (NullPointerException e) {
            createdRow.put('dateCreated', null);
        }

        try {
            createdRow.put('dateModified', Datetime.valueOfGmt((String.valueOf(order.get('datetimeModified')).replaceFirst('T', ' '))));
        } catch (NullPointerException e) {
            createdRow.put('dateModified', null);
        }

        rows.add(createdRow);
        return rows;
    }

    private static Map<String, Object> createVoucherListRow(Map<String, Object> voucherNode) {
        Map<String, Object> row = new Map<String, Object>();

        for (String key : voucherNode.keySet()) {
            switch on key {
                when 'reference' {
                    row.put('ExternalId', voucherNode.get(key));
                    row.put('voucherNumber', voucherNode.get(key));
                }
                when 'state' {
                    row.put('status', voucherNode.get(key));
                }
                when 'datetimeCreated' {
                    try{
                        row.put('dateCreated', Datetime.valueOfGmt((String.valueOf(voucherNode.get(key)).replaceFirst('T', ' '))));
                    }
                    catch (NullPointerException e){
                        row.put('dateModified', null);
                    }

                }
                when 'datetimeModified' {
                    try{
                        row.put('dateModified', Datetime.valueOfGmt((String.valueOf(voucherNode.get(key)).replaceFirst('T', ' '))));
                    }
                    catch (NullPointerException e){
                        row.put('dateModified', null);
                    }

                }
                when 'createdAmount' {
                    Map<String, Object> amountObj = (Map<String, Object>) voucherNode.get(key);
                    row.put('sendAmount', amountObj.get('amount'));
                    row.put('ledgerIndicator', amountObj.get('ledgerIndicator'));
                }
            }
        }
        return row;
    }


    public static String getVoucherUrl(DataSource.Filter filter) {

        if (filter == null) {
            throw new DataSource.DataSourceException('No filter selected');
        }

        if (filter.columnName == 'ExternalId') {
            return URL_ORDER_HISTORY_DETAILS;
        }

        if (filter.subfilters[0].columnName == 'relatedAccount') {
            return URL_ORDER_HISTORY_LIST ;
        }

        throw new DataSource.DataSourceException('No endpoint provided for this filter.');
    }


    public static String getRequestBody(DataSource.Filter filter) {
        if (filter == null) {
            throw new DataSource.DataSourceException('No filter selected');
        }

        if (filter.columnName == 'ExternalId') {
            String orderRef = String.valueOf(filter.columnValue).left(String.valueOf(filter.columnValue).indexOf('.'));
            String cifNum = String.valueOf(filter.columnValue).right(String.valueOf(filter.columnValue).length() - String.valueOf(filter.columnValue).indexOf('.') - 1);

            VoucherRequestBodyWrapper newWrapper = new VoucherRequestBodyWrapper();
            newWrapper.cifNumber = cifNum;
            newWrapper.orderReference = orderRef;

            return (JSON.serialize(newWrapper));
        }

        if (filter.subfilters[0].columnName == 'relatedAccount') {
            VoucherRequestBodyWrapper newWrapper = new VoucherRequestBodyWrapper();
            newWrapper.cifNumber = String.valueOf(filter.subfilters[0].columnValue);

            return (JSON.serialize(newWrapper));
        }

        throw new DataSource.DataSourceException('No endpoint provided for this filter.');
    }


    public class VoucherRequestBodyWrapper {
        public String cifNumber;
        public String orderReference;
    }
}