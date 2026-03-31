/**
 * @description       : COCONV-1938 - Invocable Method to check if all Debit Orders related to a case has a response
 * @author            : Samiirah.A@bsky.co.za
 * @group             : Capitec Conversions
 * @last modified on  : 09-04-2025
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class Capitec_ConversionVerifyDebitOrders {

    public class requestWrapper {
        @InvocableVariable(required=true)
        public Id caseId;
    }

    public class responseWrapper {
        @InvocableVariable
        public Boolean result;
    }

    @InvocableMethod(label='Analyse Debit Orders')
    public static List<responseWrapper> analyseDebitOrders(List<requestWrapper> caseWrappers) {
        Boolean autoCloseCase = true;

        Set<Id> setCaseIds = new Set<Id>();
        List<Case> lstCaseToUpdate = new List<Case>();
        Map<Id, List<Debit_Order__c>> mapCaseIdToDOs = new Map<Id, List<Debit_Order__c>>();

        for (requestWrapper wrapper : caseWrappers) {
            if (wrapper.caseId != null) {
                setCaseIds.add(wrapper.caseId);
            }
        }

        System.debug('##setCaseIds :' +setCaseIds);

        if (!setCaseIds.isEmpty()) {
            mapCaseIdToDOs = getDebitOrders(setCaseIds);

             System.debug('##mapCaseIdToDOs :' +mapCaseIdToDOs);

            for (Id caseId : mapCaseIdToDOs.keySet()) { //Case record will always be one, therefore no complexity due to nested for loop
                
                //one debit order - Close case
                if (mapCaseIdToDOs.get(caseId).size() <= 1){
                    autoCloseCase = true;
                }

                for (Debit_Order__c debitOrder : mapCaseIdToDOs.get(caseId)) {
                    if (debitOrder.Confirmation_Cause_Code__c == null) {
                        autoCloseCase = false;
                    }
                }
               
            }
            System.debug('##autoCloseCase :' +autoCloseCase);
        }

        responseWrapper response = new responseWrapper();
        response.result = autoCloseCase;

        return new List<responseWrapper> {response};
    }



    public static Map<Id,List<Debit_Order__c>> getDebitOrders(Set<Id> setIds){
        Map<Id,List<Debit_Order__c>> mapCaseIdToDOs = new Map<Id, List<Debit_Order__c>>();

        for(Debit_Order__c debitOrder : [SELECT Id, 
                                                Confirmation_Cause_Code__c, 
                                                Case__c 
                                         FROM Debit_Order__c 
                                         WHERE Case__c IN:setIds]){
            if(mapCaseIdToDOs.containsKey(debitOrder.Case__c)){
                mapCaseIdToDOs.get(debitOrder.Case__c).add(debitOrder);
            }
            else{
                mapCaseIdToDOs.put(debitOrder.Case__c, new List<Debit_Order__c>{debitOrder});
            }
        }

        return mapCaseIdToDOs;
    }

    
}