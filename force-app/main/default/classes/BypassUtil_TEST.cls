/**
* Class Covered:    BypassUtil
* Author           	Evans Lacour
* Company          	BlueSky
* Ticket      		ICS-948, ICS-1698
**/
@isTest
private class BypassUtil_TEST {
    
    @isTest
    static void testManageBypass() {
        BypassUtil.FlowRequest request = new BypassUtil.FlowRequest();
        request.enable = true;
        request.disableValidationRules = true;
        
        List<String> results = BypassUtil.manageBypass(new List<BypassUtil.FlowRequest>{request});
        
        Assert.areEqual(1, results.size());
        Assert.areEqual('Enabled', results[0]);
        
        request.enable = false;
        request.disable = true;
        
        results = BypassUtil.manageBypass(new List<BypassUtil.FlowRequest>{request});
        
        Assert.areEqual(1, results.size());
        Assert.areEqual('Disabled', results[0]);     
        
        request.enable = false;
        request.disable = false;
        
        results = BypassUtil.manageBypass(new List<BypassUtil.FlowRequest>{request});
        
        Assert.areEqual(1, results.size());
        Assert.areEqual('', results[0]);  
    }
    
    @isTest
    static void testManageBypassInBulk() {
        
        List<BypassUtil.FlowRequest> requests = new List<BypassUtil.FlowRequest>();
        for (Integer i=0; i<10; i++) {
            BypassUtil.FlowRequest request = new BypassUtil.FlowRequest();
            request.enable = true;
            request.disableValidationRules = true;
            requests.add(request);
        }
        
        List<String> results = BypassUtil.manageBypass(requests);
        
        Assert.areEqual(requests.size(), results.size());
        Assert.areEqual('Enabled', results[0]);
    }
}