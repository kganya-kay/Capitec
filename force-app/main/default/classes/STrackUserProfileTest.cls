@isTest
private class STrackUserProfileTest {
    @testSetup
    static void setupTestData() {
        // Create a test profile
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create a test user with the selected profile
        User testUser = new User(
            Alias = 'testusr',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'usercliente@example.com'
        );
        insert testUser;
    }

    @isTest
    static void testGetCurrentUserProfile() {
        // Run as the test user
        User testUser = [SELECT Id, Profile.Name FROM User WHERE UserName = 'usercliente@example.com' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            String profileName = STrackUserProfile.getCurrentUserProfile();
            System.assertNotEquals(null, profileName, 'Profile name should not be null');
            System.assertEquals(testUser.Profile.Name, profileName, 'Profile name should match test user’s profile');
        }
        Test.stopTest();
    }
}