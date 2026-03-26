/**
 * Created by CalebGovender on 2023/06/23.
 */
public with sharing class capitec_ReleaseCashVoucher {

    @TestVisible private static final String BAD_REQUEST_MSG = 'Bad request.';
    @TestVisible private static final String API_ISSUE_MSG = 'Capitec API not working..';

    public class ReleaseCashVoucherInput {
        @InvocableVariable(Label='CIF' Required=true)
        public String senderId;
        @InvocableVariable(Label='Order Reference' Required=true)
        public String orderReference;
        @InvocableVariable(Label='onHold')
        public String onHold;
    }

    @InvocableMethod(Label='Realese Cash Voucher' Category='Cash Vouchers' Callout=true)
    public static void ReleaseCashVoucher(List<ReleaseCashVoucherInput> input) {

        HttpResponse response = Capitec_CalloutHandler.makePOSTCalloutWithBody(
                Capitec_CalloutHandler.HOLD_CASHVOUCHER,
                createBody(input[0].senderId, input[0].orderReference, input[0].onHold));
        if (response.getStatusCode() == 400) {
            throw new ReleaseCashVoucherException(BAD_REQUEST_MSG);
        }

        if (response.getStatusCode() != 200) {
            throw new ReleaseCashVoucherException(API_ISSUE_MSG);
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

    public class ReleaseCashVoucherException extends Exception {}

}