public with sharing class IC_API_DocumentRequests {

    static List<IC_DocumentRequests_API_Settings__mdt> apiSettings = IC_DocumentRequests_API_Settings__mdt.getAll().values();

    public class FlowRequestVariables {
        @InvocableVariable
        public String idNumber;
        @InvocableVariable
        public String cifNumber;
        @InvocableVariable
        public String caseId;
    }
    
    public IC_API_DocumentRequests(){
        
    }    

    public class PolicyModel {
        List<Object> claims;
    }

    @InvocableMethod(label='Make Callout to Get Requested Items' description='Makes a callout to Get Requested Items')
    public static List<List<String>> getSanlamRequests(List<FlowRequestVariables> reqVar) {
        System.debug('IN getSanlamRequests method');
        List<IC_DocumentRequestList__c> documentRequests = new List<IC_DocumentRequestList__c>();
        FlowRequestVariables request = reqVar[0];
        //request.idNumber = '8003210824088';
        //request.cifNumber = '151350094';
        //request.caseId = '500Fg00000BN2u3IAD';
        String requestBody = JSON.serialize(request);
        Integer timeoutValue = Integer.valueOf(apiSettings[0].Timeout_in_seconds__c * 1000);

        List<String> results = new List<String>();
        List<List<String>> resultList = new List<List<String>>();
        
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiSettings[0].Endpoint_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);
            System.debug('requestBody: ' + requestBody);
            req.setTimeout(timeoutValue);
            HttpResponse response = http.send(req);
            
            if (response.getStatusCode() == 200) {
                System.debug('response.getBody() : ' + response.getBody());
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, Object> summaryDetails = (Map<String, Object>) jsonResponse.get('summaryDetails');
                List<Object> policies = (List<Object>) summaryDetails.get('policies');
                System.debug('policies ' + policies);
                if(policies.isEmpty()){
                    results.add('Error: No policies found for this client');
                }
                List<Object> claims = new List<Object>();
                for(Object policy: policies){
                    Map<String, Object> policyTemp = (Map<String, Object>) policy;
                    System.debug('policyTemp ' + policyTemp);
                    if(policyTemp.containsKey('claims')){
                        claims.addAll((List<Object>)policyTemp.get('claims')); 
                    }
                }
                System.debug('claims ' + claims);
                if(claims.isEmpty()){
                    results.add('Error: No claims found for this client');
                }
                List<Object> documentsRequired = new List<Object>();
                for(Object claim: claims){
                    Map<String, Object> claimTemp = (Map<String, Object>) claim;
                    if(claimTemp.containsKey('documentsRequired')){
                        documentsRequired.addAll((List<Object>)claimTemp.get('documentsRequired'));
                    }
                }
              
              	System.debug('documentsRequired ' + documentsRequired);
                if(documentsRequired.isEmpty()){
                    results.add('Error: No Documents Required for this client');
                }
                for (Object document : documentsRequired) {

                    Map<String, Object> documentTemp = (Map<String, Object>) document;
                    IC_DocumentRequestList__c docRequest = new IC_DocumentRequestList__c();
                    docRequest.DocumentCode__c = (String) documentTemp.get('documentCode');
                    docRequest.DocumentName__c = (String) documentTemp.get('documentName');
                    docRequest.Guid__c = (String) documentTemp.get('guid');
                    docRequest.Document_Status__c = (String) documentTemp.get('docStatus');
                    docRequest.Is_Mandatory__c = documentTemp.get('isMandatory') != NULL ? (Boolean) documentTemp.get('isMandatory') : FALSE;
                    docRequest.Case__c = request.caseId; 
                    documentRequests.add(docRequest);
                }
                if (!documentRequests.isEmpty()) {
                    insert documentRequests;
                    System.debug('documentRequests: '  + documentRequests);
                }
                    
            } else {
                 try {
                    Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    if(errorResponse.containsKey('Detail') && !((List<Object>)errorResponse.get('Detail')).isEmpty()) {
                        List<Object> details = (List<Object>)errorResponse.get('Detail');
                        for (Object detail : details) {
                            Map<String, Object> detailMap = (Map<String, Object>) detail;
                            String propertyName = (String) detailMap.get('PropertyName');
                            String errorMessage = (String) detailMap.get('ErrorMessage');
                            results.add('Error: ' + propertyName + ' - ' + errorMessage);
                        }
                    } else {
                        results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team');
                    }
                } catch (Exception e) {
                    results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team');
                }
                String errorMsg = 'HTTP Error: ' + response.getStatusCode() + ' ' + response.getStatus() +'\n';
                System.debug(errorMsg);
                results.add(errorMsg);
            }
        } catch(Exception e) {
            System.debug('Error making HTTP callout: ' + e.getMessage());
            results.add('Error: ' + e.getMessage() + '\n');
        }
        resultList.add(results);
        return resultList;
    }
}