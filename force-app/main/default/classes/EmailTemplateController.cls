/**
 * @description       : Email Template Controller for pulling Subject and HtmlValue on Email Message 
 * @author            : Rajesh Yandrathi
 * @group             : 
 * @last modified on  : 05-16-2024
**/
public with sharing class EmailTemplateController {
    @AuraEnabled(cacheable=true)
    public static EmailTemplate getTemplateInfo(String templateApiName) {
        EmailTemplate templateInfo = [SELECT Id, Subject, HtmlValue,Body FROM EmailTemplate WHERE DeveloperName = :templateApiName];
        return templateInfo;
    }
}