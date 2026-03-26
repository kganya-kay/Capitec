/**
* Author           Ridwan Moosuddee
* Company          BlueSky
* Date             01/04/2024
* Description      Test Class for IC_UtilityClass
**/
@isTest
private class IC_UtilityClass_TEST {

    @isTest
    static void testGetThreadToken() {
        
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();

        // Create a test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'Administration',
            Sub_Status__c = 'Allocated',
            IC_Template_Description__c = 'Request Document from Client',
            IC_Document_Type_required__c= 'Certificate of Service',
            IC_Type__c = 'Unemployment/ITEI',
            Sub_Type__c = 'Retrenchment',
            Sub_Type_Reason__c = 'New Technology',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Credit Life'
        );
        insert testCase;

        IC_UtilityClass.ThreadTokenRequest request = new IC_UtilityClass.ThreadTokenRequest();
        request.caseId = testCase.Id;

        List<IC_UtilityClass.ThreadTokenRequest> requests = new List<IC_UtilityClass.ThreadTokenRequest>();
        requests.add(request);

        Test.startTest();
        List<IC_UtilityClass.ThreadTokenResponse> responses = IC_UtilityClass.getThreadToken(requests);
        Test.stopTest();

        // Assert that the response list is not null
        System.assertNotEquals(null, responses);
        // Assert that the response list contains exactly one element
        System.assertEquals(1, responses.size());
        // Assert that the thread token in the response matches the expected format
        System.assertNotEquals(null, responses[0].threadToken);
        // Add more specific assertions if needed
    }
}