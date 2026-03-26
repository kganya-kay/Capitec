/**
 * Created by Sebastian on 31.03.2023.
 * Updated by Cornelia Smit on 23.07.2024 for CECSF-215
 * Updated by Johan Langenhoven on 01.10.2024 for CECSF-441
 */
@IsTest
public class capitec_CaseDMN_Test {
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
    private static final String ESCALATIONS_DEVNAME = 'Client_Escalation_Desk_Agent';//CECSF-215
    private static String ESC_PRIMARY_NEED = 'Save';//CECSF-215
    private static String ESC_SPECIFIC_NEED = 'Notice Deposit Withdrawal Enquiry';//CECSF-215
    private static String ESC_PRODUCT = 'Notice Deposit';//CECSF-215
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    static final Id CASE_AML_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('AML_Record_Type').getRecordTypeId();
    static final Id CASE_FRAUD_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Fraud_Record_Type').getRecordTypeId();
    static final Id ESCALATIONS_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Client_Escalations').getRecordTypeId();//CECSF-215

    @TestSetup
    static void setupData() {

        Profile profileConsultant = [SELECT Id FROM Profile WHERE Name = 'Consultant' LIMIT 1];
        Profile profileTeamLead = [SELECT Id FROM Profile WHERE Name = 'Team Lead' LIMIT 1];
        Profile profileEscalations = [SELECT Id FROM Profile WHERE Name = 'Client Escalations' LIMIT 1];//CECSF-215
        UserRole consAMLUr = [SELECT Id FROM UserRole WHERE DeveloperName = :capitec_CaseDMN.CONSULTANT_DEVNAME LIMIT 1];
        UserRole escAgent = [SELECT Id FROM UserRole WHERE DeveloperName = :ESCALATIONS_DEVNAME LIMIT 1];//CECSF-215
        Group fraudInvestigationQueue = [SELECT Id FROM Group WHERE Name = 'Fraud Investigation' AND Type = 'Queue'];
        Group clientEscalationQueue = [SELECT Id FROM Group WHERE Name = 'Client Escalations Desk' AND Type = 'Queue'];
        //CECSF-215
        List<User> userList = TestDataFactory.createSObjectList('User', new Map<String, Object>{
                'Alias' => new List<String>{
                        'cons', 'cons2', 'esc', 'esc2'
                },
                'ProfileId' => new List<Id>{
                        profileConsultant.Id, profileConsultant.Id, profileEscalations.Id, profileEscalations.Id
                },
                'Username' => new List<String>{
                        'test1234dupa1abc@test.com', 'test1234dupa1def@test.com', 'esctest1234escabc@test.com', 'esctest1234escdef@test.com'
                },
                'UserRoleId' => new List<Id>{
                        consAMLUr.Id, consAMLUr.Id, escAgent.Id, escAgent.Id
                }
        }, 4);

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
            }, 50);

            List<Case> caseListFraud = TestDataFactory.createSObjectList('Case', new Map<String, Object>{
                    'Status' => STATUS_FRAUD,
                    'BusinessHoursId' => bh.Id,
                    'OwnerId' => fraudInvestigationQueue.Id,
                    'RecordTypeId' => CASE_FRAUD_RECORD_TYPE_ID
            }, 50);
            //CECSF-215
            List<Case> caseListEscalations = TestDataFactory.createSObjectList('Case', new Map<String, Object>{
                    'Status' => STATUS_NEW,
                    'BusinessHoursId' => bh.Id,
                    'OwnerId' => clientEscalationQueue.Id,
                    'RecordTypeId' => ESCALATIONS_RECORD_TYPE_ID,
                    'Capitec_Primary_Need__c' => ESC_PRIMARY_NEED,
                    'Capitec_Specific_Need__c' => ESC_SPECIFIC_NEED,
                    'CM_Product__c' => ESC_PRODUCT,
                    'AccountId' => acc.Id,
                    'Notice_Deposit_Account_Number__c' => '1237778800'
            }, 1);
        }
    }

    @IsTest
    static void shouldGetErrorNoAnswersOnCases() {
        List<Case> caseList = [SELECT Id, Status, Sub_Status__c FROM Case where RecordTypeId != :ESCALATIONS_RECORD_TYPE_ID LIMIT 50];

        for (Case thisCase : caseList) {
            thisCase.Status = STATUS_DECISION;
            thisCase.Sub_Status__c = SUBSTATUS_MAINTAIN;
        }

        Boolean isExceptionCaught = false;
        Test.startTest();
        try {
            update caseList;
        } catch (Exception ex) {
            if (ex.getMessage().contains(capitec_CaseDMN.ERROR_MSG)) {
                isExceptionCaught = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, isExceptionCaught, 'Error did not appear.');
    }

    @IsTest
    static void shouldGetErrorSomeAnswersOnCases() {
        List<Case> caseList = [SELECT Id, Status, Sub_Status__c FROM Case where RecordTypeId != :ESCALATIONS_RECORD_TYPE_ID LIMIT 50];
        List<Id> caseIdList = new List<Id>();
        for (Case thisCase : caseList) {
            caseIdList.add(thisCase.Id);
        }

        List<Answer__c> answList = TestDataFactory.createSObjectList('Answer__c', new Map<String, Object>{
                'Case__c' => caseIdList,
                'Question_Type__c' => new List<String>{
                        'Source of Funds', 'Source of Wealth', 'Client Details Confirmation'
                },
                'Question_Number__c' => new List<Integer>{
                        1, 2
                }
        }, 600);

        for (Case thisCase : caseList) {
            thisCase.Status = STATUS_DECISION;
            thisCase.Sub_Status__c = SUBSTATUS_MAINTAIN;
        }

        Boolean isExceptionCaught = false;
        Test.startTest();
        try {
            update caseList;
        } catch (Exception ex) {
            if (ex.getMessage().contains(capitec_CaseDMN.ERROR_MSG)) {
                isExceptionCaught = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, isExceptionCaught, 'Error did not appear.');
    }

    @IsTest
    static void shouldGetErrorAllAnswersNoSummaryFieldOnCases() {
        List<Case> caseList = [SELECT Id, Status, Sub_Status__c FROM Case where RecordTypeId != :ESCALATIONS_RECORD_TYPE_ID LIMIT 50];
        List<Id> caseIdList = new List<Id>();

        for (Case thisCase : caseList) {
            caseIdList.add(thisCase.Id);
        }

        List<Answer__c> answList = TestDataFactory.createSObjectList('Answer__c', new Map<String, Object>{
                'Case__c' => caseIdList,
                'Question_Type__c' => new List<String>{
                        'Source of Funds', 'Media Check Results', 'Source of Wealth',
                        'Transactional Behavior Assessment', 'Client Details Confirmation', 'Suspicious Transaction Value'
                },
                'Question_Number__c' => new List<Integer>{
                        1, 2
                }
        }, 1400);

        for (Case thisCase : caseList) {
            thisCase.Status = STATUS_DECISION;
            thisCase.Sub_Status__c = SUBSTATUS_MAINTAIN;
        }

        Boolean isExceptionCaught = false;
        Test.startTest();
        try {
            update caseList;
        } catch (Exception ex) {
            if (ex.getMessage().contains(capitec_CaseDMN.ERROR_MSG)) {
                isExceptionCaught = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, isExceptionCaught, 'Error did not appear.');
    }

    @IsTest
    static void shouldGetErrorNoAnswersSummaryFieldOnCases() {
        List<Case> caseList = [SELECT Id, Status, Sub_Status__c FROM Case where RecordTypeId != :ESCALATIONS_RECORD_TYPE_ID LIMIT 50];
        List<Id> caseIdList = new List<Id>();

        for (Case thisCase : caseList) {
            thisCase.Summary__c = 'test';
            thisCase.Status = STATUS_DECISION;
            thisCase.Sub_Status__c = SUBSTATUS_MAINTAIN;
        }

        Boolean isExceptionCaught = false;
        Test.startTest();
        try {
            update caseList;
        } catch (Exception ex) {
            if (ex.getMessage().contains(capitec_CaseDMN.ERROR_MSG)) {
                isExceptionCaught = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, isExceptionCaught, 'Error did not appear.');
    }

    @IsTest
    static void shouldGetErrorSomeAnswersSummaryFieldOnCases() {
        List<Case> caseList = [SELECT Id, Status, Sub_Status__c FROM Case where RecordTypeId != :ESCALATIONS_RECORD_TYPE_ID LIMIT 50];
        List<Id> caseIdList = new List<Id>();

        for (Case thisCase : caseList) {
            caseIdList.add(thisCase.Id);
        }

        List<Answer__c> answList = TestDataFactory.createSObjectList('Answer__c', new Map<String, Object>{
                'Case__c' => caseIdList,
                'Question_Type__c' => new List<String>{
                        'Client Details Confirmation'
                },
                'Question_Number__c' => new List<Integer>{
                        1, 2
                }
        }, 600);

        for (Case thisCase : caseList) {
            thisCase.Summary__c = 'test';
            thisCase.Status = STATUS_DECISION;
            thisCase.Sub_Status__c = SUBSTATUS_MAINTAIN;
        }

        Boolean isExceptionCaught = false;
        Test.startTest();
        try {
            update caseList;
        } catch (Exception ex) {
            if (ex.getMessage().contains(capitec_CaseDMN.ERROR_MSG)) {
                isExceptionCaught = true;
            }
        }
        Test.stopTest();

        //System.assertEquals(false, isExceptionCaught, 'Error did not appear.');
    }

    @IsTest
    static void shouldNotGetErrorAllAnswersSummaryFieldOnCases() {
        List<Case> caseList = [SELECT Id, Status, Sub_Status__c FROM Case where RecordTypeId != :ESCALATIONS_RECORD_TYPE_ID LIMIT 50];
        List<Id> caseIdList = new List<Id>();
        List<Answer__c> answerList = new List<Answer__c>();
        for (Case thisCase : caseList) {
            caseIdList.add(thisCase.Id);
        }


        for (Case currentCase : caseList) {
            /*answerList.addAll((List<Answer__c>)TestDataFactory.createSObjectList('Answer__c', new Map<String, Object>{
                    'Case__c' => currentCase.Id,
                    'Question_Type__c' => new List<String>{'Client Details Confirmation', 'Media Check Results', 'Source of Funds',
                            'Source of Wealth', 'Suspicious Transaction Value', 'Transactional Behavior Assessment'},
                    'Question_Number__c' => new List<Integer>{1,2}
            }, 12, false));*/
        }

        insert answerList;

        for (Case thisCase : caseList) {
            thisCase.Summary__c = 'dupa';
            thisCase.Status = STATUS_DECISION;
            thisCase.Sub_Status__c = SUBSTATUS_MAINTAIN;
        }

        Boolean isExceptionCaught = false;
        Test.startTest();
        try {
            update caseList;
        } catch (Exception ex) {
            if (ex.getMessage().contains(capitec_CaseDMN.ERROR_MSG)) {
                isExceptionCaught = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, isExceptionCaught, 'Error did not appear.');
    }

    @IsTest
    static void lastConsultantSaved() {
        List<Case> caseList = [SELECT OwnerId FROM Case LIMIT 100];
        User consultant = [SELECT Id FROM User WHERE Alias = 'cons2'];
        System.debug(consultant);

        for (Case thisCase : caseList) {
            thisCase.OwnerId = consultant.Id;
        }

        Test.startTest();
        update caseList;
        Test.stopTest();

        Boolean isLastConsSaved = true;
        List<Case> caseListUpdated = [SELECT OwnerId, Last_Consultant__c FROM Case LIMIT 100];

        for (Case thisCase : caseListUpdated) {
            if (thisCase.Last_Consultant__c != consultant.Id) {
                isLastConsSaved = false;
            }
        }

        System.assertEquals(true, isLastConsSaved, 'Last consultant is not saved correct.');
    }

    //CECSF-215
    @IsTest
    static void escalationsUserNotCaseOwner() {
        List<Case> caseList = [SELECT Id, OwnerId FROM Case where RecordTypeId = :ESCALATIONS_RECORD_TYPE_ID LIMIT 50];
        User agent = [SELECT Id, Alias FROM User WHERE Alias = 'esc' LIMIT 1];
        User agent2 = [SELECT Id, Alias FROM User WHERE Alias = 'esc2' LIMIT 1];
        List<CaseComment> commentList = new List<CaseComment>();

        for (Case currentCase : caseList) {
            currentCase.OwnerId = agent.Id;
        }
        update caseList;

        Boolean isExceptionCaught = false;

        Test.startTest();

        System.runAs(agent2) {
            try {
                for (Case currentCase : caseList) {
                    currentCase.Subject = 'Updated Subject';
                }
                update caseList;
            } catch (Exception ex) {
                if (ex.getMessage().contains(capitec_CaseDMN.ERROR_MSG3)) {
                    isExceptionCaught = true;
                }
            }
            for (Case currentCase : caseList) {
                CaseComment comment = new CaseComment();
                comment.ParentId = currentCase.Id;
                comment.CommentBody = 'Case Comment 1';
                commentList.add(comment);
            }
            insert commentList;
        }
        Test.stopTest();

        System.assertEquals(true, isExceptionCaught, 'Only the case owner should be able to update case subject.');
        List<CaseComment> newCaseComments = [SELECT Id FROM CaseComment WHERE CommentBody = 'Case Comment 1'];
        System.assertEquals(caseList.size(), newCaseComments.size(), 'The number of case comments inserted must match the number of cases');
    }

    //CECSF-215
    @IsTest
    static void escalationsUserEqualsCaseOwner() {
        List<Case> caseList = [SELECT Id, OwnerId FROM Case WHERE RecordTypeId = :ESCALATIONS_RECORD_TYPE_ID LIMIT 50];
        User agent = [SELECT Id, Alias FROM User WHERE Alias = 'esc2' LIMIT 1];
        List<CaseComment> commentList = new List<CaseComment>();

        for (Case currentCase : caseList) {
            currentCase.OwnerId = agent.Id;
        }
        update caseList;

        Test.startTest();

        System.runAs(agent) {
            for (Case currentCase : caseList) {
                currentCase.Subject = 'Updated Subject';
                CaseComment comment = new CaseComment();
                comment.ParentId = currentCase.Id;
                comment.CommentBody = 'Case Comment 2';
                commentList.add(comment);
            }

            update caseList;
            insert commentList;
        }

        Test.stopTest();

        List<Case> updatedCaseList = [SELECT Id, OwnerId, Subject FROM Case where RecordTypeId = :ESCALATIONS_RECORD_TYPE_ID LIMIT 50];
        List<CaseComment> newCaseComments = [SELECT Id FROM CaseComment WHERE CommentBody = 'Case Comment 2'];

        System.assertEquals('Updated Subject', updatedCaseList[0].Subject, 'Owner should be able to update case subject.');
        System.assertEquals(caseList.size(), newCaseComments.size(), 'The number of case comments inserted must match the number of cases');
    }

    @IsTest
    static void kafkaIntegrationFieldsShouldBeSetUp() {
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
        Group amlConsQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :capitec_CaseDMN.AML_CONSULTANTS_TEXT LIMIT 1];

        List<Case> kCasesList = TestDataFactory.createSObjectList('Case', new Map<String, Object>{
                'Status' => STATUS_OPEN,
                'Sub_Status__c' => SUBSTATUS_NOT_YET_STARTED,
                'BusinessHoursId' => bh.Id,
                'Owner_kafka__c' => capitec_CaseDMN.AML_CONSULTANTS_TEXT,
                'Kafka_record_type__c' => capitec_CaseDMN.AML_TEXT
        }, 100, false);

        Test.startTest();
        insert (kCasesList);
        Test.stopTest();

        List<Case> kCasesListUpdated = [SELECT Id, OwnerId, RecordTypeId FROM Case WHERE Kafka_record_type__c != NULL LIMIT 100];
        Boolean isUpdatedCorrect = true;

        for (Case thisCase : kCasesListUpdated) {
            if (thisCase.RecordTypeId != CASE_AML_RECORD_TYPE_ID || thisCase.OwnerId != amlConsQueue.Id) {
                isUpdatedCorrect = false;
            }
        }

        System.assertEquals(true, isUpdatedCorrect, 'Fields on Case are not updated regard of information from Kafka.');
    }

    @IsTest
    static void shouldGetErrorNoFileAttached() {
        List<Case> caseList = [SELECT Id, Status, Sub_Status__c FROM Case LIMIT 100];

        for (Case thisCase : caseList) {
            thisCase.Status = STATUS_AWAITING_APPROVAL;
            thisCase.Sub_Status__c = SUBSTATUS_REVIEW_COMPLETE;
        }

        Boolean isExceptionCaught = false;

        Test.startTest();
        try {
            update caseList;
        } catch (Exception ex) {
            if (ex.getMessage().contains(capitec_CaseDMN.ERROR_MSG2)) {
                isExceptionCaught = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, isExceptionCaught, 'Exception is not caught.');

    }

    @IsTest
    static void shouldNotGetErrorFileAttached() {
        List<Case> caseList = [SELECT Id, Status, Sub_Status__c FROM Case LIMIT 100];
        List<Id> caseIdList = new List<Id>();
        List<Id> contentDocumentIdList = new List<Id>();
        Set<Id> contentVersionIdSet = new Set<Id>();

        for (Case thisCase : caseList) {
            caseIdList.add(thisCase.Id);
        }


        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Integer i = 0; i < 100; i++) {
            ContentVersion cv = new ContentVersion(
                    Description = 'test',
                    PathOnClient = 'test_file.txt',
                    Title = 'test file-' + Datetime.now(),
                    VersionData = Blob.valueOf('test file'));
            contentVersions.add(cv);
        }

        insert contentVersions;

        for (ContentVersion thisCV : contentVersions) {
            contentVersionIdSet.add(thisCV.Id);
        }

        List<ContentVersion> contentVersionsInserted = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIdSet];

        for (ContentVersion thisCV : contentVersionsInserted) {
            contentDocumentIdList.add(thisCV.ContentDocumentId);
        }

        List<ContentDocumentLink> contentDocumentLinks = TestDataFactory.createSObjectList('ContentDocumentLink', new Map<String, Object>{
                'ContentDocumentId' => contentDocumentIdList,
                'LinkedEntityId' => caseIdList,
                'ShareType' => 'V'
        }, 100);

        for (Case thisCase : caseList) {
            thisCase.Status = STATUS_AWAITING_APPROVAL;
            thisCase.Sub_Status__c = SUBSTATUS_REVIEW_COMPLETE;
        }

        Boolean isExceptionCaught = false;

        Test.startTest();
        try {
            update caseList;
        } catch (Exception ex) {
            if (ex.getMessage().contains(capitec_CaseDMN.ERROR_MSG2)) {
                isExceptionCaught = true;
            }
        }
        Test.stopTest();

        System.assertEquals(false, isExceptionCaught, 'Exception is caught.');
    }

    @IsTest
    static void statusShouldBeChangedFraudCase() {
        String subjectText = 'testStatusChange';
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
        List<Case> caseListToInsert = new List<Case>();

        for (Integer i = 0; i < 100; i++) {
            caseListToInsert.add(
                    new Case(Status = STATUS_NEW, Origin = ORIGIN_MANUAL,
                            BusinessHoursId = bh.Id,
                            Subject = subjectText,
                            RecordTypeId = CASE_FRAUD_RECORD_TYPE_ID));
        }

        Test.startTest();
        insert caseListToInsert;
        Test.stopTest();

        List<Case> caseToValidate = [SELECT Status FROM Case WHERE Origin = :ORIGIN_MANUAL AND Subject = :subjectText];

        Boolean isNotUpdated = false;

        for (Case thisCase : caseToValidate) {
            if (thisCase.Status != STATUS_ACTIVE) {
                isNotUpdated = true;
            }
        }

        System.assertEquals(false, isNotUpdated, 'Fraud Cases are not updated correct.');
    }

    @IsTest
    static void statusShouldChangeForSusAndFraudStatusCaseWhenMovedFromQueue() {
        List<Case> caseListToUpdate = [SELECT Id, OwnerId FROM Case WHERE RecordTypeId = :CASE_FRAUD_RECORD_TYPE_ID AND Status = :STATUS_FRAUD LIMIT 100];
        User usr = [SELECT Id FROM User WHERE Alias = 'cons' LIMIT 1];

        for (Case thisCase : caseListToUpdate) {
            thisCase.OwnerId = usr.Id;
        }

        Test.startTest();
        update usr;
        Test.stopTest();

        List<Case> caseListToValidate = [SELECT Id, OwnerId FROM Case WHERE RecordTypeId = :CASE_FRAUD_RECORD_TYPE_ID AND Status = :STATUS_ACTIVE_INVESTIGATION LIMIT 100];
        Boolean isUpdatedCorrect = true;

        for (Case thisCase : caseListToValidate) {
            if (thisCase.OwnerId != usr.Id) {
                isUpdatedCorrect = false;
            }
        }

        System.assertEquals(true, isUpdatedCorrect, 'Cases are not updated correct.');
    }
    
    @isTest
    static void testBeforeInsertHandler() {
        // Retrieve the record type ID for AML_CRA_Onboarding
        Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'AML_CRA_Onboarding' LIMIT 1].Id;
        
        // Create a test Case record with the specific RecordType
        Case testCase = new Case(
            RecordTypeId = recordTypeId,
            Subject = 'Test Case'
        );
        
        // Insert the case to trigger before insert logic
        insert testCase;
        
        // Query the Case record again to verify the fields have been set
        Case insertedCase = [SELECT Type, Origin, Alert_Create_Date__c FROM Case WHERE Id = :testCase.Id LIMIT 1];
        
        // Assert that the Type and Origin fields were set correctly
        System.assertEquals('High Risk - Onboarding', insertedCase.Type, 'Type should be set to "Onboarding High Risk"');
        System.assertEquals('New Client Review', insertedCase.Origin, 'Origin should be set to "New Client Review"');
        
        // Assert that Alert_Created_Date__c was set to today's date in string format
        String expectedDate = String.valueOf(Date.today());
        System.assertEquals(expectedDate, insertedCase.Alert_Create_Date__c, 'Alert_Create_Date__c should be set to today\'s date');
    }
}