/**
 * @description       : Class for Unblocking a channel for a CIF in Capitec
 * @author            : Caleb Govender
 * @last modified by  : Caleb Govender
**/
public with sharing class capitec_UnBlockChannel {


    @TestVisible private static final String BAD_REQUEST_MSG = 'Bad request.';
    @TestVisible private static final String API_ISSUE_MSG = 'Capitec API not working..';

    /**
    * @description       : Input class for the Unblock channel invocable method
    * @author            : Caleb Govender
    **/
    public class UnBlockChannelInput {
        @InvocableVariable(Label='Type' Required=true)
        public String channelType;
        @InvocableVariable(Label='CIF' Required=true)
        public String channelIdentifier;
        @InvocableVariable(Label='MSISDN')
        public String msisdn;
    }

    /**
    * @description       : Invocable method to Unblock a channel for a CIF
    * @author            : Caleb Govender
    **/
    @InvocableMethod(Label='UnBlock Channel' Category='Channel' Callout=true)
    public static void UnblockChannel(List<UnBlockChannelInput> input) {
        HttpResponse response = Capitec_CalloutHandler.makePOSTCalloutWithBody(
                Capitec_CalloutHandler.UNBLOCK_CHANNEL,
                createBody(input[0].channelType, input[0].channelIdentifier, input[0].msisdn));
        if (response.getStatusCode() == 400) {
            throw new UnBlockChannelException(BAD_REQUEST_MSG);
        }

        if (response.getStatusCode() != 204) {
            throw new UnBlockChannelException(API_ISSUE_MSG);
        }
    }

    /**
    * @description       : Creates the body for the Unblock channel callout request
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
    * @description       : Wrapper class for the Unblock channel callout request body
    * @author            : Caleb Govender
    **/
    public class RequestBodyWrapper {

        public String channel {get; set;}
        public String cifNumber {get; set;}
        public String msisdn {get; set;}
    }

    public class UnBlockChannelException extends Exception {}
}