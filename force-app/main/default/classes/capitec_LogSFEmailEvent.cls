/**
 * @author: Marinus Jansen van Vuuren
 */

public with sharing class capitec_LogSFEmailEvent {
    @TestVisible private static final String BAD_REQUEST_MSG = 'Bad request.';
    @TestVisible private static final String API_ISSUE_MSG = 'Capitec API not working..';
    public static final String LOG_EMAIL_EVENT = '/client/case-service/case/v1/logEmailEvent';

    public class LogEmailEventInput {
        @InvocableVariable(required=true)
        public String parentId;

        @InvocableVariable(label='Created Date')
        public String createdDate;

        @InvocableVariable(label='To Address')
        public String toAddress;

        @InvocableVariable(label='From Address')
        public String fromAddress;

        @InvocableVariable(label='Subject')
        public String subject;

        @InvocableVariable(label='Text Body')
        public String textBody;

        @InvocableVariable(label='Has Attachment')
        public String hasAttachment;

        @InvocableVariable(label='Created By Id')
        public String createdById;
    }

    @InvocableMethod(label='Log SF Email on Strack Incicident' category='Case' callout=true)
    public static void logEmail(List<LogEmailEventInput> input) {
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();

		request.setTimeout(10000);
        request.setMethod('POST');
        request.setEndpoint('callout:NC_ClientDomain' + LOG_EMAIL_EVENT);
        request.setBody(createBody(input[0].parentId, input[0].createdDate, input[0].toAddress, input[0].fromAddress, input[0].subject, input[0].textBody, input[0].hasAttachment, input[0].createdById));

		HttpResponse response = http.send(request);

        if (response.getStatusCode() == 400) {
            throw new LogEmailEventException(BAD_REQUEST_MSG);
        }

        if (response.getStatusCode() != 204) {
            throw new LogEmailEventException(API_ISSUE_MSG);
        }
    }

    private static String createBody(String parentId, String createdDate, String toAddress, String fromAddress, String subject, String textBody, String hasAttachment, String createdById) {
        
        LogEmailEventWrapper request = new LogEmailEventWrapper();
        
        request.parentId = parentId;
        request.createdDate = createdDate;
        request.toAddress = toAddress;
        request.fromAddress = fromAddress;
        request.subject = subject;
        request.textBody = textBody;
        request.hasAttachment = hasAttachment;
        request.createdById = createdById;
        
        return JSON.serialize(request);
    }

    public class LogEmailEventWrapper {

        public String parentId;
        public String createdDate;
        public String toAddress;
        public String fromAddress;
        public String subject;
        public String textBody;
        public String hasAttachment;
        public String createdById;
    }

    public class LogEmailEventException extends Exception {}
}