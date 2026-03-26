@IsTest(SeeAllData=false)
private class Capitec_GetProactiveTemplatesTest {

    /**
    * @description Valid mock response.
    */
    private static final String VALID_RESPONSE = '{"proactives":[{"id":1092,"proactiveid":"855183699267598","proactivename":"atmdisputemoreinfo","proactivecontent":"Hello {{1}}, Regarding your dispute with Ref {{2}} we require additional information to investigate further, apologies for the inconvenience this may have caused. Rest assured we’ve started investigating and aims to resolve it as soon as we can. Please press the continue button below to get in-touch with an Agent. {{3}} is assist you with your request.","proactivevariables":["Client Name","Reference","Agent"],"proactiveheader":false,"proactivefooter":"","numberid":1,"cellphone":"27716880982","wabaid":"intwaba","salesForceVariables":["Account.Name","CaseNumber","Owner.Name"]}]}';

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
                Name = 'ProactiveTemplates',
                Scheme__c = 'callout:',
                Named_Credential__c = 'NC_ClientCommsDomain',
                Endpoint_URL__c = '/clientcomms/cps-proxy/getProactives'
        );
        insert webServiceSettings;
    }

    /**
 * @description Test method for successful execution of Capitec_GetProactiveTemplates.
 */
    @IsTest
    static void testSuccessfulExecution() {
        Test.setMock(HttpCalloutMock.class, new Capitec_GetProactiveTemplatesMock(VALID_RESPONSE, SUCCESS_STATUS_CODE));

        Test.startTest();

        Capitec_GetProactiveTemplates job = new Capitec_GetProactiveTemplates('4607223050');
        System.enqueueJob(job);

        Test.stopTest();

        System.assertNotEquals(null, job.proactivesResponseWrapper, 'Profile skills wrapper should not be null');
    }

    /**
     * @description Test method for handling API call failures.
     */
    @IsTest
    static void testFailureExecution() {
        Test.setMock(HttpCalloutMock.class, new Capitec_GetProactiveTemplatesMock(INVALID_RESPONSE, ERROR_STATUS_CODE));

        Capitec_GetProactiveTemplates job = new Capitec_GetProactiveTemplates('4607223050');

        Test.startTest();

        try {
            job.execute(null);
        } catch (Capitec_GetProactiveTemplates.GetProactiveTemplatesException ex) {
            System.assert(ex.getMessage().contains('Error occurred while retrieving proactive templates'), 'Expected error message to be present');
        }

        Test.stopTest();
    }
}