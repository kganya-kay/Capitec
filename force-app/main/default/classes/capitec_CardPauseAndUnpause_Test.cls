/**
 * Created by CalebGovender on 2023/10/30.
 */
@IsTest
public with sharing class capitec_CardPauseAndUnpause_Test {

    @isTest
    static void testPauseUnpauseCardActive() {

        capitec_CardPauseAndUnpause.TEST_CIF = '1234567890';
        capitec_CardPauseAndUnpause.TEST_CARD = '5644 1234 5678 9012';
        capitec_CardPauseAndUnpause.TEST_CONSULTANT = 'CP1234568';
        capitec_CardPauseAndUnpause.TEST_STATUS = 'ACTIVE';

        capitec_CardPauseAndUnpause.PauseUnPauseCardInput input = new capitec_CardPauseAndUnpause.PauseUnPauseCardInput();
        input.recordID = 'ExternalId123';
        input.channelIdentifier = capitec_CardPauseAndUnpause.TEST_CIF;
        input.cardPan = capitec_CardPauseAndUnpause.TEST_CARD;
        input.consultantIdentifier = capitec_CardPauseAndUnpause.TEST_CONSULTANT;

        Test.setMock(HttpCalloutMock.class, new capitec_CardPauseAndUnpause_MockRepsonse());

        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_CardPauseAndUnpause.PauseUnpauseCard(new List<capitec_CardPauseAndUnpause.PauseUnPauseCardInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_CardPauseAndUnpause.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_CardPauseAndUnpause.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(false, gotError, 'Exception has been throw.');
    }

    @isTest
    static void testPauseUnpauseCardStopped() {

        capitec_CardPauseAndUnpause.TEST_CIF = '1234567890';
        capitec_CardPauseAndUnpause.TEST_CARD = '5644 1234 5678 9012';
        capitec_CardPauseAndUnpause.TEST_CONSULTANT = 'CP1234568';
        capitec_CardPauseAndUnpause.TEST_STATUS = 'STOPPED';

        capitec_CardPauseAndUnpause.PauseUnPauseCardInput input = new capitec_CardPauseAndUnpause.PauseUnPauseCardInput();
        input.recordID = 'ExternalId123';
        input.channelIdentifier = capitec_CardPauseAndUnpause.TEST_CIF;
        input.cardPan = capitec_CardPauseAndUnpause.TEST_CARD;
        input.consultantIdentifier = capitec_CardPauseAndUnpause.TEST_CONSULTANT;

        Test.setMock(HttpCalloutMock.class, new capitec_CardPauseAndUnpause_MockRepsonse());

        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_CardPauseAndUnpause.PauseUnpauseCard(new List<capitec_CardPauseAndUnpause.PauseUnPauseCardInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_CardPauseAndUnpause.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_CardPauseAndUnpause.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(false, gotError, 'Exception has been throw.');
    }

    @isTest
    static void testPauseUnpauseCardException() {

        capitec_CardPauseAndUnpause.TEST_CIF = '1234567890';
        capitec_CardPauseAndUnpause.TEST_CARD = '5644 1234 5678 9012';
        capitec_CardPauseAndUnpause.TEST_CONSULTANT = 'CP1234568';
        capitec_CardPauseAndUnpause.TEST_STATUS = 'BROKEN';

        capitec_CardPauseAndUnpause.PauseUnPauseCardInput input = new capitec_CardPauseAndUnpause.PauseUnPauseCardInput();
        input.recordID = 'ExternalId123';
        input.channelIdentifier = capitec_CardPauseAndUnpause.TEST_CIF;
        input.cardPan = capitec_CardPauseAndUnpause.TEST_CARD;
        input.consultantIdentifier = capitec_CardPauseAndUnpause.TEST_CONSULTANT;

        Test.setMock(HttpCalloutMock.class, new capitec_CardPauseAndUnpause_MockRepsonse());

        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_CardPauseAndUnpause.PauseUnpauseCard(new List<capitec_CardPauseAndUnpause.PauseUnPauseCardInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_CardPauseAndUnpause.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_CardPauseAndUnpause.BAD_REQUEST_MSG) ||
                    ex.getMessage().contains(capitec_CardPauseAndUnpause.CARD_ISSUE)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, gotError, 'Exception has been throw.');
    }

    @isTest
    static void testPauseUnpauseCardNotWorking() {

        capitec_CardPauseAndUnpause.TEST_CIF = '';
        capitec_CardPauseAndUnpause.TEST_CARD = '';
        capitec_CardPauseAndUnpause.TEST_CONSULTANT = '';
        capitec_CardPauseAndUnpause.TEST_STATUS = 'ACTIVE';

        capitec_CardPauseAndUnpause.PauseUnPauseCardInput input = new capitec_CardPauseAndUnpause.PauseUnPauseCardInput();
        input.recordID = 'ExternalId123';
        input.channelIdentifier = capitec_CardPauseAndUnpause.TEST_CIF;
        input.cardPan = capitec_CardPauseAndUnpause.TEST_CARD;
        input.consultantIdentifier = capitec_CardPauseAndUnpause.TEST_CONSULTANT;

        Test.setMock(HttpCalloutMock.class, new capitec_CardPauseAndUnpause_MockRepsonse());

        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_CardPauseAndUnpause.PauseUnpauseCard(new List<capitec_CardPauseAndUnpause.PauseUnPauseCardInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_CardPauseAndUnpause.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_CardPauseAndUnpause.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, gotError, 'Exception has been throw.');
    }

}