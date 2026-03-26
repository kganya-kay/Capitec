import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import updateCaseOutcome from "@salesforce/apex/capitec_NoticeDepositHistoryController.updateCaseOutcome";
import updateCase from "@salesforce/apex/capitec_NoticeDepositHistoryController.updateCase";

export default class Capitec_NoticeDepositModal extends LightningElement {
  @api recordId;
  @api isShowModal = false;
  @api isSuccess = false;
  @api showSpinner = false;
  @api caseOutcome;
  @api assignmentReason;
  @api assignmentReasonOptions = []; //CECSF-200 - store Assignment reason picklist values
  @api confirmEvidence = false;

  @track messageToDisplay;
  @track showPicklist = false; //CECSF-200 - Conditional display of assignment reason dropdown
  @track evidenceProvided = ""; //CECSF-201 - set to 'Yes' if agent confirms evidence attached to case

  @track evidenceOptions = [
    { label: "Yes", value: "Yes" },
    { label: "No", value: "No" }
  ];

  connectedCallback() {
    // Initialization code if needed
  }

  hideModalBox() {
    this.isShowModal = false;
  }

  handleReasonChange(event) {
    this.assignmentReason = event.target.value;
  }

  async handleConfirmation() {
    this.showSpinner = true;
    try {
      if (this.isSuccess) {
        await this.updateCaseOutcomeModal();
        this.dispatchEvent(new CustomEvent("modalclose"));
      } else {
        await this.updateCaseAssignmentReason();
      }
    } catch (error) {
      console.error("Error in handleConfirmation:", error);
    } finally {
      this.showSpinner = false;
      this.isShowModal = false;
    }
  }

  handleEvidenceChange(event) {
    this.evidenceProvided = event.target.value;
  }

  //CECSF-201 - route to Assignment Reason if Yes, update case if No
  async handleNext() {
    this.showSpinner = true;
    try {
      if (this.evidenceProvided === "Yes") {
        this.showPicklist = true;
      } else if (this.evidenceProvided === "No") {
        await this.updateCaseStatus();
      }
    } catch (error) {
      console.error("Error in handleNext:", error);
    } finally {
      this.showSpinner = false;
    }
  }

  async handleContinue() {
    if (this.assignmentReason && this.assignmentReason !== "Select an option") {
      this.showSpinner = true;
      try {
        await this.updateCaseAssignmentReason();
      } catch (error) {
        console.error("Error in handleContinue:", error);
      } finally {
        this.showSpinner = false;
      }
    }
  }

  triggerShowEmail() {
    const customEvent = new CustomEvent("showemail", {
      detail: { value: true, reason: this.assignmentReason }
    });
    this.dispatchEvent(customEvent);
  }

  async updateCaseOutcomeModal() {
    try {
      const result = await updateCaseOutcome({ caseId: this.recordId, status: this.caseOutcome });
      if (result === "Success") {
        this.showToast("Success", "Outcome updated successfully!", "success");
        this.isShowModal = false;
        this.showPicklist = false;
      } else {
        this.showToast("Error", `Failed to update case. ${result}`, "error");
      }
    } catch (error) {
      this.handleError(error, "Failed to update outcome.");
    } finally {
      this.showSpinner = false;
      this.showPicklist = false;
      this.isShowModal = false;
    }
  }

  async updateCaseAssignmentReason() {
    let caseRecord = {
      sobjectType: "Case",
      Id: this.recordId,
      Assignment_Reason__c: this.assignmentReason,
      CM_Department__c: "Save", //CECSF-201 - Add department when setting Assignment Reason
      Status: "Assigned" //CECSF-421 - Replace status change automation
    };

    try {
      const result = await updateCase({ caseObj: caseRecord });
      if (result === "Success") {
        this.triggerShowEmail();
        this.isShowModal = false;
      } else {
        throw new Error(result);
      }
    } catch (error) {
      this.handleError(error, "Failed to update Assignment Reason.");
    } finally {
      this.showSpinner = false;
      this.showPicklist = false;
      this.isShowModal = false;
    }
  }

  async updateCaseStatus() {
    let caseRecord = {
      sobjectType: "Case",
      Id: this.recordId,
      Outcome__c: "Invalid",
      Status: "Awaiting Client Feedback"
    };

    try {
      const result = await updateCase({ caseObj: caseRecord });
      if (result === "Success") {
        this.showToast("Success", "Case updated successfully!", "success");
        this.isShowModal = false;
        this.dispatchEvent(new CustomEvent("modalclose"));
      } else {
        this.showToast("Error", `Failed to update case. ${result}`, "error");
      }
    } catch (error) {
      this.handleError(error, "Failed to update case.");
    } finally {
      this.showSpinner = false;
      this.isShowModal = false;
    }
  }

  handleError(error, message) {
    //console.error(message, error);
    this.showToast("Error", `${message} ${error}`, "error");
  }

  showToast(title, message, variant) {
    const toastEvent = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(toastEvent);
  }
}