public class IC_API_ObligationServiceV3Queueable implements Finalizer, Queueable, Database.AllowsCallouts {
    
    @InvocableMethod(label='Make Callout to Obligation Service V3 Bulk')
    public static List<Id> enqueJob(List<IC_API_ObligationServiceV3.FlowRequest> flowRequests) {
        List<Id> results = new List<Id>();
        for(IC_API_ObligationServiceV3.FlowRequest request : flowRequests) {
            ID jobId = System.enqueueJob(new IC_API_ObligationServiceV3Queueable(request));
            results.add(jobId);
        }
        return results;
    }
    
    private IC_API_ObligationServiceV3.FlowRequest flowRequest;
    private String result;
    
    public IC_API_ObligationServiceV3Queueable(IC_API_ObligationServiceV3.FlowRequest flowRequest) {
        this.flowRequest = flowRequest;
    }

    public void execute(QueueableContext context) {
        System.attachFinalizer(new IC_API_ObligationServiceV3Queueable(flowRequest));
        result = IC_API_ObligationServiceV3.makePolicyCallout(new IC_API_ObligationServiceV3.FlowRequest[] { flowRequest })[0];
    }
    
    public void execute(FinalizerContext ctx) {
        String message = '';
        if (ctx.getResult() != ParentJobResult.SUCCESS) {
            message = 'Error: ' + ctx.getException().getMessage();
        } else if (result != null && !result.containsIgnoreCase('Success')) {
            message = result;
        }else {
            message = 'Successfully completed.';
        }
        notifyUser(flowRequest, message);
    }
    
    public static void notifyUser(IC_API_ObligationServiceV3.FlowRequest request, String message) {
        
        CustomNotificationType nType = [SELECT Id, DeveloperName 
                                        FROM CustomNotificationType 
                                        WHERE DeveloperName='IC_Case_Notification'];
        
        Messaging.CustomNotification notif = new Messaging.CustomNotification();
        notif.setTitle('Get Obligation Callout');
        notif.setBody(message);
        notif.setNotificationTypeId(nType.Id);
        notif.setTargetId([SELECT Id
                           FROM Case 
                           WHERE CaseNumber = :request.caseNumber LIMIT 1].Id);
        
        notif.send(new Set<String> {Userinfo.getUserId()});
    }
    
}