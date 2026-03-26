/**
 * Capitec_TrackAndTraceCalloutHandlerTest Class
 *
 * This class is for testing the Capitec_TrackAndTraceCalloutHandler class and its callouts.
 *
 * Created by: Tomasz
 */

 @isTest
public class Capitec_TrackAndTraceCalloutHandlerTest {

    @isTest
    static void testMakeCorebankingTransactionCallout() {
        String accountNumber = '12345';
        String startDate = '2023-01-01';
        String endDate = '2023-12-31';
		
        Test.setMock(HttpCalloutMock.class, new Capitec_TrackAndTraceMock());
        Test.startTest();
        String result = Capitec_TrackAndTraceCalloutHandler.makeCorebankingTransactionCallout(accountNumber, startDate, endDate);
		Test.stopTest();
        System.assertNotEquals(result, null);
        System.assertNotEquals(result, '{"error": "An error has occurred"}');
    }

    @isTest
    static void testMakeATMEventsTransactionCallout() {
        String deviceId = 'TestDevice';
        String startDateTime = '2023-01-01 00:00:00.000';
        String endDateTime = '2023-12-31 23:59:59.999';
		
        Test.setMock(HttpCalloutMock.class, new Capitec_TrackAndTraceMock());
        Test.startTest();
        String result = Capitec_TrackAndTraceCalloutHandler.makeATMEventsTransactionCallout(deviceId, startDateTime, endDateTime);
		Test.stopTest();
        System.assertNotEquals(result, null);
        System.assertNotEquals(result, '{"error": "An error has occurred"}');
    }

    @isTest
    static void testMakeATMEventsDeviceCallout() {
        String deviceId = 'TestDevice';
        String startDateTime = '2023-01-01 00:00:00.000';
        String endDateTime = '2023-12-31 23:59:59.999';
		
        Test.setMock(HttpCalloutMock.class, new Capitec_TrackAndTraceMock());
        Test.startTest();
        String result = Capitec_TrackAndTraceCalloutHandler.makeATMEventsDeviceCallout(deviceId, startDateTime, endDateTime);
		Test.stopTest();
        System.assertNotEquals(result, null);
        System.assertNotEquals(result, '{"error": "An error has occurred"}');
    }

    @isTest
    static void testMakeCardTransactionCallout() {
        String fromAccountNumber = '12345';
        String startDateTime = '2023-01-01 00:00:00.000';
        String endDateTime = '2023-12-31 23:59:59.999';
		
        Test.setMock(HttpCalloutMock.class, new Capitec_TrackAndTraceMock());
        Test.startTest();
        String result = Capitec_TrackAndTraceCalloutHandler.makeCardTransactionCallout(fromAccountNumber, startDateTime, endDateTime);
		Test.stopTest();
        System.assertNotEquals(result, null);
        System.assertNotEquals(result, '{"error": "An error has occurred"}');
    }
}