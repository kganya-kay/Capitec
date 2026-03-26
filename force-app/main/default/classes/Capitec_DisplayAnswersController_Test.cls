/**
 * Created by dawid on 03.04.2023.
 */

@IsTest
public with sharing class Capitec_DisplayAnswersController_Test {

    static final String STATUS_OPEN = 'Open';
    static final String SUBSTATUS_NOT_YET_STARTED = 'Not Yet Started';
    static final String WRONG_Q_TYPE = 'Wrong Question Type';
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

    @TestSetup
    static void setupData() {
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
        Profile profileConsultant = [SELECT Id FROM Profile WHERE Name = 'Consultant' LIMIT 1];

        List<User> userList = TestDataFactory.createSObjectList('User', new Map<String, Object>{
                'Alias' => new List<String>{'cons', 'cons2'},
                'ProfileId' => profileConsultant.Id,
                'Username' => new List<String>{'test1234dupa1abc@test.com', 'test1234dupa1def@test.com'}
        }, 2);

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
                'OwnerId' => userList[0].Id
        }, 5);


        List<Id> caseIdList = new List<Id>();
        for (Case thisCase : caseList) {
            caseIdList.add(thisCase.Id);
        }


        List<Answer__c> answList = TestDataFactory.createSObjectList('Answer__c', new Map<String, Object>{
                'Case__c' => caseIdList,
                'Question_Type__c' => new List<String>{'Client Details Confirmation', 'Media Check Results', 'Source of Wealth', 'Source of Funds',
                        'Transactional Behavior Assessment', 'Suspicious Transaction Value'},
                'Question_Number__c' => new List<Integer>{1, 2}
        }, 35);
    }


    @IsTest
    static void queryCaseAnswersTest(){

        List<Case> caseList;
        List<Answer__c> answers = new List<Answer__c>();
        caseList = [SELECT Id, Status, Sub_Status__c, (SELECT Id FROM Answers__r) FROM Case LIMIT 5];

        Test.startTest();
        for (Case currentCase : caseList) {
            answers.addAll(Capitec_DisplayAnswersController.getAnswers(currentCase.Id, Capitec_QuestionnaireUtils.Q_TYPE_CLIENT_CLASS));
            answers.addAll(Capitec_DisplayAnswersController.getAnswers(currentCase.Id, Capitec_QuestionnaireUtils.Q_TYPE_MEDIA_CHECK));
            answers.addAll(Capitec_DisplayAnswersController.getAnswers(currentCase.Id, Capitec_QuestionnaireUtils.Q_TYPE_SOURCE_WEALTH));
            answers.addAll(Capitec_DisplayAnswersController.getAnswers(currentCase.Id, Capitec_QuestionnaireUtils.Q_TYPE_SOURCE_FUNDS));
            answers.addAll(Capitec_DisplayAnswersController.getAnswers(currentCase.Id, Capitec_QuestionnaireUtils.Q_TYPE_TRANS_BEHAVIOR_ASSESSMENT));
            answers.addAll(Capitec_DisplayAnswersController.getAnswers(currentCase.Id, Capitec_QuestionnaireUtils.Q_TYPE_CLIENT_DETAILS_CONFIRM));
            answers.addAll(Capitec_DisplayAnswersController.getAnswers(currentCase.Id, Capitec_QuestionnaireUtils.Q_TYPE_SUSPICIOUS_TRANSACTION));
        }
        Test.stopTest();

        for(Case currentCase: caseList){
            System.assertEquals(35, answers.size());
        }
    }

    @IsTest
    static void wrongQuestionTypeNoErrorEmptyList(){

        List<Case> caseList;
        List<Answer__c> answers = new List<Answer__c>();
        caseList = [SELECT Id, Status, Sub_Status__c, (SELECT Id FROM Answers__r) FROM Case LIMIT 5];

        Test.startTest();
        for (Case currentCase : caseList) {
            answers.addAll(Capitec_DisplayAnswersController.getAnswers(currentCase.Id, WRONG_Q_TYPE));
        }
        Test.stopTest();

        for(Case currentCase: caseList){
            System.assertEquals(0, answers.size());
        }
    }

}