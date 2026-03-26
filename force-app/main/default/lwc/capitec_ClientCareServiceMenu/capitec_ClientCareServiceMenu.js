import { LightningElement, api, track } from "lwc";
import pubsub from "omnistudio/pubsub";
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
import { interpolateWithRegex } from "omnistudio/flexCardUtility";
import closeAgentErrorCase from '@salesforce/apex/capitec_ClientCareController.closeAgentErrorCase'; // Import the Apex method
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // Import for toast notifications
import hasRecallRequestPermission from '@salesforce/customPermission/RecallRequestFunctionalityPermission';
import hasCaseEscalationPermission from '@salesforce/customPermission/CaseEscalationFunctionalityPermission';

export default class ClientCareServiceMenuButtons extends OmniscriptBaseMixin(LightningElement) {
    @api recordId;
    @track showFraudOmniScript = false;
    @track showRecallRequestOmniScript = false;
    @track showCashDisputeOmniScript = false;
    @track hideServiceMenu = false;
    @track showEscalateCaseOmniScript = false;
    @track showCapitecPayOmniScript = false;
    @track caseId;

    pubsubEvent = [];
    pubsubChannel0 = '';
    pubsubChannel1 = '';

    // Returns prefill data with ContextId set to recordId
    get prefillData() {
        return {
            ContextId: this.recordId // Ensure that ContextId is set to recordId
        };
    }

    hasRecallRequestPermission = hasRecallRequestPermission;
    hasCaseEscalationPermission = hasCaseEscalationPermission;

    // Handles the 'omniscript_action' event
    handleEventAction(data) {

        switch (data.name) {
            case 'SetComplete':
                this.showFraudOmniScript = false;
                this.showRecallRequestOmniScript = false;
                this.showCashDisputeOmniScript = false;
                this.showCapitecPayOmniScript = false;
                this.showOmniScript = false;
                this.caseId = data.eventValues.split("|");
                this.hideServiceMenu = false;
                //CEDT-3555 - also remove modal type from storage
                sessionStorage.removeItem("trPreviousKeyValue_" + caseId[1].trim());
                sessionStorage.removeItem("trPreviousSelectedRows_" + caseId[1].trim());
                sessionStorage.removeItem("ccCaseId");
                sessionStorage.removeItem("modalType");

                let currentURL = window.location.href;

                let newURL = currentURL.substring(0, currentURL.indexOf("/view") + 5);

                window.location.href = newURL;

                break;
            case 'SetClientCareCaseValues':
                this.caseId = data.eventValues;
                sessionStorage.setItem("ccCaseId", this.caseId);
                break;
            case 'SetClientCareCaseValues_RR':
                this.caseId = data.eventValues;
                sessionStorage.setItem("ccCaseId", this.caseId);
                break;
            case 'PauseCardIP':
                const channelName = 'CardHoldings';
                const eventName = 'refreshEvent';
                this.refreshFlexcard(channelName, eventName);
                break;
            default:
                if (data.name === 'CANCEL') {
                    this.closeCaseWithReason();
                    this.showFraudOmniScript = false;
                    this.showRecallRequestOmniScript = false;
                    this.showCashDisputeOmniScript = false;
                    this.showCapitecPayOmniScript = false;
                    this.hideServiceMenu = false;
                }else if(data.name.includes('Step') || data.name.includes('cd')) {
                    this.handleToggle(data);
                }
        }
    }

    // Handles the 'omniscript_step' event
    handleEventStep(data) {
        this.handleToggle(data);
    }

    // CEDT-3298 - Add modal type to local storage to differentiate between cancel and save for later
    handleToggle(data){
        switch (data.name) {
            case 'Step1':
                sessionStorage.setItem("modalType", 'Cancel');
                this.toggleCancelButton(true);
                break;
            case 'Step1_RR':
                sessionStorage.setItem("modalType", 'Cancel');
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

    // Triggers a reload card event on a flexcard - register the channel and event names on the flexcard
    refreshFlexcard(channelName, eventName) {
        pubsub.fire(channelName, eventName, { message: 'Trigger FlexCard Refresh' })
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

    // Handles the click on the fraud button
    handleFraudClick() {
        this.showFraudOmniScript = true;
        this.hideServiceMenu = true;
    }


    handleRecallRequestClick() {
        this.showRecallRequestOmniScript = true;
        this.hideServiceMenu = true;
    }

    handleCashDisputeClick() {
        this.showCashDisputeOmniScript = true;
        this.hideServiceMenu = true;
    }
    handleEscalateCaseClick(){
        this.showEscalateCaseOmniScript = true;
        this.hideServiceMenu = true;
    }
    handleCapitecPayCaseClick(){
        this.showCapitecPayOmniScript = true;
        this.hideServiceMenu = true;
    }

    connectedCallback() {
        this.registerEvents();

        let currentURL = window.location.href;

        if(this.getParameterByName('c__instanceId', currentURL) && this.getParameterByName('c__target', currentURL)){
            let target = this.getParameterByName('c__target', currentURL);

            console.log(target);

            if(target.includes("FraudDetermination")){
                this.showFraudOmniScript = true;
                this.hideServiceMenu = true;
            }else if(target.includes("CashDisputeDetermination")){
                this.showCashDisputeOmniScript = true;
                this.hideServiceMenu = true;
            }else if(target.includes("RecallRequest")){
                this.showRecallRequestOmniScript = true;
                this.hideServiceMenu = true;
            }else if(target.includes("EscalateCase")){
                this.showEscalateCaseOmniScript = true;
                this.hideServiceMenu = true;
            }else if(target.includes("CapitecPay")){
                this.showCapitecPayOmniScript = true;
                this.hideServiceMenu = true;
            }
        }
    }

    disconnectedCallback() {
        this.unregisterEvents();

        //CEDT-3555 - clean up storage if the component is disconnected e.g. the tab is closed
        try {
            sessionStorage.removeItem("trPreviousKeyValue_" + this.caseId[1].trim());
            sessionStorage.removeItem("trPreviousSelectedRows_" + this.caseId[1].trim());
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

    getParameterByName(name, url = window.location.href) {
        name = name.replace(/[\[\]]/g, '\\$&');
        var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
            results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, ' '));
    }
}