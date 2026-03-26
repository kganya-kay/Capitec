@IsTest
public with sharing class capitec_AWS_CTI_Test {
        @isTest
        public static void testGetCurrentUserId() {
            // Set up test data if needed, e.g., creating a user, etc.
            // In this case, we are testing the current user's ID, so we don't need extra setup.

            // Create an instance of the class
            capitec_AWS_CTI awsCTI = new capitec_AWS_CTI();
            
            // Get the current user ID
            String currentUserId = awsCTI.getCurrentUserId();
            
            // Assert that the current user ID matches the expected user ID
            String expectedUserId = UserInfo.getUserId(); // This retrieves the actual current user's ID.
            System.assertEquals(expectedUserId, currentUserId, 'The current user ID returned should match the expected user ID.');

    }
}