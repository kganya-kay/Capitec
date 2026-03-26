@isTest
private class IC_SendPotentialFraudEmail_TEST {

   @testSetup
static void setupTestData() {
    // Skip email template creation for now
    // Create Account and Case
    Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
    Account a = new Account(
        LastName = 'Test Case - ICS-398',
        CIF_Number__c = '123456',
        RecordTypeId = personAccountRTId
    );
    insert a;

    Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
    Case parentCase = new Case(
        Origin = 'Manual',
        Subject = 'Test Parent Case - ICS-398',
        Status = 'New',
        Sub_Status__c = 'New',
        IC_Type__c = 'Death',
        Sub_Type__c = 'Natural',
        RecordTypeId = insuranceClaimsRTId,
        Product_Type__c = 'Credit Life',
        AccountId = a.Id
    );
    insert parentCase;
}


    @isTest
    static void testSendEmailWithValidCaseIds() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Query for an existing OrgWideEmailAddress record
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

        Test.startTest();
        List<Messaging.SendEmailResult> results = IC_SendPotentialFraudEmail.sendEmailInternal(new List<String>{testCase.Id});
        Test.stopTest();

        System.debug(results);

        //System.assertEquals(1, results.size(), 'One email should have been sent.');
        //System.assertEquals(true, results[0].isSuccess(), 'Email should have been sent successfully.');
    }

    @isTest
    static void testSendEmailWithNoCaseIds() {
        Test.startTest();
        List<Messaging.SendEmailResult> results = IC_SendPotentialFraudEmail.sendEmailInternal(new List<String>());
        Test.stopTest();

        
    }

    @isTest
    static void testSendEmailWithInvalidCaseId() {
        Test.startTest();
        List<Messaging.SendEmailResult> results = IC_SendPotentialFraudEmail.sendEmailInternal(new List<String>{'invalidId'});
        Test.stopTest();

        System.assertEquals(0, results.size(), 'No emails should have been sent.');
    }
}