/**
 * @description Test class for Capitec_ProactiveMessagingController.
 * This class contains unit tests for the methods in Capitec_ProactiveMessagingController.
 * It tests both successful and error scenarios for fetching proactive skills, templates,
 * generating proactive messages, and initiating proactive messages.
 */
@IsTest(SeeAllData=false)
private class Capitec_ProactiveMessagingControllerTest {

    /**
     * @description Valid mock response for proactive skills.
     */
    private static final String VALID_SKILLS_RESPONSE = '{"profileSkills":[{"id":100,"profile":"System Administrator","skills":[{"id":134,"skillid":"5511468950","skillname":"Complaint"},{"id":135,"skillid":"4607223050","skillname":"Fraud"}]}]}';

    /**
     * @description Valid mock response for proactive templates.
     */
    private static final String VALID_TEMPLATES_RESPONSE = '{"proactives":[{"id":1092,"proactiveid":"855183699267598","proactivename":"atmdisputemoreinfo","proactivecontent":"Hello {{1}}, Regarding your dispute with Ref {{2}} we require additional information to investigate further, apologies for the inconvenience this may have caused. Rest assured we’ve started investigating and aims to resolve it as soon as we can. Please press the continue button below to get in-touch with an Agent. {{3}} is assist you with your request.","proactivevariables":["Client Name","Reference","Agent"],"proactiveheader":false,"proactivefooter":"","numberid":1,"cellphone":"27716880982","wabaid":"intwaba","salesForceVariables":["Account.Name","CaseNumber","Owner.Name"]}]}';

    /**
     * @description Valid mock response for initiating proactive messages.
     */
    private static final String VALID_INITIATE_RESPONSE = 'PMI call Successful. Message Push onto the Kafka Queue';

    /**
     * @description Invalid mock response for simulating errors.
     */
    private static final String INVALID_RESPONSE = 'Internal Server Error';

    /**
     * @description HTTP status code for successful responses.
     */
    private static final Integer SUCCESS_STATUS_CODE = 200;

    /**
     * @description HTTP status code for error responses.
     */
    private static final Integer ERROR_STATUS_CODE = 500;

    /**
     * @description Sets up test data for all test methods.
     * This includes creating WebServiceSettings__c records, an Account, and a Case.
     */
    @TestSetup
    static void setupTestData() {
        List<WebServiceSettings__c> webServiceSettings = new List<WebServiceSettings__c>();

        WebServiceSettings__c getSkills = new WebServiceSettings__c(
                Name = 'ProactiveSkills',
                Scheme__c = 'callout:',
                Named_Credential__c = 'NC_ClientCommsDomain',
                Endpoint_URL__c = '/clientcomms/cps-proxy/getSkills'
        );
        webServiceSettings.add(getSkills);

        WebServiceSettings__c getProactives = new WebServiceSettings__c(
                Name = 'ProactiveTemplates',
                Scheme__c = 'callout:',
                Named_Credential__c = 'NC_ClientCommsDomain',
                Endpoint_URL__c = '/clientcomms/cps-proxy/getProactives'
        );
        webServiceSettings.add(getProactives);

        WebServiceSettings__c initiate = new WebServiceSettings__c(
                Name = 'InitiateProactiveMessage',
                Scheme__c = 'callout:',
                Named_Credential__c = 'NC_ClientCommsDomain',
                Endpoint_URL__c = '/clientcomms/cps-proxy/initiate'
        );
        webServiceSettings.add(initiate);

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
    }

    /**
     * @description Tests the successful retrieval of proactive skills.
     * This test verifies that the getProactiveSkills method returns a successful response with data.
     */
    @IsTest
    static void testGetProactiveSkillsSuccess() {
        Test.setMock(HttpCalloutMock.class, new Capitec_GetProactiveSkillsMock(VALID_SKILLS_RESPONSE, SUCCESS_STATUS_CODE));

        Case testCase = [
                SELECT Id, CaseNumber, AccountId, Account.Name, ContactId, ContactEmail, ContactPhone
                FROM Case
                LIMIT 1
        ];

        Test.startTest();
        Capitec_ProactiveMessagingController.ProactiveMessagingWrapper result = Capitec_ProactiveMessagingController.getProactiveSkills(testCase.Id);
        Test.stopTest();

        System.assert(result.isSuccess, 'Expected the operation to be successful.');
        System.assertNotEquals(null, result.Data, 'Expected data to be returned.');
    }

    /**
     * @description Tests the handling of exceptions when retrieving proactive skills.
     * This test verifies that the getProactiveSkills method returns an error response when an exception occurs.
     */
    @IsTest
    static void testGetProactiveSkillsException() {
        Test.setMock(HttpCalloutMock.class, new Capitec_GetProactiveSkillsMock(INVALID_RESPONSE, ERROR_STATUS_CODE));

        Case testCase = [
                SELECT Id, CaseNumber, AccountId, Account.Name, ContactId, ContactEmail, ContactPhone
                FROM Case
                LIMIT 1
        ];

        Test.startTest();
        Capitec_ProactiveMessagingController.ProactiveMessagingWrapper result = Capitec_ProactiveMessagingController.getProactiveSkills(testCase.Id);
        Test.stopTest();

        System.assert(!result.isSuccess, 'Expected the operation to fail.');
        System.assertNotEquals(null, result.Message, 'Expected an error message.');
    }

    /**
     * @description Tests the successful retrieval of proactive templates.
     * This test verifies that the getProactiveTemplates method returns a successful response with data.
     */
    @IsTest
    static void testGetProactiveTemplatesSuccess() {
        Test.setMock(HttpCalloutMock.class, new Capitec_GetProactiveTemplatesMock(VALID_TEMPLATES_RESPONSE, SUCCESS_STATUS_CODE));

        Test.startTest();
        Capitec_ProactiveMessagingController.ProactiveMessagingWrapper result = Capitec_ProactiveMessagingController.getProactiveTemplates('5511468950');
        Test.stopTest();

        System.assert(result.isSuccess, 'Expected the operation to be successful.');
        System.assertNotEquals(null, result.Data, 'Expected data to be returned.');
    }

    /**
     * @description Tests the handling of exceptions when retrieving proactive templates.
     * This test verifies that the getProactiveTemplates method returns an error response when an exception occurs.
     */
    @IsTest
    static void testGetProactiveTemplatesException() {
        Test.setMock(HttpCalloutMock.class, new Capitec_GetProactiveTemplatesMock(INVALID_RESPONSE, ERROR_STATUS_CODE));

        Test.startTest();
        Capitec_ProactiveMessagingController.ProactiveMessagingWrapper result = Capitec_ProactiveMessagingController.getProactiveTemplates('5511468950');
        Test.stopTest();

        System.assert(!result.isSuccess, 'Expected the operation to fail.');
        System.assertNotEquals(null, result.Message, 'Expected an error message.');
    }

    /**
     * @description Tests the successful generation of a proactive message.
     * This test verifies that the generateProactiveMessage method returns a successful response with data.
     */
    @IsTest
    static void testGenerateProactiveMessageSuccess() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Capitec_GetProactiveTemplates.Proactive proactiveTemplate = new Capitec_GetProactiveTemplates.Proactive();
        proactiveTemplate.salesForceVariables = new List<String>{
                'CaseNumber'
        };
        proactiveTemplate.proactiveContent = 'Hello {CaseNumber}, this is a test message.';

        Test.startTest();
        Capitec_ProactiveMessagingController.ProactiveMessagingWrapper result = Capitec_ProactiveMessagingController.generateProactiveMessage(testCase.Id, JSON.serialize(proactiveTemplate));
        Test.stopTest();

        System.assert(result.isSuccess, 'Expected the operation to be successful.');
        System.assertNotEquals(null, result.Data, 'Expected data to be returned.');
    }

    /**
     * @description Tests the handling of exceptions when generating a proactive message.
     * This test verifies that the generateProactiveMessage method returns an error response when an exception occurs.
     */
    @IsTest
    static void testGenerateProactiveMessageException() {
        Test.startTest();
        Capitec_ProactiveMessagingController.ProactiveMessagingWrapper result = Capitec_ProactiveMessagingController.generateProactiveMessage(null, '{}');
        Test.stopTest();

        System.assert(!result.isSuccess, 'Expected the operation to fail.');
        System.assertNotEquals(null, result.Message, 'Expected an error message.');
    }

    /**
     * @description Tests the successful initiation of a proactive message.
     * This test verifies that the initiateProactiveMessage method returns a successful response.
     */
    @IsTest
    static void testInitiateProactiveMessageSuccess() {
        Test.setMock(HttpCalloutMock.class, new Capitec_InitiateProactiveMessageMock(VALID_INITIATE_RESPONSE, SUCCESS_STATUS_CODE));

        Case testCase = [
                SELECT Id, CaseNumber, AccountId, Account.Name, ContactId, ContactEmail, ContactPhone
                FROM Case
                LIMIT 1
        ];

        Capitec_ProactiveMessagingController.InitiateProactiveMessageWrapper proactiveMessageRequest = new Capitec_ProactiveMessagingController.InitiateProactiveMessageWrapper();
        proactiveMessageRequest.recordId = testCase.Id;
        proactiveMessageRequest.department = 'Sales';
        proactiveMessageRequest.teamName = 'Team A';
        proactiveMessageRequest.priority = 1;
        proactiveMessageRequest.type = 'Service';
        proactiveMessageRequest.outboundNumber = 'Client';
        proactiveMessageRequest.skill = '5511468950';
        proactiveMessageRequest.templateId = '855183699267598';
        proactiveMessageRequest.templateParameters = new List<String>{
                'CaseNumber'
        };
        proactiveMessageRequest.proactiveMessage = 'Hello, this is a test message.';

        Test.startTest();
        Capitec_ProactiveMessagingController.ProactiveMessagingWrapper result = Capitec_ProactiveMessagingController.initiateProactiveMessage(JSON.serialize(proactiveMessageRequest));
        Test.stopTest();

        System.assert(result.isSuccess, 'Expected the operation to be successful.');
        System.assertEquals('Message queued for sending.', result.Message, 'Expected the message to be queued for sending.');
    }

    /**
     * @description Tests the handling of exceptions when initiating a proactive message.
     * This test verifies that the initiateProactiveMessage method returns an error response when an exception occurs.
     */
    @IsTest
    static void testInitiateProactiveMessageException() {
        Test.setMock(HttpCalloutMock.class, new Capitec_InitiateProactiveMessageMock(INVALID_RESPONSE, ERROR_STATUS_CODE));

        Test.startTest();
        Capitec_ProactiveMessagingController.ProactiveMessagingWrapper result = Capitec_ProactiveMessagingController.initiateProactiveMessage('{}');
        Test.stopTest();

        System.assert(!result.isSuccess, 'Expected the operation to fail.');
        System.assertNotEquals(null, result.Message, 'Expected an error message.');
    }
}