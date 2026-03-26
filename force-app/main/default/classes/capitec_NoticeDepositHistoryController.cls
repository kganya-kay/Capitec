/**
 * @description       : Apex controller for capitec_NoticeDepositsHistory LWC
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 30-08-2024
 * @last modified by  : Cornelia Smit - CECSF-376
**/

public with sharing class capitec_NoticeDepositHistoryController {
    private static final String NOTICE_HISTORY_ENDPOINT = '/save/notice-deposit-service/api/v1/notice-deposit/notice-history';
    private static final String NOTICE_UPDATE_ENDPOINT = '/save/notice-deposit-service/api/v1/notice-deposit/notice-withdrawal/amend';
    private static final String namedCredential = 'NC_SaveDomain';
    private static final String noticeHistoryType = 'ALL';
    private static final Integer MAX_TIMEOUT_VAL = 120000;

    @AuraEnabled(Cacheable=false)
    public static String noticeHistoryCallout(String accNumber, String accCIFKey) {
        String endpoint = 'callout:' + namedCredential + NOTICE_HISTORY_ENDPOINT + '?noticeHistoryType=' + EncodingUtil.urlEncode(noticeHistoryType, 'UTF-8');

        // Create the HTTP request
        HttpRequest request = new HttpRequest();

        request.setMethod('POST');
        request.setEndpoint(endpoint);
        request.setTimeout(MAX_TIMEOUT_VAL);
        request.setHeader('Content-Type', 'application/json'); // Set content type header
        request.setBody(JSON.serialize((new historyReqWrapper(accNumber, accCIFKey))));


        // Send the HTTP request
        Http http = new Http();
        //CECSF-376: Add error handling and return error messages from response
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                return response.getBody();
            } else {
                return parseErrorResponse(response);
            }
        } catch (Exception ex) {
            return 'Error: ' + ex.getMessage();

        }
    }

    @AuraEnabled(Cacheable=true)
    public static Map<String, String> getNoticeStatusMapping() {
        Map<String, String> mapNoticeStatus = new Map<String, String>();

        for (ND_NoticeStatusmapping__mdt mapping : [SELECT SF_Status__c, noticeStatus__c FROM ND_NoticeStatusmapping__mdt]) {
            mapNoticeStatus.put(mapping.noticeStatus__c, mapping.SF_Status__c);
        }

        return mapNoticeStatus;
    }

    @AuraEnabled(Cacheable=false)
    public static String updateNoticeCallout(String accNumber, String accCIFKey, String noticeRefId) {

        String endpoint = 'callout:' + namedCredential + NOTICE_UPDATE_ENDPOINT;

        // Create the HTTP request
        HttpRequest request = new HttpRequest();

        request.setMethod('POST');
        request.setEndpoint(endpoint);
        request.setTimeout(MAX_TIMEOUT_VAL);
        request.setHeader('Content-Type', 'application/json; charset=UTF-8');
        request.setBody(JSON.serialize((new amendReqWrapper(accNumber, accCIFKey, noticeRefId))));


        // Send the HTTP request
        //CECSF-376: Add error handling
        try {
            Http http = new Http();
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                return response.getBody();
            } else {
                return null;
            }
        } catch (Exception ex) {
            return 'Error: ' + ex.getMessage();
        }
    }

    @AuraEnabled(Cacheable=false)
    public static String updateCaseOutcome(String caseId, String status) {
        Case caseObj = new Case();
        caseObj.Id = caseId;
        caseObj.Outcome__c = status;

        try {
            //CECSF-201 - update error handling for database operation
            Database.SaveResult result = Database.update(caseObj, false);
            if (!result.isSuccess()) {
                return result.getErrors()[0].getMessage();
            }
            return 'Success';
        } catch (Exception ex) {
            return 'Exception: ' + ex.getMessage();
        }
    }

    @AuraEnabled(Cacheable=false)
    public static String updateCase(Case caseObj) {
        String errorMessage;
        try {
            Database.SaveResult result = Database.update(caseObj, false);
            if (result.isSuccess()) {
                return 'Success';
            } else {
                for (Database.Error error : result.getErrors()) {
                    errorMessage = error.getMessage();
                }
                return errorMessage;
            }
        } catch (Exception ex) {
            return 'Exception: ' + ex;
        }
    }
    //CECSF-376: Extract error messages from response
    private static String parseErrorResponse(HttpResponse response) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        String errorResult = 'Error: Status code ' + response.getStatusCode() + '; ';
        if (responseMap.containsKey('errors')) {
            List<Object> errors = (List<Object>) responseMap.get('errors');
            List<String> errorMessages = new List<String>();

            for (Object error : errors) {
                errorMessages.add(String.valueOf(error));
            }
            return errorResult + String.join(errorMessages, ', ') + '.';
        }
        return errorResult + 'An unknown error occurred.';
    }

    //wrapper for History callout
    public class historyReqWrapper {
        @AuraEnabled
        public String accountNumber;
        @AuraEnabled
        public String cifNo;

        public historyReqWrapper(String sfAccNumber, String sfCIF) {
            accountNumber = sfAccNumber;
            cifNo = sfCIF;
        }
    }

    //wrapper for Update callout
    public class amendReqWrapper {
        @AuraEnabled
        public String accountNumber;
        @AuraEnabled
        public String cifNo;
        @AuraEnabled
        public String noticeReferenceId;

        public amendReqWrapper(String sfAccNumber, String sfCIF, String noticeId) {
            accountNumber = sfAccNumber;
            cifNo = sfCIF;
            noticeReferenceId = noticeId;
        }
    }
}