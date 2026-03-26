/**
 * Created by CalebGovender on 2023/10/04.
 */
@IsTest
public class capitec_BlockChannel_Test {

    @IsTest
    static void ChannelIsBlockedNotWorking() {
        Test.setMock(HttpCalloutMock.class, new capitec_BlockChannelMockResponse());
        String channelType ='USSD';
        String msisdn ='';
        capitec_BlockChannel.BlockChannelInput input = new capitec_BlockChannel.BlockChannelInput();
        input.channelType = channelType;
        input.msisdn = msisdn;


        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_BlockChannel.blockChannel(new List<capitec_BlockChannel.BlockChannelInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_BlockChannel.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_BlockChannel.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, gotError, 'Exception has been throw.');
    }

    @IsTest
    static void ChannelIsBlockedWorking() {
        Test.setMock(HttpCalloutMock.class, new capitec_BlockChannelMockResponse());
        String channelType ='USSD';
        String msisdn ='27623453277';
        capitec_BlockChannel.BlockChannelInput input = new capitec_BlockChannel.BlockChannelInput();
        input.channelType = 'USSD';
        input.msisdn = msisdn;
        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_BlockChannel.blockChannel(new List<capitec_BlockChannel.BlockChannelInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_BlockChannel.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_BlockChannel.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(false, gotError, 'Exception has not been throw.');
    }
}