/**
 * Created by CalebGovender on 2023/06/23.
 */
@IsTest
public class capitec_HoldCashVoucher_Test {

    @IsTest
    static void HoldVoucherNotWorking() {
        Test.setMock(HttpCalloutMock.class, new capitec_HoldVoucherMockResponse());
        String CIF ='281783047';
        String onHold='true';
        String orderReference ='';
        capitec_HoldCashVoucher.HoldCashVoucherInput input = new capitec_HoldCashVoucher.HoldCashVoucherInput();
        input.senderId = CIF;
        input.orderReference = orderReference;
        input.onHold = onHold;


        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_HoldCashVoucher.HoldCashVoucher(new List<capitec_HoldCashVoucher.HoldCashVoucherInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_HoldCashVoucher.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_HoldCashVoucher.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, gotError, 'Exception has been throw.');
    }

    @IsTest
    static void HoldVoucherWorking() {
        Test.setMock(HttpCalloutMock.class, new capitec_HoldVoucherMockResponse());
        String CIF ='281783047';
        String onHold='true';
        String orderReference ='27623453277';
        capitec_HoldCashVoucher.HoldCashVoucherInput input = new capitec_HoldCashVoucher.HoldCashVoucherInput();
        input.orderReference = orderReference;
        input.senderId = CIF;
        input.onHold = onHold;
        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_HoldCashVoucher.HoldCashVoucher(new List<capitec_HoldCashVoucher.HoldCashVoucherInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_HoldCashVoucher.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_HoldCashVoucher.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(false, gotError, 'Exception has not been throw.');
    }
}