import { LightningElement, api, track, wire } from "lwc";
import getEmailTemplates from "@salesforce/apex/SendEmailController.getEmailTemplates";
import getEmailTemplateDetails from "@salesforce/apex/SendEmailController.getEmailTemplateDetails";
import getEmailTemplateFolders from "@salesforce/apex/SendEmailController.getEmailTemplateFolders";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class SendEmailSubjectBody extends LightningElement {
  // --- Public API properties ---
  @api recordId;
  @api contactId;
  @api mode;

  // --- Internal tracked state ---
  @track _subject = "";                     // Internal subject string
  @track _body = "";                        // Internal body string
  @track originalMessageBody = "";          // Used for reply/forward context

  @track selectedFolderId = null;           // Selected folder ID for filtering templates
  @track selectedTemplateId = "";           // Selected template ID
  @track emailTemplateFolders = [];         // Folder options
  @track emailTemplateOptions = [];         // Template options
  @track isTemplateSectionOpen = false;     // Toggle for showing/hiding template section
  @track isLoadingTemplate = false;         // Spinner for template load

  // --------- API Getters/Setters ---------

  @api
  get subject() {
    return this._subject;
  }

  set subject(value) {
    this._subject = value ?? "";
  }

  @api
  get body() {
    return this._body;
  }

  set body(value) {
    // Store the original body when in reply/forward mode
    if ((this.mode === "forward" || this.mode === "reply") && !this.originalMessageBody) {
      this.originalMessageBody = value ?? "";
    }

    this._body = value ?? "";
  }

  // --------- Wire email folders ---------
  @wire(getEmailTemplateFolders)
  wiredFolders({ error, data }) {
    if (data) {
      // Populate folders into combobox format
      this.emailTemplateFolders = [
        ...data.map(folder => ({
          value: folder.Id,
          label: folder.Name
        }))
      ];
    } else if (error) {
      this.showToast("Error", "Failed to load email folders", "error");
      console.error("Error fetching folders", error);
    }
  }

  // --------- Wire templates based on folder ---------
  @wire(getEmailTemplates, { folderId: "$selectedFolderId" })
  wiredTemplates({ error, data }) {
    if (data) {
      // Map templates into combobox format
      this.emailTemplateOptions = [
        ...data.map(t => ({ label: t.name, value: t.id }))
      ];

      // Show warning if folder has no templates
      if (this.selectedFolderId && this.isTemplateSectionOpen && this.emailTemplateOptions.length === 0) {
        this.showToast("Warning", "No templates found in the selected folder", "warning");
      }
    } else if (error) {
      this.showToast("Error", "Failed to load email templates", "error");
      console.error("Error fetching templates", error);
    }
  }

  // --------- Getters ---------

  // Toggle label text based on current state
  get toggleLabel() {
    return this.isTemplateSectionOpen ? "Clear Templates Section" : "Add Email Templates";
  }

  // --------- Template Section Toggle ---------
  toggleTemplateSection() {
    this.isTemplateSectionOpen = !this.isTemplateSectionOpen;

    // If closing the section, clear all selections and reset
    if (!this.isTemplateSectionOpen) {
      this.selectedTemplateId = null;
      this.selectedFolderId = null;

      this.resetSubjectAndBodyBasedOnMode();
      this.dispatchTemplateChange();
      this.handleTemplateChange({ detail: { value: "" } });
    }
  }

  // --------- Folder Change ---------
  handleFolderChange(event) {
    this.selectedFolderId = event.detail.value;
    this.selectedTemplateId = null;

    this.resetSubjectAndBodyBasedOnMode();
    this.dispatchTemplateChange();
    this.handleTemplateChange({ detail: { value: "" } });
  }

  // --------- Template Selection ---------
  handleTemplateChange(event) {
    this.selectedTemplateId = event.detail.value;

    // If no template selected, reset and exit
    if (!this.selectedTemplateId) {
      this.resetSubjectAndBodyBasedOnMode();
      this.dispatchTemplateChange();
      return;
    }

    this.isLoadingTemplate = true;

    // Fetch template details from Apex
    getEmailTemplateDetails({
      templateId: this.selectedTemplateId,
      whatId: this.recordId,
      whoId: this.contactId
    })
      .then(template => {
        let subject = template.subject?.trim() || "";

        // Apply RE:/FW: prefix and append original message if in reply/forward mode
        if (this.mode === "forward") {
          this._subject = subject.toLowerCase().startsWith("fw:")
            ? subject
            : "FW: " + subject;

          this._body = template.body + "<br><br>" + this.originalMessageBody;
        } else if (this.mode === "reply") {
          this._subject = subject.toLowerCase().startsWith("re:")
            ? subject
            : "RE: " + subject;

          this._body = template.body + "<br><br>" + this.originalMessageBody;
        } else {
          this._subject = subject;
          this._body = template.body;
        }

        this.dispatchSubjectChange();
        this.dispatchBodyChange();
        this.dispatchTemplateChange();
        this.dispatchTemplateAttachments(template.attachments);
      })
      .catch(error => {
        const errorMessage = error?.body?.message || error?.message || "An unknown error occurred.";
        this.showToast("Error", errorMessage, "error");
        console.error("Error fetching template details:", error);
      })
      .finally(() => {
        this.isLoadingTemplate = false;
      });
  }

  // --------- Reset logic for body/subject when clearing template ---------
  resetSubjectAndBodyBasedOnMode() {
    this._subject = "";

    if (this.mode !== "forward" && this.mode !== "reply") {
      this._body = "";
    } else {
      this._body = this.originalMessageBody || "";
    }
  }

  // --------- Toast Utility ---------
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  // --------- Input Change Handlers ---------

  // Handles user input for the subject field and triggers a subjectchange event
  handleSubjectChange(event) {
    this._subject = event.target.value;
    this.dispatchSubjectChange();
  }

  // Handles user input for the body field and triggers a bodychange event
  handleBodyChange(event) {
    this._body = event.detail.value;
    this.dispatchBodyChange();
  }

  // --------- Event Dispatchers ---------

  // Fires a custom event to notify the parent that the subject has changed
  dispatchSubjectChange() {
    this.dispatchEvent(new CustomEvent("subjectchange", {
      detail: { subject: this._subject }
    }));
  }

  // Fires a custom event to notify the parent that the body has changed
  dispatchBodyChange() {
    this.dispatchEvent(new CustomEvent("bodychange", {
      detail: { body: this._body }
    }));
  }

  // Fires a custom event to notify the parent that the selected template ID has changed
  dispatchTemplateChange() {
    this.dispatchEvent(new CustomEvent("templatechange", {
      detail: { templateId: this.selectedTemplateId }
    }));
  }

  // Fires a custom event to send the template’s attachments to the parent component
  dispatchTemplateAttachments(attachments) {
    this.dispatchEvent(new CustomEvent("templateattachmentsloaded", {
      detail: { attachments }
    }));
  }
}