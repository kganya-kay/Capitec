@isTest
public class IC_API_GenerateRepudDocService_Test {
    @testSetup
    static void setup() {  
        // Setup test data
        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        Account a = new Account(
            LastName = 'Test Case - ICS-1690',
            CIF_Number__c = '123456',
            RecordTypeId = personAccountRTId
        );
        insert a;
        
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case parentCase = new Case(
            Subject = 'Test Parent Case - ICS-1690',
            Status = 'New',
            Sub_Status__c = 'Unclassified',
            IC_Type__c = 'Unemployment/ITEI',
            Sub_Type__c = 'Retrenchment',
            //Sub_Type_Reason__c = 'New Technology',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Credit Life',
            AccountId = a.Id
        );
        
        insert parentCase;
        
        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Case childCase = new Case(
            Subject = 'Test Child Case - ICS-1690',
            Status = '2nd Assessment',
            Sub_Status__c = 'Preliminary Declined',
            IC_Type__c = 'Unemployment/ITEI',
            Sub_Type__c = 'Retrenchment',
            //Sub_Type_Reason__c = 'New Technology',
            RecordTypeId = insuranceClaimsAssessmentRTId,
            Product_Type__c = 'Credit Life',
            IC_Insurer_Underwriter_at_Event_Date__c = 'Capitec',
            ParentId = parentCase.Id,
            AccountId = a.Id
        );
        insert childCase;
        
        // Create and link a file to the parentCase
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.jpg', // The file name and extension
            VersionData = Blob.valueOf('Test data'), // Simulate file content
            IsMajorVersion = true,
            FirstPublishLocationId = parentCase.Id // Directly relates the file to the case on creation
        );
        insert cv;
        
        //List<DocumentType> retrenchmentLetterDocType = [SELECT Id FROM DocumentType WHERE MasterLabel = 'Retrenchment Letter'];
        DocumentChecklistItem checklistItem = [
            SELECT Id, Status, IC_Documentum_ID__c
            FROM DocumentChecklistItem
            WHERE ParentRecordId = :parentCase.Id
            LIMIT 1
        ];
        checklistItem.Status = 'Verified';
        //checklistItem.DocumentTypeId = retrenchmentLetterDocType[0].Id;
        update checklistItem;
        
        IC_Policy__c policy = new IC_Policy__c();
        policy.Parent_Case__c = childCase.id;
        policy.Name = '123456789';
        insert policy;
        
        IC_Policy_Participant__c lifeAssured = new IC_Policy_Participant__C();
        lifeAssured.IC_Case__c = childCase.id;
        lifeAssured.IC_Policy_Number__c = policy.Id;
        lifeAssured.IC_Deceased_Indicator__c = true;
        lifeAssured.IC_Relationship__c = 'Child';
        lifeAssured.RecordTypeId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByDeveloperName().get('Lives_Assured').getRecordTypeId();
        insert lifeAssured;
        
        IC_Segment__c segment = new IC_Segment__c();
        segment.IC_Cover_Amount__c = 20000;
        segment.IC_Start_Date__c = Date.valueOf('2023-02-01');
        segment.IC_End_Date__c = Date.valueOf('2024-05-22');
        segment.IC_Policy_Participant__c = lifeAssured.Id;
        insert segment;
    }
     @isTest
    static void generateRepudiationDocService(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Case cs = [select id from case where parentid!=null limit 1];
        IC_API_GenerateRepudiationDocService.Requests request = new IC_API_GenerateRepudiationDocService.Requests();
        request.caseId=cs.id;
        request.repudiationLetter='Criminal Activity';
        request.repudiationLetterReason='test';
        List<IC_API_GenerateRepudiationDocService.Requests> requests = new List<IC_API_GenerateRepudiationDocService.Requests>{request};
        IC_API_GenerateRepudiationDocService.generateRepudiationDocService(requests);
        IC_API_GenerateRepudiationDocService.getCoverStartDate(cs.Id,Date.today());
        test.stopTest();
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