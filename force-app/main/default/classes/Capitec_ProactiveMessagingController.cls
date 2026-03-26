/**
 * @description Controller class for handling proactive messaging functionalities.
 * This class provides methods to retrieve proactive messaging skills, templates,
 * generate proactive messages, and initiate proactive messaging interactions.
 */
public with sharing class Capitec_ProactiveMessagingController {

    /**
     * @description RecordTypeId for the 'Proactive_Message' record type on the Interaction object.
     */
    public static final Id proactiveMessageInteractionRecordTypeId =
            Interaction.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Proactive_Message').getRecordTypeId();

    /**
     * @description RecordTypeId for the 'Proactive_Message' record type on the InteractionSummary object.
     */
    public static final Id proactiveMessageInteractionSummaryRecordTypeId =
            InteractionSummary.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Proactive_Message').getRecordTypeId();

    /**
     * @description Current user information including Id, Name, Email, Profile Name, and SmallPhotoUrl.
     */
    public static User currentUser = [SELECT Id, Name, Email, Profile.Name, SmallPhotoUrl FROM User WHERE Id = :UserInfo.getUserId()];

    /**
     * @description Retrieves proactive messaging skills based on the current user's profile and case details.
     * @param recordId The Id of the Case record for which proactive skills are to be retrieved.
     * @return ProactiveMessagingWrapper A wrapper containing the result of the operation, including the skills data or an error message.
     */
    @AuraEnabled
    public static ProactiveMessagingWrapper getProactiveSkills(Id recordId) {
        try {
            Case proactiveCase = [SELECT Id, CaseNumber, AccountId, Account.Name, ContactId, ContactEmail, ContactPhone FROM Case WHERE Id = :recordId];

            Capitec_GetProactiveSkills getProactiveSkills = new Capitec_GetProactiveSkills(currentUser.Profile.Name);
            getProactiveSkills.execute(null);

            GetSkillsWrapper getSkillsWrapper = new GetSkillsWrapper(
                    currentUser.Name,
                    currentUser.SmallPhotoUrl,
                    proactiveCase.Account.Name,
                    System.now(),
                    getProactiveSkills.profileSkillsWrapper
            );

            return new ProactiveMessagingWrapper(true, JSON.serialize(getSkillsWrapper), null);
        } catch (Exception except) {
            return new ProactiveMessagingWrapper(false, null, except.getMessage());
        }
    }

    /**
     * @description Retrieves proactive messaging templates based on the specified skill Id.
     * @param skillId The Id of the skill for which proactive templates are to be retrieved.
     * @return ProactiveMessagingWrapper A wrapper containing the result of the operation, including the templates data or an error message.
     */
    @AuraEnabled
    public static ProactiveMessagingWrapper getProactiveTemplates(String skillId) {
        try {
            Capitec_GetProactiveTemplates getProactiveTemplates = new Capitec_GetProactiveTemplates(skillId);
            getProactiveTemplates.execute(null);

            return new ProactiveMessagingWrapper(true, JSON.serialize(getProactiveTemplates.proactivesResponseWrapper), null);
        } catch (Exception except) {
            return new ProactiveMessagingWrapper(false, null, except.getMessage());
        }
    }

    /**
     * @description Generates a proactive message based on the specified template and case data.
     * @param recordId The Id of the Case record for which the proactive message is to be generated.
     * @param proactiveTemplate The proactive template in JSON format containing the message content and variables.
     * @return ProactiveMessagingWrapper A wrapper containing the result of the operation, including the generated message or an error message.
     */
    @AuraEnabled
    public static ProactiveMessagingWrapper generateProactiveMessage(Id recordId, String proactiveTemplate) {
        try {
            Capitec_GetProactiveTemplates.Proactive proactive = new Capitec_GetProactiveTemplates.Proactive();
            proactive = (Capitec_GetProactiveTemplates.Proactive) JSON.deserialize(proactiveTemplate, Capitec_GetProactiveTemplates.Proactive.class);

            String soqlQuery = 'SELECT ' + String.join(proactive.salesForceVariables, ', ') + ' FROM Case WHERE Id = :recordId';

            Map<String, Object> bindParams = new Map<String, Object>();
            bindParams.put('recordId', recordId);

            SObject recordData = Database.queryWithBinds(String.escapeSingleQuotes(soqlQuery), bindParams, AccessLevel.SYSTEM_MODE);

            Capitec_ProactiveMessageGenerator.ProcessedProactiveMessage proactiveMessage = Capitec_ProactiveMessageGenerator.processProactiveMessage(JSON.serialize(recordData), proactive.salesForceVariables, proactive.proactiveContent);

            return new ProactiveMessagingWrapper(true, JSON.serialize(proactiveMessage), null);
        } catch (Exception except) {
            return new ProactiveMessagingWrapper(false, null, except.getMessage());
        }
    }

    /**
     * @description Initiates a proactive message by creating an Interaction and InteractionSummary record.
     * @param proactiveMessage The proactive message details in JSON format, including the record Id, template parameters, and other metadata.
     * @return ProactiveMessagingWrapper A wrapper containing the result of the operation, including a success message or an error message.
     */
    @AuraEnabled
    public static ProactiveMessagingWrapper initiateProactiveMessage(String proactiveMessage) {
        try {
            InitiateProactiveMessageWrapper proactiveMessageRequest = (InitiateProactiveMessageWrapper) JSON.deserialize(proactiveMessage, InitiateProactiveMessageWrapper.class);
            Case proactiveCase = [SELECT Id, CaseNumber, AccountId, ContactId, ContactEmail, ContactPhone FROM Case WHERE Id = :proactiveMessageRequest.recordId];

            InteractionSummary interactionSummary = createInteractionData(proactiveCase, currentUser, proactiveMessageRequest);

            Capitec_InitiateProactiveMessage initiateProactiveMessage = new Capitec_InitiateProactiveMessage
                    (
                            proactiveMessageRequest.templateParameters,
                            interactionSummary,
                            proactiveCase,
                            currentUser
                    );

            System.enqueueJob(initiateProactiveMessage);

            return new ProactiveMessagingWrapper(true, null, 'Message queued for sending.');
        } catch (Exception except) {
            return new ProactiveMessagingWrapper(false, null, except.getMessage());
        }
    }

    /**
     * @description Helper method to create Interaction and InteractionSummary records for proactive messaging.
     * @param proactiveCase The Case record associated with the proactive message.
     * @param user The current user initiating the proactive message.
     * @param proactiveMessageRequest The proactive message request details.
     * @return InteractionSummary The created InteractionSummary record.
     */
    private static InteractionSummary createInteractionData(Case proactiveCase, User user, InitiateProactiveMessageWrapper proactiveMessageRequest) {

        Interaction interaction = new Interaction
                (
                        Name = 'Outbound WhatsApp',
                        AccountId = proactiveCase.AccountId,
                        InteractionType = 'Outbound WhatsApp',
                        StartTime = System.now(),
                        EndTime = System.now(),
                        Description = proactiveMessageRequest.proactiveMessage,
                        RecordTypeId = proactiveMessageInteractionRecordTypeId
                );

        insert interaction;

        List<InteractionAttendee> interactionAttendees = new List<InteractionAttendee>();

        InteractionAttendee clientInteractionAttendee = new InteractionAttendee(
                InteractionId = interaction.Id,
                AttendeeType = 'Client',
                ContactId = proactiveCase.ContactId,
                EmailAddress = proactiveCase.ContactEmail
        );

        interactionAttendees.add(clientInteractionAttendee);

        InteractionAttendee employeeInteractionAttendee = new InteractionAttendee(
                InteractionId = interaction.Id,
                AttendeeType = 'Employee',
                UserId = user.Id,
                EmailAddress = user.Email,
                IsOrganizer = true
        );

        interactionAttendees.add(employeeInteractionAttendee);

        insert interactionAttendees;

        ProactiveMessagingSettings__c proactiveMessagingSettings = ProactiveMessagingSettings__c.getInstance();

        InteractionSummary interactionSummary = new InteractionSummary
                (
                        Name = 'Initiate Chat',
                        AccountId = proactiveCase.AccountId,
                        InteractionPurpose = 'Initiate Chat',
                        Status = 'Sent',
                        InteractionId = interaction.Id,
                        RelatedRecordId = proactiveCase.Id,
                        Skill__c = proactiveMessagingSettings.Route_to_Agent_Skill__c,
                        Fallback_Skill_Id__c = proactiveMessageRequest.skillId,
                        Fallback_Skill__c = proactiveMessageRequest.skill,
                        ConfidentialityType = 'Public',
                        Template_Id__c = proactiveMessageRequest.templateId,
                        Department__c = proactiveMessageRequest.department,
                        Type__c = proactiveMessageRequest.type,
                        Priority__c = proactiveMessageRequest.priority,
                        Campaign__c = currentUser.Profile.Name,
                        Team__c = proactiveMessageRequest.teamName,
                        Outbound_Number__c = proactiveMessageRequest.outboundNumber,
                        MeetingNotes = proactiveMessageRequest.proactiveMessage,
                        RecordTypeId = proactiveMessageInteractionSummaryRecordTypeId
                );

        insert interactionSummary;

        return interactionSummary;
    }

    /**
     * @description Wrapper class for holding proactive messaging skills data.
     */
    public class GetSkillsWrapper {
        public String agentName;
        public String agentPhotoUrl;
        public String clientName;
        public Datetime currentDateTime;
        public Capitec_GetProactiveSkills.ProfileSkillsWrapper profileSkillsWrapper;

        /**
         * @description Constructor for GetSkillsWrapper.
         * @param agentName The name of the agent.
         * @param agentPhotoUrl The URL of the agent's photo.
         * @param clientName The name of the client.
         * @param currentDateTime The current date and time.
         * @param profileSkillsWrapper The wrapper containing the profile skills data.
         */
        public GetSkillsWrapper
                (
                        String agentName,
                        String agentPhotoUrl,
                        String clientName,
                        Datetime currentDateTime,
                        Capitec_GetProactiveSkills.ProfileSkillsWrapper profileSkillsWrapper
                ) {
            this.agentName = agentName;
            this.agentPhotoUrl = agentPhotoUrl;
            this.clientName = clientName;
            this.currentDateTime = currentDateTime;
            this.profileSkillsWrapper = profileSkillsWrapper;
        }
    }

    /**
     * @description Wrapper class for holding proactive messaging initiation data.
     */
    public class InitiateProactiveMessageWrapper {
        public Id recordId;
        public String department;
        public String teamName;
        public Integer priority;
        public String type;
        public String outboundNumber;
        public String skill;
        public String skillId;
        public String templateId;
        public List<String> templateParameters;
        public String proactiveMessage;
    }

    /**
     * @description Wrapper class for holding the result of proactive messaging operations.
     */
    public class ProactiveMessagingWrapper {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String Data;
        @AuraEnabled
        public String Message;

        /**
         * @description Constructor for ProactiveMessagingWrapper.
         * @param isSuccess Indicates whether the operation was successful.
         * @param data The data returned by the operation.
         * @param message The message returned by the operation, typically an error message if the operation failed.
         */
        public ProactiveMessagingWrapper(Boolean isSuccess, String data, String message) {
            this.isSuccess = isSuccess;
            this.Data = data;
            this.Message = message;
        }
    }
}