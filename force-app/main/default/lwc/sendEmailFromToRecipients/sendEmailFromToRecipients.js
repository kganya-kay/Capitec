import { LightningElement, api, wire, track } from "lwc";
import getContacts from "@salesforce/apex/SendEmailController.getContacts";
import getOrgWideEmailAddress from "@salesforce/apex/SendEmailController.getOrgWideEmailAddress";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import OTHER_EMAIL_REASON_FIELD from "@salesforce/schema/Email_Attestation__c.Other_Email_Reason__c";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import sendEmailWarningModal from "c/sendEmailWarningModal";

export default class SendEmailFromToRecipients extends LightningElement {
  // Public API
  @api recordId;
  @api objectApiName;
  @api mode;
  @api fromAddress;
  @api replyToAddresses = [];
  @api replyToContactIds = [];

  // Internal state tracking
  @track fromAddressOptions = [];
  @track selectedFromAddressId = "";
  @track contactOptions = [];
  @track selectedToContactEmail = "";
  @track contactData = [];
  @track contactsIsLoading = false;
  @track toEmails = [];
  @track showOtherEmail = false;
  @track canAddOtherEmail = false;
  @track otherEmailReason = "";
  @track reasonOptions = [];
  @track contactEmailToIdMap = {};
  @track toInputValue = "";

  // ---------- Pre-select reply-to address when in "reply" mode ----------
  connectedCallback() {
    if (this.mode !== "reply") return;
    if (!this.replyToAddresses || this.replyToAddresses.length === 0) return;

    let email = this.replyToAddresses[0];
    const contactId = this.replyToContactIds?.[0] || null;

    if (typeof email === "object" && email?.name) {
      email = email.name;
    }

    if (!email || typeof email !== "string") return;

    this.selectedToContactEmail = email;

    this.toEmails = [{
      label: email,
      name: email
    }];

    if (contactId) {
      this.contactEmailToIdMap[email.toLowerCase()] = contactId;
    }

    this.dispatchChange();
  }

  // ---------- Load org-wide "From" addresses ----------
  @wire(getOrgWideEmailAddress)
  wiredOrgWideEmails({ error, data }) {
    if (data) {
      this.fromAddressOptions = data.map(email => ({
        label: `${email.DisplayName} (${email.Address})`,
        value: email.Id,
        rawEmail: email.Address
      }));

      if (this.fromAddress) {
        const match = this.fromAddressOptions.find(
          opt => opt.rawEmail?.toLowerCase() === this.fromAddress.toLowerCase()
        );

        if (match) {
          this.selectedFromAddressId = match.value;
          this.dispatchEvent(new CustomEvent("fromchange", { detail: this.selectedFromAddressId }));
        }
      }

    } else if (error) {
      console.error("Error fetching org-wide addresses:", error);
    }
  }

  // ---------- Load related contacts ----------
  @wire(getContacts, { recordId: "$recordId", objectType: "$objectApiName" })
  wiredContacts({ error, data }) {
    this.contactsIsLoading = true;

    if (data) {
      this.contactOptions = [];
      this.contactEmailToIdMap = {};

      data.forEach(wrapper => {
        const email = wrapper.email || wrapper.Email;
        if (email) {
          this.contactOptions.push({
            label: `${wrapper.name} (${email})`,
            value: email
          });

          this.contactEmailToIdMap[email] = wrapper.id;
        }
      });
    } else if (error) {
      this.contactOptions = [];
      this.showToast("Error", error.body?.message || "Error loading contacts", "error");
    }

    this.contactsIsLoading = false;
  }

  // ---------- Handle Contact selection ----------
  handleToContactChange(event) {
    this.selectedToContactEmail = event.detail.value;

    this.toEmails = this.selectedToContactEmail
      ? [{ label: this.selectedToContactEmail, name: this.selectedToContactEmail }]
      : [];

    this.dispatchChange();
  }

  // ---------- Clear selected contact ----------
  clearToContactSelection() {
    this.selectedToContactEmail = "";
    this.toEmails = [];
    this.dispatchChange();
  }

  // ---------- Disable clear button if no contact is selected ----------
  get isToClearDisabled() {
    return !this.selectedToContactEmail;
  }

  // ---------- Remove an email from the pill container ----------
  handleRemoveEmail(event) {
    const email = event.detail.item?.name;
    const type = event.target.dataset.inputtype;

    if (type === "to") {
      // Remove the email from the display list
      this.toEmails = this.toEmails.filter(item => item.name !== email);

      // Clear selected value if it's the one removed
      if (this.selectedToContactEmail === email) {
        this.selectedToContactEmail = "";
      }

      // Reset manually added email if it's the one being removed
      if (this.showOtherEmail && this.otherEmailReason && this.toInputValue === email) {
        this.toInputValue = "";
        this.otherEmailReason = "";
        this.canAddOtherEmail = false;
        this.showOtherEmail = false;
      }

      this.dispatchChange();
    }
  }

  // ---------- Handle From Address selection ----------
  handleFromAddressChange(event) {
    this.selectedFromAddressId = event.detail.value;
    this.dispatchEvent(new CustomEvent("fromchange", { detail: this.selectedFromAddressId }));
  }

  // ---------- Clear From Address selection ----------
  clearFromAddressSelection() {
    this.selectedFromAddressId = "";
    this.dispatchEvent(new CustomEvent("fromchange", { detail: this.selectedFromAddressId }));
  }

  // ---------- Load picklist options for "Other Email Reason" ----------
  @wire(getPicklistValues, {
    recordTypeId: "012000000000000AAA",
    fieldApiName: OTHER_EMAIL_REASON_FIELD
  })
  wiredReasonOptions({ error, data }) {
    if (data) {
      this.reasonOptions = data.values;
    } else if (error) {
      console.error("Error fetching picklist values:", error);
    }
  }

  // ---------- Handle toggle of Other Email checkbox ----------
  async handleOtherEmailCheckbox(event) {
    const isChecked = event.target.checked;
    this.showOtherEmail = isChecked;

    if (isChecked) {
      // Open modal to get reason for other email
      const result = await sendEmailWarningModal.open({
        label: "⚠️ Warning",
        size: "small",
        reasonOptions: this.reasonOptions,
        description: "You are adding an email address not associated with a contact. Specify a reason to proceed."
      });

      if (result?.proceed) {
        this.otherEmailReason = result.reason;
        this.canAddOtherEmail = true;
      } else {
        this.showOtherEmail = false;
        this.otherEmailReason = "";
        this.canAddOtherEmail = false;
      }
    } else {
      this.otherEmailReason = "";
      this.canAddOtherEmail = false;
    }

    this.dispatchChange();
  }

  // ---------- Handle manual input in "Other Email" text field ----------
  handleToInputChange(event) {
    this.toInputValue = event.target.value;
  }

  // ---------- Add manually entered email to recipient list ----------
  handleAddToEmail() {
    const email = this.toInputValue.trim();
    if (this.validateEmail(email)) {
      if (!this.isDuplicateEmail(email)) {
        this.toEmails = [...this.toEmails, { label: email, name: email }];
        this.dispatchChange();
      } else {
        this.showToast("Error", "This email is already added", "error");
      }
    } else {
      this.showToast("Error", "Please enter a valid email address.", "error");
    }
    this.toInputValue = "";
  }

  // ---------- Validate basic email format ----------
  validateEmail(email) {
    const pattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return pattern.test(email);
  }

  // ---------- Check if email is already in the list ----------
  isDuplicateEmail(email) {
    return this.toEmails.some(e => e.name === email);
  }

  // ---------- Disable clear button if no From Address is selected ----------
  get isClearDisabled() {
    return !this.selectedFromAddressId;
  }

  // ---------- Disable Add button if input is not a valid email ----------
  get isAddDisabled() {
    return !this.validateEmail(this.toInputValue?.trim());
  }

  // ---------- Dispatch recipient change event to parent ----------
  dispatchChange() {
    const selectedContactIds = this.toEmails
      .map(e => this.contactEmailToIdMap[e.name])
      .filter(id => id); // remove undefined

    this.dispatchEvent(new CustomEvent("recipientschange", {
      detail: {
        selectedContactIds: selectedContactIds,
        toEmails: this.toEmails,
        otherEmailReason: this.otherEmailReason,
        showOtherEmail: this.showOtherEmail
      }
    }));
  }

  // ---------- Show toast notification ----------
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}