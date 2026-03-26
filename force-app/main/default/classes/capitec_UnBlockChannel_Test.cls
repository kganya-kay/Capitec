@IsTest
public class capitec_UnBlockChannel_Test {

    @IsTest
    static void ChannelIsBlockedNotWorking() {
        Test.setMock(HttpCalloutMock.class, new capitec_UnBlockChannelMockResponse());
        String channelType ='USSD';
        String channelIdentifier ='281783047';
        String msisdn ='';
        capitec_UnBlockChannel.UnBlockChannelInput input = new capitec_UnBlockChannel.UnBlockChannelInput();
        input.channelType = channelType;
        input.channelIdentifier = channelIdentifier;
        input.msisdn = msisdn;


        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_UnBlockChannel.UnblockChannel(new List<capitec_UnBlockChannel.UnBlockChannelInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_UnBlockChannel.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_UnBlockChannel.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, gotError, 'Exception has been throw.');
    }

    @IsTest
    static void ChannelIsBlockedWorking() {
        Test.setMock(HttpCalloutMock.class, new capitec_UnBlockChannelMockResponse());
        String channelIdentifier ='281783047';
        String channelType ='USSD';
        String msisdn ='27623453277';
        capitec_UnBlockChannel.UnBlockChannelInput input = new capitec_UnBlockChannel.UnBlockChannelInput();
        input.channelIdentifier = channelIdentifier;
        input.channelType = 'USSD';
        input.msisdn = msisdn;
        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_UnBlockChannel.UnblockChannel(new List<capitec_UnBlockChannel.UnBlockChannelInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_UnBlockChannel.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_UnBlockChannel.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(false, gotError, 'Exception has not been throw.');
    }
}