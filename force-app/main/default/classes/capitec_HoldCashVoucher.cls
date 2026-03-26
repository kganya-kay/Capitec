/**
 * Created by CalebGovender on 2023/06/21.
 */

public with sharing class capitec_HoldCashVoucher {

    @TestVisible private static final String BAD_REQUEST_MSG = 'Bad request.';
    @TestVisible private static final String API_ISSUE_MSG = 'Capitec API not working..';

    public class HoldCashVoucherInput {
        @InvocableVariable(Label='CIF' Required=true)
        public String senderId;
        @InvocableVariable(Label='Order Reference' Required=true)
        public String orderReference;
        @InvocableVariable(Label='onHold')
        public String onHold;
    }

    @InvocableMethod(Label='Hold Cash Voucher' Category='Cash Vouchers' Callout=true)
    public static void HoldCashVoucher(List<HoldCashVoucherInput> input) {

        HttpResponse response = Capitec_CalloutHandler.makePOSTCalloutWithBody(
                Capitec_CalloutHandler.HOLD_CASHVOUCHER,
                createBody(input[0].senderId, input[0].orderReference, input[0].onHold));
        if (response.getStatusCode() == 400) {
            throw new HoldCashVoucherException(BAD_REQUEST_MSG);
        }

        if (response.getStatusCode() != 200) {
            throw new HoldCashVoucherException(API_ISSUE_MSG);
        }
    }

    private static String createBody(String senderId, String orderReference, String onHold) {
        RequestBodyWrapper requestBR = new RequestBodyWrapper();
        requestBR.senderId = senderId;
        requestBR.orderReference = orderReference;
        requestBR.onHold = onHold;

        String body =  '{' + '"cifNumber":' +'\"'+ senderId +'\"'+',  "orderReference": ' + '\"'+ orderReference + '\"' + ', "onHold": ' + onHold +'}';

        return body;
    }

    public class RequestBodyWrapper {

        public String senderId {get; set;}
        public String orderReference {get; set;}
        public String onHold {get; set;}
    }

    public class HoldCashVoucherException extends Exception {}

}