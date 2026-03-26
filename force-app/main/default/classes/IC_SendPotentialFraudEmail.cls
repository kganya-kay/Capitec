/**
* ICS-1067
* 08.07.2024 Radek Rozmus
* AC1 & AC2
*/
public without sharing class IC_SendPotentialFraudEmail {

    @InvocableMethod(label='Send Potential Fraud Email' description='Sends Potential Fraud Email')
    public static void sendEmail(List<String> caseIds) {
        sendEmailInternal(caseIds);
    }

    public static List<Messaging.SendEmailResult> sendEmailInternal(List<String> caseIds) {
        List<Messaging.SendEmailResult> emailResults = new List<Messaging.SendEmailResult>();

        try {
        List<Case> childCases;

        if (caseIds == null || caseIds.isEmpty()) {
            System.debug('Error: No case IDs provided.');
            return emailResults;
        } else { 
            childCases = [SELECT Id, RecordType.Name, IC_Type__c, Product_Type__c, IC_Insurer_Underwriter_at_Event_Date__c, Status, Sub_Status__c, IC_OCI_Insurer_email_Address__c
            FROM Case 
            WHERE Id IN :caseIds 
            AND RecordType.Name = 'Insurance Claims Assessment'];
        }

        EmailTemplate emailTemplatePotentialFraud;
        Messaging.SingleEmailMessage newEmail = new Messaging.SingleEmailMessage();
        String mdtTemplateName;

        try{
            emailTemplatePotentialFraud = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName LIKE :'IC_Potential_Fraud_Email_Template%' ORDER BY LastModifiedDate DESC LIMIT 1];
        }
        catch (QueryException e){
            System.debug('Email Template not found. Template name: IC_Potential_Fraud_Email_Template. Exception message: ' + e.getMessage());
            return emailResults;
        }

        mdtTemplateName = 'IC_Potential_Fraud_Risk';
        List<IC_Email_Template_Details__mdt> potentialFraudTemplateMdt = [SELECT Target_Object_ID__c, DeveloperName, From_Address__c FROM IC_Email_Template_Details__mdt WHERE DeveloperName = :mdtTemplateName];
        if (potentialFraudTemplateMdt.isEmpty()) {
            System.debug('Potential Fraud template custom metadata not found. Mdt name: ' + mdtTemplateName);
            return emailResults;
        }

        OrgWideEmailAddress[] orgWideEmailAddr = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :potentialFraudTemplateMdt[0].From_Address__c];
        if (!orgWideEmailAddr.isEmpty()) {
            newEmail.setOrgWideEmailAddressId(orgWideEmailAddr[0].Id);
        }

        for (Case childCase : childCases) {
            newEmail = new Messaging.SingleEmailMessage();
            newEmail.setToAddresses(new String[]{System.Label.IC_Potential_Fraud_Risk_Email});
            newEmail.setTemplateId(emailTemplatePotentialFraud.Id);
            newEmail.setTargetObjectId(potentialFraudTemplateMdt[0].Target_Object_ID__c);
            newEmail.setTreatTargetObjectAsRecipient(false);
            newEmail.setWhatId(childCase.Id);
            if (!orgWideEmailAddr.isEmpty()) {
                newEmail.setOrgWideEmailAddressId(orgWideEmailAddr[0].Id);
            }

            try {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{newEmail});
                emailResults.addAll(results);
                System.debug('Email sent successfully for Case ID: ' + childCase.Id);

            } catch (Exception e) {
                System.debug('Error sending email for Case ID: ' + childCase.Id + '. Exception message: ' + e.getMessage());
            }
        }
    }
        catch (Exception e) {
            // Log the exception and return false to indicate failure
            System.debug('Exception in sendEmail: ' + e.getMessage());
        }   
        return emailResults;
    }
}