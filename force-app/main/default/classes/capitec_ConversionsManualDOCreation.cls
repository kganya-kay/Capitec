public with sharing class capitec_ConversionsManualDOCreation {

    public capitec_ConversionsManualDOCreation() {
    }

    @InvocableMethod(label='Insert Debit Orders' description='Insert drafted debit orders from JSON with Case/Conversion ID')
    public static List<Output> insertDebitOrders(List<Request> requests) {

        List<Debit_Order__c> debitordersToInsert = new List<Debit_Order__c>();

        for (Request req : requests) {
            if (String.isNotBlank(req.jsonString)) {
                // Two-step cast
                List<Object> rawList = (List<Object>) JSON.deserializeUntyped(req.jsonString);

                for (Object obj : rawList) {
                    Map<String, Object> r = (Map<String, Object>) obj;

                    Debit_Order__c order = new Debit_Order__c(
                        Debit_Order_Initiator__c = (String) r.get('DOIId'),
                        Name = (String) r.get('Reference__c'),
                        Debit_Order_Date__c = r.containsKey('Date__c') ? Date.valueOf((String) r.get('Date__c')) : null,
                        Debit_OrderDate__c = r.containsKey('Date__c') ? Date.valueOf((String) r.get('Date__c')) : null,
                        Amount__c = r.containsKey('Amount__c') ? Decimal.valueOf(String.valueOf(r.get('Amount__c'))) : null,
                        Category__c = (String) r.get('Category__c'),
                        Case__c = req.caseId
                    );

                    debitordersToInsert.add(order);
                }
            }
        }

        if (!debitordersToInsert.isEmpty()) {
            insert debitordersToInsert;
        }

        List<Output> results = new List<Output>();
        for (Debit_Order__c o : debitordersToInsert) {
            results.add(new Output(o.Id));
        }

        return results;
    }

    public class Request {
        @InvocableVariable(required=true)
        public String jsonString;

        @InvocableVariable(required=true)
        public Id caseId;
    }

    public class Output {
        @InvocableVariable
        public Id recordId;

        public Output(Id recordId) {
            this.recordId = recordId;
        }
    }
}