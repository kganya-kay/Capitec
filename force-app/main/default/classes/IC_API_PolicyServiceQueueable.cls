/*******************************************************************
* @Class Name        :  IC_API_PolicyServiceQueueable
* @Test Class        :  IC_API_PolicyServiceQueueable_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 25-Feb-2023, Jira Tickets: ICS-426 
* @Version           :  1.0
*
*******************************************************************/

public class IC_API_PolicyServiceQueueable implements Queueable, Database.AllowsCallouts {
    private List<IC_API_PolicyService.FlowRequest> flowRequests;

    public IC_API_PolicyServiceQueueable(List<IC_API_PolicyService.FlowRequest> flowRequests) {
        this.flowRequests = flowRequests;
    }

    public void execute(QueueableContext context) {
        List<String> results = IC_API_PolicyService.makePolicyCallout(flowRequests);
    }
}