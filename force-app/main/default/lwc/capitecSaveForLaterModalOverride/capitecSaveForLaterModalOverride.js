import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
import omniscriptModal from 'omnistudio/omniscriptModal';
import getPicklistValues from '@salesforce/apex/capitec_ClientCareController.getPicklistValues';  // Fetch picklist values dynamically
import saveCaseFields from '@salesforce/apex/capitec_ClientCareController.saveCaseFields';  // Save Case fields
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // Import for toast notifications
import tmpl from './capitecSaveForLaterModalOverride.html';

//CEDT-3393 - update override
export default class CustomSaveForLaterModal extends OmniscriptBaseMixin(LightningElement, omniscriptModal) {
    @api recordId;
    @api modalType;
    @api type;
    
    @track cancelReason = '';  // To store the selected cancel reason
    @track channel = '';       // To store the selected channel
    @track cancelReasonOptions = [];  // Picklist options for Cancel Reason
    @track channelOptions = [];       // Picklist options for Channel
    @track errorMessage = '';         // To handle errors
    @track showModal = false;         // Control visibility of the modal
    @track isLoading = false;         // To control spinner visibility
    @track isFieldSet = false;         // To control spinner visibility
    @track showCancelReason = false;   // CEDT-3298 - conditionally hide cancel reason
    @track showChannel = true;
    @track headerText = 'Please confirm the following information';

    connectedCallback() {

        this.recordId = sessionStorage.getItem("ccCaseId");
        this.modalType = sessionStorage.getItem("modalType");

        //CEDT-3523 - do not expect a recordId for modalType 'Exit'
        if(!this.recordId && this.modalType !== 'Exit') {
            this.showToast('Error', 'Unable to retrieve Case record - please contact your system administrator.', 'error');
            this.closeModal();
            return;
        }

        if(this.type === 'error') {
            this.errorMessage = 'Please contant your System Admin and give them the following details:';
            this.showCancelReason = false;
            this.showChannel = false;
            this.headerText = 'An error has occurred';
            return;
        }

        //CEDT-3523 - hide picklists for modalType 'Exit'
        switch (this.modalType) {
            case 'Cancel':
                this.showChannel = true;
                this.showCancelReason = false;
                break;
            case 'SaveForLater':
                this.showChannel = true;
                this.showCancelReason = true;
                break;
            case 'Exit':
                this.showChannel = false;
                this.showCancelReason = false;
                this.headerText = 'Confirm cancel';
                return;
            default:
                this.closeModal();
                return;
        } 

        this.loadPicklistValues();

        // Remove the "OK/Continue" button when the component is connected - CEDT-3298
        this.toggleProceedButton(false);
    }

    render() {
        return tmpl;
    }

    // Toggles the visibility of the OK/Continue button based on the condition - CEDT-3298
    toggleProceedButton(show) {
        const omniscriptContainer = this.template.host.parentNode;
        const style = document.createElement('style');
        style.innerText = `li.slds-button-group-item:nth-child(2) { display: ${show ? 'block' : 'none'}; }`;

        // Check if the style has already been added to avoid duplicates
        if (!this.template.querySelector('style')) {
            omniscriptContainer.appendChild(style);
        }
    }

    // Load picklist values from Apex controller
    loadPicklistValues() {
        getPicklistValues()
            .then(result => {
                this.cancelReasonOptions = result.CM_Cancel_Reason__c.map(value => ({
                    label: value,
                    value: value
                }));
                this.channelOptions = result.CM_Channel__c.map(value => ({
                    label: value,
                    value: value
                }));
            })
            .catch(error => {
                console.error('Error fetching picklist values:', error);
                this.errorMessage = 'Failed to load picklist values';
            });
    }

    // Handle change in Cancel Reason picklist
    handleCancelReasonChange(event) {
        this.cancelReason = event.detail.value;
        this.handleSave();
    }

    // Handle change in Channel picklist
    handleChannelChange(event) {
        this.channel = event.detail.value;
        this.handleSave();
    }

    // Method to handle the save operation
    handleSave() {

        if(!this.channel) {
            this.errorMessage = 'Please select a channel.';
            return;
        }

        this.errorMessage = '';

        // Start showing spinner
        this.isLoading = true;

        //CEDT-3393 - update override
        if (this.channel || this.cancelReason) {
            saveCaseFields({ 
                caseId: this.recordId, 
                cancelReason: this.modalType == 'Cancel'? 'Agent Error' : this.cancelReason, 
                channel: this.channel,
                status: this.modalType == 'SaveForLater' ? 'Incomplete - Missing Client Info' : 'New' //CEDT-3448 - update case status
            })
            .then(() => {
                this.toggleProceedButton(true); // Re-enable the "OK/Continue" button
                this.showToast('Success', 'Case updated successfully.', 'success');
                this.isFieldSet = true;
            })
            .catch(error => {
                this.toggleProceedButton(false);
                console.error('Error updating record:', error);
                this.isFieldSet = false;
                this.showToast('Error', 'Error saving record.', 'error');
            })
            .finally(() => {
                // Stop showing spinner after operation completes
                this.isLoading = false;
            });
        } else {
            this.isLoading = false; // Stop showing spinner if validation fails
        }
    }

    // Public method to be called externally to open the modal
    @api openModal() {
        this.showModal = true; // Use state to show the modal
    }

    //Public method to be called externally to close the modal
    @api closeModal() {
        this.showModal = false;
    }

    // Utility method to show toast notifications
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}