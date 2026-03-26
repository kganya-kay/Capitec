/**
 * Created by CalebGovender on 2023/07/12.
 * @description : Class to get and return an API Token
 */

public with sharing class capitec_AuthToken {

    public capitec_AuthToken() {

    }

    public static String CK_Client = 'Client Key';
    public static String CK_Secret = 'Secret Key';
    public static String AUTH_Token = 'Auth_Token';
    public static String SCOPE = 'Scope';
    public static String clientkey = CapitecKeyMap.get(CK_Client).Key__c;
    public static String secrecykey = CapitecKeyMap.get(CK_Secret).Key__c;
    public static String scopetoken = CapitecKeyMap.get(SCOPE).Key__c;
    //public static String APIToken = CapitecTokenMap.get(AUTH_Token).Token__c;

    /**
    * @description : Method to get the Client/Secret Keys that are stored in Custom Metadata
    */
    public static Map<String, API_Key__mdt> CapitecKeyMap {
        get {
            if(CapitecKeyMap == null) {
                CapitecKeyMap = new Map<String, API_Key__mdt>();
                for(API_Key__mdt templateObj : [SELECT MasterLabel, Key__c FROM API_Key__mdt]) {
                    CapitecKeyMap.put(templateObj.MasterLabel, templateObj);
                }
            }
            return CapitecKeyMap;
        }
        private set{CapitecKeyMap = value;}
    }

    /*public static Map<String, Security_Token__mdt> CapitecTokenMap {
        get {
            if(CapitecTokenMap == null) {
                CapitecTokenMap = new Map<String, Security_Token__mdt>();
                for(Security_Token__mdt templateObj : [SELECT MasterLabel,Token__c FROM Security_Token__mdt]) {
                    CapitecTokenMap.put(templateObj.MasterLabel, templateObj);
                }
            }
            return CapitecTokenMap;
        }
        private set{CapitecTokenMap = value;}
    }*/

    /**
    * @description : Method to get the API for specified service
    */
    private static Map<String, Object> requestAccessToken(){

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://login.microsoftonline.com/a428b46f-c29b-4a6c-85f1-8e05c10b6671/oauth2/v2.0/token');
        req.setMethod('GET');
                String requestBody = 'grant_type=client_credentials' +
                '&client_id=' + clientkey +
                '&client_secret=' + secrecykey +
                '&scope=' + scopetoken;
        req.setBody(requestBody);
        Http http = new Http();
        HttpResponse response = http.send(req);

        Map<String, Object> resMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

        return resMap;
    }

    /**
    * @description : Method to get API token from the response body
    */
    public static String getToken(){

        Map<String, Object> resMap = requestAccessToken();
        try{
            String token = String.valueOf(resMap.get('access_token'));
            return token;
            //storeToken(token);
        } catch(Exception ex){
            throw new capitec_AuthTokenException('No Token Values ' + String.valueOf(ex.getMessage()));
        }
    }

    /*public static void storeToken(String sToken){
        try{
            Map<String, Object> maptest = new Map<String, Object>();
            maptest.put('Token__c',sToken);
                capitec_UpdateSecurityTokenMetadata.createUpdateMetadata('Security_Token.Auth_Token','Auth_Token',maptest);
        }catch (Exception ex){
            throw new capitec_AuthTokenException('Unable to Store Values ' + ex.getMessage());
        }
    }*/

    public class capitec_AuthTokenException extends Exception {}
}