/*******************************************************************
* @Class Name        :  IC_API_ZipFileServiceQueueable
* @Test Class        :  IC_API_ZipFileServiceQueueable_TEST
* @Author            :  Evans
* @Last Modified By  :  Evans, 17-Apr-2024, Jira Tickets:  ICS-855
* @Version           :  1.0
*
*******************************************************************/
public class IC_API_ZipFileServiceQueueable implements Finalizer, Queueable, Database.AllowsCallouts {
    private IC_API_ZipFileService.FlowRequest flowRequest;

    public IC_API_ZipFileServiceQueueable(IC_API_ZipFileService.FlowRequest flowRequest) {
        this.flowRequest = flowRequest;
    }

    public void execute(QueueableContext context) {
        System.attachFinalizer(new IC_API_ZipFileServiceQueueable(flowRequest));
        List<String> results = IC_API_ZipFileService.processCaseFiles(new List<IC_API_ZipFileService.FlowRequest> { flowRequest });
    }
    
    public void execute(FinalizerContext ctx) {
        if (ctx.getResult() != ParentJobResult.SUCCESS) {
            String message = 'Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team.';
            if (ctx.getException().getMessage().toLowercase().contains('heap size')) {
                message += ' The zip file could not be created due to file size limitations, please create the zip file & manually send email.';
            } else {
                message += ' ' + ctx.getException().getMessage();
            }
            IC_API_ZipFileService.notifyUser(flowRequest.parentCaseId, message);
        }
    }
    
    @InvocableMethod(label='ZipFileServiceQueueable Process Case Files')
    public static List<Id> enqueJob(List<IC_API_ZipFileService.FlowRequest> flowRequests) {
        List<Id> results = new List<Id>();
        for(IC_API_ZipFileService.FlowRequest request : flowRequests) {
            ID jobId = System.enqueueJob(new IC_API_ZipFileServiceQueueable(request));
            results.add(jobId);
        }
        return results;
    }
}