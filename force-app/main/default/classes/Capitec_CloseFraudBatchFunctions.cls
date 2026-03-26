/**
 * Created by CalebGovender on 2024/11/07.
 */

public with sharing class Capitec_CloseFraudBatchFunctions {

    public static String FRAUD_ALERTS_BASE_SELECT_QUERY = 'SELECT Id, Subject, Status, Priority, CreatedDate FROM Case';
    public static String FRAUD_QUEUE_NAME = 'Fraud_Monitoring';


    public static String buildFraudAlerts() {

        String query = FRAUD_ALERTS_BASE_SELECT_QUERY + ' ' ;
        String sFraudMonitoringID  = [SELECT Id FROM Group WHERE Type='Queue' AND DeveloperName=:FRAUD_QUEUE_NAME].Id;
        String sDateTime = getFormattedDateTime();
        RecordType sFraudRecordType  = [SELECT Id FROM RecordType WHERE Name = 'Fraud Record Type' LIMIT 1];
        String sFraudCloseStatus = 'Not Fraud';
        String sMOrigin = 'Monitoring';

 
       
        query += 'WHERE Priority NOT IN (\'High\', \'Critical\')';
        query += ' AND OwnerId = \'' + sFraudMonitoringID + '\'';
        query += ' AND CreatedDate <= ' + sDateTime;
        query += ' AND RecordTypeId = \'' + sFraudRecordType.Id + '\'';
        query += ' AND Status != \'' + sFraudCloseStatus + '\'';
        query += ' AND Origin = \'' + sMOrigin + '\'';


        System.debug('Query: ' + query);
        return query;
    }

    public static String getFormattedDateTime() {
        Datetime now = Datetime.now();
        //two hours
        Datetime oneHourAgo = now.addHours(-2);

        String formattedDateTime = oneHourAgo.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        return formattedDateTime;
    }
}