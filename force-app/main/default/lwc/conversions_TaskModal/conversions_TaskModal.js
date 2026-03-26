import { LightningElement, api,wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createTask from '@salesforce/apex/Conversions_SubStatusController.createTask';
import LightningModal from 'lightning/modal';

export default class Conversions_TaskModal extends LightningModal  {

    @track subject;
    @track description;
    @track status = 'Open';
    @track dueDate;
    @track showSpinner = false;

    @api caseRecord;

    statusOptions = [
        { label: 'Open', value: 'Open' },
        { label: 'Completed', value: 'Completed' }
    ];

    get getOwnerName() {
        return this.caseRecord?.Owner?.Name || '';
    }

    get getCaseNumber() {
        return this.caseRecord?.CaseNumber || '';
    }

    connectedCallback() {
       console.log('##Task modal init:', JSON.stringify(this.caseRecord));
    }

    handleInputChange(event) {
        const field = event.target.dataset.id;
        this[field] = event.target.value;

        console.log('Field updated:', this[field]);
    }

    handleSaveTask() {
        this.showSpinner = true;

        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .filter(input => input.required)
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            this.showToast('Error', 'Please fill all required fields.', 'error');
            this.showSpinner = false;
            return;
        }

        createTask({
            subject: this.subject,
            description: this.description,
            dueDate: this.dueDate,
            caseId: this.caseRecord.Id,
            ownerId: this.caseRecord.OwnerId
        })
        .then(result => {
            if (result) {
                console.log('## Task created successfully:', result);
                this.showToast('Success', 'Task created successfully', 'success');
                this.close({ result: 'success', taskId: result });
            } else {
                this.showSpinner = false;
                this.showToast('Error', 'Failed to create task', 'error');
            }
        })
        .catch(error => {
            console.error('Error creating task:', error);
            this.showSpinner = false;
            this.showToast('Error', 'Failed to create task', 'error');
        });
    }

    closeModal() {
        this.close('cancel');
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