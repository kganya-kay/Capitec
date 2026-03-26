/**
 * @description       : Class for notifying client about case status update
 * @author            : Vignesh S
 * @last modified by  : Vignesh S
**/

public with sharing class Capitec_CommsController {

    public static final String CLIENT_COMMS_NOTIFY = '/clientcomms/notification-service/notification/v1/notify';

    @TestVisible private static final String BAD_REQUEST_MSG = 'Bad request.';
    @TestVisible private static final String API_ISSUE_MSG = 'Client comms domain is unavailable';

    /**
     * @description       : Input class for the notify case status update invocable method
     * @author            : Vignesh S
    **/
    public class NotifyCaseStatusUpdateRequest {
        @InvocableVariable(required=true)
        public Case updatedCase;
        @InvocableVariable(Label='Source System')
        public String sourceSystem;
        @InvocableVariable(Label='Template ID')
        public String templateID;
        @InvocableVariable(Label='Channel')
        public String channel;
        @InvocableVariable(Label='Template Parameters')
        public List<String> templateParams;
    }

    /**
    * @description       : Invocable method to notify client for case status update
    * @author            : Vignesh S
    **/
    @InvocableMethod(Label='Notify case status update' Category='Case' Callout=true)
    public static void NotifyCaseStatusUpdate(List<NotifyCaseStatusUpdateRequest> request) {
        Http http = new Http();
        HttpRequest httpReq = new HttpRequest();

        string requestBody = formatNotifyCaseStatusRequest(request[0].updatedCase,
                request[0].sourceSystem,
                request[0].templateID,
                request[0].channel,
                request[0].templateParams);
        httpReq.setTimeout(20000);
        httpReq.setMethod('POST');
        httpReq.setEndpoint('callout:NC_ClientCommsDomain' + CLIENT_COMMS_NOTIFY);
        httpReq.setBody(requestBody);

        System.debug('REQUEST ENDPOINT: ' + httpReq.getEndpoint());
        System.debug(requestBody);
        try {
            HttpResponse response = http.send(httpReq);

            System.debug('RESPONSE BODY: ' + response.getBody());
            if (response.getStatusCode() == 400) {
                throw new ClientCommsException(BAD_REQUEST_MSG);
            }

            if (response.getStatusCode() != 200) {
                throw new ClientCommsException(API_ISSUE_MSG);
            }
        }
        catch(exception ex) {
            throw new ClientCommsException(API_ISSUE_MSG);
        }
    }

    /**
    * @description       : Creates the request body for notify client callout request
    * @author            : Vignesh S
    **/
    private static string formatNotifyCaseStatusRequest(Case cs, string sourceSystem, string templateID, string channel, List<String> tempParams) {

        Case thisCase = [SELECT Id, Account.CIF_Number__c, Account.Phone FROM Case WHERE Id = :cs.Id LIMIT 1];
        Account acc = thisCase.Account;

        NotifyStatusChangeWrapper request = new NotifyStatusChangeWrapper();

        request.entityId = '';
        request.templateID = templateID;
        request.campaignName = '';
        request.skill = '';
        request.cifNumber = acc.CIF_Number__c;
        request.deliveryChannel = DeliveryChannel.valueOf(channel);
        request.sourceSystem = sourceSystem;
        request.templateParameters = tempParams;
        request.outboundNumber = '';
        request.expires = '';
        request.clientcellNumber = acc.Phone;

        return JSON.serialize(request);
    }

    /**
    * @description       : Wrapper class for the notify client callout request body
    * @author            : Caleb Govender
    **/
    public class NotifyStatusChangeWrapper {

        public String entityId;
        public String templateID;
        public String campaignName;
        public String skill;
        public String cifNumber;
        public String clientcellNumber;
        public String outboundNumber;
        public DeliveryChannel deliveryChannel;
        public String[] templateParameters;
        public String expires;
        public String sourceSystem;
    }

    public enum DeliveryChannel {NotSpecified, InAppMailbox, InApp, Sms, Whatsapp}

    public class ClientCommsException extends Exception {}
}