/**
 * Created by dawid on 20.03.2023.
 */

public with sharing class Capitec_QuestionnaireUtils {

    static public final String Q_TYPE_CLIENT_CLASS = 'Client Classification';
    static public final String Q_TYPE_MEDIA_CHECK = 'Media Check Results';
    static public final String Q_TYPE_SOURCE_WEALTH = 'Source of Wealth';
    static public final String Q_TYPE_SOURCE_FUNDS = 'Source of Funds';
    static public final String Q_TYPE_TRANS_BEHAVIOR_ASSESSMENT = 'Transactional Behavior Assessment';
    static public final String Q_TYPE_CLIENT_DETAILS_CONFIRM = 'Client Details Confirmation';
    static public final String Q_TYPE_SUSPICIOUS_TRANSACTION = 'Suspicious Transaction Value';


    @AuraEnabled
    public static List<Answer__c> getUserCaseAnswersForQuestionType(String caseId, String questionType){
        return [SELECT Id, Question_Type__c, Question__c, Answer__c FROM Answer__c WHERE Case__c = :caseId AND Question_Type__c = :questionType];
    }
}