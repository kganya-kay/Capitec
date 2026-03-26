/**
 * Created by dawid on 19.10.2023.
 *
 * This class handles Flagging operations coming from Track and Trace component
 * It provides methods for saving flagged items as salesforce records
 */

public without sharing class Capitec_TrackAndTraceFlaggingHandler {

    /**
     *  These enums keep information about API values names for each object that
     *  Salesforce saves as flagged
     */

    public enum CoreBankingParameters {availableBalance, transactionCode, transactionAmount, transactionDate, transactionId, postDate, id, authId, branchId, creditDebitIndicator, journalNumber, narrative, promoCode, accountNumber}
    public enum TransactionCardParameters {id, postilionTransactionId, transactionNumber, cardNumber, onlineSystemId, parsedTransactionDateTime, fromAccountNumber, toAccountNumber, officeTransactionNumber, siteName, deviceId, sourceNodeName, sinkNodeName, cardProduct, transactionType, responseCode, retrievalReferenceNumber, authId, messageType, systemTraceAuditNumber, reconBatchNumber, transactionRequestAmount, transactionResponseAmount, settleAmountImpact, transactionPostilionOriginated, transactionReversed}
    public enum ATMEventTransactionParameters {id, deviceId, parsedEventDateTime, entity, eventId, severity, message}
    public enum ATMEventDeviceParameters {id, deviceId, parsedEventDateTime, source, eventNumber, eventMessage, originalMessage}


    /**
     * @param corebankingJSON - JSON string with information about the flagged objects
     *
     * This method takes a JSON string that holds information about related CaseId
     * and a list of objects that have to be flagged.
     * The method parses data into Salesforce records, checks if the records already exist
     * and if not - saves new records
     *
     * @return Boolean - either success or failure (true / false)
     */
    @AuraEnabled
    public static Boolean saveFlaggedCoreBankingTransactions(String corebankingJSON){

        /**
         *  at this point we need to parse the incoming JSON into apex structures
         *  so the method is going to cast it into untyped object and list of objects.
         *  We're also going to need a map of the created records linked to their Capitec
         *  ids in order to check for the duplicates
        */

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(corebankingJSON);
        Map<String, CR_DR_Indicator__c> transactionsByNames = new Map<String, CR_DR_Indicator__c>();
        List<Object> transactions = (List<Object>) (wrapper.get('content'));
        String caseId = safeCastToString(wrapper.get('caseId'));
        List<CR_DR_Indicator__c> alreadyFlaggedItemsForCase;


        if(transactions.isEmpty()){
            return false;
        }

        for(Object transItem: transactions){
            Map<String, Object> valuesByNames = (Map<String, Object>) transItem;
            CR_DR_Indicator__c newCoreBankingRec = new CR_DR_Indicator__c();

            newCoreBankingRec.Case__c = caseId;

            newCoreBankingRec.Available_Balance__c = safeCastToDecimal(valuesByNames.get(String.valueOf(CoreBankingParameters.availableBalance)));
            newCoreBankingRec.Transaction_Amount__c = safeCastToDecimal(valuesByNames.get(String.valueOf(CoreBankingParameters.transactionAmount)));

            newCoreBankingRec.Transaction_Date__c = safeCastToDate(valuesByNames.get(String.valueOf(CoreBankingParameters.transactionDate)));
            newCoreBankingRec.Posting_Date__c = safeCastToDate(valuesByNames.get(String.valueOf(CoreBankingParameters.postDate)));

            newCoreBankingRec.Name = safeCastToString(valuesByNames.get(String.valueOf(CoreBankingParameters.id)));
            newCoreBankingRec.Auth_ID__c = safeCastToString(valuesByNames.get(String.valueOf(CoreBankingParameters.authId)));
            newCoreBankingRec.Branch_Terminal__c = safeCastToString(valuesByNames.get(String.valueOf(CoreBankingParameters.branchId)));
            newCoreBankingRec.CR_DR_Indicator__c = safeCastToString(valuesByNames.get(String.valueOf(CoreBankingParameters.creditDebitIndicator)));
            newCoreBankingRec.Journal_Number__c = safeCastToString(valuesByNames.get(String.valueOf(CoreBankingParameters.journalNumber)));
            newCoreBankingRec.Narrative__c = safeCastToString(valuesByNames.get(String.valueOf(CoreBankingParameters.narrative)));
            newCoreBankingRec.Promo_Code__c = safeCastToString(valuesByNames.get(String.valueOf(CoreBankingParameters.promoCode)));
            newCoreBankingRec.Transaction_Code__c = safeCastToString(valuesByNames.get(String.valueOf(CoreBankingParameters.transactionCode)));
            newCoreBankingRec.Account_Number__c = safeCastToString(valuesByNames.get(String.valueOf(CoreBankingParameters.accountNumber)));

            transactionsByNames.put(newCoreBankingRec.Name,newCoreBankingRec);
        }

        /**
        * Checking for duplicates after parsing
        */

        alreadyFlaggedItemsForCase = [SELECT Id, Name FROM CR_DR_Indicator__c WHERE Name IN: transactionsByNames.keySet() AND Case__c =: caseId];

        if(alreadyFlaggedItemsForCase.isEmpty() == false){
            for (CR_DR_Indicator__c item : alreadyFlaggedItemsForCase){
                transactionsByNames.remove(item.Name);
            }
        }
        if(transactionsByNames.isEmpty() == false){
            try{
                insert transactionsByNames.values();
            }
            catch (DmlException e){
                System.debug(e.getMessage());
                return false;
            }
        }

        return true;
    }


    /**
     * @see Capitec_TrackAndTraceFlaggingHandler
     * @param cardTransactionJSON - JSON string for Card Transactions
     *
     * @return Boolean - either success or failure (true / false)
     */

    @AuraEnabled
    public static Boolean saveFlaggedCardTransactions(String cardTransactionJSON){

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(cardTransactionJSON);
        Map<String, Card_Transaction__c> cardTransactionsByNames = new Map<String, Card_Transaction__c>();
        List<Object> transactions = (List<Object>) (wrapper.get('content'));
        String caseId = safeCastToString(wrapper.get('caseId'));
        List<Card_Transaction__c> alreadyFlaggedItemsForCase;

        /**
         * @see Capitec_TrackAndTraceFlaggingHandler.saveFlaggedCoreBankingTransactions
         * this method follows the same logic as the one mentioned above.
        */

        if(transactions.isEmpty()){
            return false;
        }

        for(Object transItem: transactions){
            Map<String, Object> valuesByNames = (Map<String, Object>) transItem;
            Card_Transaction__c newCardTransRec = new Card_Transaction__c();

            newCardTransRec.Case__c = caseId;

            newCardTransRec.Name = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.id)));
            newCardTransRec.From_Account__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.fromAccountNumber)));
            newCardTransRec.To_Account__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.toAccountNumber)));
            newCardTransRec.Office_Transaction_Number__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.officeTransactionNumber)));
            newCardTransRec.Site_Name__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.siteName)));
            newCardTransRec.Terminal_ID__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.deviceId)));
            newCardTransRec.Source_Node__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.sourceNodeName)));
            newCardTransRec.Sink_Node__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.sinkNodeName)));
            newCardTransRec.Card_Product__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.cardProduct)));
            newCardTransRec.Transaction_Type__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.transactionType)));
            newCardTransRec.Response_Code__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.responseCode)));
            newCardTransRec.Retrieval_Reference__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.retrievalReferenceNumber)));
            newCardTransRec.Auth_ID__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.authId)));
            newCardTransRec.Transaction_Message_Type__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.messageType)));
            newCardTransRec.Stan_Number__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.systemTraceAuditNumber)));
            newCardTransRec.Recon_Batch_Number__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.reconBatchNumber)));
            newCardTransRec.Card_Number__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.cardNumber)));

            newCardTransRec.Tran_postilion_originated__c = safeCastToBoolean(valuesByNames.get(String.valueOf(TransactionCardParameters.transactionPostilionOriginated)));

            newCardTransRec.Timestamp__c = safeCastToString(valuesByNames.get(String.valueOf(TransactionCardParameters.parsedTransactionDateTime)));

            newCardTransRec.Request_Amount__c = safeCastToDecimal(valuesByNames.get(String.valueOf(TransactionCardParameters.transactionRequestAmount)));
            newCardTransRec.Response_Amount__c = safeCastToDecimal(valuesByNames.get(String.valueOf(TransactionCardParameters.transactionResponseAmount)));
            newCardTransRec.Settle_Request_Amount__c = safeCastToDecimal(valuesByNames.get(String.valueOf(TransactionCardParameters.settleAmountImpact)));

            cardTransactionsByNames.put(newCardTransRec.Name,newCardTransRec);
        }

        alreadyFlaggedItemsForCase = [SELECT Id, Name FROM Card_Transaction__c WHERE Name IN: cardTransactionsByNames.keySet() AND Case__c =: caseId];

        if(alreadyFlaggedItemsForCase.isEmpty() == false){
            for (Card_Transaction__c item : alreadyFlaggedItemsForCase){
                cardTransactionsByNames.remove(item.Name);
            }
        }
        if(cardTransactionsByNames.isEmpty() == false){
            try{
                insert cardTransactionsByNames.values();
                System.debug(cardTransactionsByNames.values());
            }
            catch (DmlException e){
                System.debug(e.getMessage());
                return false;
            }
        }

        return true;
    }

    /**
     * @see Capitec_TrackAndTraceFlaggingHandler
     * @param atmDeviceEventJSON - JSON string for ATM Device Event
     *
     * @return Boolean - either success or failure (true / false)
     */


    @AuraEnabled
    public static Boolean saveFlaggedCardATMDeviceEvents(String atmDeviceEventJSON){

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(atmDeviceEventJSON);
        Map<String, ATM_Device_Event__c> eventsByNames = new Map<String, ATM_Device_Event__c>();
        List<Object> events = (List<Object>) (wrapper.get('content'));
        String caseId = safeCastToString(wrapper.get('caseId'));
        List<ATM_Device_Event__c> alreadyFlaggedItemsForCase;

        /**
         * @see Capitec_TrackAndTraceFlaggingHandler.saveFlaggedCoreBankingTransactions
         * this method follows the same logic as the one mentioned above.
        */

        if(events.isEmpty()){
            return false;
        }

        for(Object eventItem: events){
            Map<String, Object> valuesByNames = (Map<String, Object>) eventItem;
            ATM_Device_Event__c newCardEventRec = new ATM_Device_Event__c();

            newCardEventRec.Case__c = caseId;

            newCardEventRec.Name = safeCastToString(valuesByNames.get(String.valueOf(ATMEventDeviceParameters.id)));
            newCardEventRec.ATM_ID__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventDeviceParameters.deviceId)));
            newCardEventRec.Event_Description__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventDeviceParameters.eventMessage)));
            newCardEventRec.Event_Number__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventDeviceParameters.eventNumber)));
            newCardEventRec.Original_Message__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventDeviceParameters.originalMessage)));
            newCardEventRec.Timestamp__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventDeviceParameters.parsedEventDateTime)));
            newCardEventRec.Source__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventDeviceParameters.source)));

            eventsByNames.put(newCardEventRec.Name, newCardEventRec);
        }

        alreadyFlaggedItemsForCase = [SELECT Id, Name FROM ATM_Device_Event__c WHERE Name IN: eventsByNames.keySet() AND Case__c =: caseId];

        if(alreadyFlaggedItemsForCase.isEmpty() == false){
            for (ATM_Device_Event__c item : alreadyFlaggedItemsForCase){
                eventsByNames.remove(item.Name);
            }
        }
        if(eventsByNames.isEmpty() == false){
            try{
                insert eventsByNames.values();
                System.debug(eventsByNames.values());
            }
            catch (DmlException e){
                System.debug(e.getMessage());
                return false;
            }
        }

        return true;
    }

    /**
     * @see Capitec_TrackAndTraceFlaggingHandler
     * @param atmTransactionEventJSON - JSON string for ATM Transaction Event
     *
     * @return Boolean - either success or failure (true / false)
     */


    @AuraEnabled
    public static Boolean saveFlaggedCardATMTransactionEvents(String atmTransactionEventJSON){

        Map<String, Object> wrapper = (Map<String, Object>) JSON.deserializeUntyped(atmTransactionEventJSON);
        Map<String, ATM_Transaction_Event__c> eventsByNames = new Map<String, ATM_Transaction_Event__c>();
        List<Object> events = (List<Object>) (wrapper.get('content'));
        String caseId = safeCastToString(wrapper.get('caseId'));
        List<ATM_Transaction_Event__c> alreadyFlaggedItemsForCase;

        /**
         * @see Capitec_TrackAndTraceFlaggingHandler.saveFlaggedCoreBankingTransactions
         * this method follows the same logic as the one mentioned above.
        */

        if(events.isEmpty()){
            return false;
        }

        for(Object eventItem: events){
            Map<String, Object> valuesByNames = (Map<String, Object>) eventItem;
            ATM_Transaction_Event__c newCardEventRec = new ATM_Transaction_Event__c();

            newCardEventRec.Case__c = caseId;
            newCardEventRec.Name = safeCastToString(valuesByNames.get(String.valueOf(ATMEventTransactionParameters.id)));
            newCardEventRec.Terminal_ID__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventTransactionParameters.deviceId)));
            newCardEventRec.Event_ID__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventTransactionParameters.eventId)));
            newCardEventRec.Entity__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventTransactionParameters.entity)));
            newCardEventRec.Severity__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventTransactionParameters.severity)));
            newCardEventRec.Message__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventTransactionParameters.message)));
            
            newCardEventRec.Timestamp__c = safeCastToString(valuesByNames.get(String.valueOf(ATMEventTransactionParameters.parsedEventDateTime)));

            eventsByNames.put(newCardEventRec.Name, newCardEventRec);
        }

        alreadyFlaggedItemsForCase = [SELECT Id, Name FROM ATM_Transaction_Event__c WHERE Name IN: eventsByNames.keySet() AND Case__c =: caseId];

        if(alreadyFlaggedItemsForCase.isEmpty() == false){
            for (ATM_Transaction_Event__c item : alreadyFlaggedItemsForCase){
                eventsByNames.remove(item.Name);
            }
        }
        if(eventsByNames.isEmpty() == false){
            try{
                insert eventsByNames.values();
                System.debug(eventsByNames.values());
            }
            catch (DmlException e){
                System.debug(e.getMessage());
                return false;
            }
        }

        return true;
    }



    private static Boolean safeCastToBoolean(Object obj){
        try{
            return Boolean.valueOf(String.valueOf(obj));
        }
        catch (TypeException e){
            return null;
        }
    }

    private static String safeCastToString(Object obj) {
        try {
            return String.valueOf(obj);
        } catch (TypeException e) {
            return null;
        }
    }

    private static Decimal safeCastToDecimal(Object obj) {
        try {
            return Decimal.valueOf(safeCastToString(obj));
        } catch (Exception e) {
            return null;
        }
    }

    private static Date safeCastToDate(Object obj) {
        try {
            System.debug(safeCastToString(obj));
            return (Date)JSON.deserialize('"'+safeCastToString(obj) + '"', Date.class);
        } catch (Exception e) {
            return null;
        }
    }

    private static Datetime safeCastToDateTime(Object obj) {
        try {
            System.debug(safeCastToString(obj));
            String stringifiedDate = safeCastToString(obj);
            return (Datetime)JSON.deserialize('"' + stringifiedDate.remove('Z') + '"', Datetime.class);
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(obj);
            return null;
        }
    }

    @AuraEnabled
    public static List<String> selectCDDRIndicatorIds(String caseId){
        List<CR_DR_Indicator__c> transactions = [SELECT Id, Name FROM CR_DR_Indicator__c LIMIT 40000];
        List<String> transactionsCapiIds = new List<String>();

        for(CR_DR_Indicator__c transRecord : transactions){
            transactionsCapiIds.add(transRecord.Name);
        }

        return transactionsCapiIds;
    }

    @AuraEnabled
    public static List<String> selectCardTransactionsIds(String caseId){
        List<Card_Transaction__c> transactions = [SELECT Id, Name FROM Card_Transaction__c LIMIT 40000];
        List<String> transactionsCapiIds = new List<String>();

        for(Card_Transaction__c transRecord : transactions){
            transactionsCapiIds.add(transRecord.Name);
        }

        return transactionsCapiIds;
    }

    @AuraEnabled
    public static List<String> selectATMTransactionEventIds(String caseId){
        List<ATM_Transaction_Event__c> transactions = [SELECT Id, Name FROM ATM_Transaction_Event__c LIMIT 40000];
        List<String> transactionsCapiIds = new List<String>();

        for(ATM_Transaction_Event__c transRecord : transactions){
            transactionsCapiIds.add(transRecord.Name);
        }

        return transactionsCapiIds;
    }

    @AuraEnabled
    public static List<String> selectATMDeviceEventsIds(String caseId){
        List<ATM_Device_Event__c> transactions = [SELECT Id, Name FROM ATM_Device_Event__c LIMIT 40000];
        List<String> transactionsCapiIds = new List<String>();

        for(ATM_Device_Event__c transRecord : transactions){
            transactionsCapiIds.add(transRecord.Name);
        }

        return transactionsCapiIds;
    }
}