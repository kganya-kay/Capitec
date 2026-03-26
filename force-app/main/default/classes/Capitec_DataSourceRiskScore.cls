/**
 * Created by dawid on 17.04.2023.
 * Updated As Kandula Added CRA Fields 16th Nov 2024 - RCS-3707  AML CRA Onboarding RB - EDD Workflow Salesforce
 */

 public with sharing class Capitec_DataSourceRiskScore {
    private static final String URL_RISK_SCORE = 'get-cra-edd/';
    private static final String CIF_FIELD_NAME = 'relatedAccount';
    private static final String CIF_PARAMETER = 'cifNumber=';
//    private static final String EXTERNAL_ID_PARAMETER = 'cifNumber=';
    private static final String IDENTITY_PARAMETER = 'idNumber=';
    private static final String URL_SUFFIX = ('correlationID='+'5008E00000MmPBUQA3'+'&eventDateTime='+String.valueOf(System.today())+'&sourceSys=SALESFORCE');

    public static List<DataSource.Column> createRiskScoreColumns() {
        List<DataSource.Column> riskScoreColumns = new List<DataSource.Column>();

        riskScoreColumns.add(DataSource.Column.indirectLookup('relatedAccount', 'Account', 'CIF_Number__c'));
        riskScoreColumns.add(DataSource.Column.text('lastRADate', 255));
        riskScoreColumns.add(DataSource.Column.text('clientRiskScore', 255));
        riskScoreColumns.add(DataSource.Column.text('riskLevel', 255));
        riskScoreColumns.add(DataSource.Column.text('clientWithSARs', 255));
        riskScoreColumns.add(DataSource.Column.text('occupation', 255));
        riskScoreColumns.add(DataSource.Column.text('clientNetWorth', 255));
        riskScoreColumns.add(DataSource.Column.text('behaviouralRiskModel', 255)); // not mapped
        riskScoreColumns.add(DataSource.Column.text('tenure', 255));
        riskScoreColumns.add(DataSource.Column.text('accountType', 255));
        riskScoreColumns.add(DataSource.Column.text('ongoingSoF', 255));
        riskScoreColumns.add(DataSource.Column.text('citizenshipCountry', 255));
        riskScoreColumns.add(DataSource.Column.text('confirmedPEP', 255));
        riskScoreColumns.add(DataSource.Column.text('industry', 255)); //not mapped but prob: CRA_Indust
        riskScoreColumns.add(DataSource.Column.text('onboardingChannel', 255)); //not mapped but prob: CRA_Channel
        riskScoreColumns.add(DataSource.Column.text('clientLocation', 255)); //not mapped
        riskScoreColumns.add(DataSource.Column.text('sourceOfFundsValue', 255)); //not mapped
        riskScoreColumns.add(DataSource.Column.text('clientNetWorthValue', 255)); //not mapped
        riskScoreColumns.add(DataSource.Column.text('tenureValue', 255));
        riskScoreColumns.add(DataSource.Column.text('accountTypeValue', 255));
        riskScoreColumns.add(DataSource.Column.text('clientWithSARsValue', 255));
        riskScoreColumns.add(DataSource.Column.text('citizenshipCountryValue', 255));
        riskScoreColumns.add(DataSource.Column.text('occupationValue', 255));
        riskScoreColumns.add(DataSource.Column.text('industryValue', 255)); 
        riskScoreColumns.add(DataSource.Column.text('onboardingChannelValue', 255)); 
        riskScoreColumns.add(DataSource.Column.text('behaviouralRiskModelValue', 255)); 
        riskScoreColumns.add(DataSource.Column.text('clientLocationValue', 255)); 
        riskScoreColumns.add(DataSource.Column.text('confirmedPEPValue', 255));       
        riskScoreColumns.add(DataSource.Column.text('PepYN', 255)); 
		//CRA Fields - RCS-3707  AML CRA Onboarding RB - EDD Workflow Salesforce
			riskScoreColumns.add(DataSource.Column.text('crariskLevel', 255));
        	riskScoreColumns.add(DataSource.Column.text('crariskscore', 255));
        	riskScoreColumns.add(DataSource.Column.text('cradate', 255));
        return riskScoreColumns;
    }

    public static List<Map<String, Object>> createRiskRowsList(Map<String, Object> riskResponse, DataSource.QueryContext context) {
       //System.debug('Riskresponse--->'+JSON.serializePretty(riskResponse));
        List<Map<String, Object>> rows = new List<Map<String, Object>>();

        String cifNumber;
        if(context.tableSelection.filter.subfilters == null){
            cifNumber = String.valueOf(context.tableSelection.filter.columnValue);
        }
        else{
            for(DataSource.Filter subfilter : context.tableSelection.filter.subfilters){
                if(subfilter.columnName.contains(CIF_FIELD_NAME)){
                    cifNumber = String.valueOf(subfilter.columnValue);
                }
            }
        }

        Map<String, Object> createdRow = new Map<String, Object>();

        createdRow.put('lastRADate', riskResponse.get('CDDDte'));
        createdRow.put('clientRiskScore', String.valueOf(riskResponse.get('CDDScore')));
        createdRow.put('riskLevel', riskResponse.get('CDDOutCome'));
        createdRow.put('PepYN', riskResponse.get('PepYN'));
        createdRow.put('ExternalId', cifNumber);
        createdRow.put('relatedAccount', cifNumber);
        //CRA Fields - RCS-3707  AML CRA Onboarding RB - EDD Workflow Salesforce
         createdRow.put('crarisklevel', riskResponse.get('CRAOutCome'));
         createdRow.put('crariskscore', riskResponse.get('CRAScore'));
         createdRow.put('cradate', riskResponse.get('CRADte'));
        
        for (Object row : (List<Object>)riskResponse.get('RiskFactorList')) {
            createdRow = (createRiskColumn((Map<String, Object>)row, createdRow));
        }

        rows.add(createdRow);
        return rows;
    }

    public static Map<String, Object> createRiskColumn(Map<String, Object> riskNode, Map<String, Object> row) {

            switch on String.valueOf(riskNode.get('RF_Label')) {
                when 'NumOfSARs[[NUM]]'{
                    row.put('clientWithSARs', String.valueOf(riskNode.get('RF_Score')));
                    row.put('clientWithSARsValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Occupation[[OCCUP]]'{
                    row.put('occupation', String.valueOf(riskNode.get('RF_Score')));
                    row.put('occupationValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Client Net Worth[[NUM]]'{
                    row.put('clientNetWorth', String.valueOf(riskNode.get('RF_Score')));
                    row.put('clientNetWorthValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Tenure'{
                    row.put('tenure', String.valueOf(riskNode.get('RF_Score')));
                    row.put('tenureValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Account Type[[ACCTCLASS]]'{
                    row.put('accountType', String.valueOf(riskNode.get('RF_Score')));
                    row.put('accountTypeValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Ongoing Source of Funds[[FUND]]'{
                    row.put('ongoingSoF', String.valueOf(riskNode.get('RF_Score')));
                    row.put('sourceOfFundsValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Citizenship Country[[CTRY]]'{
                    row.put('citizenshipCountry', String.valueOf(riskNode.get('RF_Score')));
                    row.put('citizenshipCountryValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Num Of SARs[[NUM]]'{
                    row.put('clientWithSARs', String.valueOf(riskNode.get('RF_Score')));
                    row.put('clientWithSARsValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Behavioural Risk Model'{
                    row.put('behaviouralRiskModel', String.valueOf(riskNode.get('RF_Score')));
                    row.put('behaviouralRiskModelValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Is PEP'{
                    row.put('confirmedPEP', String.valueOf(riskNode.get('RF_Score')));
                    row.put('confirmedPEPValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Industry'{
                    row.put('industry', String.valueOf(riskNode.get('RF_Score')));
                    row.put('industryValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Onboarding Channel'{
                    row.put('onboardingChannel', String.valueOf(riskNode.get('RF_Score')));
                    row.put('onboardingChannelValue', String.valueOf(riskNode.get('RF_Value')));
                }
                when 'Client Location'{
                    row.put('clientLocation', String.valueOf(riskNode.get('RF_Score')));
                    row.put('clientLocationValue', String.valueOf(riskNode.get('RF_Value')));
                } 
                //RCS-3707  AML CRA Onboarding RB - EDD Workflow Salesforce
                when 'CRA_CLITpe'{
                    row.put('craclitypevalue', String.valueOf(riskNode.get('RF_Value')));
                    //row.put('craclitypesource', String.valueOf(riskNode.get('RF_Source')));
                    row.put('craclitypescore', String.valueOf(riskNode.get('RF_Score')));
                }
                when 'CRA_Nationality'{
                    row.put('cranationalityvalue', String.valueOf(riskNode.get('RF_Value')));
                    //row.put('cranationalitysource', String.valueOf(riskNode.get('RF_Source')));
                    //row.put('cranationalityscore', String.valueOf(riskNode.get('RF_Score')));
                }
                when 'CRA_SoF'{
                    row.put('crasofvalue', String.valueOf(riskNode.get('RF_Value')));
                    //row.put('crasofsource', String.valueOf(riskNode.get('RF_Source')));
                    row.put('crasofscore', String.valueOf(riskNode.get('RF_Score')));
                }
                 when 'CRA_Indust'{
                    row.put('craindvalue', String.valueOf(riskNode.get('RF_Value')));
                    //row.put('craindsource', String.valueOf(riskNode.get('RF_Source')));
                    row.put('craindscore', String.valueOf(riskNode.get('RF_Score')));
                }
                when 'CRA_Channel'{
                    row.put('crachannelvalue', String.valueOf(riskNode.get('RF_Value')));
                    //row.put('crachannelsource', String.valueOf(riskNode.get('RF_Source')));
                    row.put('crachannelscore', String.valueOf(riskNode.get('RF_Score')));
                }
                when 'CRA_PCde'{
                    row.put('crapcdevalue', String.valueOf(riskNode.get('RF_Value')));
                    //row.put('crapcdesource', String.valueOf(riskNode.get('RF_Source')));
                    row.put('crapcdescore', String.valueOf(riskNode.get('RF_Score')));
                }
                when 'CRA_IncBnd'{
                    row.put('craincvalue', String.valueOf(riskNode.get('RF_Value')));
                    //row.put('craincsource', String.valueOf(riskNode.get('RF_Source')));
                    row.put('craincscore', String.valueOf(riskNode.get('RF_Score')));
                }
                when 'CRA_Age'{
                    row.put('craagevalue', String.valueOf(riskNode.get('RF_Value')));
                    //row.put('craagesource', String.valueOf(riskNode.get('RF_Source')));
                    row.put('craagescore', String.valueOf(riskNode.get('RF_Score')));
                }
                when 'CRA_EmpType'{
                    row.put('craempvalue', String.valueOf(riskNode.get('RF_Value')));
                    //row.put('craempsource', String.valueOf(riskNode.get('RF_Source')));
                    row.put('craempscore', String.valueOf(riskNode.get('RF_Score')));
                }
            }
        return row;
    }



    public static String getRiskScoreUrl(DataSource.Filter filter) {
        Account temp = [SELECT id FROM Account LIMIT 1];
        String composedURL = URL_RISK_SCORE + '?';
        if(filter == null){
            return composedURL;
        }
        if(filter.subfilters != null){
           // System.debug('---InIFBlock--');
            for(DataSource.Filter subfilter : filter.subfilters){
                if(subfilter.columnName.contains(CIF_FIELD_NAME)){
                  Account acc = [SELECT Id, Identity_Number__c FROM Account WHERE CIF_Number__c =: String.valueOf(subfilter.columnValue) LIMIT 1];
                    composedURL += CIF_PARAMETER + subfilter.columnValue + '&';
                    composedURL += IDENTITY_PARAMETER + acc.Identity_Number__c + '&';
                    composedURL += URL_SUFFIX;
                }
            }
        }
        else{
         //    System.debug('---InElseBlock--');
            Account acc = [SELECT Id, Identity_Number__c FROM Account WHERE CIF_Number__c =: String.valueOf(filter.columnValue) LIMIT 1];
            composedURL += CIF_PARAMETER + filter.columnValue + '&';
            composedURL += IDENTITY_PARAMETER + acc.Identity_Number__c + '&';
            composedURL += URL_SUFFIX;
        }
       // System.debug('ComposedURL-->'+composedURL);
        return composedURL;
    }
}