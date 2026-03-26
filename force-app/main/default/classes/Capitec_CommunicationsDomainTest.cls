/**
* @description Test class for Capitec_CommunicationsDomain.
*/
@IsTest(SeeAllData=false)
private class Capitec_CommunicationsDomainTest {
    /**
    * @description Valid mock response for successful notification.
    */
    private static final String VALID_RESPONSE = '{"id":"8639d391-d169-4d91-9cd4-e87c9947e594","responseDateTime":"2023-04-13T13:56:57.853875464+02:00","correlationId":"5afe0f07-9c14-4523-a910-b31bc16b71da","errorCode":null,"errorDescription":null,"success":true}';

    /**
    * @description Invalid mock response for failed notification.
    */
    private static final String INVALID_RESPONSE = '{"timestamp":"2023-05-23T08:08:41.074+00:00","status":400,"error":"BadRequest","path":"/v1/notify"}';

    /**
    * @description HTTP status code for successful response.
    */
    private static final Integer SUCCESS_STATUS_CODE = 200;

    /**
    * @description HTTP status code for bad request response.
    */
    private static final Integer BAD_REQUEST_STATUS_CODE = 400;

    /**
    * @description Setup test data for the test methods.
    * Inserts a WebServiceSettings__c record with the endpoint URL.
    */
    @TestSetup
    static void setupTestData() {
        WebServiceSettings__c webServiceSettings = new WebServiceSettings__c(
                Name = 'NotificationService',
                Scheme__c = 'callout:',
                Named_Credential__c = 'NC_ClientCommsDomain',
                Endpoint_URL__c = '/clientcomms/notification-service/notification/v1/notify'
        );
        insert webServiceSettings;

        QuickText testQuickText = new QuickText(
                Name = 'Test QuickText',
                Template_Id__c = '124',
                Message = 'Hello {!Account.FirstName}, welcome to our service!',
                RecordTypeId = Schema.getGlobalDescribe().get('QuickText').getDescribe().getRecordTypeInfosByDeveloperName().get('Notification_Template').getRecordTypeId()
        );
        insert testQuickText;

        Account testAccount = new Account
                (
                        FirstName = 'John',
                        LastName = 'Deer',
                        PersonEmail = 'john.doe@example.com',
                        Phone = '+271234567',
                        RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
                );
        insert testAccount;

        Task testTask = new Task(
                Subject = 'Client Notification (SMS)',
                OwnerId = UserInfo.getUserId(),
                WhatId = testAccount.Id,
                WhoId = testAccount.PersonContactId,
                Type = 'Notification',
                Priority = 'Normal',
                ActivityDate = System.today(),
                TaskSubtype = 'Task',
                Status = 'Completed',
                Phone_Number__c = '07123456789',
                Template_Id__c = '124',
                Delivery_Channel__c = 'Sms',
                CIF_Number__c = '123456789',
                Source_System__c = 'Salesforce',
                RecordTypeId = Schema.getGlobalDescribe().get('Task').getDescribe().getRecordTypeInfosByDeveloperName().get('Notification_Task').getRecordTypeId()
        );
        insert testTask;
    }

    /**
    * @description Test method for successful execution of the notification.
    * Mocks a successful HTTP response and verifies that the job is enqueued.
    */
    @IsTest
    static void testExecuteSuccessful() {

        Test.setMock(HttpCalloutMock.class, new Capitec_CommunicationsDomainMock(VALID_RESPONSE, SUCCESS_STATUS_CODE));

        Task notificationTask = [SELECT Id, Template_Id__c, Phone_Number__c, Delivery_Channel__c, CIF_Number__c, Source_System__c FROM Task WHERE Subject = 'Client Notification (SMS)' LIMIT 1];

        List<String> templateParams = new List<String>{
                'Param1', 'Param2'
        };

        Capitec_CommunicationsDomain notification = new Capitec_CommunicationsDomain(notificationTask, templateParams);

        Test.startTest();

        System.enqueueJob(notification);

        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable'];
        Assert.areEqual(2, jobs.size(), 'Two jobs should be enqueued');
    }

    /**
    * @description Test method for failed execution of the notification.
    * Mocks a failed HTTP response and verifies that the job is enqueued.
    */
    @IsTest
    static void testExecuteFailed() {

        Test.setMock(HttpCalloutMock.class, new Capitec_CommunicationsDomainMock(INVALID_RESPONSE, BAD_REQUEST_STATUS_CODE));

        Task notificationTask = [SELECT Id, Template_Id__c, Phone_Number__c, Delivery_Channel__c, CIF_Number__c, Source_System__c FROM Task WHERE Subject = 'Client Notification (SMS)' LIMIT 1];

        List<String> templateParams = new List<String>{
                'Param1', 'Param2'
        };

        Capitec_CommunicationsDomain notification = new Capitec_CommunicationsDomain(notificationTask, templateParams);

        Test.startTest();

        System.enqueueJob(notification);

        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable'];
        Assert.areEqual(2, jobs.size(), 'One job should be enqueued');
    }
}