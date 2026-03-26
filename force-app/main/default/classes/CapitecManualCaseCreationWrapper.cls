/**
 * @description  Data Transfer Object (DTO) wrapper classes for the
 *               capitecConversionsManualCaseCreationLWC component.
 *               All inner classes are @AuraEnabled so they can be
 *               serialised/deserialised between Apex and LWC.
 *
 * @author       Capitec Conversions Team
 * @version      1.0
 */
public class CapitecManualCaseCreationWrapper {

    // =========================================================================
    // CLIENT INFO WRAPPER  (populated from Contact lookup – Step 2)
    // =========================================================================

    /**
     * @description  Holds all client-identifying information returned from
     *               the Contact lookup performed at the end of Step 1.
     */
    public class ClientInfoWrapper {

        /** Capitec CIF (Customer Information File) number */
        @AuraEnabled public String cifNumber         { get; set; }

        /** South African ID number */
        @AuraEnabled public String idNumber          { get; set; }

        /** Passport number */
        @AuraEnabled public String passportNumber    { get; set; }

        /** Salutation (Mr / Mrs / Ms / Dr etc.) */
        @AuraEnabled public String salutation        { get; set; }

        /** Client first name */
        @AuraEnabled public String firstName         { get; set; }

        /** Client last name / surname */
        @AuraEnabled public String lastName          { get; set; }

        /** Home (landline) contact number */
        @AuraEnabled public String homeContactNumber { get; set; }

        /** Work contact number */
        @AuraEnabled public String workContactNumber { get; set; }

        /** Mobile / cell number */
        @AuraEnabled public String mobileNumber      { get; set; }

        /** Email address */
        @AuraEnabled public String emailAddress      { get; set; }

        /** Default constructor – sets N/A for optional contact numbers. */
        public ClientInfoWrapper() {
            this.homeContactNumber = 'N/A';
            this.workContactNumber = 'N/A';
        }
    }

    // =========================================================================
    // DEBIT ORDER WRAPPER  (from OCR or manual entry – Step 4)
    // =========================================================================

    /**
     * @description  Represents a single debit order line item, either extracted
     *               via OCR from an uploaded bank statement or entered manually.
     */
    public class DebitOrderWrapper {

        /** Debit Order Reference Number (unique identifier) */
        @AuraEnabled public String  doReferenceNumber { get; set; }

        /** Debit Order Instruction (DOI) name / merchant name */
        @AuraEnabled public String  doiName           { get; set; }

        /** Date of the debit order (ISO format yyyy-MM-dd) */
        @AuraEnabled public String  debitOrderDate    { get; set; }

        /** Debit amount in ZAR */
        @AuraEnabled public Decimal amount            { get; set; }

        /** Category: 'Immediate' or 'Future Dated' */
        @AuraEnabled public String  category          { get; set; }
    }

    // =========================================================================
    // UPLOADED FILE WRAPPER  (Step 3 documents)
    // =========================================================================

    /**
     * @description  Represents a file selected by the agent in Step 3.
     *               The base64Content field is populated during the API
     *               submission phase (not during the wizard draft phase).
     */
    public class UploadedFileWrapper {

        /** Original file name (e.g. BankStatement_Jan2026.pdf) */
        @AuraEnabled public String fileName      { get; set; }

        /** Document type selected by agent: Bank Statement / Authorisation Form / ID Copy */
        @AuraEnabled public String documentType  { get; set; }

        /**
         * Base64-encoded file content.
         * Populated only during final API submission.
         */
        @AuraEnabled public String base64Content { get; set; }
    }

    // =========================================================================
    // CASE PAYLOAD WRAPPER  (full submission payload – Step 5)
    // =========================================================================

    /**
     * @description  The complete case payload assembled on the Summary step and
     *               sent to the Domain API via CapitecManualCaseCreationController.submitCaseToApi().
     */
    public class CasePayloadWrapper {

        // ── Client ───────────────────────────────────────────────────────────
        @AuraEnabled public ClientInfoWrapper clientInfo           { get; set; }

        /** Identification type chosen in Step 1 */
        @AuraEnabled public String identificationType             { get; set; }

        /** Identification number entered in Step 1 */
        @AuraEnabled public String identificationNumber           { get; set; }

        /** Preferred contact time captured in Step 2 (HH:MM format) */
        @AuraEnabled public String preferredContactTime           { get; set; }

        // ── Case ─────────────────────────────────────────────────────────────
        /** Case source (maps to Case.Origin) */
        @AuraEnabled public String source                         { get; set; }

        /** Issue (maps to Case.Issue__c on Conversions record type) */
        @AuraEnabled public String issue                          { get; set; }

        // ── Old Bank ─────────────────────────────────────────────────────────
        @AuraEnabled public String oldBranchCode                  { get; set; }

        /** Old bank name (maps to Case.Old_Bank_Name__c) */
        @AuraEnabled public String oldBankName                    { get; set; }

        @AuraEnabled public String oldAccountNumber               { get; set; }

        // ── Debit Orders ─────────────────────────────────────────────────────
        @AuraEnabled public List<DebitOrderWrapper> debitOrders   { get; set; }

        // ── Supporting Documents ─────────────────────────────────────────────
        @AuraEnabled public List<UploadedFileWrapper> uploadedFiles { get; set; }

        // ── Notes ────────────────────────────────────────────────────────────
        @AuraEnabled public String additionalComments             { get; set; }

        /** Default constructor – initialises lists to avoid null references. */
        public CasePayloadWrapper() {
            this.debitOrders   = new List<DebitOrderWrapper>();
            this.uploadedFiles = new List<UploadedFileWrapper>();
        }
    }
}