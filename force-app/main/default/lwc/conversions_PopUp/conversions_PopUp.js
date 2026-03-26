import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getCaseInfo from '@salesforce/apex/Conversions_ConfirmationController.getCaseInfo';
import returnCaseToAwaitingDoi from '@salesforce/apex/Conversions_ConfirmationController.returnCaseToAwaitingDoi';

export default class ConversionsPopUp extends LightningElement {
    _recordId;
    @track alreadyInQueue = false;
    @track isLoading = false;

    @api 
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        if (value != this ._recordId){
            this._recordId = value;
        }
        console.log('##Id set:' + this._recordId)
        this.initPopUp();
    }

    connectedCallback() {
        console.log('## case recordId:' + this.recordId);
    }


    initPopUp(){
        console.log('##Init popup:' + this._recordId)
        getCaseInfo({caseId: this.recordId})
        .then(result => {
            if (result) {
                console.log('##caseRec:' + JSON.stringify(result));

                 if (result != null & result.Owner?.Name === 'Awaiting DOI Confirmation') {
                    console.log('## Already in queue');
                    this.alreadyInQueue = true;
                    return;
                }
               
            } else {
                this.isLoading = false;
                this.showToast('Error', 'Failed to retrieve case info', 'error');
            }
        })
        .catch(error => {
            console.error('Error creating task:', error);
            this.isLoading = false;
            this.showToast('Error', 'Failed to retrieve case info', 'error');
        });
    }

    handleSubmit() {
        try {
            this.isLoading = true;
            console.log('##Record Id before submit:' + this.recordId);

            returnCaseToAwaitingDoi({caseId: this.recordId})
            .then(result => {
                if (result === true) {
                    this.showToast('Success', 'Case ownership updated to Awaiting DOI Confirmation.', 'success');
                    this.close();
                    window.location.reload();
                
                } else {
                    this.isLoading = false;
                    this.showToast('Error', 'Failed to transfer case to queue', 'error');
                }
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Failed to transfer case to queue', 'error');
            });
        } 
        catch (e) {
            this.showToast('Error', this.reduceError(e), 'error');
            this.close();
        }
    }

    handleCancel() {
        this.close();
    }

    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) return error.body.map(x => x.message).join(', ');
        return error?.body?.message || error?.message || 'Unexpected error';
    }
}