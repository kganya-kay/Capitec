/**
 * @description Unit test class for Capitec_FlowGenerateNotification.
 * @author      Johan Langenhoven
 * @date        2024/10/15
 */
@IsTest(SeeAllData=false)
private class Capitec_FlowGenerateNotificationTest {

    /**
    * @description Tests the generateNotification method of Capitec_FlowGenerateNotification.
    */
    @IsTest
    static void testGenerateNotification() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Task testTask = new Task(
                WhatId = testAccount.Id,
                Subject = 'Test Task'
        );
        insert testTask;

        QuickText testQuickText = new QuickText(
                Name = 'Test QuickText',
                Message = 'Hello {!Account.Name}, welcome to our service!'
        );
        insert testQuickText;

        // Create request
        Capitec_FlowGenerateNotification.Request request = new Capitec_FlowGenerateNotification.Request();
        request.mergeRecordIds = new List<Id>{
                testAccount.Id
        };
        request.notificationTask = testTask;
        request.notificationTemplate = testQuickText;

        List<Capitec_FlowGenerateNotification.Request> requests = new List<Capitec_FlowGenerateNotification.Request>{
                request
        };

        // Start test context
        Test.startTest();

        // Call the method
        List<Capitec_FlowGenerateNotification.Response> responses = Capitec_FlowGenerateNotification.generateNotification(requests);

        // Stop test context
        Test.stopTest();

        Capitec_FlowGenerateNotification.Response response = responses[0];

        // Verify the results
        Assert.areEqual(1, responses.size());
        Assert.areEqual('Hello Test Account, welcome to our service!', response.templateMessage);
        Assert.areEqual(1, response.templateParameters.size());
        Assert.areEqual('Test Account', response.templateParameters[0]);
    }
}