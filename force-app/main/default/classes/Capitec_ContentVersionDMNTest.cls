/**
* Created by dawid on 22.06.2023.
*/
@IsTest
public with sharing class Capitec_ContentVersionDMNTest {

    static final String STATUS_OPEN = 'Open';
    static final String STATUS_DECISION = 'Decision';
    static final String STATUS_NEW = 'New';
    static final String STATUS_ACTIVE = 'Active';
    static final String STATUS_FRAUD = 'Fraud';
    static final String STATUS_ACTIVE_INVESTIGATION = 'Active Investigation UTD';
    static final String STATUS_AWAITING_APPROVAL = 'Awaiting Sign Off';
    static final String SUBSTATUS_NOT_YET_STARTED = 'Not Yet Started';
    static final String SUBSTATUS_MAINTAIN = 'Maintain - Review Complete';
    static final String SUBSTATUS_REVIEW_COMPLETE = 'Awaiting Sign Off: Review Complete';
    private static final String ORIGIN_MANUAL = 'Manual';
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    static final Id CASE_AML_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('AML_Record_Type').getRecordTypeId();
    static final Id CASE_FRAUD_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Fraud_Record_Type').getRecordTypeId();
    //COCONV-2125 - Samiirah Aujub
    static Id CASE_CONVERSIONS_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();

    @TestSetup
    static void setupData() {

        Profile profileConsultant = [SELECT Id FROM Profile WHERE Name = 'Consultant' LIMIT 1];
        Profile profileTeamLead = [SELECT Id FROM Profile WHERE Name = 'Team Lead' LIMIT 1];
        UserRole consAMLUr = [SELECT Id FROM UserRole WHERE DeveloperName = :capitec_CaseDMN.CONSULTANT_DEVNAME LIMIT 1];
        Group fraudInvestigationQueue = [SELECT Id FROM Group WHERE Name = 'Fraud Investigation' AND Type = 'Queue'];

        List<User> userList = TestDataFactory.createSObjectList('User', new Map<String, Object>{
                'Alias' => new List<String>{
                        'cons', 'cons2'
                },
                'ProfileId' => profileConsultant.Id,
                'Username' => new List<String>{
                        'test1234dupa1abc@test.com', 'test1234dupa1def@test.com'
                },
                'UserRoleId' => consAMLUr.Id
        }, 2);

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc = (Account) TestDataFactory.createSObject('Account', new Map<String, Object>{
                    'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                    'CIF_Number__c' => '123456789',
                    'Identity_Number__c' => '7101180046087'
            });

            Entitlement entit = (Entitlement) TestDataFactory.createSObject('Entitlement', new Map<String, Object>{
                    'StartDate' => Date.today(),
                    'EndDate' => Date.today().addYears(90),
                    'Name' => 'AML Full Case SLA',
                    'BusinessHoursId' => bh.Id,
                    'AccountId' => acc.Id
            });

            List<Case> caseList = TestDataFactory.createSObjectList('Case', new Map<String, Object>{
                    'Status' => STATUS_OPEN,
                    'Sub_Status__c' => SUBSTATUS_NOT_YET_STARTED,
                    'BusinessHoursId' => bh.Id,
                    'OwnerId' => userList[0].Id,
                    'Last_Consultant__c' => userList[0].Id
            }, 10);

            List<Case> caseListFraud = TestDataFactory.createSObjectList('Case', new Map<String, Object>{
                    'Status' => STATUS_FRAUD,
                    'BusinessHoursId' => bh.Id,
                    'OwnerId' => fraudInvestigationQueue.Id,
                    'RecordTypeId' => CASE_FRAUD_RECORD_TYPE_ID
            }, 10);
        }
    }

    @IsTest
    static void testAttachmentUpload() {

        Test.setMock(HttpCalloutMock.class, new Capitec_DocumentumMock.correctResponse());
        Case tempCase = [SELECT Id FROM Case LIMIT 1];

        ContentVersion tempCV = new ContentVersion();
        tempCV.Title = 'TestingCV';
        tempCV.PathOnClient = 'TestingCV';
        tempCV.FirstPublishLocationId = tempCase.Id;
        tempCV.VersionData = Blob.valueOf('some text.txt');

        Database.SaveResult saveResult = Database.insert(tempCV);
        System.assertEquals(saveResult.success, true);
    }

    //ICS-203 - START
    // This utility method creates a fake ContentVersion for testing purposes
    private static ContentVersion createFakeContentVersion(Id caseId) {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.txt'; // The file name. This must include the file extension
        cv.VersionData = Blob.valueOf('Test Content'); // Your version data here
        cv.FirstPublishLocationId = caseId; // This is the id of the related record
        return cv;
    }

    // This utility method creates a fake ContentVersion for testing purposes
    private static ContentVersion createFakeContentVersionEmailMessage(Id emailMessageId) {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.txt'; // The file name. This must include the file extension
        cv.VersionData = Blob.valueOf('Test Content'); // Your version data here
        cv.FirstPublishLocationId = emailMessageId; // This is the id of the related record
        return cv;
    }

    // This method tests the createNewDocumentChecklistRecord functionality
    @IsTest
    static void testCreateNewDocumentChecklistRecord() {

        Test.setMock(HttpCalloutMock.class, new Capitec_DocumentumMock.correctResponse());

        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();

        Case c = new Case(
                Subject = 'Test Case - ICS-225',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                IC_Type__c = 'Unemployment/ITEI',
                Sub_Type__c = 'Retrenchment',
                Sub_Type_Reason__c = 'New Technology',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Credit Life'
        );
        insert c;


        // Query for a Case since we need a Case record to associate with the ContentVersion
        Case relatedCase = [SELECT Id, RecordType.Name FROM Case WHERE Subject = 'Test Case - ICS-225' LIMIT 1];
        // Create a fake ContentVersion associated with the Case record
        ContentVersion contentVersion = createFakeContentVersion(relatedCase.Id);
        // Insert the ContentVersion to simulate the upload
        insert contentVersion;
        // Generate a fake documentumId
        String documentumId = 'dummyId';

        // Now we simulate calling the method we want to test
        DocumentChecklistItem createdItem = Capitec_ContentVersionDMN.createNewDocumentChecklistRecord(relatedCase, contentVersion, documentumId);

        // Insert the created DocumentChecklistItem to persist it into the database
        insert createdItem;

        // Retrieve the inserted DocumentChecklistItem for verification
        DocumentChecklistItem retrievedItem = [SELECT Id, Name, IC_Documentum_ID__c, ParentRecordId FROM DocumentChecklistItem WHERE Id = :createdItem.Id];

        // Verify that the DocumentChecklistItem has been created with the correct data
        System.assertEquals(documentumId, retrievedItem.IC_Documentum_ID__c, 'The documentumId should match the one provided');
        System.assertEquals(relatedCase.Id, retrievedItem.ParentRecordId, 'The ParentRecordId should be set to the related Case Id');
        System.assertEquals(contentVersion.Title, retrievedItem.Name, 'The Name of the checklist item should be the same as the content version title');
    }

    @IsTest
    static void testCreateNewDocumentChecklistRecord2() {

        Test.setMock(HttpCalloutMock.class, new Capitec_DocumentumMock.correctResponse());

        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();

        Case c = new Case(
                Subject = 'Test Case - ICS-203',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                IC_Type__c = 'Unemployment/ITEI',
                Sub_Type__c = 'Retrenchment',
                Sub_Type_Reason__c = 'New Technology',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Credit Life'
        );
        insert c;

        EmailMessage em = new EmailMessage(
                Subject = 'TEST EMAIL',
                FromAddress = 'test@test.com',
                Status = '1',
                FromName = 'Test Name',
                Incoming = true,
                RelatedToId = c.Id
        );
        insert em;

        // Query for a Case since we need a Case record to associate with the ContentVersion
        Case relatedCase = [SELECT Id, RecordType.Name FROM Case WHERE Subject = 'Test Case - ICS-203' LIMIT 1];
        // Create a fake ContentVersion associated with the Case record
        ContentVersion contentVersion = createFakeContentVersionEmailMessage(em.Id);
        // Insert the ContentVersion to simulate the upload
        insert contentVersion;
        // Generate a fake documentumId
        String documentumId = 'dummyId';

        // Now we simulate calling the method we want to test
        DocumentChecklistItem createdItem = Capitec_ContentVersionDMN.createNewDocumentChecklistRecord(c, contentVersion, documentumId);

        // Insert the created DocumentChecklistItem to persist it into the database
        insert createdItem;

        // Retrieve the inserted DocumentChecklistItem for verification
        DocumentChecklistItem retrievedItem = [SELECT Id, Name, IC_Documentum_ID__c, ParentRecordId FROM DocumentChecklistItem WHERE Id = :createdItem.Id];

        // Verify that the DocumentChecklistItem has been created with the correct data
        System.assertEquals(documentumId, retrievedItem.IC_Documentum_ID__c, 'The documentumId should match the one provided');
        System.assertEquals(relatedCase.Id, retrievedItem.ParentRecordId, 'The ParentRecordId should be set to the related Case Id');
        System.assertEquals(contentVersion.Title, retrievedItem.Name, 'The Name of the checklist item should be the same as the content version title');
    }
    //ICS-203 END


    //COCONV-2125 - Samiirah Aujub
     @IsTest
    static void testDuplicationCheck(){
        Case testCase = new Case(Subject = 'Test Case',
                                 Status = 'In Progress',
                                 Origin = 'Branch',
                                 RecordTypeId = CASE_CONVERSIONS_RECORDID
                                );
        insert testCase;

        ContentVersion contentVersion = createFakeContentVersion(testCase.Id);
        insert contentVersion;

        Test.startTest();
                try {
                        ContentVersion duplicateContentVersion = createFakeContentVersion(testCase.Id);
                        insert duplicateContentVersion;
                } catch (Exception e) {
                System.assert(
                        e.getMessage().contains('A file with the same name already exists on this Case.'),
                                                'Expected duplication error message.'
                        );
                }
        Test.stopTest();

    }

}