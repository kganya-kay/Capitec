/**
 * Created by Sebastian on 04.04.2023.
 */

@IsTest
public class capitec_MediaSearchController_Test {
    static final String STATUS_OPEN = 'Open';
    static final String SUBSTATUS_NOT_YET_STARTED = 'Not Yet Started';
    private static final String CP = 'CP340378';
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();


    @TestSetup
    static void dataSetup() {
        Profile profileConsultant = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];

        String uniqueUserName = 'testuser2' + DateTime.now().getTime() + '@testorg1.com';
        User usr = [SELECT Id, Name FROM User WHERE isActive = true AND Profile.Name = 'System Administrator' LIMIT 1];

        Account acc = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
                'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                'CIF_Number__c' => '123456789',
                'Identity_Number__c' => '7101180046087'
        });

        Entitlement entit = (Entitlement)TestDataFactory.createSObject('Entitlement', new Map<String, Object> {
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
                'OwnerId' => usr.Id
        }, 10);
    }

    @IsTest
    static void mediaSearchHistoryRecordIsInserted() {
        User usr = [SELECT Id FROM User LIMIT 1];
        List<Case> caseList = [SELECT Id FROM Case LIMIT 10];
        Set<Id> caseIdSet = new Set<Id>();

        Test.startTest();
        for (Case thisCase : caseList) {
            capitec_MediaSearchController.createMediaSearchHistoryRecord(thisCase.Id);
            caseIdSet.add(thisCase.Id);
        }
        Test.stopTest();

        List<Media_Search_History__c> mshList = [SELECT Id, User__c FROM Media_Search_History__c WHERE Case__c IN: caseIdSet];
        Boolean mshInsertCorrect = true;

        for (Media_Search_History__c thisMsh : mshList) {
            if (thisMsh.User__c != usr.Id) {
                mshInsertCorrect = false;
            }
        }
        
        System.assertEquals(true,mshList.size() == 10, 'Media Search History records are not inserted correct.');
    }

    @IsTest
    static void mediaSearchHistoryRecordsAreGotCorrect() {
        User usr = [SELECT Id FROM User LIMIT 1];
        List<Case> caseList = [SELECT Id FROM Case LIMIT 10];
        List<Id> caseIdList = new List<Id>();
        List<Object> listMshToDisplay = new List<Object>();

        for (Case thisCase : caseList) {
            caseIdList.add(thisCase.Id);
        }

        List<Media_Search_History__c> mshList = TestDataFactory.createSObjectList('Media_Search_History__c', new Map<String, Object>{
            'Click_Date__c' => Datetime.now(),
            'Case__c' => caseIdList,
            'User__c' => usr.Id
        }, 10);

        Test.startTest();
        for (Case thisCase : caseList) {
            listMshToDisplay.addAll(capitec_MediaSearchController.getMediaSearchHistory(thisCase.Id));
        }
        Test.stopTest();

        System.assertEquals(10, listMshToDisplay.size(), 'Media Search History records are not retrieved correct.');
    }

    @IsTest
    static void caseIsReturned() {
        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id FROM Case LIMIT 10]);
        List<Case> caseList = new List<Case>();

        Test.startTest();
        for (Id thisCaseId : caseMap.keySet()) {
            caseList.add(capitec_MediaSearchController.getCaseRecord(thisCaseId));
        }
        Test.stopTest();

        Boolean areCasesReturnedCorrect = true;

        for (Case thisCase : caseList) {
            if (thisCase.Media_Search_URL__c == null) {
                areCasesReturnedCorrect = false;
            }
        }

        System.assertEquals(true, areCasesReturnedCorrect && caseList.size() == 10, 'Cases are not returned correct.');
    }
}