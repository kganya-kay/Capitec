import { api, LightningElement } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class Capitec_AutoRefreshDetailView extends OmniscriptBaseMixin(LightningElement) {
    @api recordId;
    recId;

    connectedCallback() {
        if (this.recordId) {
            this.recId = this.recordId;
        } else if (this.omniJsonData?.ContextId) {
            this.recId = this.omniJsonData.ContextId;
        }

        if (this.recId) {
            // Refresh LDS Cache
            getRecordNotifyChange([{ recordId: this.recId }]);

            // Manually trigger UI refresh by reloading the view
            this.refreshLightningPage();
        }
    }

    refreshLightningPage() {
        // Refresh the Lightning Record Page using LDS
        setTimeout(() => {
            this.dispatchEvent(new CustomEvent('refreshview'));
        }, 200); // Ensures LDS updates first
    }
}