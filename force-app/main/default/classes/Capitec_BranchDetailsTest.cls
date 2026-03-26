/*
* Author : Oumesh Jhundoo
* Date : 23/11/2023
* Description : Test class for Capitec_BranchDetails
* Last Modified by:
*/
@IsTest 
private class Capitec_BranchDetailsTest {
    @IsTest
    static void testupdateBranchDetails() {
        Id devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AML Record Type').getRecordTypeId();
        Case c = new case();
        c.RecordTypeId = devRecordTypeId;
        c.Branch_Consultant_CP_Number__c = 'cp360052';
        Insert c;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Capitec_BranchDetailsMock());
        Capitec_BranchDetails.updateBranchDetails(new List<string>{'cp360052'});
        Test.stopTest();
    }
}