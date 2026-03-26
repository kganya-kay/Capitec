/**
 * @description Queueable class to initiate a proactive message via an external service.
 * Implements Database.AllowsCallouts to perform HTTP callouts asynchronously.
 */
public with sharing class Capitec_InitiateProactiveMessage implements Queueable, Database.AllowsCallouts {

    /**
     * @description Service name identifier for retrieving web service settings.
     */
    private static final String SERVICE_NAME = 'InitiateProactiveMessage';

    /**
     * @description HTTP request method for sending the request.
     */
    private static final String HTTP_POST = 'POST';

    /**
     * @description Timeout duration for HTTP request in milliseconds.
     */
    private static final Integer TIMEOUT = 120000;

    /**
     * @description Expected success status code for HTTP response.
     */
    private static final Integer SUCCESS_STATUS_CODE = 200;

    /**
     * @description Default error message prefix for callout failures.
     */
    private String errorMessage = 'Error occurred while sending the proactive message with status code: ';

    /**
     * @description Mapping interaction types to their corresponding API values.
     */
    private static final Map<String, String> typeMap = new Map<String, String>{
            'Service' => 'SERVICE', 'Marketing' => 'MARKETING', 'Utility' => 'UTILITY'
    };

    /**
     * @description Mapping outbound number types to their corresponding API values.
     */
    private static final Map<String, String> outboundNumberMap = new Map<String, String>{
            'Employee' => 'EMPLOYEE', 'Client' => 'CLIENT'
    };

    /** @description List of template parameters for the proactive message. */
    public List<String> templateParameters;

    /** @description Interaction summary record associated with the proactive message. */
    public InteractionSummary interactionSummary;

    /** @description Case record related to the proactive message. */
    public Case proactiveCase;

    /** @description User initiating the proactive message. */
    public User user;

    /**
     * @description Constructor to initialize the proactive message parameters.
     *
     * @param templateParameters List of parameters for the message template.
     * @param interactionSummary Interaction summary related to the message.
     * @param proactiveCase Case associated with the message.
     * @param user User initiating the message.
     */
    public Capitec_InitiateProactiveMessage(
            List<String> templateParameters,
            InteractionSummary interactionSummary,
            Case proactiveCase,
            User user
    ) {
        this.templateParameters = templateParameters;
        this.interactionSummary = interactionSummary;
        this.proactiveCase = proactiveCase;
        this.user = user;
    }

    /**
     * @description Executes the queueable job to initiate the proactive message.
     *
     * @param context Queueable context instance.
     */
    public void execute(QueueableContext context) {
        try {
            WebServiceSettings__c webServiceSettings = WebServiceSettings__c.getValues(SERVICE_NAME);

            MetadataWrapper metadataWrapper = new MetadataWrapper();

            metadataWrapper.addMetadataEntry('caseId', proactiveCase.CaseNumber);
            metadataWrapper.addMetadataEntry('fallbackSkillId', interactionSummary.Fallback_Skill_Id__c);

            ProactiveMessageWrapper request = new ProactiveMessageWrapper(
                    Integer.valueOf(interactionSummary.Priority__c),
                    interactionSummary.Department__c,
                    interactionSummary.Team__c,
                    user.Email,
                    typeMap.get(interactionSummary.Type__c),
                    interactionSummary.Campaign__c,
                    interactionSummary.Skill__c,
                    interactionSummary.Template_Id__c,
                    outboundNumberMap.get(interactionSummary.Outbound_Number__c),
                    formatPhoneNumber(proactiveCase.ContactPhone),
                    createTemplateParameters(templateParameters),
                    new List<Map<String, String>>(),
                    new List<Map<String, String>>(),
                    metadataWrapper.metadata
            );

            Http http = new Http();
            HttpRequest httpRequest = new HttpRequest();

            httpRequest.setTimeout(TIMEOUT);
            httpRequest.setMethod(HTTP_POST);
            httpRequest.setEndpoint(webServiceSettings.Scheme__c + webServiceSettings.Named_Credential__c + webServiceSettings.Endpoint_URL__c);
            httpRequest.setBody(JSON.serialize(request));

            HttpResponse httpResponse = http.send(httpRequest);

            System.debug(JSON.serialize(request));

            if (httpResponse.getStatusCode() == SUCCESS_STATUS_CODE) {
                interactionSummary.Status = 'Completed';
                interactionSummary.Status_Code__c = httpResponse.getStatusCode();
                interactionSummary.Integration_Response__c = httpResponse.getBody();
            } else {
                interactionSummary.Status = 'Failed';
                interactionSummary.Status_Code__c = httpResponse.getStatusCode();
                interactionSummary.Integration_Response__c = httpResponse.getBody();
                throw new InitiateProactiveMessageException(errorMessage + httpResponse.getStatusCode());
            }
        } catch (Exception except) {
            errorMessage = except.getMessage();
        } finally {
            update interactionSummary;
        }
    }

    /**
     * @description Formats a phone number to international format.
     *
     * @param phoneNumber The local phone number.
     * @return The formatted phone number in international format.
     */
    public static String formatPhoneNumber(String phoneNumber) {
        if (phoneNumber != null && phoneNumber.startsWith('0')) {
            return '+27' + phoneNumber.substring(1);
        }
        return phoneNumber;
    }

    /**
     * @description Creates a list of template parameters in the required format.
     *
     * @param templateParams List of template parameters.
     * @return List of key-value mappings representing the template parameters.
     */
    public static List<Map<String, String>> createTemplateParameters(List<String> templateParams) {
        List<Map<String, String>> templateParameters = new List<Map<String, String>>();

        if (templateParams != null && !templateParams.isEmpty()) {
            for (Integer i = 1; i <= templateParams.size(); i++) {
                Map<String, String> templateParameter = new Map<String, String>{
                        'key' => String.valueOf(i),
                        'value' => templateParams[i - 1]
                };
                templateParameters.add(templateParameter);
            }
        }
        return templateParameters;
    }

    /**
     * @description Wrapper class representing the proactive message payload.
     */
    public class ProactiveMessageWrapper {
        public Integer priority;
        public String department;
        public String teamName;
        public String agentEmail;
        public String type;
        public String campaignName;
        public String skill;
        public String templateId;
        public String outboundNumber;
        public String clientCellNumber;
        public List<Map<String, String>> templateParameters;
        public List<Map<String, String>> headerParameters;
        public List<Map<String, String>> buttonParameters;
        public List<Map<String, String>> metadata;

        /**
         * @description Constructor to initialize the proactive message payload.
         *
         * @param priority Priority level of the message.
         * @param department Department associated with the message.
         * @param teamName Team handling the message.
         * @param agentEmail Email of the agent sending the message.
         * @param type Type of message being sent.
         * @param campaignName Name of the campaign.
         * @param skill Associated skill for handling the message.
         * @param templateId ID of the message template.
         * @param outboundNumber Outbound number for sending the message.
         * @param clientCellNumber Recipient's phone number.
         * @param templateParameters Template parameters for message personalization.
         * @param headerParameters Header parameters for the message.
         * @param buttonParameters Button parameters for interactive messages.
         * @param metadata Additional metadata related to the message.
         */
        public ProactiveMessageWrapper(
                Integer priority,
                String department,
                String teamName,
                String agentEmail,
                String type,
                String campaignName,
                String skill,
                String templateId,
                String outboundNumber,
                String clientCellNumber,
                List<Map<String, String>> templateParameters,
                List<Map<String, String>> headerParameters,
                List<Map<String, String>> buttonParameters,
                List<Map<String, String>> metadata
        ) {
            this.priority = priority;
            this.department = department;
            this.teamName = teamName;
            this.agentEmail = agentEmail;
            this.type = type;
            this.campaignName = campaignName;
            this.skill = skill;
            this.templateId = templateId;
            this.outboundNumber = outboundNumber;
            this.clientCellNumber = clientCellNumber;
            this.templateParameters = templateParameters;
            this.headerParameters = headerParameters;
            this.buttonParameters = buttonParameters;
            this.metadata = metadata;
        }
    }

    /**
     * @description Wrapper class to store metadata as a list of key-value pairs.
     */
    public class MetadataWrapper {

        /**
         * @description A list of maps, where each map represents a metadata entry with key-value pairs.
         */
        public List<Map<String, String>> metadata;

        /**
         * @description Constructor to initialize the metadata list.
         */
        public MetadataWrapper() {
            metadata = new List<Map<String, String>>();
        }

        /**
         * @description Adds a metadata entry to the list.
         * @param key The key representing the metadata field.
         * @param value The value associated with the key.
         */
        public void addMetadataEntry(String key, String value) {
            Map<String, String> metadataEntry = new Map<String, String>{
                    'key' => key,
                    'value' => value
            };
            metadata.add(metadataEntry);
        }
    }

    /**
     * @description Custom exception class for proactive message errors.
     */
    public class InitiateProactiveMessageException extends Exception {
    }
}