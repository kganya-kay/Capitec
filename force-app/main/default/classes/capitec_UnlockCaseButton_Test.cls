@isTest

public with sharing class capitec_UnlockCaseButton_Test {
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    static final String SUBSTATUS_NOT_YET_STARTED = 'Not Yet Started';
    static final String STATUS_OPEN = 'Open';
    
    @TestSetup

    static void setupData(){

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];

        Account acc = (Account)TestDataFactory.createSObject('Account', new Map<String, Object>{
            'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
            'CIF_Number__c' => '123456789',
            'Identity_Number__c' => '7101180046087'
        });

        Case caseToUnLock = (Case)TestDataFactory.createSObject('Case', new Map<String, Object> {
            'AccountId' => acc.Id,
            'Status' => STATUS_OPEN,
            'Sub_Status__c' => SUBSTATUS_NOT_YET_STARTED,
            'BusinessHoursId' => bh.Id

        });    
    }

    @IsTest
    static void isCaseAndAnswerUnLocked(){
        Set<Id> CaseToUnLockId = new Map<Id,Case>([SELECT Id FROM Case LIMIT 1]).keyset();
    
        capitec_UnlockCaseButton.CasesToUnLockInput input = new capitec_UnlockCaseButton.CasesToUnLockInput();
        for (Id caseId: CaseToUnLockId){
            input.caseId = caseId;
        }
        List <capitec_UnlockCaseButton.CasesToUnLockInput> CaseToUnLock = new List<capitec_UnlockCaseButton.CasesToUnLockInput>();
        CaseToUnLock.add(input);

        Test.startTest();
        capitec_UnlockCaseButton.CaseUnlock(CaseToUnLock);
        Test.stopTest();

        System.assertEquals(false,Approval.islocked(input.caseId));

        Answer__c[] unlockedAnswers = [SELECT Id FROM Answer__c WHERE Answer__c.Case__c = :input.caseId];
        Map<Id,Boolean> unlockedAnswersResults = Approval.isLocked(unlockedAnswers);

        System.assertEquals(false, unlockedAnswersResults.values().contains(false));
    }
}