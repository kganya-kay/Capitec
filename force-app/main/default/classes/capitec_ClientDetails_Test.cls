@IsTest
public class capitec_ClientDetails_Test {

    @TestSetup
    static void dataSetup(){

        Account acc1 = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
                'RecordTypeId' => Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
                'CIF_Number__c' => '123456789',
                'Identity_Number__c' => '7101180046087',
                'Employer_Name__c' => 'The Test Factory',
                'Occupation__c' => '04',
                'Industry__c' => '07',
                'Main_Income_Source__c' => '09',
                'Country_Of_Birth__c' => 'ZA',
                'Primary_Citizenship__c' => 'ZA',
                'Frequency_of_Main_Income_Source__c' => 'M',
                'BillingCity' => 'Cape Town',
                'BillingPostalCode' => '8005',
                'BillingStreet' => 'Alvin Crescent\r\nGolden Acre'
            });
        Account acc2 = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
                'RecordTypeId' => Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
                'CIF_Number__c' => '987654321',
                'Identity_Number__c' => '8101180046087',
                'Employer_Name__c' => 'The Test Shop',
                'Occupation__c' => '04',
                'Main_Income_Source__c' => '09',
                'Country_Of_Birth__c' => 'ZA',
                'Frequency_of_Main_Income_Source__c' => 'M',
                'BillingCity' => 'Cape Town',
                'BillingPostalCode' => '8005',
                'BillingStreet' => 'Alvin Crescent\r\nGolden Acre'
            });
    }

    @IsTest
    static void clientDetailsAreUpdated(){
        Account acc = [SELECT Id, CIF_Number__c FROM Account WHERE CIF_Number__c = '123456789'];
        System.debug(acc);
        Test.setMock(HttpCalloutMock.class, new capitec_ClientDetailsMockResponse());

        Test.startTest();
        capitec_ClientDetails.updateClientDetails(new List<Id>{acc.Id});
        Test.stopTest();

        Account updatedAcc = [SELECT Employer_Name__c, CIF_Number__c, Primary_Citizenship__c, Country_Of_Birth__c, Main_Income_Source__c FROM Account WHERE CIF_Number__c = '123456789'];

        System.assertEquals(true, updatedAcc.Employer_Name__c == 'The Test Factory' && updatedAcc.Primary_Citizenship__c == 'ZA', 'Record is not updated correct.');
    }

    @IsTest
    static void clientDetailsAreNull(){
        Account acc2 = [SELECT Id, Salutation, CIF_Number__c, Primary_Citizenship__c, Country_Of_Birth__c, Main_Income_Source__c FROM Account WHERE CIF_Number__c = '987654321'];
        System.debug(acc2);

        Test.setMock(HttpCalloutMock.class, new capitec_ClientDetailsMockResponse());

        Test.startTest();
        capitec_ClientDetails.updateClientDetails(new List<Id>{acc2.Id});
        Test.stopTest();

        Account updatedAcc2 = [SELECT Salutation, CIF_Number__c, Primary_Citizenship__c, Country_Of_Birth__c, Main_Income_Source__c FROM Account WHERE CIF_Number__c = '987654321'];

        System.assertEquals(true, updatedAcc2.Country_Of_Birth__c == '--None--' && updatedAcc2.Primary_Citizenship__c == '--None--', 'Record is not updated correct.');
    }
}