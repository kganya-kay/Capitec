@isTest
public with sharing class capitec_LockApprovedCase_Test {
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

        Case caseToLock = (Case)TestDataFactory.createSObject('Case', new Map<String, Object> {
            'AccountId' => acc.Id,
            'Status' => STATUS_OPEN,
            'Sub_Status__c' => SUBSTATUS_NOT_YET_STARTED,
            'BusinessHoursId' => bh.Id

        });    
    }

    @IsTest
    static void isCaseAndAnswerLocked(){
        Set<Id> CaseToLockId = new Map<Id,Case>([SELECT Id FROM Case LIMIT 1]).keyset();
    
        capitec_LockApprovedCase.casesToLockInput input = new capitec_LockApprovedCase.casesToLockInput();
        for (Id caseId: CaseToLockId){
            input.caseId = caseId;
        }
        List <capitec_LockApprovedCase.casesToLockInput> CaseToLock = new List<capitec_LockApprovedCase.casesToLockInput>();
        CaseToLock.add(input);

        Test.startTest();
        capitec_LockApprovedCase.lockApprovedCaseRecord(CaseToLock);
        Test.stopTest();

        System.assert(Approval.isLocked(input.caseId));

        Answer__c[] lockedAnswers = [SELECT Id FROM Answer__c WHERE Answer__c.Case__c = :input.caseId];
        Map<Id,Boolean> lockedAnswersResults = Approval.isLocked(lockedAnswers);

        System.assertEquals(false, lockedAnswersResults.values().contains(false));
    }

}