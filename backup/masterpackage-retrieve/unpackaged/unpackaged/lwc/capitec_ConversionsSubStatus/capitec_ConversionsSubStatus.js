import { LightningElement, api,wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCaseInfo from '@salesforce/apex/Conversions_SubStatusController.getCaseInfo';
import ID_FIELD from '@salesforce/schema/Case.Id';
import SUBSTATUS_FIELD from '@salesforce/schema/Case.Sub_Status__c';
import { updateRecord } from 'lightning/uiRecordApi';
import Conversions_TaskModal from 'c/conversions_TaskModal';


export default class capitec_ConversionsSubStatus extends LightningElement {
    @api recordId;
    @api caseRecord;

    @track showSpinner = false;
    @track selectedSubStatus = '';
    @track disableButton = true;

    get options() {
        return [
            { label: 'Active', value: 'Active' },
            { label: 'Awaiting information - Client', value: 'Awaiting information - Client' },
            { label: 'Awaiting information - Branch', value: 'Awaiting information - Branch' }
        ];
    }

    @wire(getCaseInfo, { caseId: '$recordId' })
    wiredData({ data, error }) {
        if (data) {
              this.caseRecord = JSON.parse(JSON.stringify(data));
            this.selectedSubStatus = this.caseRecord.Sub_Status__c;

            console.log('##selectedSubStatus:', this.selectedSubStatus);
        } else if (error) {
            console.error(error);
        }
    }


    handleChange(event) {
        this.selectedSubStatus = event.detail.value;
        console.log('## this.selectedSubStatus:', this.selectedSubStatus);
        console.log('## this.caseRecord.Sub_Status__c:', this.caseRecord.Sub_Status__c);

        this.disableButton = !(
            this.selectedSubStatus &&
            this.selectedSubStatus !== this.caseRecord.Sub_Status__c
        );
    }
    async handleClick() {
        if (this.selectedSubStatus === 'Active') {
            this.updateCaseSubStatus();
        } else if (this.selectedSubStatus === 'Awaiting information - Client' || 
                   this.selectedSubStatus === 'Awaiting information - Branch') {
            await this.openTaskModal();
        }
    }

    async openTaskModal() {
        try {
            const result = await Conversions_TaskModal.open({
                size: 'small',
                caseRecord: this.caseRecord

            });
            if (result?.result === 'success') {
                this.updateCaseSubStatus();
            }

        } catch (error) {
            console.error('Error opening modal:', error);
        }

    }

    updateCaseSubStatus(){
        this.showSpinner = true;

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.caseRecord.Id;
        fields[SUBSTATUS_FIELD.fieldApiName] = this.selectedSubStatus;

        const recordInput = { fields };

    updateRecord(recordInput)
        .then(() => {
            console.log('## Case sub-status updated to Awaiting');
            this.showToast('Success', 'Case sub-status updated successfully!', 'success');
            this.caseRecord.Sub_Status__c = this.selectedSubStatus;
            this.showSpinner = false;
            this.disableButton = true;
        })
        .catch(error => {
            console.error('## Error updating Case sub-status:', error);
            this.showToast('Error', 'Failed to update case sub status', 'error');
            this.showSpinner = false;
        });      
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