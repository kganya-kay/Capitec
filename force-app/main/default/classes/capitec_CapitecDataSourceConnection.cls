/**
 * Created by Sebastian on 24.03.2023.
 */

global with sharing class capitec_CapitecDataSourceConnection extends DataSource.Connection{
    private static final String PRODUCT = 'Product';
    private static final String TRANSACTION_HISTORY = 'TransactionHistory';
    private static final String CHOLDING = 'CHolding';
    private static final String RISK_SCORE = 'RiskScore';
    private static final String CHANNEL = 'Channel';
    private static final String SEND_CASH_VOUCHERS = 'CashSendVouchers';
    private static final String URL_TRANSACTION_HISTORY = 'transaction-proxy/transaction/v1/history';


    private DataSource.ConnectionParams connectionInfo;

    global capitec_CapitecDataSourceConnection(DataSource.ConnectionParams connectionInfo) {
        this.connectionInfo = connectionInfo;
    }

    override global List<DataSource.Table> sync() {
        List<DataSource.Table> tables = new List<DataSource.Table>();

        tables.add(DataSource.Table.get(PRODUCT,'title', capitec_DataSourceProducts.createProductColumns()));
        tables.add(DataSource.Table.get(TRANSACTION_HISTORY,'title', Capitec_DataSourceTransactionHistory.createTransactionalHistoryColumns()));
        tables.add(DataSource.Table.get(CHOLDING,'title', Capitec_DataSourceCardHolding.createCardHoldingColumns()));
        tables.add(DataSource.Table.get(RISK_SCORE,'title', Capitec_DataSourceRiskScore.createRiskScoreColumns()));
        tables.add(DataSource.Table.get(CHANNEL,'title', capitec_DataSourceChannel.createChannelColumns()));
        tables.add(DataSource.Table.get(SEND_CASH_VOUCHERS,'title',capitec_DataSourceCashSendVouchers.createVoucherColumns()));
        //capitec_DataSourceCashSendVouchers.createCashSendVouchersColumns()
        return tables;
    }

    override global DataSource.TableResult query(DataSource.QueryContext context) {

        if (context.tableSelection.tableSelected.equals(CHANNEL)) {
            return capitec_DataSourceChannel.createChannelTableResult(context);
        }
        System.debug(context.tableSelection.filter);
        String url = getUrl(context);
        List<Map<String, Object>> rows;

        if(context.tableSelection.tableSelected.equals(TRANSACTION_HISTORY)){
            DataSource.QueryContext contextNoFilters = context;
            contextNoFilters.tableSelection.filter = null;
            rows = getData(url, context);
        }
        else if(context.tableSelection.tableSelected.equals(CHOLDING)){
            rows = getData(url, context);
            DataSource.QueryContext contextNoFilters = context;
            contextNoFilters.tableSelection.filter = null;
        }
        else if(context.tableSelection.tableSelected.equals(SEND_CASH_VOUCHERS)){
            rows = getData(url, context);
            DataSource.QueryContext contextNoFilters = context;
            contextNoFilters.tableSelection.filter = null;
        }
        else{
            rows = getData(url, context);
        }

        DataSource.TableResult tableResult = DataSource.TableResult.get(true, null, context.tableSelection.tableSelected, rows);
        return tableResult;
    }

    private List<Map<String, Object>> getData(String url, DataSource.QueryContext context) {
        HttpResponse response;
        if(context.tableSelection.tableSelected.equals(SEND_CASH_VOUCHERS)){
            response = getResponsePost(url, capitec_DataSourceCashSendVouchers.getRequestBody(context.tableSelection.filter));
        }
        else if(context.tableSelection.tableSelected.equals(CHOLDING)){
            response = getResponsePost(url, Capitec_DataSourceCardHolding.getRequestBody(context.tableSelection.filter));
        }
        else{
            response = getResponse(url);
        }
        String responseBody = response.getBody();


        if (response.getStatusCode() != 200) {
            throw new DataSource.OAuthTokenExpiredException(response.getStatus());
        }

        List<Map<String, Object>> returnedRows = returnRows(context, (Map<String, Object>)JSON.deserializeUntyped(responseBody));

        return returnedRows;
    }

    private static List<Map<String, Object>> returnRows(DataSource.QueryContext context, Map<String, Object> responseBodyMap) {

        List<Map<String, Object>> rows = new List<Map<String, Object>>();

        if (context.tableSelection.tableSelected.equals(PRODUCT)) {
            if (responseBodyMap != null) {
                return capitec_DataSourceProducts.createProductRows(responseBodyMap);
            }
        }

        if(context.tableSelection.tableSelected.equals(TRANSACTION_HISTORY)) {
            if (responseBodyMap != null) {
                return Capitec_DataSourceTransactionHistory.createTransactionHistoryRowsList(responseBodyMap);
            }
        }
        if(context.tableSelection.tableSelected.equals(RISK_SCORE)) {
            if (responseBodyMap != null) {
                return Capitec_DataSourceRiskScore.createRiskRowsList(responseBodyMap, context);
            }
        }
        if(context.tableSelection.tableSelected.equals(CHOLDING)) {
            if (responseBodyMap != null) {
                return Capitec_DataSourceCardHolding.createCardHoldingRowsList(responseBodyMap, context);
            }
        }
        if(context.tableSelection.tableSelected.equals(SEND_CASH_VOUCHERS)) {
            if (responseBodyMap != null) {
                return capitec_DataSourceCashSendVouchers.createVoucherRowsList(responseBodyMap, context);
            }
        }

        throw new DataSource.DataSourceException('No handler configured for ' + context.tableSelection.tableSelected + ' table.');
    }

    public static HttpResponse getResponse(String url) {
        Http httpProtocol = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:CapiEndpoints/' + url);
        request.setMethod('GET');
        HttpResponse response = httpProtocol.send(request);
        return response;
    }

    public static HttpResponse getResponsePost(String url, String body) {
        Http httpProtocol = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:CapiEndpoints/' + url);
        request.setMethod('POST');
        request.setBody(body);
        System.debug(body);
        HttpResponse response = httpProtocol.send(request);
        system.debug('response ojh'+response);
        system.debug('response.getbody() ojh'+response.getBody());
        return response;
    }

    private static String getUrl(DataSource.QueryContext context) {
        system.debug('lgo context '+context);
        system.debug('lgo context.tableSelection.filter '+context.tableSelection.filter);
        system.debug('lgo context.tableSelection.columnsSelected '+context.tableSelection.columnsSelected);


        DataSource.Filter filter = context.tableSelection.filter;

        if (context.tableSelection.tableSelected.equals(PRODUCT)) {
            return capitec_DataSourceProducts.getProductUrl(filter);
        }
        if (context.tableSelection.tableSelected.equals(TRANSACTION_HISTORY)) {
            return Capitec_DataSourceTransactionHistory.getTransactionHistoryListUrl(filter,URL_TRANSACTION_HISTORY);
        }
        if (context.tableSelection.tableSelected.equals(RISK_SCORE)) {
            return Capitec_DataSourceRiskScore.getRiskScoreUrl(filter);
        }
        if (context.tableSelection.tableSelected.equals(CHOLDING)) {
            return Capitec_DataSourceCardHolding.getCardHoldingUrl(filter);
        }
        if (context.tableSelection.tableSelected.equals(SEND_CASH_VOUCHERS)) {
            return capitec_DataSourceCashSendVouchers.getVoucherUrl(filter);
        }

        throw new DataSource.DataSourceException('Table name is incorrect or unable to handle by this Data Source Connector.');
    }
//    private static String getUrlLGOTest(DataSource.QueryContext context) {
//        system.debug('lgo context '+context);
//        system.debug('lgo context.tableSelection.filter '+context.tableSelection.filter);
//
//        DataSource.ColumnSelection filter = context.tableSelection.columnsSelected[2];
//
//        if (context.tableSelection.tableSelected.equals(PRODUCT)) {
//            return capitec_DataSourceProducts.getProductUrlLGO(filter);
//        }
//
//
//        throw new DataSource.DataSourceException('Table name is incorrect or unable to handle by this Data Source Connector.');
//    }
}