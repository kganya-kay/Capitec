/**
 * Created by CalebGovender on 2023/06/25.
 */
@IsTest
public class capitec_ReleaseCashVoucher_Test {

    @IsTest
    static void ReleaseVoucherNotWorking() {
        Test.setMock(HttpCalloutMock.class, new capitec_HoldVoucherMockResponse());
        String CIF ='281783047';
        String onHold='true';
        String orderReference ='';
        capitec_ReleaseCashVoucher.ReleaseCashVoucherInput input = new capitec_ReleaseCashVoucher.ReleaseCashVoucherInput();
        input.senderId = CIF;
        input.orderReference = orderReference;
        input.onHold = onHold;


        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_ReleaseCashVoucher.ReleaseCashVoucher(new List<capitec_ReleaseCashVoucher.ReleaseCashVoucherInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_ReleaseCashVoucher.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_ReleaseCashVoucher.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, gotError, 'Exception has been throw.');
    }

    @IsTest
    static void ReleaseVoucherWorking() {
        Test.setMock(HttpCalloutMock.class, new capitec_HoldVoucherMockResponse());
        String CIF ='281783047';
        String onHold='true';
        String orderReference ='27623453277';
        capitec_ReleaseCashVoucher.ReleaseCashVoucherInput input = new capitec_ReleaseCashVoucher.ReleaseCashVoucherInput();
        input.orderReference = orderReference;
        input.senderId = CIF;
        input.onHold = onHold;
        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_ReleaseCashVoucher.ReleaseCashVoucher(new List<capitec_ReleaseCashVoucher.ReleaseCashVoucherInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_ReleaseCashVoucher.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_ReleaseCashVoucher.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(false, gotError, 'Exception has not been throw.');
    }
}