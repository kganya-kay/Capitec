import { LightningElement, api,wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getConversionInfo from '@salesforce/apex/Conversions_SubStatusController.getConversionInfo';

export default class Conversions_ClosureReason extends LightningElement {

    @api recordId;
    @track conversionId;
    @track conversionRecord;

    @track disableReason = false;
    @track showSpinner = false;
    @track disableSubmit = true;

    @wire(getConversionInfo, { caseId: '$recordId' })
    wiredData({ data, error }) {
        if (data) {
            console.log('##SAU get conversion record:', JSON.stringify(data));
            this.conversionRecord = data;
            this.conversionId = this.conversionRecord?.Id || null;
            this.disableReason = !!this.conversionRecord.Case_Closure_Reason__c;

            console.log('##disableReason:', this.disableReason);
        } else if (error) {
            console.error(error);
        }
    }

    handleSuccess() {
        this.showSpinner = false;
        this.disableSubmit = true;
        this.disableReason = true;
        this.showToast('Success', 'Case Closure Reason updated successfully!', 'success');
    }

    handleSubmit() {
        this.showSpinner = true;
    }

    handleReasonChange(event){
        console.log('## reason triggered :' + event.target.value);
        this.disableSubmit = (this.conversionRecord.closure_reason__c != event.target.value) ? false : true;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}