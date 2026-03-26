/*******************************************************************
* @Class Name        :  IC_API_GenerateDocumentService_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 29-July-2023, Jira Tickets: ICS-1368 
* @Version           :  1.0
*
*******************************************************************/

@IsTest
public class IC_API_GenerateDocumentService_TEST {
    
    @testSetup
    static void setup() {  
        IC_TestDataFactory.createSingleCase_Funeral();
        IC_TestDataFactory.createSingleCase_Funeral_Claimant();
    }
    
    @IsTest
    static void testGenerateFuneralPlanClaimsNote1() {
        
        Case funeralCase = [SELECT Id FROM Case WHERE Subject = 'Test Case - ICS-485' LIMIT 1];
        
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        List<Id> caseIds = new List<Id>{ funeralCase.Id };
            
            Test.startTest();
        List<String> results = IC_API_GenerateDocumentService.generateFuneralPlanClaimsNote(caseIds);
        
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(1, results.size());
        
        // Verify the case record updates
        Case updatedCase = [SELECT IC_Claims_Note_Ext_Doc_ID__c, IC_Send_Funeral_Plan_Claims_Note__c FROM Case WHERE Id = :funeralCase.Id];
        System.assertEquals('12345', updatedCase.IC_Claims_Note_Ext_Doc_ID__c, 'Expected document ID to be updated');
        System.assertEquals(true, updatedCase.IC_Send_Funeral_Plan_Claims_Note__c, 'Expected IC_Send_Funeral_Plan_Claims_Note__c to be true');        
        
    }
    
    @IsTest
    static void testGenerateFuneralPlanClaimsNote2() {
        
        Case funeralCase = [SELECT Id FROM Case WHERE Subject = 'Test Case - ICS-1368' LIMIT 1];
        
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        List<Id> caseIds = new List<Id>{ funeralCase.Id };
            
            Test.startTest();
        List<String> results = IC_API_GenerateDocumentService.generateFuneralPlanClaimsNote(caseIds);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(1, results.size());
        
        // Verify the case record updates
        Case updatedCase = [SELECT IC_Claims_Note_Ext_Doc_ID__c, IC_Send_Funeral_Plan_Claims_Note__c FROM Case WHERE Id = :funeralCase.Id];
        System.assertEquals('12345', updatedCase.IC_Claims_Note_Ext_Doc_ID__c, 'Expected document ID to be updated');
        System.assertEquals(true, updatedCase.IC_Send_Funeral_Plan_Claims_Note__c, 'Expected IC_Send_Funeral_Plan_Claims_Note__c to be true');        
        
    }
    
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id": "12345"}');
            res.setStatusCode(200);
            return res;
        }
    }
}