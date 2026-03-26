/**
 * @description  Handles OCR extraction retries for the Debit Order Details step.
 *               The LWC calls this method up to 3 times when no debit orders are
 *               returned from the initial extraction attempt.
 *
 *               In the current phase this is a placeholder – the actual OCR API
 *               callout will be wired in during the integration phase.
 *
 * @author       Capitec Conversions Team
 * @version      1.0
 */
public with sharing class CapitecOcrRetryHandler {

    // =========================================================================
    // PUBLIC AURA-ENABLED METHODS
    // =========================================================================

    /**
     * @description  Attempts (or re-attempts) OCR extraction on the files that
     *               were uploaded in Step 3 of the manual case creation wizard.
     *
     *               The LWC enforces a maximum of 3 retry attempts on the client
     *               side. This method is invoked each time the agent clicks
     *               "Retry OCR" in Step 4.
     *
     * @param  fileIds  JSON array of file IDs (internal component IDs generated
     *                  by the LWC, e.g. ["file_1711234567_0", "file_1711234567_1"]).
     *                  In the integration phase these will be replaced with
     *                  ContentDocumentId values.
     *
     * @return          List of DebitOrderWrapper objects parsed from the OCR
     *                  response. Returns an empty list if OCR finds nothing.
     */
    @AuraEnabled
    public static List<CapitecManualCaseCreationWrapper.DebitOrderWrapper> retryOcrExtraction(
        String fileIds
    ) {
        if (String.isBlank(fileIds)) {
            throw new AuraHandledException(
                'File IDs are required to attempt OCR extraction.'
            );
        }

        List<CapitecManualCaseCreationWrapper.DebitOrderWrapper> results =
            new List<CapitecManualCaseCreationWrapper.DebitOrderWrapper>();

        try {
            /*
             * ─── TODO – OCR API Integration ──────────────────────────────────
             *
             * Step 1 – Deserialise the file ID list:
             *   List<String> idList = (List<String>)
             *       JSON.deserialize(fileIds, List<String>.class);
             *
             * Step 2 – For each ContentDocument, retrieve the VersionData blob:
             *   List<ContentVersion> versions = [
             *       SELECT Id, VersionData, Title, ContentDocumentId
             *       FROM ContentVersion
             *       WHERE ContentDocumentId IN :idList
             *       AND IsLatest = true
             *       WITH SECURITY_ENFORCED
             *   ];
             *
             * Step 3 – POST each file to the OCR endpoint:
             *   for (ContentVersion cv : versions) {
             *       HttpRequest req = new HttpRequest();
             *       req.setEndpoint('callout:CapitecOcrAPI/v1/extract');
             *       req.setMethod('POST');
             *       req.setHeader('Content-Type', 'application/json');
             *       req.setBody(JSON.serialize(new Map<String, String>{
             *           'fileName'    => cv.Title,
             *           'base64Data'  => EncodingUtil.base64Encode(cv.VersionData)
             *       }));
             *       req.setTimeout(60000);
             *
             *       HttpResponse res = new Http().send(req);
             *
             *       if (res.getStatusCode() == 200) {
             *           List<CapitecManualCaseCreationWrapper.DebitOrderWrapper> parsed =
             *               parseOcrResponse(res.getBody());
             *           results.addAll(parsed);
             *       }
             *   }
             * ──────────────────────────────────────────────────────────────────
             */

            // Placeholder log for development phase
            System.debug(LoggingLevel.INFO,
                'CapitecOcrRetryHandler.retryOcrExtraction – invoked for fileIds: ' + fileIds);

            // Return empty list until OCR API is integrated
            return results;

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException(
                'OCR extraction failed unexpectedly: ' + e.getMessage()
            );
        }
    }

    // =========================================================================
    // PRIVATE HELPERS
    // =========================================================================

    /**
     * @description  Parses the JSON response from the OCR API into a list of
     *               DebitOrderWrapper objects. To be fully implemented during
     *               the integration phase once the OCR response schema is known.
     *
     * @param  responseBody  Raw JSON string from the OCR API.
     * @return               List of parsed DebitOrderWrapper objects.
     */
    @TestVisible
    private static List<CapitecManualCaseCreationWrapper.DebitOrderWrapper> parseOcrResponse(
        String responseBody
    ) {
        List<CapitecManualCaseCreationWrapper.DebitOrderWrapper> parsed =
            new List<CapitecManualCaseCreationWrapper.DebitOrderWrapper>();

        if (String.isBlank(responseBody)) {
            return parsed;
        }

        try {
            /*
             * Expected OCR response schema (adjust to match actual API contract):
             * {
             *   "debitOrders": [
             *     {
             *       "referenceNumber" : "OM12345678",
             *       "name"            : "Mr Price",
             *       "date"            : "2026-04-25",
             *       "amount"          : 250.00,
             *       "category"        : "Future Dated"
             *     }
             *   ]
             * }
             */
            Map<String, Object> responseMap =
                (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            List<Object> orders = (List<Object>) responseMap.get('debitOrders');
            if (orders == null) return parsed;

            for (Object orderObj : orders) {
                Map<String, Object> orderMap = (Map<String, Object>) orderObj;

                CapitecManualCaseCreationWrapper.DebitOrderWrapper dw =
                    new CapitecManualCaseCreationWrapper.DebitOrderWrapper();

                dw.doReferenceNumber = (String)  orderMap.get('referenceNumber');
                dw.doiName           = (String)  orderMap.get('name');
                dw.debitOrderDate    = (String)  orderMap.get('date');
                dw.amount            = (Decimal) orderMap.get('amount');
                dw.category          = (String)  orderMap.get('category');

                parsed.add(dw);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'CapitecOcrRetryHandler.parseOcrResponse – parse error: ' + e.getMessage());
        }

        return parsed;
    }
}