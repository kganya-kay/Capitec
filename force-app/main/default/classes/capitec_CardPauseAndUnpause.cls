/**
 * Created by CalebGovender on 2023/10/27.
 */

public with sharing class capitec_CardPauseAndUnpause {

    @TestVisible private static final String BAD_REQUEST_MSG = 'Bad request.';
    @TestVisible private static final String API_ISSUE_MSG = 'Capitec API not working..';
    @TestVisible private static final String CARD_ISSUE = 'Card cannot be Paused or Unpaused.';
    @TestVisible private static String TEST_CIF;
    @TestVisible private static String TEST_CONSULTANT;
    @TestVisible private static String TEST_CARD;
    @TestVisible private static String TEST_STATUS;

    public class PauseUnPauseCardInput {
        @InvocableVariable(Label='recordID' Required=true)
        public String recordID;
        @InvocableVariable(Label='CIF')
        public String channelIdentifier;
        @InvocableVariable(Label='cardPan')
        public String cardPan;
        @InvocableVariable(Label='consultantIdentifier')
        public String consultantIdentifier;
    }

    @InvocableMethod(Label='Pause/Unpause Card' Category='CardHolding' Callout=true)
    public static void PauseUnpauseCard(List<PauseUnPauseCardInput> input) {
        HttpResponse response = new HttpResponse();
        String sStatus = '';

        if(Test.isRunningTest()){
            sStatus = TEST_STATUS;
        }else if(!Test.isRunningTest()) {
            List<CardHolding__x> cardStatus = [SELECT Id,cardStatus__c FROM CardHolding__x  WHERE Id = :input[0].recordID];
            sStatus = cardStatus[0].cardStatus__c;
        }

        PauseUnPauseCardInput inputs = buildInputs(input[0].recordID);
        if(sStatus == 'ACTIVE'){
            response = Capitec_CalloutHandler.makePOSTCalloutWithBody(
                    Capitec_CalloutHandler.PAUSE_CARD,
                    createBody(inputs.channelIdentifier, inputs.cardPan, inputs.consultantIdentifier));

        }
        else if(sStatus == 'STOPPED') {
            response = Capitec_CalloutHandler.makePOSTCalloutWithBody(
                    Capitec_CalloutHandler.UNPAUSE_CARD,
                    createBody(inputs.channelIdentifier, inputs.cardPan, inputs.consultantIdentifier));
        }else{
            throw new CardPauseAndUnpauseException(CARD_ISSUE);
        }
        if (response.getStatusCode() == 400) {
            throw new CardPauseAndUnpauseException(BAD_REQUEST_MSG);
        }

        if (response.getStatusCode() != 204) {
            throw new CardPauseAndUnpauseException(API_ISSUE_MSG);
        }
    }


    public static PauseUnPauseCardInput buildInputs (String recordId) {
        String sCardNumber = '';
        String sCIFNumber = '';
        String sConsultantIdentifier = '';

        if(Test.isRunningTest()){
            sCardNumber = TEST_CIF;
            sCIFNumber = TEST_CARD;
            sConsultantIdentifier = TEST_CONSULTANT;
        }else if(!Test.isRunningTest()) {
            List<CardHolding__x> cardHoldings = [SELECT Id, cardNumber__c,relatedAccount__r.CIF_Number__c,cardStatus__c FROM CardHolding__x  WHERE Id = :recordId];
            sCardNumber = cardHoldings[0].cardNumber__c;
            sCIFNumber = cardHoldings[0].relatedAccount__r.CIF_Number__c;
            sConsultantIdentifier = Capitec_DataSourceCardHolding.getUserEmployeeNumber();
        }

        PauseUnPauseCardInput input = new PauseUnPauseCardInput();
        input.recordID = recordId;
        input.channelIdentifier = sCIFNumber;
        input.cardPan = sCardNumber;
        input.consultantIdentifier = sConsultantIdentifier;

        return input;
    }

    private static String createBody(String cifNumber, String cardPan, String consultantIdentifier) {
        RequestBodyWrapper requestBR = new RequestBodyWrapper();
        requestBR.cifNumber = cifNumber;
        requestBR.cardPan = cardPan;
        requestBR.consultantIdentifier = consultantIdentifier;

        return JSON.serialize(requestBR);
    }

    public class RequestBodyWrapper {

        public String cifNumber {get; set;}
        public String cardPan {get; set;}
        public String consultantIdentifier {get; set;}
    }

    public class CardPauseAndUnpauseException extends Exception {}
}