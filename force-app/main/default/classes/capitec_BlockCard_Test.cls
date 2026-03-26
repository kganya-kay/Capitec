/**
 * Created by CalebGovender on 2023/10/09.
 */
@IsTest
public with sharing class capitec_BlockCard_Test {

    @IsTest
    static void CardBlockingNotWorking() {
        capitec_BlockCard.TEST_CIF = '';
        capitec_BlockCard.TEST_CARD = '';
        capitec_BlockCard.TEST_CONSULTANT = '';

        capitec_BlockCard.BlockCardInput input = new capitec_BlockCard.BlockCardInput();
        input.recordID = 'ExternalId123';
        input.channelIdentifier = capitec_BlockCard.TEST_CIF;
        input.cardPan = capitec_BlockCard.TEST_CARD;
        input.consultantIdentifier = capitec_BlockCard.TEST_CONSULTANT;
        input.ABUEnabled = 'true';

        Test.setMock(HttpCalloutMock.class, new capitec_BlockCardMockResponse());

        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_BlockCard.BlockCard(new List<capitec_BlockCard.BlockCardInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_BlockCard.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_BlockCard.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, gotError, 'Exception has been throw.');
    }

    @IsTest
    static void CardBlockingWorking() {
        capitec_BlockCard.TEST_CIF = '1234567890';
        capitec_BlockCard.TEST_CARD = '5644 1234 5678 9012';
        capitec_BlockCard.TEST_CONSULTANT = 'CP1234568';

        capitec_BlockCard.BlockCardInput input = new capitec_BlockCard.BlockCardInput();
        input.recordID = 'ExternalId123';
        input.channelIdentifier = capitec_BlockCard.TEST_CIF;
        input.cardPan = capitec_BlockCard.TEST_CARD;
        input.consultantIdentifier = capitec_BlockCard.TEST_CONSULTANT;
        input.ABUEnabled = 'true';

        Test.setMock(HttpCalloutMock.class, new capitec_BlockCardMockResponse());

        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_BlockCard.BlockCard(new List<capitec_BlockCard.BlockCardInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_BlockCard.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_BlockCard.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(false, gotError, 'Exception has been throw.');
    }
}