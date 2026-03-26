/**
 * @description This class is responsible for retrieving proactive skills for a given profile ID.
 * It implements Queueable and AllowsCallouts to enable asynchronous execution and external API calls.
 */
public with sharing class Capitec_GetProactiveSkills implements Queueable, Database.AllowsCallouts {

    /**
     * @description The name of the web service used to fetch proactive skills.
     */
    private static final String SERVICE_NAME = 'ProactiveSkills';

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
    private String errorMessage = 'Error occurred while retrieving proactive skills with status code: ';

    /**
     * @description The profile ID for which proactive skills need to be retrieved.
     */
    public String profileId;

    /**
     * @description Wrapper to store the retrieved proactive skills.
     */
    public ProfileSkillsWrapper profileSkillsWrapper = new ProfileSkillsWrapper();

    /**
     * @description Constructor to initialize the class with the given profile ID.
     *
     * @param profileId The profile ID for which proactive skills should be fetched.
     */
    public Capitec_GetProactiveSkills(String profileId) {
        this.profileId = profileId;
    }

    /**
     * @description Executes the queueable job to fetch proactive skills via an HTTP callout.
     *
     * @param context The queueable job context.
     */
    public void execute(QueueableContext context) {
        try {
            WebServiceSettings__c webServiceSettings = WebServiceSettings__c.getValues(SERVICE_NAME);
            ProfileIdsWrapper profileIdsWrapper = new ProfileIdsWrapper(profileId);

            Http http = new Http();
            HttpRequest httpRequest = new HttpRequest();

            httpRequest.setTimeout(TIMEOUT);
            httpRequest.setMethod(HTTP_POST);
            httpRequest.setEndpoint(webServiceSettings.Scheme__c + webServiceSettings.Named_Credential__c + webServiceSettings.Endpoint_URL__c);
            httpRequest.setBody(JSON.serialize(profileIdsWrapper));

            HttpResponse httpResponse = http.send(httpRequest);

            if (httpResponse.getStatusCode() == SUCCESS_STATUS_CODE) {
                profileSkillsWrapper = (ProfileSkillsWrapper) JSON.deserialize(httpResponse.getBody(), ProfileSkillsWrapper.class);
            } else {
                throw new GetProactiveSkillsException(errorMessage + httpResponse.getStatusCode());
            }
        } catch (Exception except) {
            errorMessage = except.getMessage();
            throw new GetProactiveSkillsException(errorMessage);
        }
    }

    /**
     * @description Wrapper class for sending profile ID(s) in the API request.
     */
    public class ProfileIdsWrapper {

        /**
         * @description List of profile IDs included in the request.
         */
        public List<String> profileIds = new List<String>();

        /**
         * @description Constructor to initialize the wrapper with a single profile ID.
         *
         * @param profileId The profile ID to be included in the request.
         */
        public ProfileIdsWrapper(String profileId) {
            this.profileIds.add(profileId);
        }
    }

    /**
     * @description Wrapper class to store the retrieved profile skills from the API response.
     */
    public class ProfileSkillsWrapper {

        /**
         * @description List of profile skill objects.
         */
        public List<ProfileSkill> profileSkills;

        /**
         * @description Constructor initializes an empty list of profile skills.
         */
        public ProfileSkillsWrapper() {
            profileSkills = new List<ProfileSkill>();
        }
    }

    /**
     * @description Represents a profile's skills as returned by the API.
     */
    public class ProfileSkill {

        /**
         * @description Unique identifier for the profile skill.
         */
        public Integer id;

        /**
         * @description Name of the profile associated with the skill.
         */
        public String profile;

        /**
         * @description List of skills assigned to the profile.
         */
        public List<Skill> skills;
    }

    /**
     * @description Represents an individual skill associated with a profile.
     */
    public class Skill {

        /**
         * @description Unique identifier for the skill.
         */
        public Integer id;

        /**
         * @description String-based skill ID.
         */
        public String skillId;

        /**
         * @description Name of the skill.
         */
        public String skillName;
    }

    /**
     * @description Custom exception class for errors encountered while retrieving proactive skills.
     */
    public class GetProactiveSkillsException extends Exception {
    }
}