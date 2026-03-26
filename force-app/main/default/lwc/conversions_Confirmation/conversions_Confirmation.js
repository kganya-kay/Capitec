import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getCaseInfo from '@salesforce/apex/Conversions_ConfirmationController.getCaseInfo';
import returnCaseToAwaitingDoi from '@salesforce/apex/Conversions_ConfirmationController.returnCaseToAwaitingDoi';

export default class Conversions_Confirmation extends LightningElement {
     @api recordId;
    @track casRecord;

    alreadyInQueue = false;
    isLoading = true;

    connectedCallback() {
        this.loadCaseInfo();
    }

    loadCaseInfo() {
        if (!this.recordId) {
            this.isLoading = false;
            return;
        }

        getCaseInfo({ caseId: this.recordId })
            .then(result => {
                this.casRecord = result;
                this.alreadyInQueue = result?.Owner?.Name === 'Awaiting DOI Confirmation';
            })
            .catch(error => {
                console.error('Error loading case info', error);
                this.alreadyInQueue = false;
                this.showToast('Error', 'Unable to load case information', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    async handleSubmit() {
        this.isLoading = true;

        try {
            await returnCaseToAwaitingDoi({ caseId: this.recordId });

            this.showToast('Success',
                           'Case has been returned to Awaiting DOI Confirmation',
                           'success'
                          );

            this.closeAction();
        } catch (error) {
            this.showToast(
                'Error',
                error.body?.message || 'Unable to update case',
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.closeAction();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    closeAction() {r
       this.dispatchEvent(new CloseActionScreenEvent());
    }
}