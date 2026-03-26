/**
 * @description Test class for the `Capitec_InitiateProactiveMessage` queueable class.
 * This class tests the functionality of initiating proactive messages, including
 * successful and failed HTTP callouts, phone number formatting, and template parameter creation.
 */
@IsTest(SeeAllData=false)
private class Capitec_InitiateProactiveMessageTest {

    /**
     * @description Valid mock response for a successful proactive message initiation.
     */
    private static final String VALID_RESPONSE = 'PMI call Successful. Message Push onto the Kafka Queue';

    /**
     * @description Invalid mock response for a failed proactive message initiation.
     */
    private static final String INVALID_RESPONSE = 'Internal Server Error';

    /**
     * @description HTTP status code for a successful response.
     */
    private static final Integer SUCCESS_STATUS_CODE = 200;

    /**
     * @description HTTP status code for a failed response (e.g., internal server error).
     */
    private static final Integer ERROR_STATUS_CODE = 500;

    /**
     * @description Setup method to create test data for all test methods.
     * This method initializes the following:
     * - WebServiceSettings__c custom setting for the proactive messaging service.
     * - Test Account (PersonAccount) with contact details.
     * - Test Case associated with the Account.
     * - Test InteractionSummary record for the proactive message.
     */
    @TestSetup
    static void setupTestData() {
        WebServiceSettings__c webServiceSettings = new WebServiceSettings__c(
                Name = 'InitiateProactiveMessage',
                Scheme__c = 'callout:',
                Named_Credential__c = 'NC_ClientCommsDomain',
                Endpoint_URL__c = '/clientcomms/cps-proxy/initiate'
        );
        insert webServiceSettings;

        ProactiveMessagingSettings__c proactiveMessagingSettings = new ProactiveMessagingSettings__c();
        proactiveMessagingSettings.Route_to_Agent_Skill__c = 'RouteToAgentINT';
        proactiveMessagingSettings.SetupOwnerId = UserInfo.getOrganizationId();
        insert proactiveMessagingSettings;

        Account testAccount = new Account(
                FirstName = 'John',
                LastName = 'Deer',
                PersonEmail = 'john.doe@example.com',
                Phone = '+271234567',
                RecordTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
        );
        insert testAccount;

        Case testCase = new Case(
                Subject = 'Test Case',
                AccountId = testAccount.Id,
                ContactId = testAccount.PersonContactId
        );
        insert testCase;

        InteractionSummary testInteractionSummary = new InteractionSummary(
                Name = 'Test Interaction Summary',
                AccountId = testAccount.Id,
                InteractionPurpose = 'Test Purpose',
                Status = 'Pending',
                RelatedRecordId = testCase.Id,
                Skill__c = 'Test Skill',
                Template_Id__c = 'Test Template',
                Department__c = 'Test Department',
                Type__c = 'Service',
                Priority__c = 1,
                Campaign__c = 'Test Campaign',
                Team__c = 'Test Team',
                Outbound_Number__c = 'Employee',
                RecordTypeId = Capitec_ProactiveMessagingController.proactiveMessageInteractionSummaryRecordTypeId
        );
        insert testInteractionSummary;
    }

    /**
     * @description Tests the successful execution of the `Capitec_InitiateProactiveMessage` queueable job.
     * This test simulates a successful HTTP callout and verifies that the InteractionSummary record
     * is updated with the correct status, status code, and integration response.
     */
    @IsTest
    static void testExecuteSuccess() {
        Test.setMock(HttpCalloutMock.class, new Capitec_InitiateProactiveMessageMock(VALID_RESPONSE, SUCCESS_STATUS_CODE));

        Case testCase = [
                SELECT Id, CaseNumber, AccountId, Account.Name, ContactId, ContactEmail, ContactPhone
                FROM Case
                LIMIT 1
        ];

        InteractionSummary testInteractionSummary = [
                SELECT Id, Name, AccountId, InteractionPurpose, Status, InteractionId, RelatedRecordId,
                        Skill__c, Fallback_Skill__c, Fallback_Skill_Id__c, ConfidentialityType, Template_Id__c, Department__c, Type__c, Priority__c,
                        Campaign__c, Team__c, Outbound_Number__c, MeetingNotes, RecordTypeId
                FROM InteractionSummary
                LIMIT 1
        ];

        User testUser = [
                SELECT Id, Name, Email, Profile.Name, SmallPhotoUrl
                FROM User
                WHERE Id = :UserInfo.getUserId()
        ];

        Capitec_InitiateProactiveMessage queueable = new Capitec_InitiateProactiveMessage(
                new List<String>{
                        'CaseNumber', 'Account.Name'
                },
                testInteractionSummary,
                testCase,
                testUser
        );

        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();

        InteractionSummary updatedInteractionSummary = [
                SELECT Status, Status_Code__c, Integration_Response__c
                FROM InteractionSummary
                WHERE Id = :testInteractionSummary.Id
        ];

        System.assertEquals('Completed', updatedInteractionSummary.Status, 'Expected status to be "Completed".');
        System.assertEquals(200, updatedInteractionSummary.Status_Code__c, 'Expected status code to be 200.');
        System.assertNotEquals(null, updatedInteractionSummary.Integration_Response__c, 'Expected integration response to be populated.');
    }

    /**
     * @description Tests the failure scenario of the `Capitec_InitiateProactiveMessage` queueable job.
     * This test simulates a failed HTTP callout and verifies that the InteractionSummary record
     * is updated with the correct status, status code, and integration response.
     */
    @IsTest
    static void testExecuteFailure() {
        Test.setMock(HttpCalloutMock.class, new Capitec_InitiateProactiveMessageMock(INVALID_RESPONSE, ERROR_STATUS_CODE));

        Case testCase = [
                SELECT Id, CaseNumber, AccountId, Account.Name, ContactId, ContactEmail, ContactPhone
                FROM Case
                LIMIT 1
        ];

        InteractionSummary testInteractionSummary = [
                SELECT Id, Name, AccountId, InteractionPurpose, Status, InteractionId, RelatedRecordId,
                        Skill__c, Fallback_Skill__c, Fallback_Skill_Id__c, ConfidentialityType, Template_Id__c, Department__c, Type__c, Priority__c,
                        Campaign__c, Team__c, Outbound_Number__c, MeetingNotes, RecordTypeId
                FROM InteractionSummary
                LIMIT 1
        ];

        User testUser = [
                SELECT Id, Name, Email, Profile.Name, SmallPhotoUrl
                FROM User
                WHERE Id = :UserInfo.getUserId()
        ];

        Capitec_InitiateProactiveMessage queueable = new Capitec_InitiateProactiveMessage(
                new List<String>{
                        'CaseNumber', 'AccountId'
                },
                testInteractionSummary,
                testCase,
                testUser
        );

        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();

        InteractionSummary updatedInteractionSummary = [
                SELECT Status, Status_Code__c, Integration_Response__c
                FROM InteractionSummary
                WHERE Id = :testInteractionSummary.Id
        ];

        System.assertEquals('Failed', updatedInteractionSummary.Status, 'Expected status to be "Failed".');
        System.assertEquals(500, updatedInteractionSummary.Status_Code__c, 'Expected status code to be 500.');
        System.assertNotEquals(null, updatedInteractionSummary.Integration_Response__c, 'Expected integration response to be populated.');
    }

    /**
     * @description Tests the `formatPhoneNumber` method to ensure it correctly formats
     * a local phone number to an international format.
     */
    @IsTest
    static void testFormatPhoneNumber() {
        String formattedNumber = Capitec_InitiateProactiveMessage.formatPhoneNumber('0123456789');
        System.assertEquals('+27123456789', formattedNumber, 'Expected phone number to be formatted to international format.');

        String unchangedNumber = Capitec_InitiateProactiveMessage.formatPhoneNumber('+27123456789');
        System.assertEquals('+27123456789', unchangedNumber, 'Expected phone number to remain unchanged.');
    }

    /**
     * @description Tests the `createTemplateParameters` method to ensure it correctly
     * creates a list of template parameters in the required format.
     */
    @IsTest
    static void testCreateTemplateParameters() {
        List<Map<String, String>> templateParameters = Capitec_InitiateProactiveMessage.createTemplateParameters(
                new List<String>{
                        'Param1', 'Param2'
                }
        );

        System.assertEquals(2, templateParameters.size(), 'Expected 2 template parameters.');
        System.assertEquals('1', templateParameters[0].get('key'), 'Expected key to be "1".');
        System.assertEquals('Param1', templateParameters[0].get('value'), 'Expected value to be "Param1".');
        System.assertEquals('2', templateParameters[1].get('key'), 'Expected key to be "2".');
        System.assertEquals('Param2', templateParameters[1].get('value'), 'Expected value to be "Param2".');
    }
}