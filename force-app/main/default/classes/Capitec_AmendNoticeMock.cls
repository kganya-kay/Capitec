/**
 * @description       : Mock Response class for Amend Notice API [Notice Deposit]
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 05-30-2024
 * @last modified by  : Samiirah.A@bsky.co.za
**/
@isTest
global class Capitec_AmendNoticeMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"noticeDepositInstructions":{"accountNumber":"225083058","noticeDate":"2024-05-30","noticeType":"NORMAL_NOTICE","noticeAmount":100,"quotedFeeAmount":0,"noticeReferenceId":"b274fcd5-3e4c-4fd0-9efc-3c035f6b1177","toAccountNumber":"2174767739","originatingChannel":"NBS"}}');
        res.setStatusCode(200);
        return res;
    }
}