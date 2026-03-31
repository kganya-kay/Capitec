/**
 * @description       : 
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 10-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class Conversions_SubStatusController {
    
    @AuraEnabled(cacheable=true)
    public static Case getCaseInfo(Id caseId) {
        return [
            SELECT Id,
                   CaseNumber,
                   Status,
                   Sub_Status__c,
                   OwnerId,
                   Owner.Name
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Conversion__c getConversionInfo(Id caseId) {
        return [
            SELECT Id,
                   Case_Closure_Reason__c,
                   Case__c
            FROM Conversion__c
            WHERE Case__c = :caseId
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static Boolean createTask(String subject, String description, Date dueDate, Id caseId, Id ownerId) {
        try {
            Task task = new Task();
            task.Subject = subject;
            task.Description = description;
            task.ActivityDate = dueDate;
            task.OwnerId = ownerId;
            task.WhatId = caseId;

            System.debug('##Creating task: ' + task);


            insert task;
            return true;
        } catch (Exception ex) {
            System.debug('##Error creating task: ' + ex.getMessage());
            return false;
        }
    }

}