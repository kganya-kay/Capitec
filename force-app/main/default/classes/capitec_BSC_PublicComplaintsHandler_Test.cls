@IsTest
public class capitec_BSC_PublicComplaintsHandler_Test {
    static final String STATUS_NEW = 'New';
    static final String STATUS_IN_PROGRESS = 'In-Progress';
    static final String STATUS_AWAITING_CLIENT_FEEDBACK = 'Awaiting Client Feedback';
    static final String COMPLEXITY_COMPLEX = 'Complex';
    static final String COMPLEXITY_NON_COMPLEX = 'Non-Complex';
    static final String CMO_ROLE = 'Complaints_Management_Officer_CMO';
    static final String CMO_PROFILE = 'Complaints Management Officer';
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    static final Id CASE_RETAIL_COMPLAINTS_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Retail_Complaints').getRecordTypeId();
    
    @TestSetup
    static void setupData() {
        Profile profileComplaintsManagementOfficer = [SELECT Id FROM Profile WHERE Name =: CMO_PROFILE LIMIT 1];
        UserRole cmoUserRole = [SELECT Id FROM UserRole WHERE DeveloperName =: CMO_ROLE LIMIT 1];

        // Ensure both profile and role are found
        System.assertNotEquals(profileComplaintsManagementOfficer, null, 'Profile not found: ' + CMO_PROFILE);
        System.assertNotEquals(cmoUserRole, null, 'User role not found: ' + CMO_ROLE);
        
        Group generalComplaintsQueue = [SELECT Id FROM Group WHERE Name = 'General Complaints' AND Type = 'Queue'];

        // Required fields for User
        String defaultEmail = '@test.com';
        String defaultTimeZoneSidKey = 'America/Los_Angeles';
        String defaultLocaleSidKey = 'en_US';
        String defaultEmailEncodingKey = 'UTF-8';
        String defaultLanguageLocaleKey = 'en_US';

        // Create User objects with all required fields populated
        List<User> userList = new List<User>{
            new User(Alias = 'cons1', LastName = 'Consultant1', Email = 'test1234dupa1abc' + defaultEmail, 
                     ProfileId = profileComplaintsManagementOfficer.Id, UserRoleId = cmoUserRole.Id, 
                     TimeZoneSidKey = defaultTimeZoneSidKey, LocaleSidKey = defaultLocaleSidKey, 
                     EmailEncodingKey = defaultEmailEncodingKey, LanguageLocaleKey = defaultLanguageLocaleKey,
                     Username = 'test1234dupa1abc' + defaultEmail,
                     FirstName = 'Test1', isActive=true), // Add FirstName field
             
            new User(Alias = 'cons2', LastName = 'Consultant2', Email = 'test1234dupa1def' + defaultEmail, 
                     ProfileId = profileComplaintsManagementOfficer.Id, UserRoleId = cmoUserRole.Id, 
                     TimeZoneSidKey = defaultTimeZoneSidKey, LocaleSidKey = defaultLocaleSidKey, 
                     EmailEncodingKey = defaultEmailEncodingKey, LanguageLocaleKey = defaultLanguageLocaleKey,
                     Username = 'test1234dupa1def' + defaultEmail,
                     FirstName = 'Test2', isActive=true) // Add FirstName field
        };
                
        // Insert user records
        insert userList;

        // Ensure users are inserted and active
        System.assertEquals(userList.size(), [SELECT COUNT() FROM User WHERE Id IN :userList AND isActive = true], 'User records not inserted properly or not active');

        // Now we have the Ids from inserted users, we can run System.runAs
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];

        // Create account and entitlement in context of first active user
        System.runAs(userList[0]) {
            Account acc = new Account(
                RecordTypeId = PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                CIF_Number__c = '123456789',
                Identity_Number__c = '7101180046087',
                LastName = 'TestAccount' // Ensure LastName is set for Person Account
            );
            insert acc;

            Entitlement entit = new Entitlement(
                StartDate = Date.today().addDays(-1),
                EndDate = Date.today().addYears(90),
                Name = 'Complaints Management',
                BusinessHoursId = bh.Id,
                AccountId = acc.Id
            );
            insert entit;

            List<Case> caseListGeneralComplaintsAwaiting = new List<Case>{
                new Case(
                    Status = STATUS_AWAITING_CLIENT_FEEDBACK,
                    CM_Complexity__c = COMPLEXITY_NON_COMPLEX,
                    BusinessHoursId = bh.Id,
                    OwnerId = generalComplaintsQueue.Id,
                    RecordTypeId = CASE_RETAIL_COMPLAINTS_RECORD_TYPE_ID,
                    CM_Date_of_Event__c = Date.today().addDays(-2),
                    EntitlementId = entit.Id
                ),
                new Case(
                    Status = STATUS_AWAITING_CLIENT_FEEDBACK,
                    CM_Complexity__c = COMPLEXITY_NON_COMPLEX,
                    BusinessHoursId = bh.Id,
                    OwnerId = generalComplaintsQueue.Id,
                    RecordTypeId = CASE_RETAIL_COMPLAINTS_RECORD_TYPE_ID,
                    CM_Date_of_Event__c = Date.today().addDays(-2),
                    EntitlementId = entit.Id
                )
            };
            insert caseListGeneralComplaintsAwaiting;

            List<Case> caseListGeneralComplaintsInProgress = new List<Case>{
                new Case(
                    Status = STATUS_IN_PROGRESS,
                    CM_Complexity__c = COMPLEXITY_NON_COMPLEX,
                    BusinessHoursId = bh.Id,
                    OwnerId = generalComplaintsQueue.Id,
                    RecordTypeId = CASE_RETAIL_COMPLAINTS_RECORD_TYPE_ID,
                    CM_Date_of_Event__c = Date.today().addDays(-2),
                    EntitlementId = entit.Id
                ),
                new Case(
                    Status = STATUS_IN_PROGRESS,
                    CM_Complexity__c = COMPLEXITY_NON_COMPLEX,
                    BusinessHoursId = bh.Id,
                    OwnerId = generalComplaintsQueue.Id,
                    RecordTypeId = CASE_RETAIL_COMPLAINTS_RECORD_TYPE_ID,
                    CM_Date_of_Event__c = Date.today().addDays(-2),
                    EntitlementId = entit.Id
                )
            };
            insert caseListGeneralComplaintsInProgress;
        }
    }

    @IsTest
    static void createPublicComplaintTest() {
        // Query for users that were inserted in the test setup
        List<User> userList = [SELECT Id FROM User WHERE Profile.Name =: CMO_PROFILE AND isActive = true];

        // Ensure there's at least one active user
        System.assert(!userList.isEmpty(), 'No active users found with profile: ' + CMO_PROFILE);
        
        // Use System.runAs with the first inserted active user
        System.runAs(userList[0]) {
            List<Case> lstCase = [SELECT Id, AccountId, Type, Description, Subject, Email_Address__c, Priority, Status FROM Case WHERE Status =: STATUS_IN_PROGRESS];

            Test.startTest();
            capitec_BSC_PublicComplaintsHandler.createPublicComplaintsFromFlow(lstCase);
            List<PublicComplaint> lstPublicComplaint = [SELECT Id FROM PublicComplaint];
            System.assertNotEquals(lstPublicComplaint, null, 'Public complaints list is null');
            System.assertEquals(lstCase.size(), lstPublicComplaint.size(), 'The number of public complaints should match the number of cases.');
            Test.stopTest();
        }
    }
}