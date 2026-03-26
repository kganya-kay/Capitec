import { LightningElement, api, track, wire } from "lwc";

import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";

import loadMessages from "@salesforce/apex/EmailTimeLineController.loadMessages";
import redoEmailSend from "@salesforce/apex/EmailTimeLineController.redoEmailSend";
import sendEmailModal from "c/sendEmailModal";

import userId from '@salesforce/user/Id';
import OWNER_ID from '@salesforce/schema/Case.OwnerId';
import ISCLOSED from '@salesforce/schema/Case.IsClosed';

export default class EmailTimeline extends NavigationMixin(LightningElement) {
  // Public API
  @api objectApiName;
  @api claimContext = false;

  // Internal state
  @track _recordId;
  @track expandedStates = {}; // Tracks expanded/collapsed state of each email
  @track emails = []; // List of email messages
  @track applicableContacts = []; // List of contacts relevant to this case
  @track error; // Stores any error messages
  @track subject; // Current subject being composed
  @track body; // Current body being composed
  @track fromAddress; // Sender email
  @track toAddresses = []; // Recipients list
  @track selectedContactsIds = []; // Selected contact IDs for sending
  @track otherEmailReason = ""; // Reason provided when using an unlisted email
  @track mode; // Mode can be 'reply', 'forward', or 'default'
  @track allExpanded = false; // Toggle for expanding/collapsing all email cards
  @track isLoading = false; // Tracks loading state

  // recordId setter triggers loading of emails when value changes
  @api
  set recordId(val) {
    if (val && val !== this._recordId) {
      this._recordId = val;

      this.loadEmailMessages().catch(error => {
        console.error("Error loading email messages:", error);
      });
    }
  }

  get recordId() {
    return this._recordId;
  }

  // current case based on source record page
  @wire(getRecord, { recordId: '$recordId', fields: [OWNER_ID, ISCLOSED]})
  caseRecord;

  // boolean flag to indicate if current case is closed
  get isCaseClosed() { 
    return getFieldValue(this.caseRecord.data, ISCLOSED);
  }
  
  // retrieve case owner id
  get caseOwnerId() { 
    return getFieldValue(this.caseRecord.data, OWNER_ID); 
  }
  
  // retrieve current login user id 
  get currentUserId() { 
    return userId;
  }

  // boolean flag to control visibility of email functions i.e. send, reply, forward and retry
  get showSendEmailActionButtons() {
    return (this.currentUserId == this.caseOwnerId && !this.isCaseClosed) || this.claimContext;
  }

  // Fetches email messages and related contacts from Apex
  async loadEmailMessages() {
    this.isLoading = true;
    try {
      const data = await loadMessages({ recordId: this.recordId });
      if (data.errorMessage) {
        this.error = data.errorMessage;
        return;
      }

      this.applicableContacts = data.applicableContacts;
      this.emails = data.emailMessages;
    } catch (err) {
      this.error = err.message;
    }
    this.isLoading = false;
  }

  // Processes email data into a display-friendly format
  get computedEmails() {
    return this.emails.map(email => {
      const expanded = this.expandedStates[email.id] || false;

      // Mapping of file extensions to Salesforce doctype icons
      const typeToIcon = {
        ai: "doctype:ai",
        attachment: "doctype:attachment",
        audio: "doctype:audio",
        box: "doctype:box_notes",
        csv: "doctype:csv",
        eps: "doctype:eps",
        excel: "doctype:excel",
        exe: "doctype:exe",
        fla: "doctype:flash",
        folder: "doctype:folder",
        gdoc: "doctype:gdoc",
        gdocs: "doctype:gdocs",
        gform: "doctype:gform",
        gpres: "doctype:gpres",
        gsheet: "doctype:gsheet",
        html: "doctype:html",
        image: "doctype:image",
        key: "doctype:keynote",
        keynote: "doctype:keynote",
        link: "doctype:link",
        library: "doctype:library_folder",
        mp4: "doctype:mp4",
        overlay: "doctype:overlay",
        pack: "doctype:pack",
        pages: "doctype:pages",
        pdf: "doctype:pdf",
        ppt: "doctype:ppt",
        psd: "doctype:psd",
        quip_doc: "doctype:quip_doc",
        quip_sheet: "doctype:quip_sheet",
        rtf: "doctype:rtf",
        slide: "doctype:slide",
        sty: "doctype:stypi",
        txt: "doctype:txt",
        visio: "doctype:visio",
        webex: "doctype:webex",
        word: "doctype:word",
        xml: "doctype:xml",
        zip: "doctype:zip",
        doc: "doctype:word",
        docx: "doctype:word",
        xls: "doctype:excel",
        xlsx: "doctype:excel",
        pptx: "doctype:ppt"
      };

      // Maps each attachment to include a doctype icon
      const computedAttachments = (email.attachments || []).map(file => {
        const fileType = file.fileType?.toLowerCase();
        const iconName = typeToIcon[fileType] || "doctype:unknown";
        return { ...file, iconName };
      });

      return {
        ...email,
        expanded,
        iconName: expanded ? "utility:chevrondown" : "utility:chevronright",
        hasAttachments: email.attachments && email.attachments.length > 0,
        directionIcon: email.isInbound ? "standard:email_chatter" : "standard:email",
        computedAttachments
      };
    });
  }

  // Label shown on the expand/collapse all toggle
  get toggleAllLabel() {
    return this.allExpanded ? "Collapse All" : "Expand All";
  }

  // Icon shown on the expand/collapse all toggle
  get toggleAllIcon() {
    return this.allExpanded ? "utility:collapse_all" : "utility:expand_all";
  }

  // Toggle expanded state for all emails
  toggleAll() {
    this.allExpanded = !this.allExpanded;
    this.expandedStates = this.emails.reduce((acc, email) => {
      acc[email.id] = this.allExpanded;
      return acc;
    }, {});
  }

  // Toggle expanded/collapsed state of a single email
  toggleDetails(event) {
    const emailId = event.currentTarget.dataset.id;
    this.expandedStates = {
      ...this.expandedStates,
      [emailId]: !this.expandedStates[emailId]
    };
  }

  // Handles menu actions for reply, forward, and redo
  handleEmailAction(event) {
    const emailId = event.currentTarget.dataset.id;
    const action = event.currentTarget.dataset.action;
    const message = this.emails.find(e => e.id === emailId);

    switch (action) {
      case "reply":
        this.reply(message);
        break;
      case "forward":
        this.forward(message);
        break;
      case "redo":
        this.handleShowConfirm(message).catch(error => {
          console.error("Error showing confirmation modal:", error);
        });
        break;
    }
  }

  // Forward selected email
  forward(message) {
    this.mode = "forward";

    const originalSubject = message.subject || "";
    const prefix = originalSubject.trim().toLowerCase().startsWith("fw:") ? "" : "FW: ";

    this.subject = prefix + originalSubject;
    this.generateBody(message, true);

    this.fromAddress = message.fromAddress;

    const originalAttachments = message.attachments?.map(attachment => ({
      ...attachment
    })) ?? [];

    this.openEmailModal("Forward Email", originalAttachments).catch(error => {
      console.error("Error opening email modal:", error);
    });
  }

  // Reply to selected email
  reply(message) {
    this.mode = "reply";

    const originalSubject = message.subject || "";
    const prefix = originalSubject.trim().toLowerCase().startsWith("re:") ? "" : "RE: ";
    this.subject = prefix + originalSubject;

    const toAddressList = (message.toAddress?.split(/[,;]/) || []).map(email => email.trim()).filter(Boolean);
    this.fromAddress = toAddressList.length > 0 ? toAddressList[0] : "";

    const toAddresses = message.fromAddress
      ? [{ label: message.fromAddress, name: message.fromAddress }]
      : [];

    this.toAddresses = toAddresses;
    this.otherEmailReason = message.otherEmailReason ?? "";

    // Match contact IDs for selected reply-to addresses
    this.selectedContactsIds = this.applicableContacts
      .filter(contact => toAddresses.some(to => to.name === contact.email))
      .map(contact => contact.id);

    this.generateBody(message, false);

    this.openEmailModal("Reply").catch(error => {
      console.error("Error opening reply email modal:", error);
    });
  }

  // Generates the quoted body for reply or forward
  generateBody(message, isForward) {
    this.body = `
      <br><br>
      --------------- ${isForward ? "Forwarded" : "Original"} Message ---------------<br>
      <b>From:</b> ${message.fromAddress}<br>
      <b>Sent:</b> ${message.formattedDate}<br>
      <b>To:</b> ${message.toAddress || ""}<br>
      <b>Subject:</b> ${this.subject}<br><br>
      <div style="border-left:2px solid #ccc; margin:10px 0; padding-left:10px;">
        ${message.body || ""}
      </div>
    `;
  }

  // Shows confirmation modal for resending email
  async handleShowConfirm(message) {
    const result = await LightningConfirm.open({
      message: "Are you sure you want to resend this email?",
      label: "⚠️ Confirm Resend",
      theme: "warning"
    });

    if (result) {
      this.redo(message);
    }
  }

  // Calls Apex to resend email
  redo(message) {
    this.isLoading = true;

    redoEmailSend({ emailMessageId: message.id })
      .then(() => {
        this.showToast("Success", "Email resent successfully", "success");
      })
      .catch(error => {
        this.showToast("Error", error.body?.message || "Failed to resend email", "error");
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  // Opens the email modal with provided parameters
  async openEmailModal(label = "", originalAttachments = []) {
    try {
      const result = await sendEmailModal.open({
        label,
        size: "large",
        params: {
          recordId: this.recordId,
          objectApiName: this.objectApiName,
          mode: this.mode,
          subject: this.subject,
          body: this.body,
          fromAddress: this.fromAddress,
          toEmails: this.toAddresses,
          otherEmailReason: this.otherEmailReason,
          selectedContactsIds: this.selectedContactsIds,
          originalAttachments
        }
      });

      if (result === "success") {
        await this.loadEmailMessages();
      }
    } catch (e) {
      console.error("Modal open failed:", e.error);
    }
  }

  // Handles new email button click
  async handleSendEmail() {
    this.subject = "";
    this.body = "";
    this.mode = "default";
    this.toAddresses = [];
    this.fromAddress = "";
    this.otherEmailReason = "";
    this.selectedContactsIds = [];

    this.openEmailModal("New Email").catch(error => {
      console.error("Error opening reply email modal:", error);
    });
  }

  // Opens attachment in file preview
  handlePreview(event) {
    const docId = event.currentTarget.dataset.id;
    this[NavigationMixin.Navigate]({
      type: "standard__namedPage",
      attributes: {
        pageName: "filePreview"
      },
      state: {
        selectedRecordId: docId
      }
    });
  }

  // Opens file in new browser tab
  handleDownload(event) {
    const downloadUrl = event.currentTarget.dataset.url;
    window.open(downloadUrl, "_blank");
  }

  // Opens the email record in a new browser tab
  handleOpenEmail(event) {
    const emailId = event.currentTarget.dataset.id;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: emailId,
        objectApiName: "EmailMessage",
        actionName: "view"
      },
      state: {
        navigationLocation: "RELATED_LIST",
        backgroundContext: `/lightning/r/Case/${this.recordId}/view`
      }
    });
  }

  // Reloads email data
  handleRefresh() {
    this.loadEmailMessages().catch(error => {
      console.error("Error loading email messages:", error);
    });
  }

  // Indicates if no emails exist and not currently loading
  get showEmptyState() {
    return !this.isLoading && this.emails.length === 0;
  }

  // Displays a toast message
  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title,
      message,
      variant
    });
    this.dispatchEvent(evt);
  }
}