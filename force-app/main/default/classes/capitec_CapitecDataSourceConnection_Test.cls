/**
 * Created by Sebastian on 19.04.2023.
 */

@IsTest
public class capitec_CapitecDataSourceConnection_Test {
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

    @TestSetup
    static void dataSetup() {
        Account acc = (Account)TestDataFactory.createSObject('Account', new Map<String, Object>{
                'Identity_Number__c' => '6503255578087',
                'CIF_Number__c' => '100590934',
                'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID
        });
    }

    @IsTest
    static void testSyncMethod() {
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        Boolean isTestValid = true;

        Test.startTest();
        try {
            DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
            dsConnection.sync();
        } catch (Exception ex) {
            isTestValid = false;
        }
        Test.stopTest();

        System.assertEquals(true, isTestValid, 'Syncing tables not working, exception thrown.');
    }

    @IsTest
    static void productsExternalObjectsAreCreated1() {
        Test.setMock(HttpCalloutMock.class, new capitec_DataSourceProductsMockResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.tableSelected = 'Product';
        context.tableSelection.filter.columnName = 'ExternalId';
        context.tableSelection.filter.columnValue = '00000001935459277.100018459';

        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        Test.stopTest();

        System.assertEquals(1, tableResult.rows.size(), 'Rows are not correct created.');
    }

    @IsTest
    static void productsExternalObjectsAreCreated2() {
        Test.setMock(HttpCalloutMock.class, new capitec_DataSourceProductsMockResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.tableSelected = 'Product';
        context.tableSelection.filter.columnName = 'relatedAccount';
        context.tableSelection.filter.columnValue = '100018459';

        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        Test.stopTest();

        System.assertEquals(2, tableResult.rows.size(), 'Rows are not correct created.');
    }

    @IsTest
    static void productsExternalObjectsAreCreated3() {
        Test.setMock(HttpCalloutMock.class, new capitec_DataSourceProductsMockResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.filter.subfilters = new List<DataSource.Filter>{new DataSource.Filter()};
        context.tableSelection.tableSelected = 'Product';
        context.tableSelection.filter.subfilters[0].columnName = 'relatedAccount';
        context.tableSelection.filter.subfilters[0].columnValue = '100018459';

        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        Test.stopTest();

        System.assertEquals(2, tableResult.rows.size(), 'Rows are not correct created.');
    }

    @IsTest
    static void noFilterOnProductsExternalObjectsExceptionThrown() {
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.tableSelected = 'Product';
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            dsConnection.query(context);
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'No exception thrown as expected.');
    }

    @IsTest
    static void transactionHistoryExternalObjectsAreCreated1() {
        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceTHMockResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.filter.subfilters = new List<DataSource.Filter>{new DataSource.Filter(), new DataSource.Filter(), new DataSource.Filter()};
        context.tableSelection.tableSelected = 'TransactionHistory';
        context.tableSelection.filter.subfilters[0].columnName = 'accountNumber';
        context.tableSelection.filter.subfilters[0].columnValue = '1953752983';
        context.tableSelection.filter.subfilters[1].columnName = 'startDate';
        context.tableSelection.filter.subfilters[1].columnValue = String.valueOf(System.today()-31);
        context.tableSelection.filter.subfilters[2].columnName = 'endDate';
        context.tableSelection.filter.subfilters[2].columnValue = String.valueOf(System.today());

        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        Test.stopTest();

        System.assertEquals(1, tableResult.rows.size(), 'Rows are not correct created.');
    }

    @IsTest
    static void transactionHistoryExternalObjectsAreCreated2() {
        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceTHMockResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.tableSelected = 'TransactionHistory';
        context.tableSelection.filter.columnName = 'accountNumber';
        context.tableSelection.filter.columnValue = '1953752983';

        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        Test.stopTest();

        System.assertEquals(1, tableResult.rows.size(), 'Rows are not correct created.');
    }

    @IsTest
    static void noFilterOnTransactionHistoryExternalObjectsExceptionThrown() {
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.tableSelected = 'TransactionHistory';
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            dsConnection.query(context);
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'No exception thrown as expected.');
    }

    @IsTest
    static void cardHoldingExternalObjectsAreCreated1() {
        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceCHMockResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.filter.subfilters = new List<DataSource.Filter>{new DataSource.Filter()};
        context.tableSelection.tableSelected = 'CHolding';
        context.tableSelection.filter.subfilters[0].columnName = 'relatedAccount';
        context.tableSelection.filter.subfilters[0].columnValue = '100590934';


        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        Test.stopTest();

        System.assertEquals(4, tableResult.rows.size(), 'Rows are not correct created.');
    }

    @IsTest
    static void cardHoldingExternalObjectsAreCreated2() {
        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceCHMockResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.filter.subfilters = new List<DataSource.Filter>{new DataSource.Filter()};
        context.tableSelection.tableSelected = 'CHolding';
        context.tableSelection.filter.columnName = 'ExternalId';
        context.tableSelection.filter.columnValue = '5284 **** **** 5787.100590934';


        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        Test.stopTest();

        System.assertEquals(1, tableResult.rows.size(), 'Rows are not correct created.');
    }
    @IsTest
    static void cardHoldingExternalObjectsAreCreated3() {
        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceCHMockResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.filter.subfilters = new List<DataSource.Filter>{new DataSource.Filter()};
        context.tableSelection.tableSelected = 'CHolding';
        context.tableSelection.filter.columnName = 'relatedAccount';
        context.tableSelection.filter.columnValue = '100590934';


        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        Test.stopTest();

        System.assertEquals(4, tableResult.rows.size(), 'Rows are not correct created.');
    }
    @IsTest
    static void noFilterOnCardHoldingExternalObjectsExceptionThrown() {
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.tableSelected = 'CHolding';
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            dsConnection.query(context);
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'No exception thrown as expected.');
    }

    @IsTest
    static void riskScoreExternalObjectsAreCreated1() {
        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceRiskScoreMockResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.filter.subfilters = new List<DataSource.Filter>{new DataSource.Filter()};
        context.tableSelection.tableSelected = 'RiskScore';
        context.tableSelection.filter.subfilters[0].columnName = 'cifNumber';
        context.tableSelection.filter.subfilters[0].columnValue = '100590934';

        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        Test.stopTest();
        System.assertEquals(1, tableResult.rows.size(), 'Rows are not correct created.');
    }

    @IsTest
    static void riskScoreExternalObjectsAreCreated2() {
        Test.setMock(HttpCalloutMock.class, new Capitec_DataSourceRiskScoreMockResponse());
        Map<String, Object> riskResponse = new Map<String, Object>{
            'CDDDte' => '2024-01-01',
            'CDDScore' => '85',
            'CDDOutCome' => 'Low Risk',
            'PepYN' => 'No',
            'RiskFactorList' => new List<Object>{
                new Map<String, Object>{
                    'RF_Label' => 'Occupation[[OCCUP]]',
                    'RF_Score' => '90',
                    'RF_Value' => 'Engineer'
                },
                new Map<String, Object>{
                    'RF_Label' => 'NumOfSARs[[NUM]]',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
                },
                new Map<String, Object>{
                    'RF_Label' => 'Client Net Worth[[NUM]]',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
                },
                new Map<String, Object>{
                    'RF_Label' => 'Tenure',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
            },
                new Map<String, Object>{
                    'RF_Label' => 'Account Type[[ACCTCLASS]]',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                  new Map<String, Object>{
                    'RF_Label' => 'Ongoing Source of Funds[[FUND]]',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                   new Map<String, Object>{
                    'RF_Label' => 'Citizenship Country[[CTRY]]',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                new Map<String, Object>{
                    'RF_Label' => 'NumOfSARs[[NUM]]',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
                },
                   new Map<String, Object>{
                    'RF_Label' => 'Is PEP',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                   new Map<String, Object>{
                    'RF_Label' => 'Behavioural Risk Model',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                   new Map<String, Object>{
                    'RF_Label' => 'Industry',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                   new Map<String, Object>{
                    'RF_Label' => 'Onboarding Channel',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                   new Map<String, Object>{
                    'RF_Label' => 'Client Location',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                   new Map<String, Object>{
                    'RF_Label' => 'CRA_CLITpe',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                   new Map<String, Object>{
                    'RF_Label' => 'CRA_Nationality',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                   new Map<String, Object>{
                    'RF_Label' => 'CRA_SoF',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                   new Map<String, Object>{
                    'RF_Label' => 'CRA_Indust',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                  new Map<String, Object>{
                    'RF_Label' => 'CRA_Channel',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                  new Map<String, Object>{
                    'RF_Label' => 'CRA_PCde',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                  new Map<String, Object>{
                    'RF_Label' => 'CRA_IncBnd',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                  new Map<String, Object>{
                    'RF_Label' => 'CRA_EmpType',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              },
                  new Map<String, Object>{
                    'RF_Label' => 'CRA_Age',
                    'RF_Score' => '10',
                    'RF_Value' => '2'
              }
              }
        };
            
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.tableSelected = 'RiskScore';
        context.tableSelection.filter.columnName = 'cifNumber';
        context.tableSelection.filter.columnValue = '100590934';

        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        List<Map<String, Object>> rows = Capitec_DataSourceRiskScore.createRiskRowsList(riskResponse, context);
        Test.stopTest();

        System.assertEquals(1, tableResult.rows.size(), 'Rows are not correct created.');
    }

    @IsTest
    static void filterNotProvidedInConnectorExceptionThrown() {
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.tableSelected = 'Not Defined';

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            dsConnection.query(context);
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'No exception thrown as expected.');
    }

    @IsTest
    static void responseStatusCodeNot200() {
        Test.setMock(HttpCalloutMock.class, new capitec_DataSource404MockResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.tableSelected = 'Product';
        context.tableSelection.filter.columnName = 'ExternalId';
        context.tableSelection.filter.columnValue = '00000001935459277.100018459';

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            dsConnection.query(context);
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'No exception thrown as expected.');
    }

    @IsTest
    static void voucherListViewTest() {
        Test.setMock(HttpCalloutMock.class, new Capitec_CapitecDataSourceVouchersMock.listViewResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.filter.subfilters = new List<DataSource.Filter>{new DataSource.Filter()};
        context.tableSelection.tableSelected = 'CashSendVouchers';
        context.tableSelection.filter.subfilters[0].columnName = 'relatedAccount';
        context.tableSelection.filter.subfilters[0].columnValue = '121646688';

        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        Test.stopTest();

        System.assertEquals(20, tableResult.rows.size(), 'Rows created successfully');
    }

    @IsTest
    static void voucherDetailsViewTest() {
        Test.setMock(HttpCalloutMock.class, new Capitec_CapitecDataSourceVouchersMock.detailsViewResponse());
        DataSource.ConnectionParams connectionInfo = new DataSource.ConnectionParams();
        DataSource.Connection dsConnection = new capitec_CapitecDataSourceConnection(connectionInfo);
        DataSource.QueryContext context = new DataSource.QueryContext();
        //context.tableSelection.tableSelected = capitec_CapitecDataSourceConnection.PRODUCT;
        context.tableSelection = new DataSource.TableSelection();
        context.tableSelection.filter = new DataSource.Filter();
        context.tableSelection.filter.subfilters = new List<DataSource.Filter>{new DataSource.Filter()};
        context.tableSelection.tableSelected = 'CashSendVouchers';
        context.tableSelection.filter.columnName = 'ExternalId';
        context.tableSelection.filter.columnValue = 'C3157283767.121646688';

        Test.startTest();
        DataSource.TableResult tableResult = dsConnection.query(context);
        Test.stopTest();

        System.assertEquals(1, tableResult.rows.size(), 'Rows created successfully');
    }


}