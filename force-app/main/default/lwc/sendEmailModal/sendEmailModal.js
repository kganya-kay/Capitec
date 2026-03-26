import LightningModal from "lightning/modal";
import { api, track } from "lwc";
import createEmailMessage from "@salesforce/apex/SendEmailController.createEmailMessage";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";

// Enum for supported email modes
export const EMAIL_MODE = {
  DEFAULT: "default",
  FORWARD: "forward",
  REPLY: "reply",
  REPLY_ALL: "replyAll"
};

export default class SendEmailModal extends LightningModal {
  // --- Incoming modal parameters passed from parent ---
  @api params;

  // --- Local tracked state for UI and logic ---
  @track showSpinner = false;              // Spinner shown during send operation
  @track showOtherEmail = false;           // Toggle for showing the 'Other Email' reason
  @track showFinalWarningModal = false;    // Not currently used, but tracked for potential second modal
  @track fromAddress = "";                 // Human-readable 'From' address
  @track selectedFromAddressId = "";       // Org-wide Email Address ID
  @track attachments = [];                 // Final attachments to be sent
  @track forwardedAttachments = [];        // Forwarded files (read-only)
  @track templateAttachments = [];         // Attachments that come from template
  @track attestationAccepted = false;      // Privacy notice confirmation

  // --- Values populated by child components ---
  @track subject = "";
  @track body = "";
  @track selectedContactIds = [];          // Contacts selected from the dropdown
  @track toEmails = [];                    // List of email recipients
  @track _otherEmailReason = "";           // Reason for using an unlinked email address

  // Initialize modal state from params
  connectedCallback() {
    this.subject = this.params.subject || "";
    this.body = this.params.body || "";
    this.forwardedAttachments = this.params.originalAttachments || [];
    this.fromAddress = this.params.fromAddress || "";
    this.toEmails = this.params.toEmails || [];
    this.selectedContactIds = this.params.selectedContactIds || [];
    this._otherEmailReason = this.params.otherEmailReason || "";
    if (this._otherEmailReason && this.params.mode !== EMAIL_MODE.DEFAULT) {
      this.showOtherEmail = true;
    }
  }

  // --- Getters for parameters passed to child components ---
  get recordId() {
    return this.params?.recordId;
  }

  get objectApiName() {
    return this.params?.objectApiName;
  }

  get mode() {
    return this.params?.mode || EMAIL_MODE.DEFAULT;
  }

  // Uses first contact if multiple selected
  get contactId() {
    return this.selectedContactIds.length > 0 ? this.selectedContactIds[0] : null;
  }

  // Getter/setter for Other Email Reason
  get otherEmailReason() {
    return this._otherEmailReason;
  }

  set otherEmailReason(val) {
    this._otherEmailReason = val;
    if (val && this.mode !== EMAIL_MODE.DEFAULT) {
      this.showOtherEmail = true;
    }
  }

  // --- Event handlers for updates from child components ---

  handleFromChange(event) {
    this.selectedFromAddressId = event.detail;
  }

  handleRecipientsChange(event) {
    const { selectedContactIds, toEmails, otherEmailReason } = event.detail;
    this.selectedContactIds = selectedContactIds;
    this.toEmails = toEmails;
    this.otherEmailReason = otherEmailReason;
  }

  handleSubjectUpdate(event) {
    this.subject = event.detail.subject;
  }

  handleBodyUpdate(event) {
    this.body = event.detail.body;
  }

  handleTemplateUpdate(event) {
    this.selectedTemplateId = event.detail.templateId;
  }

  handleTemplateAttachments(event) {
    this.templateAttachments = event.detail.attachments;
  }

  handleAttachmentsChange(event) {
    this.attachments = event.detail;
  }

  // Close modal with status
  closeModal() {
    this.close("cancel");
  }

  // --- Toast utility functions ---

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  showError(message) {
    this.showToast("Error", message, "error");
  }

  showSuccess(message) {
    this.showToast("Success", message, "success");
  }

  // --- Confirm modal before final send (privacy warning) ---
  async handleShowConfirm() {
    const result = await LightningConfirm.open({
      message: "The wrong contact details or attachment can cause a privacy incident and put Capitec at risk. Please ensure you have performed the correct due diligence. Disciplinary processes will be followed for non-adherence. Do you want to proceed?",
      label: "⚠️ Confirmation Required",
      theme: "warning"
    });

    if (result) {
      this.confirmAndSendEmail();
    }
  }

  // --- Final send operation via Apex ---
  confirmAndSendEmail() {
    this.attestationAccepted = true;
    this.showSpinner = true;

    createEmailMessage({
      toAddresses: this.toEmails.map(e => e.label),
      templateId: this.selectedTemplateId && this.selectedTemplateId.trim() !== "" ? this.selectedTemplateId : null,
      subject: this.subject,
      body: this.body,
      recordId: this.recordId,
      selectedContactIds: this.selectedContactIds ?? [],
      attachments: (this.attachments?.length > 0) ? JSON.stringify(this.attachments) : null,
      fromAddressId: this.selectedFromAddressId,
      otherEmailReason: this.otherEmailReason,
      attestationAccepted: this.attestationAccepted
    })
      .then(() => {
        this.showSuccess("Email sent successfully!");
        this.close("success");
      })
      .catch(error => {
        this.showError("Error sending email: " + error.body.message);
      })
      .finally(() => {
        this.showSpinner = false;
      });
  }

  // --- Validate input before attempting to send ---
  handleSendEmail() {
    if (!this.selectedFromAddressId) {
      this.showError("Please select a From Address.");
    } else if (!this.toEmails.length) {
      this.showError("Please add Recipients.");
    } else if (!this.subject || !this.subject.trim()) {
      this.showError("Please enter a Subject.");
    } else if (!this.body || !this.body.trim()) {
      this.showError("Please enter a Body.");
    } else {
      this.handleShowConfirm();
    }
  }
}