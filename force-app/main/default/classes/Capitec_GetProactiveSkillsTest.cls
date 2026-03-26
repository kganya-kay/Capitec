/**
 * @description Unit test class for Capitec_GetProactiveSkills using Capitec_GetProactiveSkillsMock.
 */
@IsTest(SeeAllData=false)
private class Capitec_GetProactiveSkillsTest {

    /**
    * @description Valid mock response.
    */
    private static final String VALID_RESPONSE = '{"profileSkills":[{"id":100,"profile":"System Administrator","skills":[{"id":134,"skillid":"5511468950","skillname":"Complaint"},{"id":135,"skillid":"4607223050","skillname":"Fraud"}]}]}';

    /**
    * @description Invalid mock response.
    */
    private static final String INVALID_RESPONSE = 'Internal Server Error';

    /**
    * @description HTTP status code for successful response.
    */
    private static final Integer SUCCESS_STATUS_CODE = 200;

    /**
    * @description HTTP status code for bad request response.
    */
    private static final Integer ERROR_STATUS_CODE = 500;

    /**
    * @description Setup test data for the test methods.
    * Inserts a WebServiceSettings__c record with the endpoint URL.
    */
    @TestSetup
    static void setupTestData() {
        WebServiceSettings__c webServiceSettings = new WebServiceSettings__c(
                Name = 'ProactiveSkills',
                Scheme__c = 'callout:',
                Named_Credential__c = 'NC_ClientCommsDomain',
                Endpoint_URL__c = '/clientcomms/cps-proxy/getSkills'
        );
        insert webServiceSettings;
    }

    /**
     * @description Test method for successful execution of Capitec_GetProactiveSkills.
     */
    @IsTest
    static void testSuccessfulExecution() {
        Test.setMock(HttpCalloutMock.class, new Capitec_GetProactiveSkillsMock(VALID_RESPONSE, SUCCESS_STATUS_CODE));

        Test.startTest();

        Capitec_GetProactiveSkills job = new Capitec_GetProactiveSkills('System Administrator');
        System.enqueueJob(job);

        Test.stopTest();

        System.assertNotEquals(null, job.profileSkillsWrapper, 'Profile skills wrapper should not be null');
    }

    /**
     * @description Test method for handling API call failures.
     */
    @IsTest
    static void testFailureExecution() {
        Test.setMock(HttpCalloutMock.class, new Capitec_GetProactiveSkillsMock(INVALID_RESPONSE, ERROR_STATUS_CODE));

        Capitec_GetProactiveSkills job = new Capitec_GetProactiveSkills('System Administrator');

        Test.startTest();

        try {
            job.execute(null);
        } catch (Capitec_GetProactiveSkills.GetProactiveSkillsException ex) {
            System.assert(ex.getMessage().contains('Error occurred while retrieving proactive skills'), 'Expected error message to be present');
        }

        Test.stopTest();
    }
}