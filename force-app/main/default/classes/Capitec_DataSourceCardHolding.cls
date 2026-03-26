/**
 * Created by dawid on 17.04.2023.
 */

public with sharing class Capitec_DataSourceCardHolding {
    private static final String URL_CARD_HOLDING = 'client/product-proxy/product/v1/card/list';
    private static final String URL_CARD_HOLDING_DETAILS = 'client/account-action-service/v1/card/details';
    @TestVisible private static final String CIF_NUMBER_FILTER_NAME = 'relatedAccount';
    @TestVisible private static final String DETAILS_FILTER_NAME = 'ExternalId';

    public static List<DataSource.Column> createCardHoldingColumns(){
        List<DataSource.Column> productColumns = new List<DataSource.Column>();

        productColumns.add(DataSource.Column.indirectLookup('relatedAccount', 'Account', 'CIF_Number__c'));
        productColumns.add(DataSource.Column.text('ExternalId', 255));
        productColumns.add(DataSource.Column.text('cardNumber', 255));
        productColumns.add(DataSource.Column.text('cardholderId', 255));
        productColumns.add(DataSource.Column.text('cardHolderName', 255));
        productColumns.add(DataSource.Column.text('cardStatus', 255));
        productColumns.add(DataSource.Column.text('cardAllocatedDate', 255));

        return productColumns;
    }

    public static List<Map<String, Object>> createCardHoldingRowsList(Map<String, Object> productResponse, DataSource.QueryContext context) {
        List<Map<String, Object>> rows;
        DataSource.Filter currentFilter = context.tableSelection.filter;

        if (currentFilter.subfilters != null && currentFilter.subfilters[0].columnName == CIF_NUMBER_FILTER_NAME) {
            rows = handleListViewRows(productResponse, currentFilter);
        } 
         //START cater omniscript view - DR_ExtractFraudCard1
        if (currentFilter.columnName == 'relatedAccount') {
            String sCIF = String.valueOf(currentFilter.columnValue);
            rows = handleListViewRows(productResponse,currentFilter);
        }
         //END cater omniscript view - DR_ExtractFraudCard1
        else if (currentFilter.columnName == DETAILS_FILTER_NAME) {
            String sCIF = String.valueOf(currentFilter.columnValue).substring(String.valueOf(currentFilter.columnValue).indexOf('.') + 1, String.valueOf(currentFilter.columnValue).indexOf('.') + 10);
            rows = createCardDetailHoldingRow(productResponse,sCIF);
        }
        return rows;
    }

    private static List<Map<String, Object>> handleListViewRows(Map<String, Object> productResponse, DataSource.Filter currentFilter) {

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        String cifNumber;
        if (currentFilter.subfilters != null) {
            cifNumber = String.valueOf(currentFilter.subfilters[0].columnValue);
        } 
         //START cater omniscript view - DR_ExtractFraudCard1
        if (currentFilter.columnName == 'relatedAccount') {
            cifNumber = String.valueOf(currentFilter.columnValue);
        }
         //END cater omniscript view - DR_ExtractFraudCard1

        for (Object row : (List<Object>) productResponse.get('cards')) {
            Map<String, Object> createdRow = createCardHoldingRow((Map<String, Object>) row);
            createdRow.put('ExternalId', createdRow.get('ExternalId') + '.' + cifNumber + '.' +  createdRow.get('cardNumber'));
            createdRow.put('relatedAccount', cifNumber);
            rows.add(createdRow);
        }
        return rows;
    }

    private static List<Map<String, Object>> createCardDetailHoldingRow(Map<String, Object> productNode, String sCIF) {
        Map<String, Object> createdRow = new Map<String, Object>();
        List<Map<String, Object>> rows = new List<Map<String, Object>>();

        createdRow.put('ExternalId', sCIF);
        createdRow.put('relatedAccount', sCIF);
        createdRow.put('cardNumber', productNode.get('cardId'));
        createdRow.put('cardStatus', productNode.get('cardStatus'));
        createdRow.put('cardHolderName', productNode.get('cardholderName'));
        createdRow.put('cardType', productNode.get('cardType'));
        createdRow.put('cardholderId', productNode.get('contactlessCard'));
        createdRow.put('cardStopReason',productNode.get('cardStopReason'));
        createdRow.put('cardStopDate',productNode.get('cardStopDate')); //Added for ticket FFSF-355
        createdRow.put('Account', sCIF);

        rows.add(createdRow);

        return rows;
    }

    private static Map<String, Object> createCardHoldingRow(Map<String, Object> productNode) {
        Map<String, Object> row = new Map<String, Object>();

        for (String key : productNode.keySet()) {
            switch on key {
                when 'maskedCardNumber' {
                    row.put('ExternalId', productNode.get(key));
                    row.put('cardNumber', productNode.get(key));
                    row.put('relatedAccount', productNode.get(key));
                }
                when 'cardStatus' {
                    row.put('cardStatus', productNode.get(key));
                }
                when 'cardType' {
                    row.put('cardType', productNode.get(key));
                }
                when 'cardholderName' {
                    row.put('cardHolderName', productNode.get(key));
                }
                when 'contactlessCard' {
                    row.put('cardholderId', productNode.get(key));
                }
                when 'cardStopReason' {
                    row.put('cardStopReason', productNode.get(key));
                }
                 when 'cardStopDate' {  //Added for ticket FFSF-355
                    row.put('cardStopDate', productNode.get(key));
                }
                when 'cifNumber' {
                    row.put('Account', productNode.get(key));
                }
            }
        }

        return row;
    }

    public static String getCardHoldingUrl(DataSource.Filter filter) {
        System.debug(filter);

        if (filter.columnName == 'ExternalId') {
            return (URL_CARD_HOLDING_DETAILS);
        }

        if (filter.columnName == 'relatedAccount') {
            return URL_CARD_HOLDING + '?cifNumber=' + filter.columnValue;
        }
        else if (filter != null) {
            return (URL_CARD_HOLDING + '?cifNumber=' + filter.subfilters[0].columnValue);

        }
        throw new DataSource.DataSourceException('No endpoint provided for this filter.');
    }

    public static String getRequestBody(DataSource.Filter filter) {
        System.debug(filter);

        //START cater omniscript view - DR_ExtractFraudCard1
        if (filter.columnName == 'relatedAccount') {
            String cifNum = String.valueOf(filter.columnValue);

            CardRequestBodyWrapper newWrapper = new CardRequestBodyWrapper();
            newWrapper.cifNumber = cifNum;
            newWrapper.consultantIdentifier = getUserEmployeeNumber();
            newWrapper.cardPan = null;

            return (JSON.serialize(newWrapper));
        } 
         //END cater omniscript view - DR_ExtractFraudCard1

        if (filter.columnName == 'ExternalId') {
            String sColumnValue = String.valueOf(filter.columnValue);
            String[] sParam =  sColumnValue.split('\\.');


            CardRequestBodyWrapper newWrapper = new CardRequestBodyWrapper();
            newWrapper.cifNumber = sParam[1];
            newWrapper.consultantIdentifier = getUserEmployeeNumber();
            newWrapper.cardPan = sParam[0];

            return (JSON.serialize(newWrapper));
        }

        if (filter.subfilters != null && filter.subfilters[0].columnName == 'relatedAccount') {
            String cifNum = String.valueOf(filter.subfilters[0].columnValue).right(String.valueOf(filter.subfilters[0].columnValue).length() - String.valueOf(filter.subfilters[0].columnValue).indexOf('.') - 1);

            CardRequestBodyWrapper newWrapper = new CardRequestBodyWrapper();
            newWrapper.cifNumber = cifNum;
            newWrapper.consultantIdentifier = getUserEmployeeNumber();

            return (JSON.serialize(newWrapper));
        }

        if (filter == null) {
            throw new DataSource.DataSourceException('No filter selected');
        }

        throw new DataSource.DataSourceException('No endpoint provided for this filter.');
    }

    public static String getUserEmployeeNumber()
    {
        String userID = UserInfo.getUserId();
        List<User> accountList = [SELECT EmployeeNumber FROM User WHERE Id=: userID];
        String sList = accountList.toString();
        String subString = sList.substring(22, 30);

        if (subString == null) {
            throw new DataSource.DataSourceException('No employee number found');
        }

        return subString;
    }

    public class CardRequestBodyWrapper {
        public String cifNumber;
        public String consultantIdentifier;
        public String cardPan;
    }

}