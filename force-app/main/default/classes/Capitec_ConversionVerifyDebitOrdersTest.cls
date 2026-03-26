/**
 * @description       : Test class for Capitec_ConversionVerifyDebitOrders.cls
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 01-27-2026
 * @last modified by  : Samiirah Aujub
**/
@isTest
public with sharing class Capitec_ConversionVerifyDebitOrdersTest {
    public static Id CONVERSIONS_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();

    @TestSetup
    static void setupTestData() {
         Case testCaseNoResponse = new Case(Subject = 'Case related to DOs with no reponses',
                                            Status = 'In Progress',
                                            Origin = 'Branch',
                                            RecordTypeId = CONVERSIONS_RECORDID
                                        );
                                        
        Case testCaseResponse = new Case(Subject = 'Case related to DOs with responses',
                                         Status = 'In Progress',
                                         Origin = 'Branch',
                                         RecordTypeId = CONVERSIONS_RECORDID
                                        );

        insert new List<Case>{ testCaseNoResponse, testCaseResponse };

        Debit_Order__c debitOrder = new Debit_Order__c(Name = 'DO-001',
                                                       Amount__c = 100.0,
                                                       From_Account__c = '123456789',
                                                       To_Capitec_Account__c = '987654321',
                                                       Debit_OrderDate__c = Date.today(),
                                                       Submitted_Cause_Code__c = 'Client to Action',
                                                       Case__c = testCaseNoResponse.Id
                                                     );
        Debit_Order__c debitOrder2 = new Debit_Order__c(Name = 'DO-001',
                                                       Amount__c = 100.0,
                                                       From_Account__c = '123455789',
                                                       To_Capitec_Account__c = '987654321',
                                                       Debit_OrderDate__c = Date.today(),
                                                       Submitted_Cause_Code__c = 'Client to Action',
                                                       Case__c = testCaseNoResponse.Id
        );

        Debit_Order__c debitOrderConfirmed = new Debit_Order__c(Name = 'DO-002',
                                                                Amount__c = 100.0,
                                                                From_Account__c = '123456789',
                                                                To_Capitec_Account__c = '987654321',
                                                                Debit_OrderDate__c = Date.today(),
                                                                Confirmation_Cause_Code__c = '	Client to Contact DOI',
                                                                Case__c = testCaseResponse.Id
                                                                );
        Debit_Order__c debitOrderConfirmed2 = new Debit_Order__c(Name = 'DO-002',
                                                                Amount__c = 100.0,
                                                                From_Account__c = '123456789',
                                                                To_Capitec_Account__c = '987654321',
                                                                Debit_OrderDate__c = Date.today(),
                                                                Confirmation_Cause_Code__c = '	Client to Contact DOI',
                                                                Case__c = testCaseResponse.Id
                                                                );
        
        

        
        insert new List<Debit_Order__c>{debitOrder,debitOrder2, debitOrderConfirmed,debitOrderConfirmed2};
        
    }


    public static List<Capitec_ConversionVerifyDebitOrders.responseWrapper> callAnalyse(Id caseId) {
        Capitec_ConversionVerifyDebitOrders.requestWrapper req = new Capitec_ConversionVerifyDebitOrders.requestWrapper();
        req.caseId = caseId;
        return Capitec_ConversionVerifyDebitOrders.analyseDebitOrders(new List<Capitec_ConversionVerifyDebitOrders.requestWrapper>{ req });
    }
    
    @IsTest
    public static void testDebitOrderResponse() {
        Case caseRecord = [SELECT Id FROM Case WHERE Subject = 'Case related to DOs with responses'];

        List<Capitec_ConversionVerifyDebitOrders.responseWrapper> result = callAnalyse(caseRecord.Id);
        Assert.isTrue(result[0].result, 'All DOs have a confirmation cause code. Case Auto Close');
    }
    
    @IsTest
    public static void testDebitOrderNoResponse() {
         Case caseRecord = [SELECT Id, Subject FROM Case WHERE Subject = 'Case related to DOs with no reponses'];

         System.debug('##testDebitOrderNoResponse caseRecord fetched:' + caseRecord);

        List<Capitec_ConversionVerifyDebitOrders.responseWrapper> result = callAnalyse(caseRecord.Id);
        Assert.isFalse(result[0].result, 'At least one Debit_Order missing Confirmation_Cause_Code . Case remain open');
    }
}