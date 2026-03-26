/**
 * @description This class retrieves proactive templates for a given skill ID.
 * It implements Queueable and AllowsCallouts to enable asynchronous execution and external API calls.
 */
public with sharing class Capitec_GetProactiveTemplates implements Queueable, Database.AllowsCallouts {

    /**
     * @description The name of the web service used to fetch proactive templates.
     */
    private static final String SERVICE_NAME = 'ProactiveTemplates';

    /**
     * @description The HTTP method used for the API request.
     */
    private static final String HTTP_POST = 'POST';

    /**
     * @description Timeout duration for the HTTP request in milliseconds.
     */
    private static final Integer TIMEOUT = 120000;

    /**
     * @description Expected HTTP status code for a successful response.
     */
    private static final Integer SUCCESS_STATUS_CODE = 200;

    /**
     * @description Default error message used when an exception occurs during the API call.
     */
    private String errorMessage = 'Error occurred while retrieving proactive templates with status code: ';

    /**
     * @description The skill ID for which proactive templates need to be retrieved.
     */
    public String skillId;

    /**
     * @description Wrapper to store the retrieved proactive templates.
     */
    public ProactivesResponseWrapper proactivesResponseWrapper = new ProactivesResponseWrapper();

    /**
     * @description Constructor to initialize the class with the given skill ID.
     *
     * @param skillId The skill ID for which proactive templates should be fetched.
     */
    public Capitec_GetProactiveTemplates(String skillId) {
        this.skillId = skillId;
    }

    /**
     * @description Executes the queueable job to fetch proactive templates via an HTTP callout.
     *
     * @param context The queueable job context.
     */
    public void execute(QueueableContext context) {
        try {
            WebServiceSettings__c webServiceSettings = WebServiceSettings__c.getValues(SERVICE_NAME);
            SkillWrapper skillWrapper = new SkillWrapper(skillId);

            Http http = new Http();
            HttpRequest httpRequest = new HttpRequest();

            httpRequest.setTimeout(TIMEOUT);
            httpRequest.setMethod(HTTP_POST);
            httpRequest.setEndpoint(webServiceSettings.Scheme__c + webServiceSettings.Named_Credential__c + webServiceSettings.Endpoint_URL__c);
            httpRequest.setBody(JSON.serialize(skillWrapper));

            HttpResponse httpResponse = http.send(httpRequest);

            if (httpResponse.getStatusCode() == SUCCESS_STATUS_CODE) {
                proactivesResponseWrapper = (ProactivesResponseWrapper) JSON.deserialize(httpResponse.getBody(), ProactivesResponseWrapper.class);
            } else {
                throw new GetProactiveTemplatesException(errorMessage + httpResponse.getStatusCode());
            }
        } catch (Exception except) {
            errorMessage = except.getMessage();
            throw new GetProactiveTemplatesException(errorMessage);
        }
    }

    /**
     * @description Wrapper class for sending the skill ID in the API request.
     */
    public class SkillWrapper {

        /**
         * @description The skill ID included in the request.
         */
        public String skillId;

        /**
         * @description Constructor to initialize the wrapper with a skill ID.
         *
         * @param skillId The skill ID to be included in the request.
         */
        public SkillWrapper(String skillId) {
            this.skillId = skillId;
        }
    }

    /**
     * @description Wrapper class to store the retrieved proactive templates from the API response.
     */
    public class ProactivesResponseWrapper {

        /**
         * @description List of proactive template objects.
         */
        public List<Proactive> proactives;

        /**
         * @description Constructor initializes an empty list of proactive templates.
         */
        public ProactivesResponseWrapper() {
            proactives = new List<Proactive>();
        }
    }

    /**
     * @description Represents an individual proactive template as returned by the API.
     */
    public class Proactive {

        /**
         * @description Unique identifier for the proactive template.
         */
        public Integer id;

        /**
         * @description String-based proactive template ID.
         */
        public String proactiveId;

        /**
         * @description Name of the proactive template.
         */
        public String proactiveName;

        /**
         * @description Content of the proactive template.
         */
        public String proactiveContent;

        /**
         * @description List of variables used in the proactive template.
         */
        public List<String> proactiveVariables;

        /**
         * @description Indicates whether the proactive template has a header.
         */
        public Boolean proactiveHeader;

        /**
         * @description Footer content of the proactive template.
         */
        public String proactiveFooter;

        /**
         * @description Numeric identifier for the proactive template.
         */
        public Integer numberId;

        /**
         * @description Cellphone number associated with the proactive template.
         */
        public String cellphone;

        /**
         * @description WhatsApp Business Account ID associated with the proactive template.
         */
        public String wabaId;

        /**
         * @description List of Salesforce variables linked to the proactive template.
         */
        public List<String> salesForceVariables;
    }

    /**
     * @description Custom exception class for errors encountered while retrieving proactive templates.
     */
    public class GetProactiveTemplatesException extends Exception {
    }
}