public class Capitec_BranchDetails {

    @InvocableMethod(label='Update Branch Consultant Details' category='Case' callout=true)
    public static List<Case> updateBranchDetails(List<String> cpNumber) {
        List<Case> caseList = new List<Case>();
      	caseList.add(makeCallout(cpNumber[0]));
        return caseList;
    }

    private static Case makeCallout(String cpNumber) {
        Case returnCase = new Case();
        //String endpoint = 'https://api-client-domain-int.int.capinet/strack-proxy/incident-management/v1/user/' + cpNumber;
        String endpoint = 'callout:CapiEndpoints/client'+'/strack-proxy/incident-management/v1/user/'+ cpNumber;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
		ResponseBodyWrapper result;
        try {
            Http http = new Http();
            HttpResponse response = http.send(request);
			System.debug('getStatusCode: ' + response.getStatusCode());
			System.debug('response: ' + response);
            // Process the response as needed
            if (response.getStatusCode() == 200) {
                // Successful response handling
                result = (ResponseBodyWrapper)System.JSON.deserialize(response.getBody(), ResponseBodyWrapper.class);
                System.debug('result: ' + result);    
                    returnCase.Branch_Consultant_First_Name__c = result.firstName;
                    returnCase.Branch_Consultant_Last_Name__c = result.lastName;
                    returnCase.Branch_Consultant_Email__c = result.email;
                    returnCase.Branch_Consultant_CP_Number__c = result.loginId;
                    returnCase.ND_Branch_Name__c = result.branchName;
                    returnCase.Branch_Code__c = result.branchId;

                    //update fields here
                System.debug('returnCase: ' + returnCase);    
                //update caseObj;

            } else {
                // Handle non-200 status codes
                System.debug('Callout failed, StatusCode: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            // Handle exceptions
            System.debug('Exception Exception: ' + e.getMessage());
        }
        return returnCase;
    }

    public class ResponseBodyWrapper {
        public String firstName {get; set;}
        public String lastName {get; set;}
        public String email {get; set;}
        public String department {get; set;}
        public String location {get; set;}
        public String status {get; set;}
        public String loginId {get; set;}
        public String primaryTeam {get; set;}
        public String branchId {get; set;}
        public String branchName {get; set;}
    }
}