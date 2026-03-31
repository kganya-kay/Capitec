/**
 * @description       : Prepare list of Immediate and Future Dated Debit Orders
 * @author            : Samiirah.A@bsky.co.za
 * @group             : Conversions
 * @last modified on  : 09-22-2025
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class Conversions_AnalyseDebitOrders {

    @InvocableMethod(label='Segregate Debit Orders')
    public static List<DebitOrderOutput> generateEmailBodyForDebitOrders(List<debitOrderInput> requests) {
        String noActionDOStr = '';
        String clientActionStr = '';
         List<DebitOrderOutput> lstOutputs = new List<DebitOrderOutput>();

        debitOrderInput request = requests[0];

        if(request != null){
            List<Debit_Order__c> lstDebitOrders = [SELECT Id,
                                                    Amount__c,
                                                    Category__c,
                                                    Submitted_Cause_Code__c,
                                                    Debit_Order_Initiator__r.Name
                                                FROM Debit_Order__c 
                                                WHERE Case__c = :request.caseId ];

            if(!lstDebitOrders.isEmpty()){
                Map<String,List<Debit_Order__c>> mapDebitOrderTypeToDOs = segregateDOs(lstDebitOrders);

                if(mapDebitOrderTypeToDOs.containsKey('No Client Action')){
                        noActionDOStr += '<ol>';
                        for(Debit_Order__c debitOrder : mapDebitOrderTypeToDOs.get('No Client Action')){
                            noActionDOStr += '<li>';
                            noActionDOStr +=  debitOrder.Debit_Order_Initiator__r.Name + ' ';
                            noActionDOStr +=  'R' + debitOrder.Amount__c + '</li>';
                        }
                        noActionDOStr += '</ol>';
                }


                if(mapDebitOrderTypeToDOs.containsKey('Client to Action')){
                    clientActionStr += '<ol>';
                    for(Debit_Order__c debitOrder : mapDebitOrderTypeToDOs.get('Client to Action')){
                        clientActionStr += '<li>';
                        clientActionStr +=  debitOrder.Debit_Order_Initiator__r.Name + ' ';
                        clientActionStr +=  'R' + debitOrder.Amount__c + '</li>';
                    }
                    clientActionStr += '</ol>';
                }
            }
        }

        DebitOrderOutput output = new DebitOrderOutput();
        output.noActionDebitOrdersText = noActionDOStr;
        output.clientActionDebitOrdersText = clientActionStr;

        lstOutputs.add(output);

        return lstOutputs;
    }

    public static Map<String, List<Debit_Order__c>> segregateDOs(List<Debit_Order__c> lstDOs){
        Map<String, List<Debit_Order__c>> mapDebitOrderTypeToDOs = new Map<String, List<Debit_Order__c>>();

        for(Debit_Order__c debitOrder : lstDOs){
            if(mapDebitOrderTypeToDOs.containsKey(debitOrder.Submitted_Cause_Code__c)){
                mapDebitOrderTypeToDOs.get(debitOrder.Submitted_Cause_Code__c).add(debitOrder);
            }else{
                mapDebitOrderTypeToDOs.put(debitOrder.Submitted_Cause_Code__c, new List<Debit_Order__c>{debitOrder});
            }
        }
        return mapDebitOrderTypeToDOs;
    }
     public class debitOrderInput {
        @InvocableVariable(required=true)
        public Id caseId;
    }

    public class debitOrderOutput {
        @InvocableVariable
        public String noActionDebitOrdersText;

        @InvocableVariable
        public String clientActionDebitOrdersText;
    }
}