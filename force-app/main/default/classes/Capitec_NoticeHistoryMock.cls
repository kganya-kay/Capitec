/**
 * @description       : Mock Response class for Notice Deposit History API
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 30-08-2024
 * @last modified by  : Cornelia Smit- CECSF-376
**/
@isTest
global class Capitec_NoticeHistoryMock implements HttpCalloutMock {
    private Boolean isSuccess; // CECSF-376 - determines success vs failure response
    
    // CECSF-376 - set success/failure
    public Capitec_NoticeHistoryMock(Boolean isSuccess) {
        this.isSuccess = isSuccess;
    }
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        // CECSF-376 - expand mock to include success & failure
        if(isSuccess) {
            res.setBody('{"noticePeriod":32,"noticeDepositInstructions":[{"accountNumber":"2250830580","noticeDate":"2024-05-07","noticeType":"NORMAL_NOTICE","noticeAmount":200,"quotedFeeAmount":0,"noticeReferenceId":"CA8AA553-3003-41F2-9034-5AE487BC966Q","toAccountNumber":"2174767739","originatingChannel":"APP","noticeStatus":"NOTICE_RECEIVED","paymentDate":"2024-06-08"},{"accountNumber":"2250830580","noticeDate":"2024-05-15","noticeType":"NORMAL_NOTICE","noticeAmount":300,"quotedFeeAmount":0,"noticeReferenceId":"aafced8a-0423-4cf6-9331-c46d66b27ef1","toAccountNumber":"2174767739","originatingChannel":"APP","noticeStatus":"NOTICE_RECEIVED","paymentDate":"2024-06-16"},{"accountNumber":"2250830580","noticeDate":"2024-05-16","noticeType":"NORMAL_NOTICE","noticeAmount":50,"quotedFeeAmount":0,"noticeReferenceId":"9bafc632-05dd-4bb8-b074-4b7b8640a666","toAccountNumber":"2174767739","originatingChannel":"APP","noticeStatus":"NOTICE_RECEIVED","paymentDate":"2024-06-17"},{"accountNumber":"2250830580","noticeDate":"2024-05-16","noticeType":"NORMAL_NOTICE","noticeAmount":50,"quotedFeeAmount":0,"noticeReferenceId":"697397c9-6e44-4251-9669-f88a31fdd527","toAccountNumber":"2174767739","originatingChannel":"APP","noticeStatus":"NOTICE_RECEIVED","paymentDate":"2024-06-17"},{"accountNumber":"2250830580","noticeDate":"2024-05-16","noticeType":"NORMAL_NOTICE","noticeAmount":50,"quotedFeeAmount":0,"noticeReferenceId":"3e90c33c-d018-4d2a-a336-86e4653371b1","toAccountNumber":"2174767739","originatingChannel":"APP","noticeStatus":"NOTICE_RECEIVED","paymentDate":"2024-06-17"},{"accountNumber":"2250830580","noticeDate":"2024-05-16","noticeType":"NORMAL_NOTICE","noticeAmount":50,"quotedFeeAmount":0,"noticeReferenceId":"48f721c4-a365-462c-b824-48eef8737f80","toAccountNumber":"2174767739","originatingChannel":"APP","noticeStatus":"NOTICE_RECEIVED","paymentDate":"2024-06-17"},{"accountNumber":"2250830580","noticeDate":"2024-05-22","noticeType":"NORMAL_NOTICE","noticeAmount":50,"quotedFeeAmount":0,"noticeReferenceId":"b7942a8a-13ce-4159-894d-18da434e507e","toAccountNumber":"2174767739","originatingChannel":"APP","noticeStatus":"NOTICE_RECEIVED","paymentDate":"2024-06-23"},{"accountNumber":"2250830580","noticeDate":"2024-05-22","noticeType":"NORMAL_NOTICE","noticeAmount":35.67,"quotedFeeAmount":0,"noticeReferenceId":"7a42874b-b73f-45a8-bbe1-be304a91f70f","toAccountNumber":"2174767739","originatingChannel":"APP","noticeStatus":"NOTICE_RECEIVED","paymentDate":"2024-06-23"},{"accountNumber":"2250830580","noticeDate":"2024-05-23","noticeType":"NORMAL_NOTICE","noticeAmount":150,"quotedFeeAmount":0,"noticeReferenceId":"sales_force_int_testing_6","toAccountNumber":"2174767739","originatingChannel":"NBS","noticeStatus":"NOTICE_RECEIVED","paymentDate":"2024-05-21"},{"accountNumber":"2250830580","noticeDate":"2024-05-23","noticeType":"NORMAL_NOTICE","noticeAmount":110,"quotedFeeAmount":0,"noticeReferenceId":"sales_force_int_testing_7","toAccountNumber":"2174767739","originatingChannel":"NBS","noticeStatus":"NOTICE_RECEIVED","paymentDate":"2024-05-21"},{"accountNumber":"2250830580","noticeDate":"2024-05-23","noticeType":"NORMAL_NOTICE","noticeAmount":90,"quotedFeeAmount":0,"noticeReferenceId":"sales_force_int_testing_8","toAccountNumber":"2174767739","originatingChannel":"NBS","noticeStatus":"NOTICE_RECEIVED","paymentDate":"2024-05-21"}]}');
        	res.setStatusCode(200);
        }
        else {
            res.setBody('{"status":"BAD_REQUEST","message":"DEPENDENCY_SYSTEM_ERROR","source":"NOTICE_DEPOSIT_SERVICE","errors":["INVALID CHECK DIGIT / ACCOUNT NUMBER"]}');
            res.setStatusCode(400);
        }
        return res;
    }
}