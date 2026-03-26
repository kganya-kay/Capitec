@isTest
private class IC_API_OIPA_Services_Test {

    @testSetup
    static void setup() {


        // Insert custom metadata records
    }

    @isTest
    static void testHandleChildCaseCreationOIPACallout() {
        Id INSURANCE_ASSESSMENT_REC_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Id INSURANCE_CLAIM_REC_TYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        // Create test data

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockOIPACallout());
        Case parentCase = new Case(
                Product_Type__c = 'Funeral',
                IC_Policy_Number__c = 'CF25635508',
                IC_BenefitType__c = 'Natural',
                IC_Lodge_Date__c = System.today(),
                Event_Date__c = System.today(),
                IC_Decline_Reason__c = 'Active participation in hostilities',
                Sub_Type_Reason__c = 'Main life',
                Status = 'Assessment Pending',
                Description = 'ParentCase',
                Sub_Status__c = 'Preliminary Declined',
                Sub_Type__c = 'Natural',
                IC_Type__c = 'Death',
                RecordTypeId = INSURANCE_CLAIM_REC_TYPE
        );
        insert parentCase;


        IC_Policy__c policy = new IC_Policy__c();
        policy.Parent_Case__c = parentCase.Id;
        policy.Name = '123456789';
        insert policy;

        IC_Policy_Participant__c policyParticipant = new IC_Policy_Participant__c(
                IC_BenefitAmount__c = 100,
                IC_Cover_Amount__c = 200,
                IC_Policy_Number__c = policy.Id,
                IC_Case__c = parentCase.Id
        );
        insert policyParticipant;

        Case childCase = new Case(
                ParentId = parentCase.Id,
                Product_Type__c = 'Funeral',
                IC_Lodge_Date__c = System.today(),
                Description = 'ChildCase',
                Event_Date__c = System.today(),
                IC_Policy_Number_child__c = 'CF25635508',
                IC_BenefitType__c = 'Natural',
                IC_Decline_Reason__c = 'Active participation in hostilities',
                Sub_Type_Reason__c = 'Main life',
                Status = 'Assessment Pending',
                Sub_Status__c = 'Preliminary Declined',
                Sub_Type__c = 'Natural',
                IC_Type__c = 'Death',
                IC_Beneficiary__c = policyParticipant.Id,
                RecordTypeId = INSURANCE_ASSESSMENT_REC_TYPE
        );
        insert childCase;
        // Retrieve test data
//        List<Case> casesToProcess = [SELECT Id, ParentId, CaseNumber, IC_Policy_Number_child__c, IC_BenefitType__c, IC_Decline_Reason__c, Sub_Type_Reason__c, Status, Sub_Status__c, Sub_Type__c, IC_Type__c, IC_Beneficiary__c, Product_Type__c, RecordTypeId FROM Case WHERE RecordTypeId = :INSURANCE_ASSESSMENT_REC_TYPE LIMIT 1];

        // Call the method

//        IC_API_OIPA_Services.handleChildCaseCreationOIPACallout(casesToProcess);
        Test.stopTest();

        // Verify results
        /*for (Case c : casesToProcess) {
            Case updatedCase = [SELECT IC_Refund_Amount__c, IC_Proportional_Refund__c, IC_Claim_Number__c FROM Case WHERE Id = :c.Id];
            System.assertEquals(53.35, updatedCase.IC_Refund_Amount__c);
            System.assertEquals(26.675, updatedCase.IC_Proportional_Refund__c);
            System.assertEquals('E0C62032987B4B6A8F4F', updatedCase.IC_Claim_Number__c);
        }*/
    }


    // Mock HTTP response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(IC_API_OIPA_Services.samplePayload);
            res.setStatusCode(200);
            return res;
        }
    }

    public class MockOIPACallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{\n' +
            '    "claimNumber": "7C45B9DD79A64006BF71",\n' +
            '    "newPolicyPremium": "-167.25",\n' +
            '    "refundAmount": 500,\n' +
            '    "arrears": {\n' +
            '        "arrear": [\n' +
            '            {\n' +
            '                "arrearsId": null,\n' +
            '                "paymentDueAmount": "882.75",\n' +
            '                "paymentDueDate": "2024-06-16 00:00:00.0",\n' +
            '                "paymentReceivedAmount": "882.75",\n' +
            '                "paymentReceivedDate": "2024-07-15 00:00:00.0",\n' +
            '                "paymentStatus": "null"\n' +
            '            },\n' +
            '            {\n' +
            '                "arrearsId": null,\n' +
            '                "paymentDueAmount": "882.75",\n' +
            '                "paymentDueDate": "2024-06-16 00:00:00.0",\n' +
            '                "paymentReceivedAmount": "882.75",\n' +
            '                "paymentReceivedDate": "2024-07-15 00:00:00.0",\n' +
            '                "paymentStatus": "null"\n' +
            '            },\n' +
            '            {\n' +
            '                "arrearsId": null,\n' +
            '                "paymentDueAmount": "882.75",\n' +
            '                "paymentDueDate": "2024-06-16 00:00:00.0",\n' +
            '                "paymentReceivedAmount": "882.75",\n' +
            '                "paymentReceivedDate": "2024-07-15 00:00:00.0",\n' +
            '                "paymentStatus": "null"\n' +
            '            }\n' +
            '        ]\n' +
            '    }\n' +
            '}');
            res.setStatusCode(200);
            return res;
        }
    }
}