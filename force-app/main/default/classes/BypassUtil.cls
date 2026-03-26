/**
* Test Class:       BypassUtil_TEST
* Author           	Evans Lacour
* Company          	BlueSky
* Ticket      		ICS-948, ICS-1698
**/
public class BypassUtil {
    
    public class FlowRequest {
        @InvocableVariable(label='Enable Bypass')
        public Boolean enable;
        
        @InvocableVariable(label='Disable Bypass')
        public Boolean disable;
        
        @InvocableVariable(label='Disable Validation Rules')
        public Boolean disableValidationRules;
    }
    
    @InvocableMethod(label='Manage Bypass Settings')
    public static List<String> manageBypass(List<FlowRequest> requests) {
        List<String> results = new List<String>();
        String result = '';
        
        FlowRequest request = requests[0];

        Bypass__c bypass = Bypass__c.getValues(UserInfo.getUserId());
        
        if (bypass == null) {
            bypass = new Bypass__c(SetupOwnerId=UserInfo.getUserId()) ;
            insert bypass;
        }
        
        if (request.enable != null && request.enable) {
            bypass.DisableValidationRules__c = request.disableValidationRules;
            result = 'Enabled';
        } else if (request.disable != null && request.disable)  {
            bypass.DisableValidationRules__c = false;
            result = 'Disabled';
        }
        
        for (FlowRequest req : requests) {
            results.add(result);
        }
        
        update bypass;
        
        return results;
    }
}