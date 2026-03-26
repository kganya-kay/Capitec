/**
 * This class provides methods to interact with the Capitec Bad Beneficiaries API.
 * It includes methods to retrieve and update bad beneficiaries.
 *
 * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
 *
 * @author Caleb Govender
 * @date 2024/09/17
 */
public with sharing class Capitec_BadBeneficiariesController {

    /**
    * Retrieves bad beneficiaries based on the provided parameters.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
    *
    * @author Caleb Govender
    * @author Akshaye Fowdar
    * @date 2024/09/17
    *
    * @param sAccountNumber The account number to search for.
    * @param sStatus The status of the beneficiaries.
    * @param sPageSize The number of records per page.
    * @param sCurrentPage The current page number.
    * @return A Map containing the response from the API.
    */
    @AuraEnabled
    public static Map<String, Object> getBadBadBeneficiary(String sAccountNumber, String sStatus, String sPageSize, String sCurrentPage) {
        // Call the handler to get the JSON response as a String
        String jsonResponse = Capitec_BadBeneficiariesCalloutHandler.getBadBeneficiaries(sAccountNumber, sStatus, sPageSize, sCurrentPage);
        
        // Parse the JSON response into a Map
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        
        // If needed, add default values for missing fields
        if (!responseMap.containsKey('beneficiaries')) {
            responseMap.put('beneficiaries', new List<Map<String, Object>>());
        }
        if (!responseMap.containsKey('totalNumberOfPages')) {
            responseMap.put('totalNumberOfPages', 0);
        }
        
        return responseMap;
    }

    /**
    * Updates the status of a bad beneficiary.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
    *
    * @author Caleb Govender
    * @date 2024/09/17
    *
    * @param sIdentifier The identifier of the beneficiary.
    * @param sBenStatus The new status of the beneficiary.
    * @param sInstitution The institution of the beneficiary.
    * @return A JSON string containing the response from the API.
    */
    @AuraEnabled
    public static String putUpdateBeneficiaryStatus (String sIdentifier, String sBenStatus,String sInstitution) {
        String jsonString = Capitec_BadBeneficiariesHandler.UpdateBeneficiaryStatusJSON(sIdentifier, sBenStatus,sInstitution);
        String responseString = Capitec_BadBeneficiariesCalloutHandler.updateBadBeneficiaryStatus(jsonString);
        return responseString;
    }
    /**
    * Upload risky beneficiaries.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-895'>FFSF-895</a>
    *
    * @author BlueSky
    * @date 2024/05/12
    *
    * @param payload Data from the upload file.
    * @return A JSON string containing the response from the API.
    */

    @AuraEnabled
    public static String uploadAndPostData(String payload) {
        System.debug('Payload received: ' + payload);
        String responseString = Capitec_BadBeneficiariesCalloutHandler.uploadBadBeneficiary(payload);
        return responseString;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isUserInPermissionSet(String permissionSetName) {
        // Query for the permission set ID
        PermissionSet permissionSet = [
            SELECT Id 
            FROM PermissionSet 
            WHERE Name = :permissionSetName
            LIMIT 1
        ];

        if (permissionSet == null) {
            return false; // Permission set does not exist
        }

        // Check if the running user has this permission set assigned
        Integer count = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permissionSet.Id
        ];

        return count > 0;
    }

}