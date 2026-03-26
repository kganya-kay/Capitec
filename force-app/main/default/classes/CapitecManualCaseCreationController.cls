/**
 * @description  Main Apex controller for the capitecConversionsManualCaseCreationLWC component.
 *               Handles client lookup by identification type/number and the Domain API submission
 *               placeholder (to be wired up in the integration phase).
 *
 * @author       Capitec Conversions Team
 * @version      2.0
 */
public with sharing class CapitecManualCaseCreationController {

    // =========================================================================
    // CONSTANTS
    // =========================================================================

    /** Developer name of the Case record type used for Conversions. */
    private static final String CONVERSIONS_RT_DEV_NAME = 'Conversions';

    /** Maps each identification type label to the corresponding Account field API name. */
    private static final Map<String, String> ID_TYPE_TO_FIELD = new Map<String, String>{
        'ID number'       => 'Identity_Number__c',
        'Passport number' => 'Passport_Number__c',
        'CIF number'      => 'CIF_Number__c',
        'Account number'  => 'Account_Number__c'
    };

    // =========================================================================
    // PUBLIC AURA-ENABLED METHODS
    // =========================================================================

    /**
     * @description  Looks up a client (Account - Person Account) by the agent-provided identification
     *               type and number. Returns a populated ClientInfoWrapper if found,
     *               or null if no matching record exists.
     */
    @AuraEnabled
    public static CapitecManualCaseCreationWrapper.ClientInfoWrapper searchClient(
        String idType,
        String idNumber
    ) {
        // ── Input guards ─────────────────────────────────────────────────────
        if (String.isBlank(idType) || String.isBlank(idNumber)) {
            throw new AuraHandledException(
                'Both Identification Type and Identification Number are required.'
            );
        }

        String fieldName = ID_TYPE_TO_FIELD.get(idType);
        if (String.isBlank(fieldName)) {
            throw new AuraHandledException(
                'Unrecognised identification type: ' + idType
            );
        }

        String trimmedSearchValue = idNumber.trim();

        // ── Query ────────────────────────────────────────────────────────────
        try {
            String soql =
                'SELECT Id, CIF_Number__c, Identity_Number__c, Passport_Number__c, ' +
                '       Salutation, FirstName, LastName, Phone, PersonMobilePhone, ' +
                '       Work_Contact_Number__c, PersonEmail ' +
                'FROM Account ' +
                'WHERE ' + fieldName + ' = :trimmedSearchValue ' +
                'AND IsPersonAccount = true ' +
                'WITH SECURITY_ENFORCED ' +
                'LIMIT 1';

            List<Account> accounts = Database.query(soql);

            if (accounts.isEmpty()) {
                return null;
            }

            return mapAccountToWrapper(accounts[0]);

        } catch (QueryException qe) {
            throw new AuraHandledException(
                'Database error during client lookup: ' + qe.getMessage()
            );
        } catch (Exception e) {
            throw new AuraHandledException(
                'Unexpected error searching for client: ' + e.getMessage()
            );
        }
    }

    /**
     * @description  Placeholder for the Domain API submission call.
     *               Receives the full case payload as a JSON string and will
     *               perform an HTTP callout to the Domain system in the
     *               integration phase.
     *
     * @param  payload  JSON-serialised CasePayloadWrapper built by the LWC.
     * @return          Acknowledgement string from Domain API (or placeholder).
     */
    @AuraEnabled
    public static String submitCaseToApi(String payload) {
        if (String.isBlank(payload)) {
            throw new AuraHandledException('Submission payload cannot be empty.');
        }

        try {
            /*
             * ─── TODO – Domain API Integration ───────────────────────────────
             * Uncomment and configure the callout below once the named credential
             * and endpoint are confirmed:
             *
             *   HttpRequest req = new HttpRequest();
             *   req.setEndpoint('callout:CapitecDomainAPI/v1/cases');
             *   req.setMethod('POST');
             *   req.setHeader('Content-Type', 'application/json');
             *   req.setHeader('Accept', 'application/json');
             *   req.setBody(payload);
             *   req.setTimeout(30000);
             *
             *   Http http = new Http();
             *   HttpResponse res = http.send(req);
             *
             *   if (res.getStatusCode() == 201 || res.getStatusCode() == 200) {
             *       return res.getBody();
             *   }
             *   throw new AuraHandledException(
             *       'Domain API error ' + res.getStatusCode() + ': ' + res.getBody()
             *   );
             * ──────────────────────────────────────────────────────────────────
             */

            // Placeholder – log payload for debugging during development
            System.debug(LoggingLevel.INFO,
                'CapitecManualCaseCreationController.submitCaseToApi – payload ready:\n' + payload);

            return 'PENDING_API_IMPLEMENTATION';

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Failed to submit case to Domain API: ' + e.getMessage()
            );
        }
    }

    /**
     * @description  Returns the Name of a Debit Order Initiator record by Id.
     *               Called by the LWC after a lightning-record-picker selection
     *               to populate the doiName field for datatable display.
     *
     * @param  recordId  Id of the selected Debit_Order_Initiator__c record.
     * @return           The record's Name field value.
     */
    @AuraEnabled(cacheable=true)
    public static String getDebitOrderInitiatorName(String recordId) {
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Record Id is required.');
        }
        try {
            List<Debit_Order_Initiator__c> dois = [
                SELECT Name
                FROM   Debit_Order_Initiator__c
                WHERE  Id = :recordId
                WITH   SECURITY_ENFORCED
                LIMIT  1
            ];
            return dois.isEmpty() ? '' : dois[0].Name;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error fetching Debit Order Initiator name: ' + e.getMessage()
            );
        }
    }

    // =========================================================================
    // PRIVATE HELPERS
    // =========================================================================

    /**
     * @description  Maps a queried Account record to the ClientInfoWrapper DTO.
     */
    private static CapitecManualCaseCreationWrapper.ClientInfoWrapper mapAccountToWrapper(Account acc) {
        CapitecManualCaseCreationWrapper.ClientInfoWrapper wrapper =
            new CapitecManualCaseCreationWrapper.ClientInfoWrapper();

        wrapper.cifNumber         = (String) acc.get('CIF_Number__c');
        wrapper.idNumber          = (String) acc.get('Identity_Number__c');
        wrapper.passportNumber    = (String) acc.get('Passport_Number__c');

        wrapper.salutation        = acc.Salutation;
        wrapper.firstName         = acc.FirstName;
        wrapper.lastName          = acc.LastName;

        wrapper.mobileNumber      = acc.PersonMobilePhone;
        wrapper.emailAddress      = acc.PersonEmail;

        wrapper.homeContactNumber = String.isNotBlank(acc.Phone)
            ? acc.Phone
            : 'N/A';

        wrapper.workContactNumber = String.isNotBlank(acc.Work_Contact_Number__c)
            ? acc.Work_Contact_Number__c
            : 'N/A';

        return wrapper;
    }
}