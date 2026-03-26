/**
 * Created by dawid on 20.03.2023.
 */

public with sharing class Capitec_DisplayAnswersController {

    @AuraEnabled
    public static List<Answer__c> getAnswers(String caseId, String questionType){
        return Capitec_QuestionnaireUtils.getUserCaseAnswersForQuestionType(caseId, questionType);
    }
}