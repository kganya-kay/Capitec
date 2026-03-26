/**
 * @description Class to generate notifications based on the provided notification tasks and templates.
 * @author      Johan Langenhoven
 * @date        2024/10/15
 */
public with sharing class Capitec_FlowGenerateNotification {

    /**
    * @description Generates notifications based on the provided requests.
    * @param requests List of Request objects containing the details for generating notifications.
    * @return List of Response objects containing the generated notification messages and parameters.
    */
    @InvocableMethod(Label='Generate Notification' Description='Generates a notification based on the notification task.' Category='Notification' IconName='slds:standard:merge')
    public static List<Response> generateNotification(List<Request> requests) {
        // List to hold the output results
        List<Response> responses = new List<Response>();

        for (Request request : requests) {
            Response response = new Response();

            QuickText quickText = request.notificationTemplate;
            Set<Id> recordIds = new Set<Id>(request.mergeRecordIds);

            Capitec_MergeQuickTextUtility.MergedQuickText mergedQuickText = Capitec_MergeQuickTextUtility.generateMergedText(recordIds, quickText);

            response.templateMessage = mergedQuickText.message;
            response.templateParameters = mergedQuickText.mergedFields;

            responses.add(response);
        }

        return responses;
    }

    /**
    * @description Class representing the request for generating a notification.
    */
    public class Request {
        /**
        * @description The record Ids that will be used to generate the notification.
        */
        @InvocableVariable(Label='Merge Record Ids' Description='The record Ids that will be used to generate the notification.' Required=true)
        public List<Id> mergeRecordIds;
        /**
        * @description The task record that will be used to store notification.
        */
        @InvocableVariable(Label='Notification Task' Description='The task record that will be to store notification.' Required=true)
        public Task notificationTask;
        /**
        * @description The task record that will be used to store notification.
        */
        @InvocableVariable(Label='Notification Template' Description='The QuickText template used for the notification task.' Required=true)
        public QuickText notificationTemplate;
    }

    /**
    * @description Class representing the response after generating a notification.
    */
    public class Response {
        /**
        * @description The notification message that will be sent.
        */
        @InvocableVariable(Label='Template Message' Description='The notification message that will be sent.' Required=true)
        public String templateMessage;
        /**
        * @description List of parameters to be used in the template.
        */
        @InvocableVariable(Label='Template Parameters' Description='List of parameters to be used in the template.' Required=true)
        public List<String> templateParameters;
    }
}