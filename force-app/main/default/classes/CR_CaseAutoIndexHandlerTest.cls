/**
 * @description       : Test class for CR_CaseAutoIndexHandler
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 09-05-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
@IsTest(SeeAllData=false)
private class CR_CaseAutoIndexHandlerTest {
    @TestSetup
    static void createTestData() {

        //Create Account
        List<Account> lstAccounts = new List<Account>();

        Account personAccount1 = new Account();
        personAccount1.FirstName = 'John';
        personAccount1.LastName = 'Doe';
        personAccount1.ID_Type__c = 'SA Id';
        personAccount1.Identity_Number__c = '1234567890123';
        personAccount1.Passport_Number__c = 'P78477';
        personAccount1.CIF_Number__c = '123456789';
        personAccount1.AccountNumber = 'AccNUM1234';
        lstAccounts.add(personAccount1);

        //Create Account
        Account personAccount2 = new Account();
        personAccount2.FirstName = 'Amy';
        personAccount2.LastName = 'Doe';
        personAccount2.ID_Type__c = 'SA Id';
        personAccount2.Identity_Number__c = '1234567890456';
        personAccount2.Passport_Number__c = 'P78477';
        personAccount2.CIF_Number__c = '123456123';
        personAccount2.AccountNumber = 'AccNUM4567';
        lstAccounts.add(personAccount2);

        insert lstAccounts;

        //create case
        List<Case> lstCases = new List<Case>();

        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'Email';
        caseObj.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Agent_Efficiency').getRecordTypeId();
        caseObj.Subject = 'Test Id number';
        caseObj.Description = 'Complaint on Account 1234567890123 Id number with CIF number';
        lstCases.add(caseObj);

        Case caseObj2 = new Case();
        caseObj2.Status = 'New';
        caseObj2.Origin = 'Email';
        caseObj2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Agent_Efficiency').getRecordTypeId();
        caseObj2.Subject = 'Test CIF';
        caseObj2.Description = 'Complaint on cif 123456123 number';
        lstCases.add(caseObj2);

        Case caseObj3 = new Case();
        caseObj3.Status = 'New';
        caseObj3.Origin = 'Email';
        caseObj3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Administration').getRecordTypeId();
        caseObj3.Subject = 'Test Main Applicant';
        caseObj3.Description = 'Complaint on Account 1234567890123';
        caseObj3.Type = 'Administration Order';
        lstCases.add(caseObj3);

        Case caseObj4 = new Case();
        caseObj4.Status = 'New';
        caseObj4.Origin = 'Email';
        caseObj4.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Sequestration').getRecordTypeId();
        caseObj4.Subject = 'Test Dual Id with Spouse';
        caseObj4.Description = 'Main account: 1234567890123 Spouse: 1234567890456';
        caseObj4.Type = 'Sequestration Order';
        lstCases.add(caseObj4);

        insert lstCases;
    }

    @IsTest
    private static void testAnalyzeEfficiencyCases() {
        List<Case> lstCases = [
                SELECT
                        Id,
                        Type,
                        Subject,
                        Description,
                        CIF_Number__c,
                        Client_ID_Number__c,
                        AccountId,
                        Account.CIF_Number__c,
                        Account.Identity_Number__c,
                        RecordTypeId
                FROM
                        Case
                WHERE
                        RecordType.DeveloperName = 'Agent_Efficiency'
        ];

        Test.startTest();

        CR_CaseAutoIndexHandler.analyzeCase(lstCases);

        Test.stopTest();

        List<Case> updatedCases = [SELECT Id, AccountId FROM Case WHERE RecordType.DeveloperName = 'Agent_Efficiency'];

        Assert.isNotNull(updatedCases[0].AccountId, 'The Account Id field should be populated.');
        Assert.isNotNull(updatedCases[1].AccountId, 'The Account Id field should be populated.');
    }

    @IsTest
    private static void testAnalyzeAdminCases() {
        List<Case> lstCases = [
                SELECT
                        Id,
                        Type,
                        Subject,
                        Description,
                        CIF_Number__c,
                        Client_ID_Number__c,
                        AccountId,
                        Account.CIF_Number__c,
                        Account.Identity_Number__c,
                        RecordTypeId,
                        RecordType.DeveloperName
                FROM
                        Case
                WHERE
                        RecordType.DeveloperName = 'Administration'
        ];

        Test.startTest();

        CR_CaseAutoIndexHandler.analyzeCase(lstCases);

        Test.stopTest();

        List<Case> updatedCases = [SELECT Id, AccountId FROM Case WHERE RecordType.DeveloperName = 'Administration'];
        List<CaseParticipant> caseParticipants = [SELECT Id, CaseId FROM CaseParticipant WHERE CaseId = :updatedCases[0].Id];

        Assert.isNotNull(updatedCases[0].AccountId, 'The Account Id field should be populated.');
        Assert.areEqual(caseParticipants.size(), 0, 'Case participants should not be created');
    }

    @IsTest
    private static void testDualId() {
        List<Case> lstCases = [
                SELECT Id,
                        Type,
                        Subject,
                        Description,
                        CIF_Number__c,
                        Client_ID_Number__c,
                        AccountId,
                        Account.CIF_Number__c,
                        Account.Identity_Number__c,
                        RecordTypeId
                FROM Case
                WHERE RecordType.DeveloperName = 'Sequestration'
        ];

        Test.startTest();

        CR_CaseAutoIndexHandler.analyzeCase(lstCases);

        Test.stopTest();

        List<Case> updatedCases = [SELECT Id, AccountId FROM Case WHERE RecordType.DeveloperName = 'Sequestration'];
        List<CaseParticipant> caseParticipants = [SELECT Id, CaseId FROM CaseParticipant WHERE CaseId = :updatedCases[0].Id];

        Assert.isNotNull(updatedCases[0].AccountId, 'The Account Id field should be populated.');
        Assert.isNotNull(caseParticipants, 'Case Participant should be added.');
    }
}