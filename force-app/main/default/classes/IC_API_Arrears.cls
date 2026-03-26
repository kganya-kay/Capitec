/**
 * @description       : Obligation Service call to process Arrears per policies only [ICS-1831 - Lapsed policies]
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 12-11-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class IC_API_Arrears {

    static List<IC_Get_Obligations_V3_API_Settings__mdt> apiSettings = IC_Get_Obligations_V3_API_Settings__mdt.getAll().values();

    /**
    * @description Mthod to initialise the request and get arrears for the policy on the child case
    * @author Samiirah.A@bsky.co.za | 12-09-2024 
    * @param childCase 
    * @param parentCase 
    * @return List<IC_Arrears__c> 
    **/
    public static List<IC_Arrears__c> getArrearsFromObligationService(Case childCase, Case parentCase){
        List<IC_Arrears__c> lstArrears = new List<IC_Arrears__c>();

        RequestWrapper request = new RequestWrapper();
        request.caseNumber = parentCase.CaseNumber; //takes parent caseNumber
        request.cifNumber = parentCase.CIF_Number__c;
        request.productType = parentCase.Product_Type__c;
        request.caseType = parentCase.IC_Type__c;
        request.caseSubType = parentCase.Sub_Type__c;
        request.lastWorkingDate = parentCase.Last_Working_Date__c;
        request.idNumber = parentCase.Client_ID_Number__c;
        request.eventDate = parentCase.Event_Date__c;
        request.product = 'Funeral';

        String response = makeCallout(request);

        if(response != null){
            lstArrears = processResponse(response, childCase);
        }

        return lstArrears;
    }

    /**
    * @description Callout method to the 'Obligation' service
    * @author Samiirah.A@bsky.co.za | 12-09-2024 
    * @param request 
    * @return String 
    **/
    public static String makeCallout(RequestWrapper request){

        String requestBody = JSON.serialize(request);
        Integer timeoutValue = Integer.valueOf(apiSettings[0].Timeout_in_seconds__c * 1000);
        List<String> results = new List<String>();
        final UUID randomUuid = UUID.randomUUID();
        final String randomUuidStr = randomUuid.toString();

       try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiSettings[0].Endpoint_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-request-id', randomUuidStr);
            req.setHeader('x-session-id', randomUuidStr);
            req.setHeader('x-requester-uid', 'SALESFORCE_00000_12_0000_00');
            req.setBody(requestBody);
            req.setTimeout(timeoutValue);
            
            HttpResponse res = http.send(req);

            System.debug('## makeCallout requestBody: ' + requestBody);
            System.debug('## makeCallout response: ' + res);
            
            if (res.getStatusCode() == 200) {
                
                String responseBody = res.getBody();
                System.debug('## makeCallout response body:' + res.getBody());
                
                if (String.isNotBlank(responseBody)) {
                    Map<String, Object> mapResponseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                    if (mapResponseBody.containsKey('funeral') 
                        && ((Map<String, Object>)mapResponseBody.get('funeral')).containsKey('policies') 
                        && ((List<Object>)((Map<String, Object>)mapResponseBody.get('funeral')).get('policies')).isEmpty()) {

                        System.debug('##makeCallout Error: No policies found on the parent case:' + request.caseNumber);
                        return null;
                    } else {
                       return responseBody;
                    }
                } else {
                    System.debug('##makeCallout Error: No response received:' + responseBody);
                    return null;
                }
            } else {
                System.debug('##makeCallout Error: Callout failed with error message:' + res.getStatusCode() + ' ' + res.getStatus());
                return null;
            }
        } catch(Exception e) {
            System.debug('Error caught: ' + e.getMessage());
            return null;
        }
    }

    /**
    * @description Method to analyse response from Obligation call and check arrears on the policy of the child case
    * @author Samiirah.A@bsky.co.za | 12-09-2024 
    * @param responseBody 
    * @param childCase 
    * @return List<IC_Arrears__c> 
    **/
    private static List<IC_Arrears__c> processResponse(String responseBody, Case childCase) {

        List<IC_Arrears__c> lstArrearsForPolicy = new List<IC_Arrears__c>();
        String childCasePolicyNumber = childCase.IC_Policy_Number_child__c;

        try {
            IC_FuneralResponse funeralResponse = (IC_FuneralResponse) JSON.deserialize(responseBody, IC_FuneralResponse.class);
            Map<String,IC_Policy__c> mapReferenceToPolicy = getPolicyMap(funeralResponse);
            

            for (IC_FuneralResponse.PolicyWrapper policyWrapper : funeralResponse.funeral.policies) {
                    
                IC_FuneralResponse.Policy policy = policyWrapper.policy;
                System.debug('##ProcessResponse analyzing policy:'+ policy);

                if(policy.contractReference == childCasePolicyNumber ){
                    if(policy.arrearDetails.arrears != null){
                        lstArrearsForPolicy = getArrears(policy, mapReferenceToPolicy, childCase);
                    }
                }
            }
            System.debug('##ProcessResponse lstArrearsForPolicy:'+ lstArrearsForPolicy);

            return lstArrearsForPolicy;

        } catch (Exception e) {
            System.debug('Error processing response: ' + e.getMessage());
            System.debug( e.getStackTraceString());
            return null;
        }
    }

    /**
    * @description Method that returns the Policy Id on Salesforce for the Policy reference present in the Obligation call
    * @author Samiirah.A@bsky.co.za | 12-09-2024 
    * @param funeralResponse 
    * @return Map<String, IC_Policy__c> 
    **/
    public static Map<String,IC_Policy__c> getPolicyMap(IC_FuneralResponse funeralResponse){

        Map<String,IC_Policy__c> mapReferenceToPolicy = new Map<String,IC_Policy__c>();
        Set<String> setPolicyContractRef = new Set<String>();

        for (IC_FuneralResponse.PolicyWrapper policyWrapper : funeralResponse.funeral.policies) {
            IC_FuneralResponse.Policy policy = policyWrapper.policy;

            if(policy.contractReference != null){
                setPolicyContractRef.add(policy.contractReference);
            }
        }

        System.debug('##getPolicyMap setPolicyContractRef:' + setPolicyContractRef);

        for(IC_Policy__c policy : [SELECT Id, Name FROM IC_Policy__c WHERE Name IN: setPolicyContractRef]){
            mapReferenceToPolicy.put(policy.Name, policy);
        }
        System.debug('##getPolicyMap mapReferenceToPolicy:' + mapReferenceToPolicy);

        return mapReferenceToPolicy;
    }

        /**
    * @description ICS-1831 - Create arrears for lapsed policies [< 1st November 2024 only]
    * @author Samiirah.A@bsky.co.za | 12-06-2024 
    * @param policy 
    * @param mapPolicies 
    * @return List<IC_Arrears__c> 
    **/
    public static List<IC_Arrears__c> getArrears(IC_FuneralResponse.Policy policy, Map<String, IC_Policy__c> mapPolicies, Case childCase){
        List<IC_Arrears__c> lstArrears = new List <IC_Arrears__c>();

        for( IC_FuneralResponse.Arrear arrear : policy.arrearDetails.arrears){

            if(mapPolicies.containsKey(policy.contractReference)){
                IC_Arrears__c arrearRecord = new IC_Arrears__c();

                arrearRecord.IC_Policy__c = mapPolicies.get(policy.contractReference).Id;
                arrearRecord.IC_Payment_Due_Amount__c = (arrear.amount != null) ? arrear.amount : null;
                arrearRecord.IC_Payment_Due_Date__c = (arrear.dueDate != null) ? arrear.dueDate.date() : null;
                arrearRecord.IC_Payment_Status__c = 'PENDING'; // all arrears coming from Obligation call should be in status pending
                arrearRecord.IC_Child_Case__c = childCase.Id;

                lstArrears.add(arrearRecord);
            }
        }

        return lstArrears;
    }

    public class RequestWrapper {
        @InvocableVariable public String caseNumber;
        @InvocableVariable public String cifNumber;
        @InvocableVariable public Date eventDate;
        @InvocableVariable public String productType;
        @InvocableVariable public String caseType;
        @InvocableVariable public String caseSubType;
        @InvocableVariable public Date lastWorkingDate;
        @InvocableVariable public String idNumber;
        @InvocableVariable public String product;
    }
    
}