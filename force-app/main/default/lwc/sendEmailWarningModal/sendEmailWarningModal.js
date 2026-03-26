import LightningModal from "lightning/modal";
import { api, track } from "lwc";

// Modal component to capture reason when using an 'Other Email' address
export default class SendEmailWarningModal extends LightningModal {
  // List of reason picklist options passed from parent
  @api reasonOptions = [];

  // Track the currently selected reason
  @track selectedReason = "";

  // Control the disabled state of the Proceed button
  isProceedDisabled = true;

  // Handle changes to the selected reason
  handleReasonChange(event) {
    this.selectedReason = event.detail.value;
    this.isProceedDisabled = !this.selectedReason;
  }

  // Close the modal when the Cancel button is clicked
  handleCancel() {
    this.close({ proceed: false });
  }

  // Close the modal and return the selected reason when Proceed is clicked
  handleProceed() {
    this.close({
      proceed: true,
      reason: this.selectedReason
    });
  }
}