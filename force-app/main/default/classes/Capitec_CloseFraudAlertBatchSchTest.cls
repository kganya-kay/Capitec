@IsTest
public class Capitec_CloseFraudAlertBatchSchTest {
    private static final String FRAUD_RECORD_TYPE_ID = Schema.getGlobalDescribe()
        .get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Fraud_Record_Type').getRecordTypeId();
    private static User adminUser ;
    @TestSetup
    static void setupTestData() {
        // Fetch the Fraud Monitoring queue
        Group fraudQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Fraud_Monitoring' AND Type = 'Queue' LIMIT 1];

        // Create a test user to bypass the validation rule
        adminUser = new User(
            FirstName = 'Admin',
            LastName = 'User',
            Alias = 'admusr',
            Email = 'admin.user@example.com',
            Username = 'admin.user+' + System.currentTimeMillis() + '@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            EmployeeNumber = 'CT123456'
        );
        insert adminUser;

        // Use System.runAs to insert test cases as the Admin User
        System.runAs(adminUser) {
            List<Case> testCases = new List<Case>();
            for (Integer i = 0; i < 1; i++) {
                testCases.add(new Case(
                    Subject = 'Fraud Alert ' + i,
                    Status = 'New', // Allowed initial status
                    Priority = 'Low', // Not 'High' or 'Critical'
                    OwnerId = fraudQueue.Id,
                    RecordTypeId = FRAUD_RECORD_TYPE_ID,
                    Origin = 'Monitoring'
                ));
            }
            insert testCases;

            // Adjust CreatedDate to meet the query condition
            for (Case cs : testCases) {
                Test.setCreatedDate(cs.Id, Datetime.now().addHours(-3)); // Older than 2 hours
            }
        }
    }

    @IsTest
    static void testBatchExecutionWithBypass() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];

        // Execute as the admin user
        System.runAs(adminUser) {
            Test.startTest();

            // Execute the batch
            Capitec_CloseFraudAlertsBatch batch = new Capitec_CloseFraudAlertsBatch();
            Database.executeBatch(batch, 1); 

            Test.stopTest();

            // Verify that records are updated
            List<Case> updatedCases = [SELECT Id, Status FROM Case WHERE Status = 'Not Fraud'];
            Assert.areEqual(1, updatedCases.size(), 'All cases should have their status updated to "Not Fraud".');
        }
    }
       @isTest
    static void testCloseFraudAlertsBatchScheduler() {
        // Create an instance of the scheduler class
        Capitec_CloseFraudAlertsBatchScheduler scheduler = new Capitec_CloseFraudAlertsBatchScheduler();
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];

        // Execute as the admin user
        System.runAs(adminUser) {

            Test.startTest();
            // Execute the scheduled job
            scheduler.execute(null);
            Test.stopTest();
        }

    }
}