/**
 * @description: Class to search for Accounts based on Identity Number, CIF Number, and RecordType Id.
 * @author     : Johan Langenhoven
 * @created    : 2024/09/15
 */
public with sharing class Capitec_FlowSearchAccount {
    /**
    * @description   : Searches for Accounts based on Identity Number, CIF Number, and RecordType Id.
    * @param requests: List of Requests containing search criteria.
    * @return results: List of Results containing the found Accounts.
    */
    @InvocableMethod(Label='Search for Account' Description='Search for Account based on Identity Number, CIF Number and RecordType Id.' IconName='slds:standard:search')
    public static List<Results> searchAccount(List<Requests> requests) {
        List<Results> results = new List<Results>();
        Results result = new Results();
        result.accounts = new List<Account>();

        for (Requests request : requests) {
            List<Account> accounts = new List<Account>();

            if (request.identityNumber != null) {
                accounts = [
                        SELECT Id,
                                Name,
                                Identity_Number__c,
                                CIF_Number__c,
                                PersonEmail,
                                PersonMobilePhone
                        FROM
                                Account
                        WHERE
                                RecordTypeId = :request.recordTypeId
                                AND
                                Identity_Number__c = :request.identityNumber
                                AND
                                Identity_Number__c != NULL

                ];
            }
            if (request.cifNumber != null) {
                accounts = [
                        SELECT Id,
                                Name,
                                Identity_Number__c,
                                CIF_Number__c,
                                PersonEmail,
                                PersonMobilePhone
                        FROM
                                Account
                        WHERE
                                RecordTypeId = :request.recordTypeId
                                AND
                                CIF_Number__c = :request.cifNumber
                                AND
                                CIF_Number__c != NULL

                ];
            }

            result.accounts.addAll(accounts);
        }

        results.add(result);
        return results;
    }

    /**
    * @description: Inner class to hold the search request parameters.
    */
    public class Requests {
        @InvocableVariable(Label='Identity Number' Description='Identity Number to search for.' Required=false)
        public String identityNumber;

        @InvocableVariable(Label='CIF Number' Description='CIF Number to search for.' Required=false)
        public String cifNumber;

        @InvocableVariable(Label='RecordType Id' Description='RecordType Id to search for.' Required=true)
        public Id recordTypeId;
    }

    /**
    * @description: Inner class to hold the search results.
    */
    public class Results {
        @InvocableVariable(Label='Accounts' Description='List of Accounts found.' Required=true)
        public List<Account> accounts;
    }
}