/**
 * Created by sebastian on 23/05/2023.
 */
@IsTest
public class capitec_BlockAccount_Test {

    @IsTest
    static void accountIsBlocked() {
        Test.setMock(HttpCalloutMock.class, new capitec_BlockAccountMockResponse());
        String accountNumber = '123456789';
        String reason = 'FRAUD';
        capitec_BlockAccount.BlockAccountInput input = new capitec_BlockAccount.BlockAccountInput();
        input.reason = reason;
        input.accountNumber = accountNumber;

        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_BlockAccount.blockAccount(new List<capitec_BlockAccount.BlockAccountInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_BlockAccount.API_ISSUE_MSG) ||
                ex.getMessage().contains(capitec_BlockAccount.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(false, gotError, 'Exception has been throw.');
    }

    @IsTest
    static void accountIsNotBlocked() {
        Test.setMock(HttpCalloutMock.class, new capitec_BlockAccountMockResponse());
        String accountNumber = '123456789';
        String reason = 'error';
        capitec_BlockAccount.BlockAccountInput input = new capitec_BlockAccount.BlockAccountInput();
        input.reason = reason;
        input.accountNumber = accountNumber;

        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_BlockAccount.blockAccount(new List<capitec_BlockAccount.BlockAccountInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_BlockAccount.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_BlockAccount.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, gotError, 'Exception has not been throw.');
    }
}