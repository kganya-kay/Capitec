/**
* @description Test class for Capitec_FlowNotification.
*/
@IsTest(SeeAllData=false)
private class Capitec_FlowCommunicationsDomainTest {
    /**
    * @description Valid mock response for successful notification.
    */
    private static final String VALID_RESPONSE = '{"id":"8639d391-d169-4d91-9cd4-e87c9947e594","responseDateTime":"2023-04-13T13:56:57.853875464+02:00","correlationId":"5afe0f07-9c14-4523-a910-b31bc16b71da","errorCode":null,"errorDescription":null,"success":true}';

    /**
    * @description HTTP status code for successful response.
    */
    private static final Integer SUCCESS_STATUS_CODE = 200;

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
                Template_Id__c = '123',
                Message = 'Hello {!Account.FirstName}, welcome to our service!',
                RecordTypeId = Schema.getGlobalDescribe().get('QuickText').getDescribe().getRecordTypeInfosByDeveloperName().get('Notification_Template').getRecordTypeId()
        );
        insert testQuickText;

        Account testAccount = new Account
                (
                        FirstName = 'John',
                        LastName = 'Doe',
                        PersonEmail = 'john.doe@example.com',
                        Phone = '+271234567',
                        RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
                );
        insert testAccount;
    }

    /**
    * @description Test method for successful notification.
    */
    @IsTest
    static void testSuccessfulNotification() {

        Test.setMock(HttpCalloutMock.class, new Capitec_CommunicationsDomainMock(VALID_RESPONSE, SUCCESS_STATUS_CODE));

        Account testAccount = [SELECT Id, FirstName, LastName, PersonContactId, PersonEmail, Phone FROM Account WHERE PersonEmail = 'john.doe@example.com' LIMIT 1];

        Test.startTest();

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
                Phone_Number__c = '+27123456789',
                Template_Id__c = '123',
                Delivery_Channel__c = 'Sms',
                CIF_Number__c = '123456789',
                Source_System__c = 'Salesforce',
                RecordTypeId = Schema.getGlobalDescribe().get('Task').getDescribe().getRecordTypeInfosByDeveloperName().get('Notification_Task').getRecordTypeId()
        );
        insert testTask;

        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable'];
        Assert.areEqual(1, jobs.size(), 'One job should be enqueued');
    }
}