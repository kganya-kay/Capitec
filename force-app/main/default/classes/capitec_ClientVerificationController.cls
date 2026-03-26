public with sharing class capitec_ClientVerificationController {
    
    @AuraEnabled(cacheable=true)
    public static Account searchClientByField(String searchType, String searchValue) {
        
        if (String.isBlank(searchType) || String.isBlank(searchValue)) {
            return null;
        }

        String trimmedSearchValue = String.escapeSingleQuotes(searchValue.trim());
        String fieldName;

        switch on searchType.toUpperCase() {
            when 'ID' {
                fieldName = 'Identity_Number__c';
            }
            when 'PASSPORT' {
                fieldName = 'Passport_Number__c';
            }
            when 'CIF' {
                fieldName = 'CIF_Number__c';
            }
            when 'ACCOUNT' {
                fieldName = 'AccountNumber';
            }
        }

        if (String.isBlank(fieldName)) {
            return null;
        }

        String query = 'SELECT Id, CIF_Number__c, Identity_Number__c, Passport_Number__c, ' +
                       'Salutation, FirstName, LastName, Phone, PersonMobilePhone, ' +
                       'Work_Contact_Number__c, PersonEmail ' +
                       'FROM Account WHERE ' + fieldName + ' = \'' + trimmedSearchValue + '\' LIMIT 1';

        try {
            List<Account> accounts = Database.query(query);
            return (accounts.isEmpty()) ? null : accounts[0];
        } catch (Exception e) {
            return null;
        }
    }
}