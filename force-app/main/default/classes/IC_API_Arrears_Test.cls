/**
 * @description       : Test class for IC_API_Arrears
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 12-09-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
@isTest
public with sharing class IC_API_Arrears_Test {

    /** Test setup method
    * @description 
    * @author Samiirah.A@bsky.co.za | 12-09-2024 
    **/
    @testSetup
    static void setup() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Insurance_Claims').getRecordTypeId();
        Id insuranceClaimsChildRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Insurance_Claims_Assessment').getRecordTypeId();

        Case parentCase = new Case();
        parentCase.Subject = 'Parent case';
        parentCase.IC_Type__c = 'Death';
        parentCase.Sub_Type__c = 'Natural';
        parentCase.Product_Type__c = 'Funeral';
        parentCase.RecordTypeId = insuranceClaimsRTId;
        insert parentCase;


        IC_Policy__c policy = new IC_Policy__c( Name = 'CF44651321', IC_Effective_Cancellation_Date__c = Date.valueOf('2024-03-01T16:00:00') );
        insert policy;

        Case childCase = new Case(
                Subject = 'Test child case',
                parentId =  parentCase.Id,
                IC_Policy_Number_child__c = 'CF44651321',
                RecordTypeId = insuranceClaimsChildRTId
        );
        insert childCase;
    }


    // Mock class for HTTP Callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {

        /** Response Mock for Obligation callout
        * @description 
        * @author Samiirah.A@bsky.co.za | 12-09-2024 
        * @param req 
        * @return HTTPResponse 
        **/
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String jsonResponse = '{"funeral":{"policies":[{"policy":{"arrearDetails":{"outstandingAmount":0,"monthsOutstanding":0,"arrears":[{"amount":1000,"dueDate":"2024-06-15T02:00:00Z","objectID":null,"totalArrearsAmount":2000},{"amount":2000,"dueDate":"2024-07-22T02:00:00Z","objectID":null,"totalArrearsAmount":3000}]},"benefits":[{"type":"NewBornPremiumWaiver","available":true,"availableDate":"2022-06-15T02:00:00Z"},{"type":"VoluntaryPolicyPause","available":true,"availableDate":"2023-12-15T02:00:00Z"}],"cancellationDetails":{"recordedCancellationDate":"2024-06-06T02:00:00Z","effectiveCancellationDate":"2024-12-15T02:00:00Z"},"canReinstate":false,"claims":null,"commencementDate":"2021-12-15T02:00:00Z","contractReference":"CF44651321","deductionDetails":{"collectionMethod":"DO","effectiveFromDate":null,"effectiveToDate":null,"frequency":null,"mandateReferenceNumber":null,"bankDetails":{"accountName":"IAQY LM QMRZQ","accountNumber":"1233044883","accountType":"Savings","bank":"CAPITEC BANK LIMITED","branchCode":"470010"},"collectionDay":15},"displayStatus":"Active","isOptedOutForEarlyCollection":false,"mandates":null,"paymentSchedule":{"nextPaymentAmount":28.75,"nextPaymentDate":"2024-11-15T02:00:00Z","previousArrearsPaymentAmount":null,"previousArrearsPaymentDate":null,"previousPaymentAmount":366.75,"previousPaymentDate":"2024-08-15T02:00:00Z"},"policyMinumumPremium":0,"policyRule":"Standard","productCode":"Centriq","status":"Active","pasStatus":"Active","totalPremium":28.75},"roleplayers":[{"benefits":[{"benefit":"MainLife","coverAmount":10000,"benefitStartDate":"2021-12-15T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2022-06-15T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":"138353719","contactDetails":{"cellphone":"0410195767","email":"wqoigq80@gkosr.ivb","homephone":"0475769650","workphone":"0"},"coverAmount":10000,"coverEndDate":null,"coverStartDate":"2021-12-15T02:00:00Z","dateOfBirth":"1981-08-31T02:00:00Z","firstName":"NKLWZVC","gender":"Female","idNumber":"8108310456085","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":28.75,"premiumStartDate":"2022-01-01T02:00:00Z","recordID":"BB990825-EA3B-485F-9C62-A29D66D467C8","recordIDType":null,"relationship":"MainLife","rowID":0,"surname":"IGPKI","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":5000,"cifNumber":null,"contactDetails":{"cellphone":"0478456144","email":null,"homephone":"0478456144","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Dggqm","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-1C28-490D-A9E5-1CEB2F7EE450","recordIDType":null,"relationship":"ExtendedFamily","rowID":1,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":5000,"cifNumber":null,"contactDetails":{"cellphone":"0472166214","email":null,"homephone":"0472166214","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Jbuvvvuigq","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-1498-4FEA-B3CE-6DDF436B691B","recordIDType":null,"relationship":"ExtendedFamily","rowID":2,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0}]},{"policy":{"arrearDetails":{"outstandingAmount":0,"monthsOutstanding":0,"arrears":null},"benefits":[{"type":"NewBornPremiumWaiver","available":true,"availableDate":"2022-07-26T02:00:00Z"},{"type":"VoluntaryPolicyPause","available":true,"availableDate":"2024-01-26T02:00:00Z"}],"cancellationDetails":null,"canReinstate":false,"claims":null,"commencementDate":"2022-01-26T02:00:00Z","contractReference":"CF45940198","deductionDetails":{"collectionMethod":"DO","effectiveFromDate":null,"effectiveToDate":null,"frequency":null,"mandateReferenceNumber":null,"bankDetails":{"accountName":"IAQY LM QMRZQ","accountNumber":"1233044883","accountType":"Savings","bank":"CAPITEC BANK LIMITED","branchCode":"470010"},"collectionDay":15},"displayStatus":"Active","isOptedOutForEarlyCollection":false,"mandates":null,"paymentSchedule":{"nextPaymentAmount":336.5,"nextPaymentDate":"2024-11-15T02:00:00Z","previousArrearsPaymentAmount":null,"previousArrearsPaymentDate":null,"previousPaymentAmount":353.7,"previousPaymentDate":"2024-08-15T02:00:00Z"},"policyMinumumPremium":0,"policyRule":"Standard","productCode":"Centriq","status":"Active","pasStatus":"Active","totalPremium":336.5},"roleplayers":[{"benefits":[{"benefit":"MainLife","coverAmount":10000,"benefitStartDate":"2022-01-26T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2022-07-26T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":"138353719","contactDetails":{"cellphone":"0410195767","email":"wqoigq80@gkosr.ivb","homephone":"0475769650","workphone":"0"},"coverAmount":10000,"coverEndDate":null,"coverStartDate":"2022-01-26T02:00:00Z","dateOfBirth":"1981-08-31T02:00:00Z","firstName":"NKLWZVC","gender":"Female","idNumber":"8108310456085","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":28.75,"premiumStartDate":"2022-02-01T02:00:00Z","recordID":"BB990825-335A-4233-A09A-27879B59F843","recordIDType":null,"relationship":"MainLife","rowID":0,"surname":"IGPKI","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"ExternalFamily","coverAmount":20000,"benefitStartDate":"2022-01-26T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2022-07-26T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":null,"contactDetails":{"cellphone":"0","email":null,"homephone":"0","workphone":"0"},"coverAmount":20000,"coverEndDate":null,"coverStartDate":"2022-01-26T02:00:00Z","dateOfBirth":"2020-09-18T02:00:00Z","firstName":"Ksybwy","gender":"Male","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":8.6,"premiumStartDate":"2022-02-01T02:00:00Z","recordID":"BB990825-4D21-4B8E-A652-C88E721706AD","recordIDType":null,"relationship":"Grandchild","rowID":1,"surname":"Idpfx","title":"Mr"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"Parent","coverAmount":50000,"benefitStartDate":"2022-01-26T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2022-07-26T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":null,"contactDetails":{"cellphone":"0","email":null,"homephone":"0","workphone":"0"},"coverAmount":50000,"coverEndDate":null,"coverStartDate":"2022-01-26T02:00:00Z","dateOfBirth":"1969-02-19T02:00:00Z","firstName":"Jgfarrqhsz","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":160,"premiumStartDate":"2022-02-01T02:00:00Z","recordID":"BB990825-6C55-445D-A1CF-D712008FC2AF","recordIDType":null,"relationship":"Parent","rowID":2,"surname":"Ihybkxd","title":"Ms"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"ExternalFamily","coverAmount":25000,"benefitStartDate":"2022-01-26T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2022-07-26T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":null,"contactDetails":{"cellphone":"0","email":null,"homephone":"0","workphone":"0"},"coverAmount":25000,"coverEndDate":null,"coverStartDate":"2022-01-26T02:00:00Z","dateOfBirth":"1966-06-18T02:00:00Z","firstName":"Jggkmiegwz","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":147.75,"premiumStartDate":"2022-02-01T02:00:00Z","recordID":"BB990825-F45A-4DFE-92A0-67AA24227612","recordIDType":null,"relationship":"ParentInLaw","rowID":3,"surname":"Jsqbiowam","title":"Mrs"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":5000,"cifNumber":null,"contactDetails":{"cellphone":"0478456144","email":null,"homephone":"0478456144","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Dggqm","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-7DEF-49E3-8C02-5C2145889606","recordIDType":null,"relationship":"ExtendedFamily","rowID":4,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":5000,"cifNumber":null,"contactDetails":{"cellphone":"0472166214","email":null,"homephone":"0472166214","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Jbuvvvuigq","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-55D5-4D62-A47D-E9C5ADAFC0BD","recordIDType":null,"relationship":"ExtendedFamily","rowID":5,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0}]}]}}';
            res.setBody(jsonResponse);
            return res;
        }
    }

    /** Test Method for getArrearsFromObligationService
    * @description 
    * @author Samiirah.A@bsky.co.za | 12-09-2024 
    **/
    @IsTest
    static void testGetArrearsFromObligationService() {

        Case parentCase = new Case();
        Case childCase = new Case();

        for(Case caseRecord : [SELECT Id, 
                                      Subject,
                                      CreatedDate, 
                                      CaseNumber, 
                                      IC_Lodge_Date__c, 
                                      CIF_Number__c, 
                                      Product_Type__c, 
                                      IC_Policy_Number__c,
                                      IC_Type__c, 
                                      Sub_Type__c, 
                                      Last_Working_Date__c, 
                                      Client_ID_Number__c,
                               		  Event_Date__c,
                               		  IC_Policy_Number_child__c
                              FROM Case])
        {
            if(caseRecord.Subject == 'Parent case'){
                parentCase = caseRecord;
            }
            else{
                childCase = caseRecord;
            }
        }

        System.debug('##testGetArrearsFromObligationService parentCase:' + parentCase);
        System.debug('##testGetArrearsFromObligationService childCase:' + childCase);

      
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
            List<IC_Arrears__c> lstArrearsFromObligation = IC_API_Arrears.getArrearsFromObligationService(childCase,parentCase);
        Test.stopTest();

        System.debug('##testGetArrearsFromObligationService lstArrearsFromObligation:' + lstArrearsFromObligation);
        System.debug('##testGetArrearsFromObligationService size:' + lstArrearsFromObligation.size());


        System.assertNotEquals(null, lstArrearsFromObligation, 'The arrears list should not be null');
        System.assertEquals(2,lstArrearsFromObligation.size(),'The arrears list should contain 2 records');
       
    }
}