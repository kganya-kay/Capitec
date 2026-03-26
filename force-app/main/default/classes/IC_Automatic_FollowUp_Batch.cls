/**
* Class Name:       IC_Automatic_FollowUp_Batch
* Test Class:       IC_Automatic_FollowUp_Batch_TEST
* Author           	Ridwan Moosuddee
* Company          	BlueSky
* Date             19/02/2024
* Ticket      		ICS-578 - Assess Claim - Credit Life: Own Credit Insurance (OCI) - child case [AC5]
**/
global class IC_Automatic_FollowUp_Batch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query for cases in Waiting for Insurer queue with Insurer Underwriter as Unknown
        String query = 'SELECT Id, Owner.Name, IC_AccountPersonContactId__c, IC_Insurer_Underwriter_at_Event_Date__c, IC_From_Email_Address__c, IC_Last_Response_Received_Date__c FROM Case WHERE Owner.Name = \'Waiting for Insurer\' AND IC_Insurer_Underwriter_at_Event_Date__c = \'Unknown\'';
        System.debug('query: ' + query);
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        EmailTemplate emailTempAutomaticFollowUp = [SELECT Id FROM EmailTemplate WHERE Name = 'IC OCI response not received yet' LIMIT 1]; 
        List<IC_Email_Template_Details__mdt> template = [SELECT Target_Object_ID__c, DeveloperName, From_Address__c FROM IC_Email_Template_Details__mdt WHERE DeveloperName = 'IC_OCI_response_not_received_yet'];
            
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :template[0].From_Address__c];
        
        System.debug('scope: ' + scope);     
        for (Case c : scope) {
            
            Date caseLastReponseReceivedDate = c.IC_Last_Response_Received_Date__c; 
			Date today = Date.today();
            
            // Check if the date field is 7 days different from today's date
            if (caseLastReponseReceivedDate != null && caseLastReponseReceivedDate.daysBetween(today) == 7) {
				
                System.debug('The date field is 7 days different from today.');
                // Create email message
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTemplateId(emailTempAutomaticFollowUp.Id);
                //email.setToAddresses(new List<String>{c.IC_From_Email_Address__c});
                String[] addresses = new String[]{c.IC_From_Email_Address__c};
				email.setToAddresses(addresses);
                email.setTargetObjectId(c.IC_AccountPersonContactId__c); 
                email.setWhatId(c.Id); 
                email.setSaveAsActivity(true);
                if ( owea.size() > 0 ) {
                    email.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                emailsToSend.add(email);
            }             
        }
        System.debug('emailsToSend: ' + emailsToSend);   
        // Send emails
        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
			System.debug('mail sent');             
        }
    }

    global void finish(Database.BatchableContext BC) {

    }
}