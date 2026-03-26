/**
 * Created by dawid on 26.09.2024.
 */

@IsTest
public class IC_EmailMessageDomain_TEST {

    @TestSetup
    static void prepareTestData() {

        // Setup test data
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        Account a = new Account(
                LastName = 'Test Case - ICS-1254',
                CIF_Number__c = '123456',
                RecordTypeId = personAccountRTId
        );
        insert a;

        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case parentCase = new Case(
                Subject = 'Test Parent Case - ICS-1254',
                Status = 'New',
                Sub_Status__c = 'Unclassified',
                IC_Type__c = 'Unemployment/ITEI',
                Sub_Type__c = 'Retrenchment',
                //Sub_Type_Reason__c = 'New Technology',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Credit Life',
                IC_Insurer_Underwriter_at_Event_Date__c = 'Centriq',
                AccountId = a.Id
        );

        insert parentCase;

        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Case childCase = new Case(
                Subject = 'Test Child Case - ICS-1254',
                Status = '2nd Assessment',
                Sub_Status__c = 'Preliminary Declined',
                IC_Type__c = 'Unemployment/ITEI',
                Sub_Type__c = 'Retrenchment',
                //Sub_Type_Reason__c = 'New Technology',
                RecordTypeId = insuranceClaimsAssessmentRTId,
                Product_Type__c = 'Credit Life',
                IC_Insurer_Underwriter_at_Event_Date__c = 'Centriq',
                IC_1st_decline_process_completed__c = false,
                ParentId = parentCase.Id,
                AccountId = a.Id
        );
        insert childCase;

        // Create and link a file to the parentCase
        ContentVersion cv = new ContentVersion(
                Title = 'TestFile',
                PathOnClient = 'TestFile.jpg', // The file name and extension
                VersionData = Blob.valueOf('Test data'), // Simulate file content
                IsMajorVersion = true,
                FirstPublishLocationId = parentCase.Id // Directly relates the file to the case on creation
        );
        insert cv;

        List<DocumentType> retrenchmentLetterDocType = [SELECT Id FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];
        DocumentChecklistItem checklistItem = [
                SELECT Id, Status, IC_Documentum_ID__c
                FROM DocumentChecklistItem
                WHERE ParentRecordId = :parentCase.Id
                LIMIT 1
        ];
        checklistItem.Status = 'Verified';
        checklistItem.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem;

        // Insert a test case
        Case testCase = new Case(
                Status = 'New',
                Subject = ' STRACK IS 2182323491 claim for policy CF23954234',
                Origin = 'Email',
                IC_Sanlam_Claim__c = true,
                RecordTypeId = insuranceClaimsRTId);
        insert testCase;

        Case testCase2 = new Case(
                Status = 'New',
                Subject = 'Non-Sanlam Test Case',
                Origin = 'Email',
                IC_Sanlam_Claim__c = false,
                RecordTypeId = insuranceClaimsRTId);
        insert testCase2;

        // Setup test data
    }


    @IsTest
    static void testCentriqInsert(){
        Case parentCase = [SELECT Id FROM Case WHERE Subject LIKE '%Parent%' LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Case childCase = new Case(
                Subject = 'Test Child Case - ICS-1254',
                Status = '2nd Assessment',
                Sub_Status__c = 'Preliminary Declined',
                IC_Type__c = 'Unemployment/ITEI',
                Sub_Type__c = 'Retrenchment',
                //Sub_Type_Reason__c = 'New Technology',
                RecordTypeId = insuranceClaimsAssessmentRTId,
                Product_Type__c = 'Credit Life',
                IC_Insurer_Underwriter_at_Event_Date__c = 'Centriq',
                IC_1st_decline_process_completed__c = true,
                ParentId = parentCase.Id,
                AccountId = acc.Id
        );
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());


        Test.startTest();
        insert childCase;
        Test.stopTest();
    }

    @IsTest
    static void testCentriqUpdate(){

        Case childCase = [SELECT Id, IC_1st_decline_process_completed__c FROM Case WHERE Subject LIKE '%Child Case%' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());


        Test.startTest();
        childCase.IC_1st_decline_process_completed__c = true;
        update childCase;
        Test.stopTest();
    }


    // Mock class for HttpCallout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"fileContent":"fakeZipFileContent"}'); // Simulate successful response
            res.setStatusCode(200);
            return res;
        }
    }

    //===================================================================================
    //      Search For Sanlam Methods
    //===================================================================================
    @IsTest
    static void testSearchForSanlamAcknowledgement() {
        String emailBodyWithAcknowledgement = 'This is an email containing the Sanlam acknowledgment: ' + System.Label.IC_SanlamAcknowledgment;
        String emailBodyWithoutAcknowledgement = 'This is an email without the acknowledgment phrase.';

        Boolean resultWith = IC_EmailMessageDomain.searchForSanlamAcknowledgement(emailBodyWithAcknowledgement);
        Boolean resultWithout = IC_EmailMessageDomain.searchForSanlamAcknowledgement(emailBodyWithoutAcknowledgement);

        System.assert(resultWith, 'The acknowledgment phrase should be found.');
        System.assert(!resultWithout, 'The acknowledgment phrase should not be found.');
    }


    /**
     * @author Gerhard de Klerk
     * @date 03.10.2024
     *
     * @description Search the email body for a string denoting documents required for sanlam
     * @param emailBody the TextBody of an email that we want
     *
     * @return returns true if the acknowledgment phrase was found, false if not
     */
    @istest
    public static void test_searchForSanlamNeedsDocs(){
        String emailBodybody =
                'Good day\n' +
                        '\n' +
                        'Please note that in order to finalise the assessment of this funeral claim we require the following outstanding documents.\n' +
                        'Regards\n' +
                        '\n' +
                        'Claims Department';
        Boolean result_positive = IC_EmailMessageDomain.searchForSanlamNeedsDocs(emailBodybody);
        System.assertEquals(result_positive, TRUE, 'Unexpected outcome');

        Boolean result_negative = IC_EmailMessageDomain.searchForSanlamNeedsDocs(null);
        System.assertEquals(result_negative, false, 'Unexpected outcome');

    }

    /**
     * @author Gerhard de Klerk
     * @date 03.10.2024
     *
     * @description Search the email body for a string denoting Repudiation Letter Received
     * @param emailBody the TextBody of an email that we want
     *
     * @return returns true if the acknowledgment phrase was found, false if not
     */
    @IsTest
    public static void test_searchForSanlamRepudiationLetterReceived(){
        String emailBodybody =
                'Good day\n' +
                        '\n' +
                        'Please receive the attached repudiation letter.\n' +
                        'Regards\n' +
                        '\n' +
                        'Claims Department';
        Boolean result_positive = IC_EmailMessageDomain.searchForSanlamRepudiationLetterReceived(emailBodybody);
        System.assertEquals(result_positive, TRUE, 'Unexpected outcome');

        Boolean result_negative = IC_EmailMessageDomain.searchForSanlamRepudiationLetterReceived(null);
        System.assertEquals(result_negative, FALSE, 'Unexpected outcome');
    }

    /**
     * @author Gerhard de Klerk
     * @date 03.10.2024
     *
     * @description Search the email body for a string denoting Repudiation Letter Received - other version
     * @param emailBody the TextBody of an email that we want
     *
     * @return returns true if the acknowledgment phrase was found, false if not
     */
    @IsTest
    public static void test_searchForSanlamRepudiationLetterReceived_OtherVersion(){
        String emailBodybody =
                'Good day\n' +
                        '\n' +
                        'Please find attached Repudiation Letter.\n' +
                        'Regards\n' +
                        '\n' +
                        'Claims Department';
        Boolean result_positive = IC_EmailMessageDomain.searchForSanlamRepudiationLetterReceived_OtherVersion(emailBodybody);
        System.assertEquals(result_positive, TRUE, 'Unexpected outcome');

        Boolean results_negative = IC_EmailMessageDomain.searchForSanlamRepudiationLetterReceived_OtherVersion(null);
        System.assertEquals(results_negative, FALSE, 'Unexpected outcome');
    }


    /**
     * @author Gerhard de Klerk
     * @date 03.10.2024
     *
     * @description Search the email body for a string denoting Claim finalized
     * @param emailBody the TextBody of an email that we want
     *
     * @return returns true if the acknowledgment phrase was found, false if not
     */
    @IsTest
    public static void test_searchForSanlamClaimFinalized(){
        String emailBodybody =
                'Good day\n' +
                        '\n' +
                        'Please be advised that the claim has been finalized.\n' +
                        'Regards\n' +
                        '\n' +
                        'Claims Department';
        Boolean result_positive = IC_EmailMessageDomain.searchForSanlamClaimFinalized(emailBodybody);
        System.assertEquals(result_positive, TRUE, 'Unexpected outcome');

        Boolean results_negative = IC_EmailMessageDomain.searchForSanlamClaimFinalized(null);
        System.assertEquals(results_negative, FALSE, 'Unexpected outcome');
    }

    /**
     * @author Gerhard de Klerk
     * @date 03.10.2024
     *
     * @description Search the email body for a string denoting Claim finalized - natural Death
     * @param emailBody the TextBody of an email that we want
     *
     * @return returns true if the acknowledgment phrase was found, false if not
     */
    @IsTest
    public static void test_searchForSanlamClaimFinalizedNaturalDeath(){
        String emailBodybody =
                'Good day\n' +
                        '\n' +
                        'Please be advised that the Natural Death portion of this claim has been finalized.\n' +
                        'Regards\n' +
                        '\n' +
                        'Claims Department';
        Boolean result_positive = IC_EmailMessageDomain.searchForSanlamClaimFinalizedNaturalDeath(emailBodybody);
        System.assertEquals(result_positive, TRUE, 'Unexpected outcome');

        Boolean results_negative = IC_EmailMessageDomain.searchForSanlamClaimFinalizedNaturalDeath(null);
        System.assertEquals(results_negative, FALSE, 'Unexpected outcome');
    }

    //===================================================================================
    //      Update Case Sanlam Methods
    //===================================================================================
    @IsTest
    static void testUpdateCaseSanlamAcknowledgment() {
        Case testCase = [SELECT Id, OwnerId, Status, Sub_Status__c FROM Case LIMIT 1];

        IC_EmailMessageDomain.updateCaseSanlamAcknowledgment(testCase);

        Case updatedCase = [SELECT Id, OwnerId, Status, Sub_Status__c FROM Case WHERE Id = :testCase.Id];
        Group sanlamAssessmentQueue = [SELECT Id FROM Group WHERE DeveloperName = 'IC_Waiting_for_Sanlam_Assessment'];

        System.assertEquals(updatedCase.OwnerId, sanlamAssessmentQueue.Id, 'The case owner should be the Sanlam Assessment queue.');
    }

    @IsTest
    public static void test_updateCaseSanlamNeedsDocs(){
        Case testcase = [SELECT Id, IC_BulkSMS_Paid__c, IC_BulkSMS_Docs__c, IC_BulkSMS_Reputiate__c FROM Case WHERE IC_Sanlam_Claim__c = true LIMIT 1];
        IC_EmailMessageDomain.updateCaseSanlamNeedsDocs(testcase);
        Case case_retrieved = [SELECT Id, IC_BulkSMS_Paid__c, IC_BulkSMS_Docs__c, IC_BulkSMS_Reputiate__c FROM Case WHERE IC_Sanlam_Claim__c = true LIMIT 1];
        System.assertEquals(case_retrieved.IC_BulkSMS_Docs__c, true, 'Unexpected Value');
    }

    @IsTest
    public static void test_updateCaseSanlamRepudiationLetterReceived(){
        Case testcase = [SELECT Id, IC_BulkSMS_Paid__c, IC_BulkSMS_Docs__c, IC_BulkSMS_Reputiate__c FROM Case WHERE IC_Sanlam_Claim__c = true LIMIT 1];
        IC_EmailMessageDomain.updateCaseSanlamRepudiationLetterReceived(testcase);
        Case case_retrieved = [SELECT Id, IC_BulkSMS_Paid__c, IC_BulkSMS_Docs__c, IC_BulkSMS_Reputiate__c FROM Case WHERE IC_Sanlam_Claim__c = true LIMIT 1];
        System.assertEquals(case_retrieved.IC_BulkSMS_Reputiate__c, true, 'Unexpected Value');
    }

    @IsTest
    public static void test_updateCaseSanlamClaimFinalized(){
        Case testcase = [SELECT Id, IC_BulkSMS_Paid__c, IC_BulkSMS_Docs__c, IC_BulkSMS_Reputiate__c FROM Case WHERE IC_Sanlam_Claim__c = true LIMIT 1];
        IC_EmailMessageDomain.updateCaseSanlamClaimFinalized(testcase);
        Case case_retrieved = [SELECT Id, IC_BulkSMS_Paid__c, IC_BulkSMS_Docs__c, IC_BulkSMS_Reputiate__c FROM Case WHERE IC_Sanlam_Claim__c = true LIMIT 1];
        System.assertEquals(case_retrieved.IC_BulkSMS_Paid__c, true, 'Unexpected Value');
    }


    @IsTest
    static void testupdateCaseSanlamFuneralClaimsQueue() {
        Test.StartTest();
        Case testCase = [SELECT Id, OwnerId, Status, Sub_Status__c FROM Case LIMIT 1];

        IC_EmailMessageDomain.updateCaseSanlamFuneralClaimsQueue(testCase);

        Case updatedCase = [SELECT Id, OwnerId, Status, Sub_Status__c FROM Case WHERE Id = :testCase.Id];
        Group funeralClaimsQueue = [SELECT Id FROM Group WHERE DeveloperName = 'IC_Funeral_Claims'];
		Test.StopTest();
        
        System.assertEquals(updatedCase.OwnerId, funeralClaimsQueue.Id, 'The case owner should be the Funeral Claims queue.');
        System.assertEquals(updatedCase.Status, 'Administration', 'The status should be updated to Administration.');
        //System.assertEquals(updatedCase.Sub_Status__c, 'Admin Queued', 'The sub-status should be updated to Admin Queued.');
        System.assertEquals(updatedCase.Sub_Status__c, 'Update Received', 'The sub-status should be updated to Update Received.');
    }


    @IsTest
    static void testUpdateCaseSanlamResponded() {
        Test.StartTest();
        Case testCase = [SELECT Id, OwnerId, Status, Sub_Status__c FROM Case LIMIT 1];

        IC_EmailMessageDomain.updateCaseSanlamResponseWaitingQueue(testCase);

        Case updatedCase = [SELECT Id, OwnerId, Status, Sub_Status__c FROM Case WHERE Id = :testCase.Id];
        Group funeralSanlamResponseQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Funeral_Sanlam_Responses'];
		Test.StopTest();
        
        System.assertEquals(updatedCase.OwnerId, funeralSanlamResponseQueue.Id, 'The case owner should be the Funeral Sanlam Response queue.');
        System.assertEquals(updatedCase.Status, 'Administration', 'The status should be updated to Administration.');
        //System.assertEquals(updatedCase.Sub_Status__c, 'Admin Queued', 'The sub-status should be updated to Admin Queued.');
        System.assertEquals(updatedCase.Sub_Status__c, 'Update Received', 'The sub-status should be updated to Update Received.');
    }


    @IsTest
    static void testHandleEscalationAssessmentResponse() {
        Test.StartTest();
        Case testCase = [SELECT Id, OwnerId, Status, Sub_Status__c FROM Case where IC_Sanlam_Claim__c = false LIMIT 1];

      
        IC_EmailMessageDomain.updateCaseSanlamResponseWaitingQueue(testCase);

        Case updatedCase = [SELECT Id, OwnerId, Status, Sub_Status__c FROM Case WHERE Id = :testCase.Id];
        Group funeralClaimsQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Funeral_Sanlam_Responses'];
		Test.StopTest();
        
        System.assertEquals(updatedCase.OwnerId, funeralClaimsQueue.Id, 'The case owner should be the Funeral Claims queue.');
        System.assertEquals(updatedCase.Status, 'Administration', 'The status should be updated to Administration.');
        //System.assertEquals(updatedCase.Sub_Status__c, 'Admin Queued', 'The sub-status should be updated to Admin Queued.');
        System.assertEquals(updatedCase.Sub_Status__c, 'Update Received', 'The sub-status should be updated to Update Received.');
    }

    @IsTest
    static void testhandleXTNDResponse() {
        Test.StartTest();
        Case testCase = [SELECT Id, OwnerId, Status, Sub_Status__c FROM Case WHERE IC_Sanlam_Claim__c = FALSE LIMIT 1];

        IC_EmailMessageDomain.handleXTNDResponse(testCase);

        Case updatedCase = [SELECT Id, OwnerId, Status, Sub_Status__c FROM Case WHERE Id = :testCase.Id];
        Group queueId = [SELECT Id FROM Group WHERE DeveloperName = 'IC_Second_Assessment_Queue'];
		Test.StopTest();
        String statusValue = 'Assessment';
        String substatusValue = 'Update Received';
        System.assertEquals(updatedCase.OwnerId, queueId.Id, 'The case owner is incorrect.');
        System.assertEquals(updatedCase.Status, statusValue, 'The status should be updated to ' + statusValue);
        System.assertEquals(updatedCase.Sub_Status__c, substatusValue, 'The sub-status should be updated to ' + substatusValue);
    }


    @IsTest
    static void testResultWrapper() {
        IC_ResultWrapper wrapper = new IC_ResultWrapper();
        IC_ResultWrapper wrapper1 = new IC_ResultWrapper(true, '', 0, '');
        IC_ResultWrapper wrapper2 = new IC_ResultWrapper(true, '', 0, '', '');
    }
    
    @isTest 
    public static void justIncrementTest() {
        IC_EmailMessageDomain.justIncrement();
    }
}