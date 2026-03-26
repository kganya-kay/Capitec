/**
 * Created by CalebGovender on 2024/09/13.
 */

@IsTest
public class Capitec_BadBeneficiariesTest {

    @IsTest
    static void testMakePostCallout() {
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new Capitec_BadBeneficiariesMockResponses.MockHttpResponseGenerator());

        String endpoint = 'https://example.com/api';
        String payload = '{"key":"value"}';

        HttpResponse res = Capitec_BadBeneficiariesCalloutHandler.makeUpdateCallout(endpoint, payload,'PUT');

        System.assertEquals(200, res.getStatusCode(), 'Status code should be 200');
        System.assertEquals('{"response":"success"}', res.getBody(), 'Response body should match the mock response');
    }

    @IsTest
    static void testConstructURL() {
        String endpoint = '/endpoint';
        String parameters = '?param=value';

        String constructedURL = Capitec_BadBeneficiariesCalloutHandler.constructURL(endpoint, parameters);

        System.assertEquals('callout:CapiEndpoints/endpoint?param=value', constructedURL, 'Constructed URL should match the expected format');
    }

    @IsTest
    static void testGetBadBadBeneficiary() {
        Test.setMock(HttpCalloutMock.class, new Capitec_BadBeneficiariesMockResponses.GetBadBeneficiaries());
        Map<String, Object> result = Capitec_BadBeneficiariesController.getBadBadBeneficiary('1', '2024-09-01', '2024-09-10', 'PENDING_FRAUD');
        //Map<String, Object> expectedresult = new Map<String, Object>{JSON.deserialize(Capitec_BadBeneficiariesMockResponses.FullJSON)};
        //System.assertEquals(expectedresult, result, 'Result should match jsonBadBen');

        result = Capitec_BadBeneficiariesController.getBadBadBeneficiary('2', '2024-09-01', '2024-09-10', 'PENDING_FRAUD');
        //System.assertEquals(Capitec_BadBeneficiariesMockResponses.FullJSON, result, 'Result should match jsonMultiBadBen');
    }

    @IsTest
    static void testPostUpdateBeneficiaryStatus() {
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new Capitec_BadBeneficiariesMockResponses.MockHttpResponseGenerator());

        String response = Capitec_BadBeneficiariesController.putUpdateBeneficiaryStatus('62783236336','PENDING_FRAUD','UNKNOWN');

        System.assertEquals('200', response, 'Response should match the mock response');
    }

    @IsTest
    static void testGetBadBeneficiaries_Success() {
        // Mock the HTTP response for a successful call
        Test.setMock(HttpCalloutMock.class, new Capitec_BadBeneficiariesMockResponses.GetBadBeneficiaries());

        String result = Capitec_BadBeneficiariesCalloutHandler.getBadBeneficiaries('1234567890', '2024-09-01', '2024-09-10', 'PENDING_FRAUD');
        System.debug(result);
        System.assert(result.contains('"error" : false'), 'The response should indicate no error.');
        System.assert(result.contains('"statusCode" : 200'), 'The response should have a status code of 200.');
    }

    @IsTest
    static void testGetBadBeneficiaries_NoBadBeneficiaries() {
        // Mock the HTTP response for no bad beneficiaries
        Test.setMock(HttpCalloutMock.class, new Capitec_BadBeneficiariesMockResponses.EmptyBadBeneficiaries());

        String result = Capitec_BadBeneficiariesCalloutHandler.getBadBeneficiaries('1234567890', '2024-09-01', '2024-09-10', 'PENDING_FRAUD');
        System.debug(result);
        System.assert(result.contains('"error" : true'), 'The response should indicate an error.');
        System.assert(result.contains('"statusCode" : "400"'), 'The response should have a status code of 400.');
        System.assert(result.contains('There are no Bad Beneficiaries associated with this Account Number'), 'The response should contain the appropriate error message.');
    }

    @IsTest
    static void testGetBadBeneficiaries_UnexpectedError() {
        // Mock the HTTP response for an unexpected error
        Test.setMock(HttpCalloutMock.class, new Capitec_BadBeneficiariesMockResponses.FailedGetCAResponse());

        String result = Capitec_BadBeneficiariesCalloutHandler.getBadBeneficiaries('1234567890', '2024-09-01', '2024-09-10', 'PENDING_FRAUD');
        System.assert(result.contains('"error" : true'), 'The response should indicate an error.');
        System.assert(result.contains('"statusCode" : "500"'), 'The response should have a status code of 500.');
        System.assert(result.contains('An unexpected error has occurred, please try again later'), 'The response should contain the appropriate error message.');
    }

        @IsTest
    static void testUploadBadBeneficiaries_Success() {

        String endpoint = 'https://example.com/api';
        String payload = '[[{"identifier":"9392373617","identifierType":"ACCOUNT_NUMBER","institution":"ABSA","fraudStatus":"APPROVED","defaultBranchCode":"28164"}]';

        // Mock the HTTP response for a successful call
        Test.setMock(HttpCalloutMock.class, new Capitec_BadBeneficiariesMockResponses.UploadBadBeneficiaries());

        String result = Capitec_BadBeneficiariesController.uploadAndPostData(payload);
        System.debug('Capitec_BadBeneficiariesController result '+ result);
        System.assert(result.contains('204'), 'The response should have a status code of 204.');
    }

    @isTest
    static void testIsUserInPermissionSet_UserInPermissionSet() {
        // Create a test user
        User testUser = createTestUser();
        System.runAs(testUser) {
            // Create a mock permission set
            PermissionSet testPermissionSet = new PermissionSet(
                Name = 'Test_Permission_Set',
                Label = 'Test Permission Set'
            );
            insert testPermissionSet;

            // Assign the permission set to the test user
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = testUser.Id,
                PermissionSetId = testPermissionSet.Id
            );
            insert psa;

            // Call the method and assert the result
            Test.startTest();
            Boolean result = Capitec_BadBeneficiariesController.isUserInPermissionSet('Test_Permission_Set');
            Test.stopTest();

            System.assert(result, 'The method should return true because the user is assigned to the permission set.');
        }
    }

    @isTest
    static void testIsUserInPermissionSet_UserNotInPermissionSet() {
        // Create a test user
        User testUser = createTestUser();
        System.runAs(testUser) {
            // Create a mock permission set (not assigned to the user)
            PermissionSet testPermissionSet = new PermissionSet(
                Name = 'Unassigned_Permission_Set',
                Label = 'Unassigned Permission Set'
            );
            insert testPermissionSet;

            // Call the method and assert the result
            Test.startTest();
            Boolean result = Capitec_BadBeneficiariesController.isUserInPermissionSet('Unassigned_Permission_Set');
            Test.stopTest();

            System.assert(!result, 'The method should return false because the user is not assigned to the permission set.');
        }
    }


    // Helper method to create a test user
    private static User createTestUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
    }


}