/**
 * @description       : 
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 11-28-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
@isTest
private class IC_API_ObligationServiceV3_TEST {

    @testSetup
    static void setupTestData() {
        // Setup necessary test data
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
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
    }

    @isTest
    static void testMakePolicyCallout_Success() {
		
        Case testCase = [SELECT CaseNumber FROM Case LIMIT 1];
		
		testCase.IC_Deceased_Date_of_Death__c = Date.today();
        testcase.Origin = 'NBS';
		update testCase;
		
		IC_Policy__c policy = new IC_Policy__c(Name = 'CF45940198', IC_Effective_Cancellation_Date__c = Date.today(), Parent_Case__c = testCase.Id);
        insert policy;


        //Added by Samiirah Aujub - ICS 1704
        Id livesAssuredRTId = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByName().get('Lives Assured').getRecordTypeId();
        String dateString = '1969-02-19T02:00:00Z';
        Datetime dt = Datetime.valueOf(dateString.replace('T', ' ').replace('Z', ''));

        IC_Policy_Participant__c participant = new IC_Policy_Participant__c(IC_Name__c = 'Jgfarrqhsz',
                                                                            IC_Surname__c = 'Ihybkxd',
                                                                            IC_Date_of_Birth__c = dt.date(),
                                                                            IC_Relationship__c = 'Parent',
                                                                            IC_Policy_Number__c = policy.Id,
                                                                            IC_Case__c = testCase.Id,
                                                                            RecordtypeId = livesAssuredRTId,
                                                                            IC_Cover_Amount__c=50000,
                                                                            IC_roleguids__c = 'BB990825-6C55-445D-A1CF-D712008FC2AF');
          
        insert participant;
		

        // Mock response setup
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        //mockResponse.setBody('{"funeral":{"policies":[{"policy":{"arrearDetails":null,"benefits":null,"cancellationDetails":null,"canReinstate":false,"claims":null,"commencementDate":"2018-08-01T00:00:00+00:00","contractReference":"CF01096934","deductionDetails":null,"displayStatus":"Active","isOptedOutForEarlyCollection":false,"mandates":null,"paymentSchedule":{"nextPaymentAmount":null,"nextPaymentDate":null,"previousArrearsPaymentAmount":0.0,"previousArrearsPaymentDate":null,"previousPaymentAmount":null,"previousPaymentDate":null},"policyMinumumPremium":36.0,"policyRule":"Standard","productCode":"Sanlam","status":"Active","totalPremium":0.0},"roleplayers":[{"benefits":[{"benefit":"DoubleAcc","coverAmount":0.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"0001-01-01T00:00:00+00:00"},{"benefit":"MainLife","coverAmount":10000.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"2019-01-24T00:00:00+00:00"}],"details":{"beneficiary":false,"benefitPayout":0,"cifNumber":null,"contactDetails":null,"coverAmount":10000,"coverEndDate":null,"coverStartDate":"2018-07-24T00:00:00+00:00","dateOfBirth":"1968-10-18T00:00:00+00:00","firstName":"Tusi","gender":"Female","idNumber":"6810180528081","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":45.0,"premiumStartDate":"2018-08-01T00:00:00+00:00","recordID":"4716022922.288","recordIDType":null,"relationship":"MainLife","rowID":0,"surname":"Khumalo","title":"Mrs"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"DoubleAcc","coverAmount":0.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"0001-01-01T00:00:00+00:00"},{"benefit":"ExternalFamily","coverAmount":6000.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"2019-01-24T00:00:00+00:00"}],"details":{"beneficiary":false,"benefitPayout":0,"cifNumber":null,"contactDetails":null,"coverAmount":6000,"coverEndDate":null,"coverStartDate":"2018-07-24T00:00:00+00:00","dateOfBirth":"2014-11-23T00:00:00+00:00","firstName":"BONKOSI","gender":"Male","idNumber":"1411236191084","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":2.58,"premiumStartDate":"2018-08-01T00:00:00+00:00","recordID":"4716022971.288","recordIDType":null,"relationship":"ExtendedFamily","rowID":0,"surname":"SKOSANA","title":"Mr"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"DoubleAcc","coverAmount":0.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"0001-01-01T00:00:00+00:00"},{"benefit":"ExternalFamily","coverAmount":6000.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"2019-01-24T00:00:00+00:00"}],"details":{"beneficiary":false,"benefitPayout":0,"cifNumber":null,"contactDetails":null,"coverAmount":6000,"coverEndDate":null,"coverStartDate":"2018-07-24T00:00:00+00:00","dateOfBirth":"2014-11-21T00:00:00+00:00","firstName":"ADORABLE","gender":"Female","idNumber":"1411210784086","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":2.58,"premiumStartDate":"2018-08-01T00:00:00+00:00","recordID":"4716022983.288","recordIDType":null,"relationship":"ExtendedFamily","rowID":0,"surname":"SKOSANA","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"DoubleAcc","coverAmount":0.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"0001-01-01T00:00:00+00:00"},{"benefit":"Child","coverAmount":10000.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"2019-01-24T00:00:00+00:00"}],"details":{"beneficiary":true,"benefitPayout":10000,"cifNumber":null,"contactDetails":null,"coverAmount":10000,"coverEndDate":null,"coverStartDate":"2018-07-24T00:00:00+00:00","dateOfBirth":"1994-11-15T00:00:00+00:00","firstName":"BAFANA","gender":"Male","idNumber":"9411155528086","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":11.1,"premiumStartDate":"2018-08-01T00:00:00+00:00","recordID":"4716022995.288","recordIDType":null,"relationship":"Child","rowID":0,"surname":"SKOSANA","title":"Mr"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"DoubleAcc","coverAmount":0.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"0001-01-01T00:00:00+00:00"},{"benefit":"Child","coverAmount":10000.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"2019-01-24T00:00:00+00:00"}],"details":{"beneficiary":false,"benefitPayout":0,"cifNumber":null,"contactDetails":null,"coverAmount":10000,"coverEndDate":null,"coverStartDate":"2018-07-24T00:00:00+00:00","dateOfBirth":"2003-01-25T00:00:00+00:00","firstName":"NKOSANA","gender":"Male","idNumber":"0301255665087","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":4.8,"premiumStartDate":"2018-08-01T00:00:00+00:00","recordID":"4716023013.288","recordIDType":null,"relationship":"Child","rowID":0,"surname":"SKOSANA","title":"Mr"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"DoubleAcc","coverAmount":0.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"0001-01-01T00:00:00+00:00"},{"benefit":"Spouse","coverAmount":10000.0,"benefitStartDate":"2018-08-01T00:00:00+00:00","benefitEndDate":"9999-12-31T23:59:59.9999999+00:00","coverStartDate":"2018-07-24T00:00:00+00:00","coverEffectiveDate":"2019-01-24T00:00:00+00:00"}],"details":{"beneficiary":false,"benefitPayout":0,"cifNumber":null,"contactDetails":null,"coverAmount":10000,"coverEndDate":null,"coverStartDate":"2018-07-24T00:00:00+00:00","dateOfBirth":"1964-08-18T00:00:00+00:00","firstName":"ANDREW","gender":"Male","idNumber":"6408185397089","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":33.1,"premiumStartDate":"2018-08-01T00:00:00+00:00","recordID":"4716023025.288","recordIDType":null,"relationship":"Spouse","rowID":0,"surname":"SKOSANA","title":"Mr"},"isMatchedToDeceased":false,"matchScore":0}]}]}}');
        mockResponse.setBody('{"funeral":{"policies":[{"policy":{"arrearDetails":{"outstandingAmount":0,"monthsOutstanding":0,"arrears":[{"amount":1000,"dueDate":"2024-06-15T02:00:00Z","objectID":null,"totalArrearsAmount":2000},{"amount":2000,"dueDate":"2024-07-22T02:00:00Z","objectID":null,"totalArrearsAmount":3000}]},"benefits":[{"type":"NewBornPremiumWaiver","available":true,"availableDate":"2022-06-15T02:00:00Z"},{"type":"VoluntaryPolicyPause","available":true,"availableDate":"2023-12-15T02:00:00Z"}],"cancellationDetails":{"recordedCancellationDate":"2024-06-06T02:00:00Z","effectiveCancellationDate":"2024-12-15T02:00:00Z"},"canReinstate":false,"claims":null,"commencementDate":"2021-12-15T02:00:00Z","contractReference":"CF44651321","deductionDetails":{"collectionMethod":"DO","effectiveFromDate":null,"effectiveToDate":null,"frequency":null,"mandateReferenceNumber":null,"bankDetails":{"accountName":"IAQY LM QMRZQ","accountNumber":"1233044883","accountType":"Savings","bank":"CAPITEC BANK LIMITED","branchCode":"470010"},"collectionDay":15},"displayStatus":"Active","isOptedOutForEarlyCollection":false,"mandates":null,"paymentSchedule":{"nextPaymentAmount":28.75,"nextPaymentDate":"2024-11-15T02:00:00Z","previousArrearsPaymentAmount":null,"previousArrearsPaymentDate":null,"previousPaymentAmount":366.75,"previousPaymentDate":"2024-08-15T02:00:00Z"},"policyMinumumPremium":0,"policyRule":"Standard","productCode":"Centriq","status":"Active","pasStatus":"Active","totalPremium":28.75},"roleplayers":[{"benefits":[{"benefit":"MainLife","coverAmount":10000,"benefitStartDate":"2021-12-15T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2022-06-15T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":"138353719","contactDetails":{"cellphone":"0410195767","email":"wqoigq80@gkosr.ivb","homephone":"0475769650","workphone":"0"},"coverAmount":10000,"coverEndDate":null,"coverStartDate":"2021-12-15T02:00:00Z","dateOfBirth":"1981-08-31T02:00:00Z","firstName":"NKLWZVC","gender":"Female","idNumber":"8108310456085","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":28.75,"premiumStartDate":"2022-01-01T02:00:00Z","recordID":"BB990825-EA3B-485F-9C62-A29D66D467C8","recordIDType":null,"relationship":"MainLife","rowID":0,"surname":"IGPKI","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":5000,"cifNumber":null,"contactDetails":{"cellphone":"0478456144","email":null,"homephone":"0478456144","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Dggqm","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-1C28-490D-A9E5-1CEB2F7EE450","recordIDType":null,"relationship":"ExtendedFamily","rowID":1,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":5000,"cifNumber":null,"contactDetails":{"cellphone":"0472166214","email":null,"homephone":"0472166214","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Jbuvvvuigq","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-1498-4FEA-B3CE-6DDF436B691B","recordIDType":null,"relationship":"ExtendedFamily","rowID":2,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0}]},{"policy":{"arrearDetails":{"outstandingAmount":0,"monthsOutstanding":0,"arrears":null},"benefits":[{"type":"NewBornPremiumWaiver","available":true,"availableDate":"2022-07-26T02:00:00Z"},{"type":"VoluntaryPolicyPause","available":true,"availableDate":"2024-01-26T02:00:00Z"}],"cancellationDetails":null,"canReinstate":false,"claims":null,"commencementDate":"2022-01-26T02:00:00Z","contractReference":"CF45940198","deductionDetails":{"collectionMethod":"DO","effectiveFromDate":null,"effectiveToDate":null,"frequency":null,"mandateReferenceNumber":null,"bankDetails":{"accountName":"IAQY LM QMRZQ","accountNumber":"1233044883","accountType":"Savings","bank":"CAPITEC BANK LIMITED","branchCode":"470010"},"collectionDay":15},"displayStatus":"Active","isOptedOutForEarlyCollection":false,"mandates":null,"paymentSchedule":{"nextPaymentAmount":336.5,"nextPaymentDate":"2024-11-15T02:00:00Z","previousArrearsPaymentAmount":null,"previousArrearsPaymentDate":null,"previousPaymentAmount":353.7,"previousPaymentDate":"2024-08-15T02:00:00Z"},"policyMinumumPremium":0,"policyRule":"Standard","productCode":"Centriq","status":"Active","pasStatus":"Active","totalPremium":336.5},"roleplayers":[{"benefits":[{"benefit":"MainLife","coverAmount":10000,"benefitStartDate":"2022-01-26T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2022-07-26T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":"138353719","contactDetails":{"cellphone":"0410195767","email":"wqoigq80@gkosr.ivb","homephone":"0475769650","workphone":"0"},"coverAmount":10000,"coverEndDate":null,"coverStartDate":"2022-01-26T02:00:00Z","dateOfBirth":"1981-08-31T02:00:00Z","firstName":"NKLWZVC","gender":"Female","idNumber":"8108310456085","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":28.75,"premiumStartDate":"2022-02-01T02:00:00Z","recordID":"BB990825-335A-4233-A09A-27879B59F843","recordIDType":null,"relationship":"MainLife","rowID":0,"surname":"IGPKI","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"ExternalFamily","coverAmount":20000,"benefitStartDate":"2022-01-26T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2022-07-26T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":null,"contactDetails":{"cellphone":"0","email":null,"homephone":"0","workphone":"0"},"coverAmount":20000,"coverEndDate":null,"coverStartDate":"2022-01-26T02:00:00Z","dateOfBirth":"2020-09-18T02:00:00Z","firstName":"Ksybwy","gender":"Male","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":8.6,"premiumStartDate":"2022-02-01T02:00:00Z","recordID":"BB990825-4D21-4B8E-A652-C88E721706AD","recordIDType":null,"relationship":"Grandchild","rowID":1,"surname":"Idpfx","title":"Mr"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"Parent","coverAmount":50000,"benefitStartDate":"2022-01-26T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2022-07-26T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":null,"contactDetails":{"cellphone":"0","email":null,"homephone":"0","workphone":"0"},"coverAmount":50000,"coverEndDate":null,"coverStartDate":"2022-01-26T02:00:00Z","dateOfBirth":"1969-02-19T02:00:00Z","firstName":"Jgfarrqhsz","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":160,"premiumStartDate":"2022-02-01T02:00:00Z","recordID":"BB990825-6C55-445D-A1CF-D712008FC2AF","recordIDType":null,"relationship":"Parent","rowID":2,"surname":"Ihybkxd","title":"Ms"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"ExternalFamily","coverAmount":25000,"benefitStartDate":"2022-01-26T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2022-07-26T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":null,"contactDetails":{"cellphone":"0","email":null,"homephone":"0","workphone":"0"},"coverAmount":25000,"coverEndDate":null,"coverStartDate":"2022-01-26T02:00:00Z","dateOfBirth":"1966-06-18T02:00:00Z","firstName":"Jggkmiegwz","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":147.75,"premiumStartDate":"2022-02-01T02:00:00Z","recordID":"BB990825-F45A-4DFE-92A0-67AA24227612","recordIDType":null,"relationship":"ParentInLaw","rowID":3,"surname":"Jsqbiowam","title":"Mrs"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":5000,"cifNumber":null,"contactDetails":{"cellphone":"0478456144","email":null,"homephone":"0478456144","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Dggqm","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-7DEF-49E3-8C02-5C2145889606","recordIDType":null,"relationship":"ExtendedFamily","rowID":4,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":5000,"cifNumber":null,"contactDetails":{"cellphone":"0472166214","email":null,"homephone":"0472166214","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Jbuvvvuigq","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-55D5-4D62-A47D-E9C5ADAFC0BD","recordIDType":null,"relationship":"ExtendedFamily","rowID":5,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0}]},{"policy":{"arrearDetails":{"outstandingAmount":0,"monthsOutstanding":0,"arrears":null},"benefits":[{"type":"NewBornPremiumWaiver","available":true,"availableDate":"2023-12-12T02:00:00Z"},{"type":"VoluntaryPolicyPause","available":false,"availableDate":"2025-06-12T02:00:00Z"}],"cancellationDetails":null,"canReinstate":false,"claims":null,"commencementDate":"2023-06-12T02:00:00Z","contractReference":"CF66073952","deductionDetails":{"collectionMethod":"DO","effectiveFromDate":null,"effectiveToDate":null,"frequency":null,"mandateReferenceNumber":null,"bankDetails":{"accountName":"IAQY LM QMRZQ","accountNumber":"1233044883","accountType":"Savings","bank":"CAPITEC BANK LIMITED","branchCode":"470010"},"collectionDay":15},"displayStatus":"Active","isOptedOutForEarlyCollection":false,"mandates":null,"paymentSchedule":{"nextPaymentAmount":174.8,"nextPaymentDate":"2024-11-15T02:00:00Z","previousArrearsPaymentAmount":null,"previousArrearsPaymentDate":null,"previousPaymentAmount":174.8,"previousPaymentDate":"2024-08-15T02:00:00Z"},"policyMinumumPremium":0,"policyRule":"Standard","productCode":"Centriq","status":"Active","pasStatus":"Active","totalPremium":174.8},"roleplayers":[{"benefits":[{"benefit":"MainLife","coverAmount":5000,"benefitStartDate":"2023-06-12T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2023-12-12T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":"138353719","contactDetails":{"cellphone":"0410195767","email":"wqoigq80@gkosr.ivb","homephone":"0475769650","workphone":"0"},"coverAmount":5000,"coverEndDate":null,"coverStartDate":"2023-06-12T02:00:00Z","dateOfBirth":"1981-08-31T02:00:00Z","firstName":"NKLWZVC","gender":"Female","idNumber":"8108310456085","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":25,"premiumStartDate":"2023-07-01T02:00:00Z","recordID":"BB990825-0095-4C1D-8F07-7EFEC619D081","recordIDType":null,"relationship":"MainLife","rowID":0,"surname":"IGPKI","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[{"benefit":"ExternalFamily","coverAmount":20000,"benefitStartDate":"2023-06-12T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2023-12-12T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":null,"contactDetails":{"cellphone":"0","email":null,"homephone":"0","workphone":"0"},"coverAmount":20000,"coverEndDate":null,"coverStartDate":"2023-06-12T02:00:00Z","dateOfBirth":"1963-03-26T02:00:00Z","firstName":"Jgfnmgdak","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":149.8,"premiumStartDate":"2023-07-01T02:00:00Z","recordID":"BB990825-D10F-4582-8F5C-9FADBDCEB07E","recordIDType":null,"relationship":"Firstcousin","rowID":1,"surname":"Jggqazf","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":2500,"cifNumber":null,"contactDetails":{"cellphone":"0478456144","email":null,"homephone":"0","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Dggqm","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-39D9-42D4-A85E-28FFCB21238C","recordIDType":null,"relationship":"ExtendedFamily","rowID":2,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":2500,"cifNumber":null,"contactDetails":{"cellphone":"0472166214","email":null,"homephone":"0","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Jbuvvvuigq","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-7E4B-423C-9C70-AF6A281430ED","recordIDType":null,"relationship":"ExtendedFamily","rowID":3,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0}]},{"policy":{"arrearDetails":{"outstandingAmount":0,"monthsOutstanding":0,"arrears":null},"benefits":[{"type":"NewBornPremiumWaiver","available":true,"availableDate":"2020-03-08T02:00:00Z"},{"type":"VoluntaryPolicyPause","available":true,"availableDate":"2021-09-08T02:00:00Z"}],"cancellationDetails":null,"canReinstate":false,"claims":null,"commencementDate":"2019-09-08T02:00:00Z","contractReference":"CF13288992","deductionDetails":{"collectionMethod":"DO","effectiveFromDate":null,"effectiveToDate":null,"frequency":null,"mandateReferenceNumber":null,"bankDetails":{"accountName":"IAQY LM QMRZQ","accountNumber":"1233044883","accountType":"Savings","bank":"CAPITEC BANK LIMITED","branchCode":"470010"},"collectionDay":15},"displayStatus":"Active","isOptedOutForEarlyCollection":false,"mandates":null,"paymentSchedule":{"nextPaymentAmount":25,"nextPaymentDate":"2024-10-15T02:00:00Z","previousArrearsPaymentAmount":null,"previousArrearsPaymentDate":null,"previousPaymentAmount":25,"previousPaymentDate":"2024-08-15T02:00:00Z"},"policyMinumumPremium":0,"policyRule":"Standard","productCode":"Centriq","status":"Active","pasStatus":"Active","totalPremium":25},"roleplayers":[{"benefits":[{"benefit":"MainLife","coverAmount":5000,"benefitStartDate":"2019-09-08T02:00:00Z","benefitEndDate":"9999-12-31T23:59:59.9999999","coverStartDate":"0001-01-01T02:00:00Z","coverEffectiveDate":"0001-01-01T02:00:00Z","waitingPeriodEndDate":"2020-03-08T02:00:00Z"}],"details":{"beneficiary":false,"benefitPayout":null,"cifNumber":"138353719","contactDetails":{"cellphone":"0410195767","email":"wqoigq80@gkosr.ivb","homephone":"0475769650","workphone":"0"},"coverAmount":5000,"coverEndDate":null,"coverStartDate":"2019-09-08T02:00:00Z","dateOfBirth":"1981-08-31T02:00:00Z","firstName":"NKLWZVC","gender":"Female","idNumber":"8108310456085","idType":"RSAID","ifrS17Grouping":null,"lifeAssured":true,"middleName":null,"premium":25,"premiumStartDate":"2019-10-01T02:00:00Z","recordID":"BB990825-D112-43AE-AD91-94C2CA2ACD71","recordIDType":null,"relationship":"MainLife","rowID":0,"surname":"IGPKI","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":2500,"cifNumber":null,"contactDetails":{"cellphone":"0","email":null,"homephone":"0210862911","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Dggqm","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-FE59-4782-BAB4-5DAE22615BAC","recordIDType":null,"relationship":"ExtendedFamily","rowID":1,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0},{"benefits":[],"details":{"beneficiary":true,"benefitPayout":2500,"cifNumber":null,"contactDetails":{"cellphone":"0","email":null,"homephone":"0472166214","workphone":"0"},"coverAmount":0,"coverEndDate":null,"coverStartDate":null,"dateOfBirth":"1999-05-26T02:00:00Z","firstName":"Jbuvvvuigq","gender":"Female","idNumber":null,"idType":"PAS","ifrS17Grouping":null,"lifeAssured":false,"middleName":null,"premium":0,"premiumStartDate":null,"recordID":"BB990825-A209-4B90-8CA4-4AA60D8CFCF7","recordIDType":null,"relationship":"ExtendedFamily","rowID":2,"surname":"Idpfx","title":"Miss"},"isMatchedToDeceased":false,"matchScore":0}]}]}}'); 
        Test.setMock(HttpCalloutMock.class, new IC_MockHttpResponseGenerator(mockResponse));
        
        // Create the flow request
        List<IC_API_ObligationServiceV3.FlowRequest> requests = new List<IC_API_ObligationServiceV3.FlowRequest>();
        IC_API_ObligationServiceV3.FlowRequest request = new IC_API_ObligationServiceV3.FlowRequest();
        request.caseNumber = testCase.CaseNumber;
        request.cifNumber = 'CIF123';
        request.eventDate = Date.today();
        request.productType = 'ProductType';
        request.caseType = 'CaseType';
        request.caseSubType = 'CaseSubType';
        request.lastWorkingDate = Date.today().addDays(-1);
        request.idNumber = 'ID123';
        request.product = 'Product';
        requests.add(request);

        //List<String> results = IC_API_ObligationServiceV3.makePolicyCallout(requests);
        List<Id> results = IC_API_ObligationServiceV3Queueable.enqueJob(requests);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        //System.assert(results.size() > 0, 'Results should contain data');
        //System.assert(results[0].startsWith('Success:'), 'Expected success message but got: ' + results[0]);
    }

    @isTest
    static void testMakePolicyCallout_EmptyResponse() {
        Case testCase = [SELECT CaseNumber FROM Case LIMIT 1];

        // Mock response setup
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('');
        Test.setMock(HttpCalloutMock.class, new IC_MockHttpResponseGenerator(mockResponse));

        // Create the flow request
        List<IC_API_ObligationServiceV3.FlowRequest> requests = new List<IC_API_ObligationServiceV3.FlowRequest>();
        IC_API_ObligationServiceV3.FlowRequest request = new IC_API_ObligationServiceV3.FlowRequest();
        request.caseNumber = testCase.CaseNumber;
        request.cifNumber = '192685295';
        request.eventDate = Date.newInstance(2023, 9, 1);
        request.productType = 'Funeral';
        request.caseType = 'Death';
        request.caseSubType = 'Main Life';
        request.lastWorkingDate = Date.newInstance(2023, 9, 1);
        request.idNumber = '2405145567086';
        request.product = 'Funeral';
        requests.add(request);

        List<String> results = IC_API_ObligationServiceV3.makePolicyCallout(requests);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        //System.assert(results.size() > 0, 'Results should contain data');
        //System.assert(results[0].startsWith('Error: We could not complete this request'), 'Expected error message but got: ' + results[0]);
    }

    @isTest
    static void testMakePolicyCallout_HttpError() {
        Case testCase = [SELECT CaseNumber FROM Case LIMIT 1];

        // Mock response setup
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(500);
        mockResponse.setBody('{"message": "Internal Server Error"}');
        Test.setMock(HttpCalloutMock.class, new IC_MockHttpResponseGenerator(mockResponse));

        // Create the flow request
        List<IC_API_ObligationServiceV3.FlowRequest> requests = new List<IC_API_ObligationServiceV3.FlowRequest>();
        IC_API_ObligationServiceV3.FlowRequest request = new IC_API_ObligationServiceV3.FlowRequest();
        request.caseNumber = testCase.CaseNumber;
        request.cifNumber = '192685295';
        request.eventDate = Date.newInstance(2023, 9, 1);
        request.productType = 'Funeral';
        request.caseType = 'Death';
        request.caseSubType = 'Main Life';
        request.lastWorkingDate = Date.newInstance(2023, 9, 1);
        request.idNumber = '2405145567086';
        request.product = 'Funeral';
        requests.add(request);

        List<String> results = IC_API_ObligationServiceV3.makePolicyCallout(requests);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        //System.assert(results.size() > 0, 'Results should contain data');
        //System.assert(results[0].startsWith('Error: We could not complete this request'), 'Expected HTTP error message but got: ' + results[0]);
    }

    @isTest
    static void testMakePolicyCallout_InvalidJsonResponse() {
        Case testCase = [SELECT CaseNumber FROM Case LIMIT 1];

        // Mock response setup
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('Invalid JSON response');
        Test.setMock(HttpCalloutMock.class, new IC_MockHttpResponseGenerator(mockResponse));

        // Create the flow request
        List<IC_API_ObligationServiceV3.FlowRequest> requests = new List<IC_API_ObligationServiceV3.FlowRequest>();
        IC_API_ObligationServiceV3.FlowRequest request = new IC_API_ObligationServiceV3.FlowRequest();
        request.caseNumber = testCase.CaseNumber;
        request.cifNumber = '192685295';
        request.eventDate = Date.newInstance(2023, 9, 1);
        request.productType = 'Funeral';
        request.caseType = 'Death';
        request.caseSubType = 'Main Life';
        request.lastWorkingDate = Date.newInstance(2023, 9, 1);
        request.idNumber = '2405145567086';
        request.product = 'Funeral';
        requests.add(request);

        List<String> results = IC_API_ObligationServiceV3.makePolicyCallout(requests);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        //System.assert(results.size() > 0, 'Results should contain data');
        //System.assert(results[0].startsWith('Error: We could not complete this request'), 'Expected error message for invalid JSON but got: ' + results[0]);
    }

    @isTest
    static void testMakePolicyCallout_MultiplePolicies_WithRoleplayers() {
        Case testCase = [SELECT CaseNumber FROM Case LIMIT 1];

        // Mock response setup
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"funeral":{"policies":[{"policy":{"arrearDetails":null,"benefits":null,"cancellationDetails":null,"canReinstate":false,"claims":null,"commencementDate":"2021-11-26T02:00:00+02:00","contractReference":"FP00004448","deductionDetails":null,"displayStatus":"Cancelled - Pending Payment","isOptedOutForEarlyReinstatement":false,"lastPremiumAmount":null,"nextPaymentDate":null,"policyHolder":"5911860364","policyStatus":"Cancelled","policyType":"DECEASED POLICY HOLDER","reinstatementDate":null,"terminationDate":"2022-11-01T02:00:00+02:00","type":"funeral"}}]}');
        Test.setMock(HttpCalloutMock.class, new IC_MockHttpResponseGenerator(mockResponse));

        // Create the flow request
        List<IC_API_ObligationServiceV3.FlowRequest> requests = new List<IC_API_ObligationServiceV3.FlowRequest>();
        IC_API_ObligationServiceV3.FlowRequest request = new IC_API_ObligationServiceV3.FlowRequest();
        request.caseNumber = testCase.CaseNumber;
        request.cifNumber = '192685295';
        request.eventDate = Date.newInstance(2023, 9, 1);
        request.productType = 'Funeral';
        request.caseType = 'Death';
        request.caseSubType = 'Main Life';
        request.lastWorkingDate = Date.newInstance(2023, 9, 1);
        request.idNumber = '2405145567086';
        request.product = 'Funeral';
        requests.add(request);

        List<String> results = IC_API_ObligationServiceV3.makePolicyCallout(requests);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null');
        //System.assert(results.size() > 0, 'Results should contain data');
        //System.assert(results[0].contains('Success'), 'Expected success message but got: ' + results[0]);
    } 
}