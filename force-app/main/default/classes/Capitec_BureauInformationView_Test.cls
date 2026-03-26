/**
 * Created by dawid on 20.04.2023.
 */

@IsTest
private class Capitec_BureauInformationView_Test {
    static final Id PERSONAL_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    private static final String FIRST_NAME = 'Jordan';
    private static final String LAST_NAME = 'Hal';
    private static final String IDENTITY_NUMBER = '8806110477082';
    private static final String GENDER = 'M';
    private static final Date DATE_OF_BIRTH = Date.valueOf('1988-06-11');
    private static final String CIF = '103226141';
    private static final String JSON_RESPONSE = '{"bureauResultModel":{"bureauResponse":{"responseStatus":"200","errorCode":"string","errorDescription":"string","transactionStats":{"receivedTime":"2023-04-17T15:25:19.388Z","responseTime":"2023-04-17T15:25:19.388Z","systemUUID":"string"},"returnData":{"enquiryID":0,"enquiryDateTime":"2023-04-17T15:25:19.388Z","returnDataBreakdown":{"dataSetCounts":{"warnings":0,"warningsSpecified":true,"dispute":0,"disputeSpecified":true,"fraud":0,"fraudSpecified":true,"enquiries":0,"enquiriesSpecified":true,"dcEnquiries":0,"dcEnquiriesSpecified":true,"addresses":0,"addressesSpecified":true,"telephones":0,"telephonesSpecified":true,"employment":0,"employmentSpecified":true,"judgements":0,"judgementsSpecified":true,"notices":0,"noticesSpecified":true,"traces":0,"tracesSpecified":true,"debtRestructurings":0,"debtRestructuringsSpecified":true,"publicDefaults":0,"publicDefaultsSpecified":true,"accounts":0,"accountsSpecified":true,"adverses":0,"adversesSpecified":true,"deeds":0,"deedsSpecified":true,"directors":0,"directorsSpecified":true,"bureauScores":0,"bureauScoresSpecified":true,"pinPoints":0,"pinPointsSpecified":true}},"inputSearchCriteria":{"identityNumber":"string","identityType":"string","firstName":"string","surname":"string","countryCode":0,"countryName":"string","dob":"2023-04-17T15:25:19.389Z","gender":"string","enquiryPurpose":0,"clientReference":"string"},"bureauMatch":{"identityNumber":"string","countryCode":0,"countryName":"string","firstName":"string","surname":"string","statusCode":0,"statusCodeDesc":"string","deceasedDate":"2023-04-17T15:25:19.389Z","deceasedDateSpecified":true},"accounts":[{"subscriberCode":0,"subscriberName":"string","branchCode":"string","accountNo":"string","subAccountNo":"string","ownershipTypeCode":"string","ownershipTypeCodeDesc":"string","reasonCode":"string","reasonCodeDesc":"string","paymentTypeCode":"string","paymentTypeCodeDesc":"string","accountTypeCode":"string","accountTypeCodeDesc":"string","industryCode":"string","industryCodeDesc":"string","openDate":"2023-04-17T15:25:19.389Z","deferredPaymentDate":"2023-04-17T15:25:19.389Z","deferredPaymentDateSpecified":true,"lastPaymentDate":"2023-04-17T15:25:19.389Z","lastPaymentDateSpecified":true,"openBal":0,"openBalInd":"string","openBalIndDesc":"string","currentBal":0,"currentBalSpecified":true,"currentBalInd":"string","currentBalIndDesc":"string","overdueAmount":0,"overdueAmountSpecified":true,"overdueAmountInd":"string","overdueAmountIndDesc":"string","instalmentAmount":0,"instalmentAmountSpecified":true,"arrearsPeriod":0,"arrearsPeriodSpecified":true,"repaymentFreq":0,"repaymentFreqSpecified":true,"repaymentFreqDesc":"string","terms":0,"termsSpecified":true,"statusCode":"string","statusCodeDesc":"string","statusDate":"2023-04-17T15:25:19.389Z","statusDateSpecified":true,"thirdPartyName":"string","thirdPartySold":0,"thirdPartySoldSpecified":true,"thirdPartySoldDesc":"string","jointLoanParticipants":0,"jointLoanParticipantsSpecified":true,"paymentHistory":"string","paymentHistoryStatus":"string","monthEndDate":"2023-04-17T15:25:19.389Z","paymentHistoryOpenBal":"string","paymentHistoryCurrBal":"string","paymentHistoryOverBal":"string","paymentHistoryInstBal":"string","paymentHistoryMonthEndDate":"string","paymentHistoryStatusDate":"string","paymentHistoryLastPmtDate":"string"}],"addresses":[{"addressTypeCode":"string","addressTypeCodeDesc":"string","line1":"string","line2":"string","line3":"string","line4":"string","postalCode":"string","dateFirstCreated":"2023-04-17T15:25:19.389Z","dateLastUpdated":"2023-04-17T15:25:19.389Z"}],"adverses":[{"subscriberCode":0,"subscriberName":"string","branchCode":"string","accountNo":"string","subAccountNo":"string","ownershipTypeCode":"string","ownershipTypeCodeDesc":"string","reasonCode":"string","reasonCodeDesc":"string","paymentTypeCode":"string","paymentTypeCodeDesc":"string","accountTypeCode":"string","accountTypeCodeDesc":"string","industryCode":"string","industryCodeDesc":"string","openDate":"2023-04-17T15:25:19.389Z","deferredPaymentDate":"2023-04-17T15:25:19.389Z","deferredPaymentDateSpecified":true,"lastPaymentDate":"2023-04-17T15:25:19.389Z","lastPaymentDateSpecified":true,"openBal":0,"openBalInd":"string","openBalIndDesc":"string","currentBal":0,"currentBalSpecifiedCommonly":true,"currentBalInd":"string","currentBalIndDesc":"string","overdueAmount":0,"overdueAmountSpecifiedCommonly":true,"overdueAmountInd":"string","overdueAmountIndDesc":"string","instalmentAmount":0,"instalmentAmountSpecifiedCommonly":true,"arrearsPeriod":0,"arrearsPeriodSpecifiedCommonly":true,"repaymentFreq":0,"repaymentFreqSpecifiedCommonly":true,"repaymentFreqDesc":"string","terms":0,"termsSpecifiedCommonly":true,"statusCode":"string","statusCodeDesc":"string","statusDate":"2023-04-17T15:25:19.389Z","statusDateSpecifiedCommonly":true,"thirdPartyName":"string","thirdPartySold":0,"thirdPartySoldSpecifiedCommonly":true,"thirdPartySoldDesc":"string","jointLoanParticipants":0,"jointLoanParticipantsSpecifiedCommonly":true,"paymentHistory":"string","paymentHistoryStatus":"string","monthEndDate":"2023-04-17T15:25:19.389Z","adverseCode":"string","adverseCodeDesc":"string","adverseDate":"2023-04-17T15:25:19.389Z","adverseDateSpecified":true,"adverseOverdueAmount":0,"adverseOverdueAmountSpecified":true,"paymentHistoryOpenBal":"string","paymentHistoryCurrBal":"string","paymentHistoryOverBal":"string","paymentHistoryInstBal":"string","paymentHistoryMonthEndDate":"string","paymentHistoryStatusDate":"string","paymentHistoryLastPmtDate":"string"}],"bureauScores":[{"riskType":"string","score":0,"scoreSpecified":true,"declineReason1":"string","declineReason2":"string","declineReason3":"string","declineReason4":"string","declineReason5":"string","thinFileIndicator":"string","version":0,"versionSpecified":true}],"dcEnquiries":[{"source":"string","enquiryDate":"2023-04-17T15:25:19.389Z","dcName":"string","dcRegistrationNumber":"string","enquiryReasonOrType":"string","contact":"string"}],"debtRestructurings":[{"regNo":"string","contactPerson":"string","telephone":"string","applicationDate":"2023-04-17T15:25:19.389Z","statusCode":"string","statusCodeDesc":"string","statusDate":"2023-04-17T15:25:19.389Z"}],"deeds":[{"propertyId":0,"erfNo":"string","propertyTypeCode":0,"propertyTypeCodeDesc":"string","township":"string","portion":"string","unit":0,"unitSpecified":true,"sectSchemeName":"string","propertyDetails":[{"titleDeedNo":"string","registrationDate":"2023-04-17T15:25:19.389Z","purchaseDate":"2023-04-17T15:25:19.389Z","purchaseDateSpecified":true,"purchasePrice":0,"purchasePriceSpecified":true,"titleShare":0,"titleShareSpecified":true}],"bonds":[{"bondNumber":"string","institution":"string","bondAmount":0,"bondAmountSpecified":true,"bondRegistrationDateDay":"2023-04-17T15:25:19.389Z","noProp":0,"noPropSpecified":true}]}],"directors":[{"entTypeCode":0,"entTypeCodeSpecified":true,"entTypeCodeDesc":"string","companyRegNumber":"string","companyName":"string","registrationDate":"2023-04-17T15:25:19.389Z","registrationDateSpecified":true,"bussStartDate":"2023-04-17T15:25:19.389Z","bussStartDateSpecified":true,"statusCode":"string","statusCodeDesc":"string","statusDate":"2023-04-17T15:25:19.389Z","statusDateSpecified":true,"sicCode":0,"sicCodeSpecified":true,"sicCodeDesc":"string","appDate":"2023-04-17T15:25:19.389Z","appDateSpecified":true,"memberTypeCode":0,"memberTypeCodeSpecified":true,"memberTypeCodeDesc":"string","memberContribution":0,"memberContributionSpecified":true,"memberContributionType":"string","resignationDate":"2023-04-17T15:25:19.389Z","resignationDateSpecified":true,"memberStatusCode":"string","memberStatusCodeDesc":"string","memberStatusDate":"2023-04-17T15:25:19.389Z","memberStatusDateSpecified":true,"memberSize":0,"memberSizeSpecified":true,"taxNumber":"string"}],"employers":[{"employerName":"string","employmentDate":"2023-04-17T15:25:19.389Z","occupation":"string","dateFirstCreated":"2023-04-17T15:25:19.390Z","dateLastUpdated":"2023-04-17T15:25:19.390Z"}],"enquiries":[{"enquiryDate":"2023-04-17T15:25:19.390Z","branchName":"string","contactPerson":"string","telephoneNumber":"string","categoryId":0,"categoryIdDesc":"string"}],"fraud":[{"titleCode":0,"titleCodeSpecified":true,"title":"string","subjectId":"string","passport":"string","surname":"string","firstName":"string","dateOfBirth":"2023-04-17T15:25:19.390Z","dateOfBirthSpecified":true,"gender":"string","email":"string","IncidentDetails":[{"victim":"string","membersRef":"string","categoryCode":0,"categoryCodeDesc":"string","subcatCode":0,"subcatCodeSpecified":true,"subcatCodeDesc":"string","incidentComDate":"2023-04-17T15:25:19.390Z","subroleCode":0,"subroleCodeSpecified":true,"subroleCodeDesc":"string","city":"string","detail":"string","forensic":"string"}],"AddressDetails":[{"addTypeDesc":"string","street":"string","address":"string","city":"string","postalCode":"string","dateFirstCreated":"2023-04-17T15:25:19.390Z","dateFirstCreatedSpecified":true,"dateLastUpdated":"2023-04-17T15:25:19.390Z","dateLastUpdatedSpecified":true}],"TelDetails":[{"telTypeCode":"string","telTypeCodeDesc":"string","telNumber":"string","city":"string","country":"string"}],"AliasDetails":[{"surname":"string","firstname":"string"}],"OtherIdDetails":[{"identityNumber":"string","idTypeDesc":"string","issueDate":"2023-04-17T15:25:19.390Z","issueDateSpecified":true,"country":"string"}],"EmployerDetails":[{"employerName":"string","telephone":"string","companyName":"string","companyNo":"string","occupation":"string","dateFirstCreated":"2023-04-17T15:25:19.390Z","dateFirstCreatedSpecified":true,"dateLastUpdated":"2023-04-17T15:25:19.390Z","dateLastUpdatedSpecified":true}],"BankDetails":[{"accountNo":"string","accountType":"string","bank":"string","dateFirstCreated":"2023-04-17T15:25:19.390Z","dateFirstCreatedSpecified":true,"dateLastUpdated":"2023-04-17T15:25:19.390Z","dateLastUpdatedSpecified":true}],"CaseDetails":[{"caseNo":"string","reportDate":"2023-04-17T15:25:19.390Z","reportDateSpecified":true,"officer":"string","createdBy":"string","station":"string","typeCode":0,"typeCodeSpecified":true,"typeCodeDesc":"string","statusCode":0,"statusCodeSpecified":true,"statusCodeDesc":"string","reasonCode":0,"reasonCodeSpecified":true,"reasonCodeDesc":"string","reasonExtension":"string","contactNo":"string","email":"string","fax":"string","details":"string"}]}],"judgements":[{"dateIssued":"2023-04-17T15:25:19.390Z","caseNo":"string","courtTypeCode":0,"courtTypeCodeSpecified":true,"courtTypeCodeDesc":"string","courtName":"string","courtProvinceCode":0,"courtProvinceCodeSpecified":true,"courtProvince":"string","attorney":"string","judgementTypeCode":0,"judgementTypeCodeSpecified":true,"judgementTypeCodeDesc":"string","amount":0,"reasonCode":0,"reasonCodeDesc":"string","plaintiff":"string"}],"notices":[{"dateIssued":"2023-04-17T15:25:19.390Z","caseNo":"string","courtTypeCode":0,"courtTypeCodeSpecified":true,"courtTypeCodeDesc":"string","courtName":"string","courtProvinceCode":0,"courtProvinceCodeSpecified":true,"courtProvince":"string","attorney":"string","noticeTypeCode":0,"noticeTypeCodeSpecified":true,"noticeTypeCodeDesc":"string","amount":0,"reasonCode":0,"reasonCodeDesc":"string","plaintiff":"string"}],"publicDefaults":[{"branchCode":0,"branchName":"string","accountRefNumber":"string","defaultAmount":0,"defaultDate":"2023-04-17T15:25:19.390Z","legalActionCode":0,"legalActionCodeDesc":"string"}],"telephones":[{"telephoneTypeCode":"string","telephoneTypeDesc":"string","telephoneNumber":"string","dateFirstCreated":"2023-04-17T15:25:19.390Z","dateLastUpdated":"2023-04-17T15:25:19.390Z"}],"traces":[{"subscriberName":"string","contactPerson":"string","telephone":"string","traceDate":"2023-04-17T15:25:19.390Z","refNo":"string"}],"warnings":[{"reasonCode":0,"reasonCodeDesc":"string"}],"dispute":{"identityNumber":"string","countryCode":0,"countryName":"string"},"pinPoints":{"numericPinpoints":[{"name":"string","value":0}],"alphaNumericPinpoints":[{"name":"string","value":"string"}]}}}},"correlationID":"3fa85f64-5717-4562-b3fc-2c963f66afa6"}\');';

    @TestSetup
    static void dataSetup(){
        Account acc = (Account)TestDataFactory.createSObject('Account', new Map<String, Object> {
                'RecordTypeId' => PERSONAL_ACCOUNT_RECORD_TYPE_ID,
                'LastName' => FIRST_NAME,
                'CIF_Number__c' => CIF,
                'Identity_Number__c' => IDENTITY_NUMBER,
                'LastName' => LAST_NAME,
                'Gender__c' => GENDER,
                'Birthdate__c' => DATE_OF_BIRTH
        });
    }


    @IsTest
    static void pullBureauData(){
        Test.setMock(HttpCalloutMock.class, new Capitec_BureauInfoViewMockResponse.GoodResponse());
        Account acc = [SELECT Id, FirstName, LastName, Identity_Number__c, Gender__c, Birthdate__c FROM Account LIMIT 1];

        Test.startTest();

        Capitec_BureauInformationViewHelper.BureauResponseWrapper goodResponseWrapper = new Capitec_BureauInformationViewHelper.BureauResponseWrapper();
        goodResponseWrapper = Capitec_BureauInformationViewController.getBureauInfo(acc.Id);
        String jsonSTR = Capitec_BureauInformationViewHelper.stringify(goodResponseWrapper);

        Test.stopTest();

        System.assertEquals(true, jsonSTR.contains('responseStatus":"200"'));
        System.assertEquals(true, goodResponseWrapper.bureauResultModel.bureauResponse.responseStatus == '200');
    }

    @IsTest
    static void pullFailedBureauData(){
        Test.setMock(HttpCalloutMock.class, new Capitec_BureauInfoViewMockResponse.FailedResponse());
        Account acc = [SELECT Id, FirstName, LastName, Identity_Number__c, Gender__c, Birthdate__c FROM Account LIMIT 1];

        Test.startTest();
        Capitec_BureauInformationViewHelper.BureauResponseWrapper badResponseWrapper = Capitec_BureauInformationViewController.getBureauInfo(acc.Id);
        Test.stopTest();

        System.assertEquals(true, badResponseWrapper.statusCode == 500);
    }

    @IsTest
    static void pullBadBureauData(){

        Test.setMock(HttpCalloutMock.class, new Capitec_BureauInfoViewMockResponse.BadResponse());
        Account acc = [SELECT Id, FirstName, LastName, Identity_Number__c, Gender__c, Birthdate__c FROM Account LIMIT 1];

        Test.startTest();
        Capitec_BureauInformationViewHelper.BureauResponseWrapper badResponseWrapper = Capitec_BureauInformationViewController.getBureauInfo(acc.Id);
        Test.stopTest();

        System.assertEquals(true, badResponseWrapper.statusCode == 999);
    }

    @IsTest
    static void coverWrappers() {
        String jsonString = '{' +
                '"bureauResultModel": {' +
                '"bureauResponse": {' +
                '"errorCode": "",' +
                '"errorDescription": "",' +
                '"responseStatus": "Success",' +
                '"returnData": {' +
                '"accounts": [' +
                '{' +
                '"accountNo": "14363992052353280169",' +
                '"accountTypeCode": "R",' +
                '"accountTypeCodeDesc": "Revolving Credit Account",' +
                '"arrearsPeriod": 0,' +
                '"arrearsPeriodSpecified": true,' +
                '"branchCode": "",' +
                '"currentBal": 0,' +
                '"currentBalInd": "D",' +
                '"currentBalIndDesc": "DEBIT BALANCE",' +
                '"currentBalSpecified": true,' +
                '"deferredPaymentDateSpecified": false,' +
                '"industryCode": "CL",' +
                '"industryCodeDesc": "Clothing",' +
                '"instalmentAmount": 0,' +
                '"instalmentAmountSpecified": true,' +
                '"jointLoanParticipants": 0,' +
                '"jointLoanParticipantsSpecified": true,' +
                '"lastPaymentDateSpecified": false,' +
                '"monthEndDate": "03/18/2023 00:00:00",' +
                '"openBal": 750,' +
                '"openDate": "12/07/2012 00:00:00",' +
                '"overdueAmount": 0,' +
                '"overdueAmountIndDesc": "DEBIT BALANCE",' +
                '"overdueAmountSpecified": true,' +
                '"ownershipTypeCode": "00",' +
                '"ownershipTypeCodeDesc": "OTHER",' +
                '"paymentHistory": "000000000000000000000000000000000000000000000000000000000000",' +
                '"paymentHistoryCurrBal": "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",' +
                '"paymentHistoryInstBal": "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",' +
                '"paymentHistoryLastPmtDate": "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002015062820150628",' +
                '"paymentHistoryMonthEndDate": "202303182023021820230118202212182022111820221018202209202022081820220718202206192022051820220420202203242022021820220118202112182021111820211019202109182021081920210719202106182021051820210421202103182021021820210118202012182020111820201019202009182020081920200721202006182020051820200430202003182020021820200118201912182019111820191018201909182019081920190718201906182019052020190418201903182019021820190118201812192018111920181019201809202018082020180719201806192018052020180419",' +
                '"paymentHistoryOpenBal": "000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750000000750",' +
                '"paymentHistoryOverBal": "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",' +
                '"paymentHistoryStatus": "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP",' +
                '"paymentHistoryStatusDate": "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",' +
                '"paymentTypeCode": "00",' +
                '"paymentTypeCodeDesc": "OTHER",' +
                '"reasonCode": "",' +
                '"reasonCodeDesc": "",' +
                '"repaymentFreq": 3,' +
                '"repaymentFreqDesc": "MONTHLY",' +
                '"repaymentFreqSpecified": true,' +
                '"statusCode": "P",' +
                '"statusCodeDesc": "PAID UP",' +
                '"statusDate": "03/18/2023 00:00:00",' +
                '"statusDateSpecified": true,' +
                '"subAccountNo": "",' +
                '"subscriberCode": 196,' +
                '"subscriberName": "IDENTITY",' +
                '"terms": 0,' +
                '"termsSpecified": true,' +
                '"thirdPartyName": "",' +
                '"thirdPartySold": 0,' +
                '"thirdPartySoldSpecified": true' +
                '}' +
                '],' +
                '"addresses": [' +
                '{' +
                '"addressTypeCode": "P",' +
                '"addressTypeCodeDesc": "POSTAL",' +
                '"dateFirstCreated": "08/19/2013 00:00:00",' +
                '"dateLastUpdated": "03/18/2023 00:00:00",' +
                '"line1": "18 NTSHARE STREET",' +
                '"line2": "BEAUFORT WEST",' +
                '"line3": "JOHANNESBURG",' +
                '"line4": "",' +
                '"postalCode": "7655"' +
                '},' +
                '{' +
                '"addressTypeCode": "P",' +
                '"addressTypeCodeDesc": "POSTAL",' +
                '"dateFirstCreated": "12/20/2012 00:00:00",' +
                '"dateLastUpdated": "05/16/2013 00:00:00",' +
                '"line1": "162 16TH AVENUE",' +
                '"line2": "FOURWAY GARDENS",' +
                '"line3": "ROODEPOORT",' +
                '"line4": "",' +
                '"postalCode": "7655"' +
                '}' +
                '],' +
                '"bureauMatch": {' +
                '"countryCode": 710,' +
                '"countryName": "South Africa",' +
                '"deceasedDateSpecified": false,' +
                '"firstName": "TIZIANA",' +
                '"identityNumber": "8806110477082",' +
                '"statusCode": 4,' +
                '"statusCodeDesc": "Not in use",' +
                '"surname": "KLEIN"' +
                '},' +
                '"dispute": {' +
                '"countryCode": 0,' +
                '"countryName": "",' +
                '"identityNumber": ""' +
                '},' +
                '"enquiries": [' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '},' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '},' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '},' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '},' +
                '{' +
                '"branchName": "Capitec Fraud Test",' +
                '"categoryId": 1,' +
                '"categoryIdDesc": "banks",' +
                '"contactPerson": "Hein Olivier",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0824991087"' +
                '},' +
                '{' +
                '"branchName": "Capitec Fraud Test",' +
                '"categoryId": 1,' +
                '"categoryIdDesc": "banks",' +
                '"contactPerson": "Hein Olivier",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0824991087"' +
                '},' +
                '{' +
                '"branchName": "Capitec Fraud Test",' +
                '"categoryId": 1,' +
                '"categoryIdDesc": "banks",' +
                '"contactPerson": "Hein Olivier",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0824991087"' +
                '},' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '},' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '},' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '},' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '},' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '},' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '},' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '},' +
                '{' +
                '"branchName": "Marketing CODIX",' +
                '"categoryId": 12,' +
                '"categoryIdDesc": "other entities",' +
                '"contactPerson": "CraigB",' +
                '"enquiryDate": "04/20/2023 00:00:00",' +
                '"telephoneNumber": "0218886000"' +
                '}' +
                '],' +
                '"enquiryDateTime": "04/20/2023 21:17:36",' +
                '"enquiryID": "4.72558464E8",' +
                '"inputSearchCriteria": {' +
                '"clientReference": "a572e652-b72c-47e5-b959-860ea4da0cb3",' +
                '"countryCode": 710,' +
                '"countryName": "South Africa",' +
                '"dob": "06/11/1988 00:00:00",' +
                '"enquiryPurpose": 12,' +
                '"firstName": "Jordan",' +
                '"gender": "M",' +
                '"identityNumber": "8806110477082",' +
                '"identityType": "SID",' +
                '"surname": "Hal"' +
                '},' +
                '"pinPoints": {' +
                '"alphaNumericPinpoints": [],' +
                '"numericPinpoints": []' +
                '},' +
                '"returnDataBreakdown": {' +
                '"dataSetCounts": {' +
                '"accounts": 1,' +
                '"accountsSpecified": true,' +
                '"addresses": 2,' +
                '"addressesSpecified": true,' +
                '"adversesSpecified": false,' +
                '"bureauScoresSpecified": false,' +
                '"dcEnquiriesSpecified": false,' +
                '"debtRestructuringsSpecified": false,' +
                '"deedsSpecified": false,' +
                '"directorsSpecified": false,' +
                '"disputeSpecified": false,' +
                '"employmentSpecified": false,' +
                '"enquiries": 15,' +
                '"enquiriesSpecified": true,' +
                '"fraudSpecified": false,' +
                '"judgementsSpecified": false,' +
                '"noticesSpecified": false,' +
                '"pinPointsSpecified": false,' +
                '"publicDefaultsSpecified": false,' +
                '"telephones": 5,' +
                '"telephonesSpecified": true,' +
                '"tracesSpecified": false,' +
                '"warnings": 1,' +
                '"warningsSpecified": true' +
                '}' +
                '},' +
                '"telephones": [' +
                '{' +
                '"dateFirstCreated": "10/25/2017 00:00:00",' +
                '"dateLastUpdated": "12/19/2014 00:00:00",' +
                '"telephoneNumber": "9999999999",' +
                '"telephoneTypeCode": "C",' +
                '"telephoneTypeDesc": "CELL"' +
                '},' +
                '{' +
                '"dateFirstCreated": "06/22/2015 00:00:00",' +
                '"dateLastUpdated": "11/19/2013 00:00:00",' +
                '"telephoneNumber": "9999999999",' +
                '"telephoneTypeCode": "W",' +
                '"telephoneTypeDesc": "WORK"' +
                '},' +
                '{' +
                '"dateFirstCreated": "03/25/2015 00:00:00",' +
                '"dateLastUpdated": "12/20/2012 00:00:00",' +
                '"telephoneNumber": "9999999999",' +
                '"telephoneTypeCode": "C",' +
                '"telephoneTypeDesc": "CELL"' +
                '},' +
                '{' +
                '"dateFirstCreated": "03/19/2014 00:00:00",' +
                '"dateLastUpdated": "11/19/2013 00:00:00",' +
                '"telephoneNumber": "9999999999",' +
                '"telephoneTypeCode": "C",' +
                '"telephoneTypeDesc": "CELL"' +
                '},' +
                '{' +
                '"dateFirstCreated": "12/18/2013 00:00:00",' +
                '"dateLastUpdated": "06/18/2013 00:00:00",' +
                '"telephoneNumber": "9999999999",' +
                '"telephoneTypeCode": "C",' +
                '"telephoneTypeDesc": "CELL"' +
                '}' +
                '],' +
                '"warnings": [' +
                '{' +
                '"reasonCode": 1,' +
                '"reasonCodeDesc": "MORE THAN THREE ENQUIRIES IN THE LAST SEVEN DAYS (BY OTHER SUBSCRIBERS)."' +
                '}' +
                ']' +
                '},' +
                '"transactionStats": {' +
                '"receivedTime": "04/20/2023 21:17:36",' +
                '"responseTime": "04/20/2023 21:17:37",' +
                '"systemUUID": "f63f961af54c5b29a0fb32edf450eeba"' +
                '}' +
                '}' +
                '},' +
                '"correlationID": "a572e652-b72c-47e5-b959-860ea4da0cb3",' +
                '"statusCode": 200' +
                '}';
        Capitec_BureauInformationViewHelper.BureauResponseWrapper badResponseWrapper = Capitec_BureauInformationViewHelper.pareJSON(jsonString);
        System.assert(badResponseWrapper != null);
    }
}