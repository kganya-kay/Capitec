/**
 * Created by sebastian on 25/05/2023.
 */

global with sharing class capitec_DataSourceChannel {
    @TestVisible private static final String URL_USSD = 'account-action-service/v1/ussd-details';
    @TestVisible private static final String URL_IBANK = 'account-action-service/v1/internet-banking-details';
    @TestVisible private static final String URL_APP = 'account-action-service/v1/app-details';

    public static List<DataSource.Column> createChannelColumns() {
        List<DataSource.Column> productColumns = new List<DataSource.Column>();

        productColumns.add(DataSource.Column.indirectLookup('relatedAccount', 'Account', 'CIF_Number__c'));
        productColumns.add(DataSource.Column.text('isActive', 6));
        productColumns.add(DataSource.Column.text('channelType', 255));
        productColumns.add(DataSource.Column.text('msisdn', 255));
        productColumns.add(DataSource.Column.text('userRegNr', 255));
        productColumns.add(DataSource.Column.text('username', 255));
        productColumns.add(DataSource.Column.text('email', 255));
        productColumns.add(DataSource.Column.text('registrationDate', 255));
        productColumns.add(DataSource.Column.text('lastInteractionDate', 255));
        productColumns.add(DataSource.Column.text('tokenType', 255));
        productColumns.add(DataSource.Column.text('suspendReason', 255));
        productColumns.add(DataSource.Column.text('email', 255));
        productColumns.add(DataSource.Column.text('email', 255));
        productColumns.add(DataSource.Column.text('email', 255));

        return productColumns;
    }

    public static DataSource.TableResult createChannelTableResult(DataSource.QueryContext context) {
        DataSource.Filter filter = context.tableSelection.filter;
        DataSource.Filter subFilter = context.tableSelection.filter.subfilters != null ? context.tableSelection.filter.subfilters[0] : null;

        List<Map<String, Object>> rows;

        if (filter == null && subFilter == null) {
            throw new DataSource.DataSourceException('No filter selected');
        }

        if (filter.columnName == 'ExternalId') {
            String cifNum = String.valueOf(filter.columnValue).left(String.valueOf(filter.columnValue).indexOf('.'));
            String channelType = String.valueOf(filter.columnValue).right(String.valueOf(filter.columnValue).length() - String.valueOf(filter.columnValue).indexOf('.') - 1);

            rows = createChannelRows(new List<Map<String, Object>>{createRecordNode(listSelectedChannel(channelType, cifNum), channelType, cifNum)});
        }
        else if (subFilter.columnName == 'relatedAccount') {
            String cifNumber = (String)subFilter.columnValue;
            List<Object> recordNodesList = new List<Object>();
            List<String> channelTypesList = new List<String>{'USSD', 'APP', 'INTERNET_BANKING'};

            for (String channelType : channelTypesList) {
                recordNodesList.add(createRecordNode(listSelectedChannel(channelType, cifNumber), channelType, cifNumber));
            }

            rows = createChannelRows(recordNodesList);
        }

        return DataSource.TableResult.get(true, null,  context.tableSelection.tableSelected, rows);
    }

    private static List<Map<String, Object>> createChannelRows(List<Object> channelNodesList) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();

        for (Object row : channelNodesList) {
            Map<String, Object> createdRow = createChannelRow((Map<String, Object>)row);

            createdRow.put('ExternalId', createdRow.get('ExternalId') + '.' + createdRow.get('channelType'));

            rows.add(createdRow);
        }

        return rows;
    }

    private static Map<String, Object> createRecordNode(Map<String, Object> channelNode, String channelType, String cifNum) {
        if (channelType == 'USSD') {
            channelNode = (Map<String, Object>)((List<Object>)channelNode.get('msisdns'))[0];
        }

        Map<String, Object> recordNode = new Map<String, Object>();

        switch on channelType {
            when 'USSD' {
                recordNode.put('cifNumber', cifNum);
                recordNode.put('msisdn', channelNode.get('msisdn'));
                recordNode.put('status', channelNode.get('status'));
                recordNode.put('channelType', channelType);
            }
            when 'APP' {
                recordNode.put('cifNumber', cifNum);
                recordNode.put('userRegNr', channelNode.get('userRegNr'));
                recordNode.put('status', channelNode.get('userStatus'));
                recordNode.put('tokenType', channelNode.get('tokenType'));
                recordNode.put('channelType', channelType);
            }
            when 'INTERNET_BANKING' {
                recordNode.put('cifNumber', cifNum);
                recordNode.put('userRegNr', channelNode.get('userRegNr'));
                recordNode.put('username', channelNode.get('username'));
                recordNode.put('status', channelNode.get('status'));
                recordNode.put('email', channelNode.get('email'));
                recordNode.put('registrationDate', channelNode.get('registrationDate'));
                recordNode.put('lastInteractionDate', channelNode.get('lastInteractionDate'));
                recordNode.put('tokenType', channelNode.get('tokenType'));
                recordNode.put('suspendReason', channelNode.get('suspendReason'));
                recordNode.put('channelType', channelType);
            }
        }

        return recordNode;
    }

    private static Map<String, Object> createChannelRow(Map<String, Object> channelNode) {
        Map<String, Object> row = new Map<String, Object>();

        for (String key : channelNode.keySet()) {
            switch on key {
                when 'cifNumber' {
                    row.put('ExternalId', channelNode.get(key));
                    row.put('relatedAccount', channelNode.get(key));
                }
                when 'channelType' {
                    row.put('channelType', channelNode.get(key));
                }
                when 'status' {
                    row.put('isActive', channelNode.get(key));
                }
                when 'msisdn' {
                    row.put('msisdn', channelNode.get(key));
                }
                when 'userRegNr' {
                    row.put('userRegNr', channelNode.get(key));
                }
                when 'tokenType' {
                    row.put('tokenType', channelNode.get(key));
                }
                when 'username' {
                    row.put('username', channelNode.get(key));
                }
                when 'email' {
                    row.put('email', channelNode.get(key));
                }
                when 'registrationDate' {
                    row.put('registrationDate', channelNode.get(key));
                }
                when 'lastInteractionDate' {
                    row.put('lastInteractionDate', channelNode.get(key));
                }
                when 'suspendReason' {
                    row.put('suspendReason', channelNode.get(key));
                }
            }
        }

        return row;
    }

    private static Map<String, Object> listSelectedChannel(String channelType, String cifNumber) {
        String url;

        switch on channelType {
            when 'USSD' {
                url = URL_USSD;
            }
            when 'APP' {
                url = URL_APP;
            }
            when 'INTERNET_BANKING' {
                url = URL_IBANK;
            }
        }

        String body = JSON.serialize(new Map<String, Object>{'cifNumber' => cifNumber});
        HttpResponse response = capitec_CapitecDataSourceConnection.getResponsePost(url, body);

        if (response.getStatusCode() == 400) {
            throw new DataSourceChannelException(response.getBody());
        }

        if (response.getStatusCode() == 500) {
            throw new DataSourceChannelException('Problem with Capitec API.');
        }
        System.debug('resposne body2: ' + response.getBody());
        return (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

    }

    global class DataSourceChannelException extends Exception {}
}