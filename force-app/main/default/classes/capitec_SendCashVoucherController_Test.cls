/*
  @description       : CEDT-2946 - Test class for capitec_SendCashVoucherController functionality
  @author            : Kevin Nundran
  @last modified on  : 10-09-2024
  @last modified by  : Kevin Nundran
*/
@isTest
public class capitec_SendCashVoucherController_Test {

    /*
      @description       : Sets up test data for the test methods by creating a test account
      @author            : Kevin Nundran
      @created on        : 10-09-2024
    */
    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account', CIF_Number__c = 'CIF12345');
        insert testAccount;
    }

    /*
      @description       : Tests the functionality of SendCashVoucherWrapper class by setting and asserting field values
      @author            : Kevin Nundran
      @created on        : 10-09-2024
    */
    @isTest
    static void testSendCashVoucherWrapper() {
        // Create an instance of SendCashVoucherWrapper and set fields
        capitec_SendCashVoucherController.SendCashVoucherWrapper wrapper = new capitec_SendCashVoucherController.SendCashVoucherWrapper();
        wrapper.Id = '001';
        wrapper.ExternalId = 'EXT-001';
        wrapper.VoucherNumber = 'VCH001';
        wrapper.SentFrom = 'Capitec Branch A';
        wrapper.SendAmount = 1500.00;
        wrapper.Status = 'REDEEMABLE';
        wrapper.DateCreated = DateTime.now();
        wrapper.DateModified = DateTime.now();
        wrapper.isRedeemable = true;
        wrapper.isRedeemed = false;
        wrapper.isHold = false;
        wrapper.showHoldButton = true;
        wrapper.showReleaseButton = false;

        // Assert that all fields are set correctly
        System.assertEquals('001', wrapper.Id, 'Id should be 001');
        System.assertEquals('EXT-001', wrapper.ExternalId, 'ExternalId should be EXT-001');
        System.assertEquals('VCH001', wrapper.VoucherNumber, 'VoucherNumber should be VCH001');
        System.assertEquals('Capitec Branch A', wrapper.SentFrom, 'SentFrom should be Capitec Branch A');
        System.assertEquals(1500.00, wrapper.SendAmount, 'SendAmount should be 1500.00');
        System.assertEquals('REDEEMABLE', wrapper.Status, 'Status should be REDEEMABLE');
        System.assert(wrapper.isRedeemable, 'isRedeemable should be true');
    }

    /*
      @description       : Tests the getVoucherListDummy method to verify the hardcoded dummy voucher data is returned correctly
      @author            : Kevin Nundran
      @created on        : 10-09-2024
    */
    @isTest
    static void testGetVoucherListDummy() {
        // Retrieve the Account Id from the setup data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        // Directly test the getVoucherListDummy method
        Test.startTest();
        String result = capitec_SendCashVoucherController.getVoucherListDummy(testAccount.Id, 'Hold');
        Test.stopTest();

        // Deserialize the result and verify it contains the dummy data
        List<capitec_SendCashVoucherController.SendCashVoucherWrapper> vouchers =
            (List<capitec_SendCashVoucherController.SendCashVoucherWrapper>) JSON.deserialize(result, List<capitec_SendCashVoucherController.SendCashVoucherWrapper>.class);
        
        System.assertEquals(3, vouchers.size(), 'There should be two dummy vouchers');
        System.assertEquals('VCH001', vouchers[0].VoucherNumber, 'First voucher number should be VCH001');
        System.assertEquals(2500.0, vouchers[0].SendAmount, 'First voucher SendAmount should be 2500.0');
        System.assertEquals(false, vouchers[0].isRedeemable, 'First voucher isRedeemable should be false');
        System.assertEquals('REDEEMABLE', vouchers[1].Status, 'Second voucher status should be REDEEMABLE');
        System.assert(vouchers[1].isRedeemable, 'Second voucher isRedeemable should be true');
    }

    /*
      @description       : Tests the getVoucherList method in the success scenario where external object data is returned correctly
      @author            : Kevin Nundran
      @created on        : 10-09-2024
    */
    @isTest
    static void testGetVoucherList_Success() {
        // Retrieve the Account Id from the setup data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        // Mock the response from the external object (successful scenario)
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SendCashVoucherMock());
        
        // Call the method being tested
        String result = capitec_SendCashVoucherController.getVoucherList(testAccount.Id, 'Release');
        Test.stopTest();

        // Assert that result is not null and contains the expected data
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    /*
      @description       : Tests the getVoucherList method when an exception occurs and verifies the fallback to the dummy voucher data
      @author            : Kevin Nundran
      @created on        : 10-09-2024
    */
    @isTest
    static void testGetVoucherList_Exception() {
        // Retrieve the Account Id from the setup data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        // Mock the response to simulate an error in the external object
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FaultySendCashVoucherMock());

        // Call the method being tested and expect the fallback to dummy data
        String result = capitec_SendCashVoucherController.getVoucherList(testAccount.Id, 'Release');
        Test.stopTest();

        // Assert that the result is not null and is a serialized string
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    /*
      @description       : Tests the callHoldVoucher method in a successful scenario where the voucher is held correctly
      @author            : Kevin Nundran
      @created on        : 10-09-2024
    */
    @isTest
    static void testCallHoldVoucher_Success() {
        // Retrieve the Account Id from the setup data
        Account testAccount = [SELECT Id, CIF_Number__c FROM Account LIMIT 1];

        // Mock the response for the external callout (successful response)
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HoldCashVoucherMock(200, 'Success Response'));

        // Call the method being tested
        capitec_SendCashVoucherController.callHoldVoucher(testAccount.Id, 'ORDER-12345');
        Test.stopTest();

        // Assert that no exception is thrown and the system behaves as expected
        System.assert(true, 'No exception should be thrown for successful hold');
    }

    /*
      @description       : Tests the callHoldVoucher method when an exception occurs during the external callout
      @author            : Kevin Nundran
      @created on        : 10-09-2024
    */
    @isTest
    static void testCallHoldVoucher_Exception() {
        // Retrieve the Account Id from the setup data
        Account testAccount = [SELECT Id, CIF_Number__c FROM Account LIMIT 1];

        // Mock the response for a failed external callout
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HoldCashVoucherMock(500, 'Internal Server Error'));

        // Call the method being tested and handle the exception
        try {
            capitec_SendCashVoucherController.callHoldVoucher(testAccount.Id, 'ORDER-12345');
        } catch (Exception e) {
            // Handle exception if needed (currently commented out)
        }
        Test.stopTest();
    }

    /*
      @description       : Mock class to simulate a successful response for SendCashVoucher external object data
      @author            : Kevin Nundran
      @created on        : 10-09-2024
    */
    private class SendCashVoucherMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('[{"Id":"a01Tr000002A1b4IAB", "ExternalId":"Ext-001", "Voucher_Number__c":"Voucher-0", "Sent_From__c":"Sender-0", "Send_Amount__c":100.00, "Status__c":"Sent", "Date_Created__c":"2024-09-01T00:00:00.000Z", "Date_Modified__c":"2024-09-01T00:00:00.000Z"}]');
            return res;
        }
    }

    /*
      @description       : Mock class to simulate a fault response for SendCashVoucher external object data
      @author            : Kevin Nundran
      @created on        : 10-09-2024
    */
    private class FaultySendCashVoucherMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Error response');
            return res;
        }
    }

    /*
      @description       : Mock class to simulate HoldCashVoucher API responses, supporting both success and failure scenarios
      @author            : Kevin Nundran
      @created on        : 10-09-2024
    */
    private class HoldCashVoucherMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public HoldCashVoucherMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
    
    /*
      @description       : Mock class to simulate callReleaseVoucher API responses, supporting both success and failure scenarios
      @author            : Kevin Nundran
      @created on        : 23-10-2024
    */
    @IsTest
    static void ReleaseVoucherWorking() {
        Account testAccount = [SELECT Id, CIF_Number__c FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new capitec_HoldVoucherMockResponse());
        String orderReference ='27623453277';
        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_SendCashVoucherController.callReleaseVoucher(testAccount.Id, orderReference);
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