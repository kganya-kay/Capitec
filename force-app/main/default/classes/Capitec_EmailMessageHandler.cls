/**
 * @description       : Handler class for EmailMessage Trigger
 * @author            : Samiirah.A@bsky.co.za
 * @group             : Capitec Network Deposit
 * @last modified on  : 06-06-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class Capitec_EmailMessageHandler {

    public static void handleVerifyAttachments(List<EmailMessage> lstNewEmailMessages){
        System.debug('handleVerifyAttachments START WITH' + lstNewEmailMessages);
        Set<String> setAssignmentReasons = new Set<String>{'Technical issue with submitting notice', 'Technical issue with submitted notice'};
        Set<Id> setCaseIds               = new Set<Id>();
        String emailAdressToBlock        = 'dlsave@capitecbank.co.za';

        for (EmailMessage email : lstNewEmailMessages) {
            if (email.ParentId != null && email.ParentId.getSObjectType() == Case.SObjectType) {
                setCaseIds.add(email.ParentId);
            }
        }
        System.debug('handleVerifyAttachments setCaseIds: ' + setCaseIds);

        if(!setCaseIds.isEmpty() && setCaseIds != null){
            Map<Id, Case> mapCaseIdToCase = new Map<Id, Case>([ SELECT Id, Assignment_Reason__c 
                                                                FROM Case 
                                                                WHERE Id IN :setCaseIds
                                                              ]);

            System.debug('handleVerifyAttachments mapCaseIdToCase: ' + mapCaseIdToCase);                                                 

            if(!mapCaseIdToCase.isEmpty() && mapCaseIdToCase != null){
                for (EmailMessage email : lstNewEmailMessages) {
                    System.debug('handleVerifyAttachments ANALYZING attachment : ' + email.HasAttachment);
                    System.debug('handleVerifyAttachments ANALYZING status : ' + email.status);

                    if (mapCaseIdToCase.containsKey(email.ParentId) && email.ToAddress != null) {

                        Case caseRec = mapCaseIdToCase.get(email.ParentId);
                        Set <String> setRecipientEmails =  getEmailAddresses(email.ToAddress);
                        
                        System.debug('handleVerifyAttachments Case reason : ' + caseRec.Assignment_Reason__c);
                        System.debug('handleVerifyAttachments setAssignmentReasons.contains(caseRec.Assignment_Reason__c) : ' + setAssignmentReasons.contains(caseRec.Assignment_Reason__c));
                        System.debug('handleVerifyAttachments setRecipientEmails : ' + setRecipientEmails);
                        System.debug('handleVerifyAttachments emailAdressToBlock : ' + emailAdressToBlock);
                        System.debug('handleVerifyAttachments setRecipientEmails.contains(emailAdressToBlock) : ' + setRecipientEmails.contains(emailAdressToBlock.toLowerCase()));

                        if (caseRec != null && 
                            caseRec.Assignment_Reason__c != null &&
                            setAssignmentReasons.contains(caseRec.Assignment_Reason__c) &&
                            setRecipientEmails.contains(emailAdressToBlock.toLowerCase())
                           ) {
                            System.debug('handleVerifyAttachments conditions met');  
                            if (!email.HasAttachment) {
                                System.debug('handleVerifyAttachments no attachment found for: ' + email); 
                                email.addError('Cannot send an email without attachments when assignment reason is "Technical issue with submitted notice" or "Technical issue with submitting notice".');
                            }
                        }
                    }
                }   
            }

        }
        System.debug('handleVerifyAttachments END');
    }


    public static set<String> getEmailAddresses(String recipientEmails){
        System.debug('getEmailAddresses START WITH' + recipientEmails);
        List<String> lstEmailAddresses = recipientEmails.split(';');

        Set<String> setEmailAddresses = new Set<String>();

        for (String email : lstEmailAddresses) {
            if(email.trim() != null){
                setEmailAddresses.add(email.trim().toLowerCase());
            }
        }
        System.debug('getEmailAddresses setEmailAddresses :' + setEmailAddresses);
        return setEmailAddresses;
    }

}