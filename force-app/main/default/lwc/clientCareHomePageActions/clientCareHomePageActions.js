import { LightningElement, track } from 'lwc';
import pubsub from "omnistudio/pubsub";
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
import { interpolateWithRegex } from "omnistudio/flexCardUtility";
import closeAgentErrorCase from '@salesforce/apex/capitec_ClientCareController.closeAgentErrorCase'; // Import the Apex method
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // Import for toast notifications

export default class ClientCareHomePageActions extends OmniscriptBaseMixin(LightningElement) {
    @track showNonClientOmniscript = false;
    @track caseId;

    pubsubEvent = [];
    pubsubChannel0 = '';
    pubsubChannel1 = '';

    // Handles the 'omniscript_action' event
    handleEventAction(data) {
    
        switch (data.name) {
            case 'SetComplete':
                this.showNonClientOmniscript = false;
                this.caseId = data.eventValues.split("|");
                this.hideActions = false;
                sessionStorage.removeItem("ccCaseId");
                sessionStorage.removeItem("modalType");
                break;
            case 'SetClientCareCaseValues':
                this.caseId = data.eventValues;
                sessionStorage.setItem("ccCaseId", this.caseId);
                break;
            default:
                if (data.name === 'CANCEL') {
                    if (sessionStorage.getItem("modalType") === 'Cancel') {
                        this.closeCaseWithReason();
                    }
                    this.showNonClientOmniscript = false;
                    this.hideActions = false;
                }else if(data.name.includes('Step') || data.name.includes('cd')) {
                    this.handleToggle(data);
                }
        }
    }
    
    // Handles the 'omniscript_step' event
    handleEventStep(data) {
        this.handleToggle(data);
    }
    
    handleToggle(data){
        switch (data.name) {
            case 'ncWhoReportedStep':
                sessionStorage.setItem("modalType", 'Exit');
                this.toggleCancelButton(true);
                break;
            case 'cdIdentifyDisputeScreen':
                sessionStorage.setItem("modalType", 'Cancel');
                this.toggleCancelButton(true);
                break;
            default:
                if (data.name.includes('Step') || data.name.includes('cd')) {
                    sessionStorage.setItem("modalType", 'SaveForLater');
                    this.toggleCancelButton(false);
                }
        }    
    }
    
    // Toggles the visibility of the cancel button based on the condition
    toggleCancelButton(show) {
        const omniscriptContainer = this.template.host.parentNode;
        const style = document.createElement('style');
        style.innerText = `div.omniscript-sfl-actions > div:nth-child(1):has(.vlocity-btn) { display: ${show ? 'block' : 'none'}; }`;

        // Check if the style has already been added to avoid duplicates
        if (!this.template.querySelector('style')) {
            omniscriptContainer.appendChild(style);
        }    
    }        
    
    // Handles the click on the non-client button
    handleNonClientClick() {
        this.showNonClientOmniscript = true;
        this.hideActions = true;
    }
    
    connectedCallback() {
        this.registerEvents();
    }
    
    disconnectedCallback() {
        this.unregisterEvents();

        try {
            sessionStorage.removeItem("ccCaseId");
            sessionStorage.removeItem("modalType");
        } catch (error) {
            console.error('Error clearing storage:', error);
        }
    }
    
    // Registers PubSub events for omniscript_action and omniscript_step
    registerEvents() {
        // Create a placeholder data object
        const data = { events: [{}] };
    
        // Register for the 'omniscript_action' event
        this.pubsubEvent[0] = {
            [interpolateWithRegex('data', this._allMergeFields, this._regexPattern, 'noparse')]: this.handleEventAction.bind(this, data.events[0], 0)
        };
        this.pubsubChannel0 = interpolateWithRegex('omniscript_action', this._allMergeFields, this._regexPattern, 'noparse');
        pubsub.register('omniscript_action', {
            data: this.handleEventAction.bind(this), 
        });
    
        // Register for the 'omniscript_step' event
        this.pubsubEvent[1] = {
            [interpolateWithRegex('data', this._allMergeFields, this._regexPattern, 'noparse')]: this.handleEventStep.bind(this, data.events[0], 0)
        };
        this.pubsubChannel1 = interpolateWithRegex('omniscript_step', this._allMergeFields, this._regexPattern, 'noparse');
        pubsub.register('omniscript_step', {
            data: this.handleEventAction.bind(this), 
        });
    }
    
    // Unregisters PubSub events for omniscript_action and omniscript_step
    unregisterEvents() {
        if (this.pubsubChannel0 && this.pubsubEvent[0]) {
            pubsub.unregister(this.pubsubChannel0, this.pubsubEvent[0]);
        }
        if (this.pubsubChannel1 && this.pubsubEvent[1]) {
            pubsub.unregister(this.pubsubChannel1, this.pubsubEvent[1]);
        }
    }
    
    // Apex method to close the case and show a toast notification
    closeCaseWithReason() {
        closeAgentErrorCase({ recordId: this.recordId, caseId: this.caseId })
            .then(() => {
                this.showToast('Success', 'Case closed successfully.', 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
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
    
    renderedCallback() {
        // Placeholder for further actions to be taken when the component is rendered
    }
}