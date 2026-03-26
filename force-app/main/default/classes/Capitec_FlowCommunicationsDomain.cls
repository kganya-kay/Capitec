/**
 * @description          : This class contains an invocable method that can be called from Salesforce flows to send notifications.
 * @date                 : 22/09/2024
 * @author               : Johan Langenhoven
**/
public with sharing class Capitec_FlowCommunicationsDomain {
    /**
    * @description: Invocable method to send notifications.
    * This method enqueues a job for each request to send notifications asynchronously.
    * @param requests: List of Requests objects containing the notification details.
    * @invocableMethod: This annotation makes the method available to be called from Salesforce flows.
    */
    @InvocableMethod(Label='Send Notification' Category='Notification' Description='Send a notification to a client.' IconName='slds:custom:custom53')
    public static void queueNotifications(List<Requests> requests) {
        List<Capitec_CommunicationsDomain> jobs = new List<Capitec_CommunicationsDomain>();
        for (Requests request : requests) {
            Task notificationTask = request.notificationTask;
            List<String> templateParameters = request.templateParameters;

            jobs.add(new Capitec_CommunicationsDomain(
                    notificationTask,
                    templateParameters
            ));
        }
        enqueueJobs(jobs);
    }

    /**
    * @description: Enqueues a list of Capitec_ApiRestNotification jobs to be processed asynchronously.
    * @param jobs: List of Capitec_ApiRestNotification objects representing the notification jobs to be enqueued.
    * @private
    */
    private static void enqueueJobs(List<Capitec_CommunicationsDomain> jobs) {
        for (Capitec_CommunicationsDomain job : jobs) {
            System.enqueueJob(job);
        }
    }

    /**
     * @description: Inner class to hold the request parameters for the notification.
     * This class is used to pass the necessary data to the notification method.
     * @variables:
     * - notificationTask    : Id of the template to use for the notification.
     * - templateParameters  : List of parameters to be used in the template.
     */
    public class Requests {
        @InvocableVariable(Label='Notification Task' Description='The task record that will be used to send a notification.' Required=true)
        public Task notificationTask;
        @InvocableVariable(Label='Template Parameters' Description='List of parameters to be used in the template.')
        public List<String> templateParameters;
    }
}