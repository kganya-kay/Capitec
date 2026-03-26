/**
 * Created by sebastian on 18/05/2023.
 */

public with sharing class capitec_BlockAccount {
    @TestVisible private static final String BAD_REQUEST_MSG = 'Bad request.';
    @TestVisible private static final String API_ISSUE_MSG = 'Capitec API not working..';

    public class BlockAccountInput {
        @InvocableVariable(Label='Account Number' Required=true)
        public String accountNumber;

        @InvocableVariable(Label='Blocking Reason' Required=true)
        public String reason;
    }

    @InvocableMethod(Label='Block Clients Account(Product)' Category='Product' Callout=true)
    public static void blockAccount(List<BlockAccountInput> input) {

        HttpResponse response = Capitec_CalloutHandler.makePOSTCalloutWithBody(
                Capitec_CalloutHandler.PRODUCTS_BLOCK_ACCOUNT,
                createBody(input[0].accountNumber, input[0].reason));

        if (response.getStatusCode() == 400) {
            throw new BlockAccountException(BAD_REQUEST_MSG);
        }

        if (response.getStatusCode() != 200) {
            throw new BlockAccountException(API_ISSUE_MSG);
        }
    }

    private static String createBody(String accNumber, String reason) {
        RequestBodyWrapper requestBR = new RequestBodyWrapper();
        requestBR.accountNumber = accNumber;
        requestBR.correlationId = '3fa85f64-5717-4562-b3fc-2c963f66afa6';
        requestBR.stopReason = reason;

        return JSON.serialize(requestBR);
    }

    public class RequestBodyWrapper {
        public String correlationId {get; set;}
        public String stopReason {get; set;}
        public String accountNumber {get; set;}
    }

    public class BlockAccountException extends Exception {}
}