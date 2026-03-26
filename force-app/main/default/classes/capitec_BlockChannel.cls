/**
 * @description       : Class for blocking a channel for a CIF in Capitec
 * @author            : Caleb Govender
 * @last modified by  : Caleb Govender
**/
public with sharing class capitec_BlockChannel {

    @TestVisible private static final String BAD_REQUEST_MSG = 'Bad request.';
    @TestVisible private static final String API_ISSUE_MSG = 'Capitec API not working..';

    /**
     * @description       : Input class for the block channel invocable method
     * @author            : Caleb Govender
    **/
    public class BlockChannelInput {
        @InvocableVariable(Label='Type' Required=true)
        public String channelType;
        @InvocableVariable(Label='CIF' Required=true)
        public String cifNumber;
        @InvocableVariable(Label='MSISDN')
        public String msisdn;
    }

    /**
    * @description       : Invocable method to block a channel for a CIF
    * @author            : Caleb Govender
    **/
    @InvocableMethod(Label='Block Channel' Category='Channel' Callout=true)
    public static void blockChannel(List<BlockChannelInput> input) {
        HttpResponse response = Capitec_CalloutHandler.makePOSTCalloutWithBody(
                Capitec_CalloutHandler.BLOCK_CHANNEL,
                createBody(input[0].channelType, input[0].cifNumber, input[0].msisdn));
        if (response.getStatusCode() == 400) {
            throw new BlockChannelException(BAD_REQUEST_MSG);
        }

        if (response.getStatusCode() != 204) {
            throw new BlockChannelException(API_ISSUE_MSG);
        }
    }

    /**
    * @description       : Creates the body for the block channel callout request
    * @author            : Caleb Govender
    **/
    private static String createBody(String channeltype, String cifNumber, String msisdn) {
        RequestBodyWrapper requestBR = new RequestBodyWrapper();
        requestBR.channel = channeltype;
        requestBR.cifNumber = cifNumber;
        requestBR.msisdn = msisdn;

        return JSON.serialize(requestBR);
    }

    /**
    * @description       : Wrapper class for the block channel callout request body
    * @author            : Caleb Govender
    **/
    public class RequestBodyWrapper {

        public String channel {get; set;}
        public String cifNumber {get; set;}
        public String msisdn {get; set;}
    }

    public class BlockChannelException extends Exception {}
}