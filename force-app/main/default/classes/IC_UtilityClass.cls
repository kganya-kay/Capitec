/**
* Class Name:       IC_UtilityClass
* Test Class:       IC_UtilityClass_TEST
* Author:          	Ridwan Moosuddee
* Company:         	BlueSky
* Description:  	Utility class containing common methods that can be used across all dev works
**/
public class IC_UtilityClass {

    @InvocableMethod(label='Get Thread Token' description='Returns the Thread Token for a given Case ID')
    public static List<ThreadTokenResponse> getThreadToken(List<ThreadTokenRequest> requests) {
        List<ThreadTokenResponse> responses = new List<ThreadTokenResponse>();
        
        for (ThreadTokenRequest request : requests) {
            String caseId = request.caseId;
            String formattedToken = EmailMessages.getFormattedThreadingToken(caseId);
            
            ThreadTokenResponse response = new ThreadTokenResponse();
            response.threadToken = formattedToken;
            responses.add(response);
        }
        
        return responses;
    }

    // Inner class to hold input variables
    public class ThreadTokenRequest {
        @InvocableVariable(required=true)
        public String caseId;
    }
    
    // Inner class to hold output variables
    public class ThreadTokenResponse {
        @InvocableVariable
        public String threadToken;
    }
}