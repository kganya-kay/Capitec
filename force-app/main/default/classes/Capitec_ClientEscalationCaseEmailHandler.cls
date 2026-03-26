/**
 * @description This class handles inbound emails related to client escalation cases.
 * It extends the Capitec_GenericCaseEmailHandler class and overrides the processInboundEmail method.
 * @author by Johan Langenhoven on 2024/10/28.
 */
public with sharing class Capitec_ClientEscalationCaseEmailHandler extends Capitec_GenericCaseEmailHandler {

    /**
    * @description A set of allowed field names that can be used in the SOQL query to retrieve related cases.
    * This set is used to validate the field names provided to the getRelatedCase method.
    */
    private static final Set<String> ALLOWED_FIELDS = new Set<String>{
            'Id',
            'CaseNumber',
            'Subject',
            'Description',
            'Status',
            'IsClosed',
            'RecordTypeId',
            'OwnerId',
            'AccountId',
            'ContactId',
            'ContactEmail',
            'Priority',
            'Primary_Language__c',
            'Capitec_Primary_Need__c',
            'Capitec_Specific_Need__c',
            'CM_Channel__c',
            'CM_Product__c',
            'Strack_Incident_Number__c',
            'Capitec_Transaction_ID__c',
            'Capitec_From_Account__c',
            'Date_of_Transaction__c',
            'Investigate_Dispute_Transaction_Amount__c',
            'Capitec_Recipient_Account__c',
            'Capitec_Recipient_Phone__c',
            'Capitec_Transaction_Type__c',
            'Capitec_Statement_Description__c',
            'CC_Disclaimer_Fee_Accepted__c',
            'Client_Comments__c',
            'Notice_Deposit_Account_Number__c',
            'Notice_Deposit_Withdrawal_Amount__c',
            'ND_Notice_Date__c',
            'ND_Notice_Period__c',
            'Notice_Deposit_UUID__c'
    };

    /**
    * @description Entry point for handling inbound emails.
    * @param email The inbound email message.
    * @param envelope The envelope containing the inbound email.
    * @return Messaging.InboundEmailResult The result of processing the inbound email.
    */
    public override Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        return processInboundEmail(email, envelope);
    }

    /**
     * @description Processes the inbound email and performs actions based on the related case status.
     * @param email The inbound email message.
     * @param envelope The envelope containing the inbound email.
     * @return Messaging.InboundEmailResult The result of processing the inbound email.
     */
    public override Messaging.InboundEmailResult processInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        Case relatedCase;
        Id caseId = getCaseIdFromEmailMessage(email);

        if (caseId != null) {
            relatedCase = getRelatedCase('Id', caseId);
        } else {
            String caseNumber = getCaseNumberFromEmailMessage(email);

            if (caseNumber != null) {
                relatedCase = getRelatedCase('CaseNumber', caseNumber);
            } else {
                String sTrackNumber = getSTrackIncidentNumberFromEmailMessage(email);

                if (sTrackNumber != null) {
                    relatedCase = getRelatedCase('Strack_Incident_Number__c', sTrackNumber);
                }
            }
        }

        if (relatedCase != null) {
            if (!relatedCase.IsClosed && relatedCase.Status != 'Awaiting Client feedback') {
                EmailMessage emailMessage = createEmailMessage(email, relatedCase.Id);
                logEmailAsTask(emailMessage, relatedCase, 'Client_Escalations_Task');
                handleAttachments(email, emailMessage.Id, relatedCase.Id);
                // Send email to the client
                sendSingleEmailUsingTemplate(relatedCase.ContactId, relatedCase.Id, new List<String>{
                        relatedCase.ContactEmail
                }, 'Clients_Seeking_Feedback_1730788189307', true, 'Client Escalations');

            } else if (relatedCase.IsClosed) {

                Group caseQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Client_Escalations_Desk' LIMIT 1];

                Case childCase = relatedCase.clone();

                childCase.ParentId = relatedCase.Id;
                childCase.Status = 'New';
                childCase.OwnerId = caseQueue.Id;
                childCase.Origin = 'Email';
                childCase.Priority = relatedCase.Priority;
                childCase.Capitec_Transaction_ID__c = relatedCase.Capitec_Transaction_ID__c;
                childCase.Capitec_From_Account__c = relatedCase.Capitec_From_Account__c;
                childCase.Date_of_Transaction__c = relatedCase.Date_of_Transaction__c;
                childCase.Investigate_Dispute_Transaction_Amount__c = relatedCase.Investigate_Dispute_Transaction_Amount__c;
                childCase.Capitec_Recipient_Account__c = relatedCase.Capitec_Recipient_Account__c;
                childCase.Capitec_Recipient_Phone__c = relatedCase.Capitec_Recipient_Phone__c;
                childCase.Capitec_Transaction_Type__c = relatedCase.Capitec_Transaction_Type__c;
                childCase.Capitec_Statement_Description__c = relatedCase.Capitec_Statement_Description__c;
                childCase.CC_Disclaimer_Fee_Accepted__c = relatedCase.CC_Disclaimer_Fee_Accepted__c;
                childCase.Client_Comments__c = relatedCase.Client_Comments__c;
                childCase.Notice_Deposit_Account_Number__c = relatedCase.Notice_Deposit_Account_Number__c;
                childCase.Notice_Deposit_Withdrawal_Amount__c = relatedCase.Notice_Deposit_Withdrawal_Amount__c;
                childCase.ND_Notice_Date__c = relatedCase.ND_Notice_Date__c;
                childCase.ND_Notice_Period__c = relatedCase.ND_Notice_Period__c;
                childCase.Notice_Deposit_UUID__c = relatedCase.Notice_Deposit_UUID__c;
                childCase.Strack_Incident_Number__c = relatedCase.Strack_Incident_Number__c;

                insert childCase;

                EmailMessage emailMessage = createEmailMessage(email, childCase.Id);
                logEmailAsTask(emailMessage, childCase, 'Client_Escalations_Task');
                handleAttachments(email, emailMessage.Id, childCase.Id);
            } else {
                EmailMessage emailMessage = createEmailMessage(email, relatedCase.Id);
                logEmailAsTask(emailMessage, relatedCase, 'Client_Escalations_Task');
                handleAttachments(email, emailMessage.Id, relatedCase.Id);
            }
        } else {
            if (!FromAddressCheck(email.fromAddress)) {
                Account account = [SELECT Id, PersonContactId, PersonEmail FROM Account WHERE PersonEmail = :email.fromAddress LIMIT 1];

                if (account != null) {
                    sendSingleEmailUsingTemplate(account.PersonContactId, account.Id, new List<String>{
                            account.PersonEmail
                    }, 'Escalations_Desk_Email_Automated_Response_1730771857507', true, 'Client Escalations');
                }
            }
        }

        return result;
    }

    /**
    * @description Retrieves a related case based on the specified field name and field value.
    * This method dynamically constructs and executes a SOQL query to find the related case.
    * @param fieldName The name of the field to query against. Must be one of the allowed fields.
    * @param fieldValue The value of the field to match in the query.
    * @return Case The related case if found, otherwise null.
    * @throws IllegalArgumentException if the provided field name is not allowed.
    */
    private static Case getRelatedCase(String fieldName, String fieldValue) {
        if (!ALLOWED_FIELDS.contains(fieldName)) {
            throw new IllegalArgumentException('Invalid field name provided: ' + fieldName);
        }

        String fieldsToQuery = String.join(new List<String>(ALLOWED_FIELDS), ',');

        String query = 'SELECT ' + fieldsToQuery + ' FROM Case WHERE ' + fieldName + ' = :value ORDER BY CreatedDate DESC LIMIT 1';

        Map<String, Object> bindParams = new Map<String, Object>{
                'value' => fieldValue
        };

        List<Case> cases = Database.queryWithBinds(String.escapeSingleQuotes(query), bindParams, AccessLevel.SYSTEM_MODE);

        return cases.isEmpty() ? null : cases[0];
    }
}