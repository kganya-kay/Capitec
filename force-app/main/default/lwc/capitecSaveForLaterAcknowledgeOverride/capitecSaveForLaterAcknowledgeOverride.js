import { LightningElement } from 'lwc';

export default class CapitecSaveForLaterAcknowledgeOverride extends LightningElement {
    handleFinish() {
        // Refresh the current page
        window.location.reload();
    }
}