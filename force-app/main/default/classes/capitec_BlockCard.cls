/**
 * Created by CalebGovender on 2023/10/09.
 */
public with sharing class capitec_BlockCard {

    @TestVisible private static final String BAD_REQUEST_MSG = 'Bad request.';
    @TestVisible private static final String API_ISSUE_MSG = 'Capitec API not working..';
    @TestVisible private static String TEST_CIF;
    @TestVisible private static String TEST_CONSULTANT;
    @TestVisible private static String TEST_CARD;

    /**
    * @description       : Input class for the block Card invocable method
    * @author            : Caleb Govender
    **/
    public class BlockCardInput {
        @InvocableVariable(Label='recordID' Required=true)
        public String recordID;
        @InvocableVariable(Label='CIF')
        public String channelIdentifier;
        @InvocableVariable(Label='cardPan')
        public String cardPan;
        @InvocableVariable(Label='consultantIdentifier')
        public String consultantIdentifier;
        @InvocableVariable(Label='ABUEnabled')
        public String ABUEnabled;
    }

    /**
    * @description       : Invocable method to Stop a Card for a CIF
    * @author            : Caleb Govender
    **/
    @InvocableMethod(Label='Block Card' Category='CardHolding' Callout=true)
    public static void BlockCard(List<BlockCardInput> input) {

        BlockCardInput inputs = buildInputs(input[0].recordID,input[0].ABUEnabled);
        HttpResponse response = Capitec_CalloutHandler.makePOSTCalloutWithBody(
                Capitec_CalloutHandler.BLOCK_CARD,
                createBody(inputs.channelIdentifier, inputs.cardPan, inputs.consultantIdentifier, inputs.ABUEnabled));

        if (response.getStatusCode() == 400) {
            throw new BlockCardException(BAD_REQUEST_MSG);
        }

        if (response.getStatusCode() != 204) {
            throw new BlockCardException(API_ISSUE_MSG);
        }
    }

    /**
    * @description       : Builds the inputs for the Stop Card callout request body
    * @author            : Caleb Govender
    **/
    public static BlockCardInput buildInputs (String recordId,String ABUEnabled) {
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


        BlockCardInput input = new BlockCardInput();
        input.recordID = recordId;
        input.channelIdentifier = sCIFNumber;
        input.cardPan = sCardNumber;
        input.consultantIdentifier = sConsultantIdentifier;
        input.ABUEnabled = ABUEnabled;

        return input;
    }


    /**
    * @description       : Creates the body for the Stop Card callout request
    * @author            : Caleb Govender
    **/
    private static String createBody(String cifNumber, String cardPan, String consultantIdentifier, String abuEnabled) {
        RequestBodyWrapper requestBR = new RequestBodyWrapper();
        requestBR.cifNumber = cifNumber;
        requestBR.cardPan = cardPan;
        requestBR.consultantIdentifier = consultantIdentifier;
        requestBR.keepAbuEnrollment = abuEnabled;

        return JSON.serialize(requestBR);
    }

    /**
    * @description       : Wrapper class for the Stop Card callout request body
    * @author            : Caleb Govender
    **/
    public class RequestBodyWrapper {

        public String cifNumber {get; set;}
        public String cardPan {get; set;}
        public String consultantIdentifier {get; set;}
        public String keepAbuEnrollment {get; set;}
    }

    public class BlockCardException extends Exception {}

}