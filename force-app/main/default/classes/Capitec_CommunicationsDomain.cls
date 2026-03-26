/**
 * @description Class to send notifications via REST API. Implements Queueable and Database.AllowsCallouts interfaces to allow asynchronous processing and callouts.
 * @author     Johan Langenhoven
 * @date       14/10/2024
**/
public with sharing class Capitec_CommunicationsDomain implements Queueable, Database.AllowsCallouts {

    private static final String SERVICE_NAME = 'NotificationService';
    private static final String HTTP_POST = 'POST';
    private static final String EMPTY_STRING = '';
    private static final Integer TIMEOUT = 20000;
    private static final Integer SUCCESS_STATUS_CODE = 200;
    private static final Integer SERVICE_UNAVAILABLE_STATUS_CODE = 503;

    public Task notificationTask;
    public List<String> templateParams;

    /**
    * @description Constructor to initialize the Capitec_CommunicationsDomain class.
    * @param notificationTask Task object containing notification details.
    * @param templateParams List of parameters to be used in the template.
    */
    public Capitec_CommunicationsDomain(Task notificationTask, List<String> templateParams) {
        this.notificationTask = notificationTask;
        this.templateParams = templateParams;
    }

    /**
    * @description Executes the queueable job to send the notification via REST API.
    * @param context Queueable context.
    */
    public void execute(QueueableContext context) {
        try {
            WebServiceSettings__c webServiceSettings = WebServiceSettings__c.getValues(SERVICE_NAME);

            CommunicationsDomainWrapper request = new CommunicationsDomainWrapper
                    (
                            EMPTY_STRING,
                            notificationTask.Template_Id__c,
                            EMPTY_STRING,
                            EMPTY_STRING,
                            notificationTask.CIF_Number__c,
                            formatPhoneNumber(notificationTask.Phone_Number__c),
                            DeliveryChannel.valueOf(notificationTask.Delivery_Channel__c),
                            templateParams,
                            EMPTY_STRING,
                            notificationTask.Source_System__c
                    );

            Http http = new Http();
            HttpRequest httpRequest = new HttpRequest();

            httpRequest.setTimeout(TIMEOUT);
            httpRequest.setMethod(HTTP_POST);
            httpRequest.setEndpoint(webServiceSettings.Scheme__c + webServiceSettings.Named_Credential__c + webServiceSettings.Endpoint_URL__c);
            httpRequest.setBody(JSON.serialize(request));

            HttpResponse httpResponse = http.send(httpRequest);

            if (httpResponse.getStatusCode() == SUCCESS_STATUS_CODE) {
                notificationTask.Status_Code__c = httpResponse.getStatusCode();
                notificationTask.Response__c = httpResponse.getBody();
            } else {
                notificationTask.Status_Code__c = httpResponse.getStatusCode();
                notificationTask.Response__c = httpResponse.getBody();
                throw new CommunicationsDomainException('Error occurred while sending notification with status code: ' + httpResponse.getStatusCode());
            }
        } catch (Exception except) {
            notificationTask.Status_Code__c = SERVICE_UNAVAILABLE_STATUS_CODE;
            notificationTask.Response__c = except.getMessage();
        } finally {
            update notificationTask;
        }
    }

    /**
    * @description Formats phone number by removing country code if it starts with +27.
    * @param phoneNumber Phone number to be formatted.
    * @return Returns formatted phone number.
    */
    public static String formatPhoneNumber(String phoneNumber) {
        if (phoneNumber != null && phoneNumber.startsWith('+27')) {
            return '0' + phoneNumber.substring(3);
        }
        return phoneNumber;
    }

    /**
    * @description Wrapper class for the notification callout request body.
    */
    public class CommunicationsDomainWrapper {

        public String entityId;
        public String templateID;
        public String campaignName;
        public String skill;
        public String cifNumber;
        public String clientcellNumber;
        public String outboundNumber;
        public DeliveryChannel deliveryChannel;
        public List<String> templateParameters;
        public String expires;
        public String sourceSystem;

        /**
        * @description Constructor to initialize the CommunicationsDomainWrapper class.
        * @param entityId Entity Id.
        * @param templateID Template Id.
        * @param campaignName Campaign name.
        * @param skill Skill.
        * @param cifNumber Customer Identification Number.
        * @param clientcellNumber Client cell number.
        * @param deliveryChannel Delivery channel for the notification.
        * @param templateParameters List of parameters to be used in the template.
        * @param expires Expiry date/time.
        * @param sourceSystem Source system initiating the notification.
        */
        public CommunicationsDomainWrapper
                (
                        String entityId,
                        String templateID,
                        String campaignName,
                        String skill,
                        String cifNumber,
                        String clientcellNumber,
                        DeliveryChannel deliveryChannel,
                        List<String> templateParameters,
                        String expires,
                        String sourceSystem
                ) {
            this.entityId = entityId;
            this.templateID = templateID;
            this.campaignName = campaignName;
            this.skill = skill;
            this.cifNumber = cifNumber;
            this.clientcellNumber = clientcellNumber;
            this.outboundNumber = outboundNumber;
            this.deliveryChannel = deliveryChannel;
            this.templateParameters = templateParameters;
            this.expires = expires;
            this.sourceSystem = sourceSystem;
        }
    }

    /**
     * @description Enum for notification delivery channels.
     */
    public enum DeliveryChannel {
        NotSpecified,
        InAppMailbox,
        InApp,
        Sms
    }

    /**
    * @description Exception class for notification errors.
    */
    public class CommunicationsDomainException extends Exception {
    }
}