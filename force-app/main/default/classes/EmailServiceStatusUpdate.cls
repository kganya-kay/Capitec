/**
 * @name EmailServiceStatusUpdate
 * @description
 * Restful Apex service to receive email status updates from an external system and update the associated EmailMessage record.
 *
 * This class exposes a POST endpoint that accepts a JSON payload containing status metadata and applies it to the matching EmailMessage record.
 *
 * Expected JSON payload structure:
 * - emailMessageId (required)
 * - statusCode (optional)
 * - status (optional)
 * - correlationId (optional)
 * - error (optional)
 *
 * If the update is successful, a response with status code 200 is returned.
 * If the emailMessageId is missing, a 400 error is returned.
 * Any unexpected exceptions result in a 500 error response.
 *
 * @url /services/apexrest/emailService/statusUpdate/*
 */
@RestResource(UrlMapping='/emailService/statusUpdate/*')
global with sharing class EmailServiceStatusUpdate {

    /**
     * Error message returned when the required emailMessageId field is missing from the incoming payload.
     */
    private static final String MSG_MISSING_ID = 'Missing emailMessageId.';

    /**
     * HTTP status code 200: Indicates a successful request.
     */
    private static final Integer HTTP_OK = 200;

    /**
     * HTTP status code 400: Indicates a client error due to missing or invalid input (e.g., no emailMessageId).
     */
    private static final Integer HTTP_BAD_REQUEST = 400;

    /**
     * HTTP status code 500: Indicates a server error due to an unhandled exception during processing.
     */
    private static final Integer HTTP_SERVER_ERROR = 500;

    /**
     * @name updateStatus
     * @description
     * Handles incoming POST requests to update the status of an EmailMessage.
     *
     * Deserializes the request body, validates the input, and applies the provided metadata
     * to the EmailMessage record. This includes updating fields like:
     * - Status_Code__c
     * - Email_Service_Status__c
     * - Correlation_Id__c
     * - Error_Message__c
     *
     * Responds with a serialized EmailServiceStatusUpdateResponseWrapper indicating the result.
     *
     * @method POST
     * @endpoint /emailService/statusUpdate
     */
    @HttpPost
    global static void updateStatus() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            EmailServiceStatusUpdateWrapper body = (EmailServiceStatusUpdateWrapper) JSON.deserialize(
                    req.requestBody.toString(),
                    EmailServiceStatusUpdateWrapper.class
            );

            if (String.isBlank(body.emailMessageId)) {
                res.statusCode = HTTP_BAD_REQUEST;

                EmailServiceStatusUpdateResponseWrapper response = new EmailServiceStatusUpdateResponseWrapper(
                        null,
                        res.statusCode,
                        body.correlationId,
                        MSG_MISSING_ID
                );

                res.responseBody = Blob.valueOf(JSON.serialize(response));
                return;
            }

            EmailMessage email = [
                    SELECT
                            Id,
                            Status_Code__c,
                            Email_Service_Status__c,
                            Correlation_Id__c,
                            Error_Message__c
                    FROM EmailMessage
                    WHERE Id = :body.emailMessageId
            ];

            email.Status_Code__c = body.statusCode;
            email.Email_Service_Status__c = body.status;
            email.Correlation_Id__c = body.correlationId;
            email.Error_Message__c = body.error;

            update email;

            res.statusCode = HTTP_OK;

            EmailServiceStatusUpdateResponseWrapper response = new EmailServiceStatusUpdateResponseWrapper(
                    body.emailMessageId,
                    res.statusCode,
                    body.correlationId,
                    null
            );

            res.responseBody = Blob.valueOf(JSON.serialize(response));
        } catch (Exception ex) {
            res.statusCode = HTTP_SERVER_ERROR;

            EmailServiceStatusUpdateResponseWrapper response = new EmailServiceStatusUpdateResponseWrapper(
                    null,
                    res.statusCode,
                    null,
                    ex.getMessage()
            );

            res.responseBody = Blob.valueOf(JSON.serialize(response));
        }
    }

    /**
     * @name EmailServiceStatusUpdateWrapper
     * @description
     * Request wrapper class for deserializing the status update payload.
     *
     * Used internally to map the incoming JSON request body to Apex fields.
     */
    global class EmailServiceStatusUpdateWrapper {
        /**
         * @description Required. The ID of the EmailMessage to update.
         */
        public String emailMessageId;

        /**
         * @description Optional. Numeric status code to be stored in the EmailMessage.Status_Code__c field.
         */
        public Integer statusCode;

        /**
         * @description Optional. Status string (e.g., 'Delivered', 'Failed') to be stored in EmailMessage.Email_Service_Status__c.
         */
        public String status;

        /**
         * @description Optional. Correlation ID for tracking and auditing, stored in EmailMessage.Correlation_Id__c.
         */
        public String correlationId;

        /**
         * @description Optional. Error details to be saved in EmailMessage.Error_Message__c.
         */
        public String error;
    }

    /**
     * @name EmailServiceStatusUpdateResponseWrapper
     * @description
     * Response wrapper class for serializing the API response payload.
     *
     * Returned in all responses to provide context about the operation's outcome.
     */
    global class EmailServiceStatusUpdateResponseWrapper {
        /**
         * @description The ID of the updated EmailMessage record. Null if not found or failed.
         */
        public String emailMessageId;

        /**
         * @description The HTTP-like status code of the operation (200, 400, 500).
         */
        public Integer statusCode;

        /**
         * @description The correlation ID from the original request, if provided.
         */
        public String correlationId;

        /**
         * @description Error message if the operation failed. Null on success.
         */
        public String error;

        /**
         * @description Constructs the response wrapper with required values.
         * @param emailMessageId ID of the EmailMessage (can be null)
         * @param statusCode HTTP status code indicating the result
         * @param correlationId Optional correlation ID
         * @param error Optional error message (null for success)
         */
        global EmailServiceStatusUpdateResponseWrapper(
                String emailMessageId,
                Integer statusCode,
                String correlationId,
                String error
        ) {
            this.emailMessageId = emailMessageId;
            this.statusCode = statusCode;
            this.correlationId = correlationId;
            this.error = error;
        }
    }
}