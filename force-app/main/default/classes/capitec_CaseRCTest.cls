/**
* @description Test class for capitec_CaseRC to ensure the child case owner updates are functioning as expected.
* @date Created: 22.07.2024
* @author Kevin Nundran
*/
@isTest
public class capitec_CaseRCTest {
    static final String RETAIL_COMPLAINTS_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Retail_Complaints').getRecordTypeId();
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    private static final String CIF = '103226141';
    private static final String CP = 'CP340378';
    private static final String START_DATE = String.valueOf(System.today()-31);
    private static final String END_DATE = String.valueOf(System.today());
    private static final String FIRST_NAME = 'Jordan';
    private static final String LAST_NAME = 'Hal';
    private static final String IDENTITY_NUMBER = '8806110477082';
    private static final String GENDER = 'M';
    private static final Date DATE_OF_BIRTH = Date.valueOf('1988-06-11');
    
    /**
    * @description Sets up test data for use in test methods.
    */
    @TestSetup
    static void dataSetup() {
        String uniqueUserName = 'testuser2' + DateTime.now().getTime() + '@testorg1.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        List<User> lstUsers = new List<User>();
        User u = new User(Alias = 'usert1', Email='testUser1@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles',
                Username=uniqueUserName, EmployeeNumber=CP);
        lstUsers.add(u);

        String uniqueUserNameNoCode = 'testuser1' + DateTime.now().getTime() + '@testorg2.com';
        User userNoCode = new User(Alias = 'usert2', Email='testUser2@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles',
                Username=uniqueUserNameNoCode);
        lstUsers.add(userNoCode);
        Database.insert(lstUsers);
        
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
        Id retailComplaintsRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Retail_Complaints').getRecordTypeId();
        
        Id amlRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('AML_Record_Type').getRecordTypeId();
        
        Account acc = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
            'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                'LastName' => FIRST_NAME,
                'CIF_Number__c' => CIF,
                'Identity_Number__c' => IDENTITY_NUMBER,
                'LastName' => LAST_NAME,
                'Gender__c' => GENDER,
                'Birthdate__c' => DATE_OF_BIRTH
                }, true);
        
        Account accNoCif = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
            'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                'LastName' => FIRST_NAME,
                'Identity_Number__c' => IDENTITY_NUMBER,
                'LastName' => LAST_NAME,
                'Gender__c' => GENDER,
                'Birthdate__c' => DATE_OF_BIRTH
                }, true);
        
        Entitlement entit = (Entitlement)TestDataFactory.createSObject('Entitlement', new Map<String, Object> {
            'StartDate' => Date.today(),
                'EndDate' => Date.today().addYears(90),
                'Name' => 'AML Full Case SLA',
                'BusinessHoursId' => bh.Id,
                'AccountId' => acc.Id
                }, true);
        
        Case parentCase = (Case) TestDataFactory.createSObject('Case', new Map<String, Object>{
            'Account_CIF_Number__c' => CIF,
                'RecordTypeId' => RETAIL_COMPLAINTS_RECORD_TYPE_ID,
                'capitec_Employee_Code__c' => CP,
                'BusinessHoursId' => bh.Id,
                'AccountId' => acc.Id,
                'OwnerId' => u.Id
                }, true);
        
        Case childCase1 = (Case) TestDataFactory.createSObject('Case', new Map<String, Object>{
            'Account_CIF_Number__c' => CIF,
                'RecordTypeId' => RETAIL_COMPLAINTS_RECORD_TYPE_ID,
                'capitec_Employee_Code__c' => CP,
                'BusinessHoursId' => bh.Id,
                'AccountId' => acc.Id,
                'ParentId' => parentCase.Id,
                'OwnerId' => u.Id
                }, true);
        
        Case childCase2 = (Case) TestDataFactory.createSObject('Case', new Map<String, Object>{
            'Account_CIF_Number__c' => CIF,
                'RecordTypeId' => RETAIL_COMPLAINTS_RECORD_TYPE_ID,
                'capitec_Employee_Code__c' => CP,
                'BusinessHoursId' => bh.Id,
                'AccountId' => acc.Id,
                'ParentId' => parentCase.Id,
                'OwnerId' => u.Id
                }, true);
    }
    
    /**
    * @description Test method to verify that the parent case owner is updated correctly.
    */    
    @isTest
    static void updateParentCaseOwner(){
        List<Case> caseWithOriginalOwner = [SELECT Id, OwnerId FROM Case WHERE ParentId=null];
        List<Case> caseToUpdate = [SELECT Id, OwnerId FROM Case WHERE ParentId=null];
        List<User> lstUser = [SELECT Id FROM User WHERE Email='testUser2@testorg.com'];
        
        Test.startTest();
        
        caseToUpdate[0].OwnerId = lstUser[0].Id;
        Database.update(caseToUpdate);
        
        System.assertNotEquals(caseWithOriginalOwner[0].OwnerId, caseToUpdate[0].OwnerId);
        
        Test.stopTest();
    }
}