import { LightningElement, api, wire, track } from 'lwc';
import updateCaseStatus from '@salesforce/apex/Capitec_DebitOrderController.updateCaseStatus';
//import getDOIDetails from '@salesforce/apex/Capitec_DebitOrderController.getDOIDetails';
import getHolidays from '@salesforce/apex/Capitec_DebitOrderController.getHolidays';
import searchDOI from '@salesforce/apex/Capitec_DebitOrderController.searchDOI';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class Capitec_ConversionsNewDOModal extends LightningElement {
    @api showModal;
    @api editDO;
    @api caseRecord;
    @api selectedDO;
    @api showRefreshMessage;
    @api caseInProgress;

    @track disableSubmittedCode = false;
    @track recordId;
    @track disableCauseCode = false;
    @track disableWithdrawnCode = false;
    @track disableDOI = false;
    @track isSaveAndNew = false;
    @track showSpinner = false;
    @track updateCase = false;
    @track showErr = false;
    @track futureDated = false;
    @track disableSubmissionDate = false;
    @track selectedDebitOrderId;
    @track submittedCauseCode = '';
    @track dateErr = '';
    @track errorMessage = '';
    @track initiatorEmail = '';
    @track initiatorPreferredComms = '';
    @track modalTitle;
    @track modalInstruction;
    @track submissionDate;
    @track lstHolidays = [];
    @track deactivateFields = true;
    @track showOtherIssue = false;
    @track lastValidDOIssues = [];
    @track fromAccountValue = '';
    @track flagIssue = false;
    @track searchResults = [];
    @track selectedDOIId = '';

    @wire(getHolidays)
    wiredHolidays({ error, data }) {
        if (data) {
            console.error('##wiredHolidays data:', data);
             this.lstHolidays = data;
             console.error('##lstHolidays', JSON.stringify(this.lstHolidays));
            
        } else if (error) {
            console.error('Error fetching holidays', error);
        }
    }

    connectedCallback() {
        console.log('##Modal INITT:', JSON.stringify(this.selectedDO));
        this.initModal();
        this.checkDateBeforeToday();
    }

    initModal(){
        this.modalInstruction = 'Please enter the following details related to the debit order switch.';
        this.dateErr = '';
        this.selectedDebitOrderId = this.selectedDO?.Id;
        this.submissionDate = this.selectedDO?.Submission_Date__c;
        this.submittedCauseCode = this.selectedDO?.Submitted_Cause_Code__c;
        this.recordId  = this.caseRecord?.Id;
        this.deactivateFields = (this.caseRecord.Origin != 'Manual') ? false : true;
        this.fromAccountValue =  this.caseRecord?.Conversion__r?.Old_Account_Number__c;

        console.log('##INIT DO: ' + this.editDO);

        if(this.editDO){
            this.modalTitle = 'Debit Order ' + this.selectedDO.Name;
            this.futureDated = (this.selectedDO.Category__c == 'FD Debit Order Switch') ? true : false;
            this.selectedDOIName = this.selectedDO?.InitiatorName;
            this.initiatorEmail = this.selectedDO?.InitiatorEmail;
            this.initiatorPreferredComms = this.selectedDO?.Preferred_Comms__c;
            this.flagIssue = (this.selectedDO.DO_Issue__c) != null ? true : false;
            this.selectedDOIId = this.selectedDO?.Debit_Order_Initiator__c;
            
            if (!this.selectedDO.Debit_Order_Initiator__c && !this.selectedDO.Not_yet_onboarded__c) {
                this.submittedCauseCode = 'Client To Action';
            }
            else{
              this.analyseCodesToDisable();
            }

            if(this.selectedDO?.DO_Issue__c) {
                this.lastValidDOIssues = this.selectedDO.DO_Issue__c.split(';');
                this.showOtherIssue = (this.selectedDO.DO_Issue__c == 'Other') ? true : false;
            } else {
                this.lastValidDOIssues = [];
            }
        }
        else{
            this.modalTitle = 'New Debit Order';
            this.selectedDebitOrderId = null;
            this.selectedDO = null;
            this.initiatorEmail = '';
            this.initiatorPreferredComms = '';
            this.dateErr = '';
        }
        this.disableValuesBasedOnStatus();
    }

    get disableCategory() {
        return !this.caseInProgress;
    }

    checkDateBeforeToday() {
        if (!this.submissionDate) {
            return false;
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const selected = new Date(this.submissionDate);

        this.disableSubmissionDate = (selected < today) ? true : false;
    }

    /*handleDOIChange(event) {
        const currentId = Array.isArray(event.detail.value) ? event.detail.value[0] :event.detail.value;

        if (this.previousDoiId === currentId) return;

        this.previousDoiId = currentId;

        if (currentId) {
            getDOIDetails({ doiId: currentId})
                .then(result => {
                    console.log('## DOI result:'+ JSON.stringify(result))
                    this.initiatorEmail = result?.DOI_Contact_Email__c || '';
                    this.initiatorPreferredComms = result?.Preferred_Comms__c || '';
                    
                    let field = this.template.querySelector('[data-id="notOnboarded"]');

                    if (field && field.value) {
                        field.value = null;
                    }

                    this.analyseCodesToDisable();
                })
                .catch(error => {
                    console.error('Error fetching DOI details:', error);
                });
        } else {
            this.initiatorEmail = '';
            this.initiatorPreferredComms = '';
        }
    }*/

    handleSearchDOI(event) {
        if (event.key === 'Enter') {
            event.preventDefault();

            const value = event.target.value;

            if (!value || value.length < 3) {
                this.searchResults = [];
                return;
            }

            this.searchDOI(value);
        }
    }

    searchDOI(searchKey) {
        if (!searchKey || searchKey.length < 2) {
            this.searchResults = [];
            return;
        }

        searchDOI({ searchKey })
            .then(result => {
                this.searchResults = result;
            })
            .catch(error => {
                console.error(error);
            });
    }


    handleSelect(event) {
        this.selectedDOIId = event.currentTarget.dataset.id;
        this.selectedDOIName = event.currentTarget.dataset.name;
        this.initiatorEmail = event.currentTarget.dataset.email;
        this.initiatorPreferredComms = event.currentTarget.dataset.comms;

        this.searchResults = [];
    }

    disableValuesBasedOnStatus(){
        if(this.caseRecord.Status == 'In Progress'){
            this.disableCauseCode = true;

           if(this.selectedDO?.Submitted_Cause_Code__c != null ){
                this.disableSubmittedCode = false;
                this.disableWithdrawnCode = true; 
                return;
            }

            if(this.selectedDO?.Withdrawn_Cause_Code__c != null ){
                this.disableSubmittedCode = true;
                this.disableWithdrawnCode = false; 
                return;
            }
        }
        else if(this.caseRecord.Status == 'Submitted' || this.caseRecord.Status == 'Confirmed'){
            this.disableSubmittedCode = true;
            this.disableWithdrawnCode = true;
            this.disableDOI = true;
            this.disableCauseCode = false;
            this.deactivateFields = true;
            return;
        }
        else if(this.caseRecord.Status == 'Closed'){
            this.disableSubmittedCode = true;
            this.disableWithdrawnCode = true;
            this.disableDOI = true;
            this.disableCauseCode = true;
            this.deactivateFields = true;
            return;
        }
    }

    analyseCodesToDisable(){
        if (this.initiatorPreferredComms === 'CB To Email') {
            if(this.editDO){
                if(this.selectedDO?.Withdrawn_Cause_Code__c == null ){
                    this.submittedCauseCode = 'No Client Action';
                }
            }
            else{
                this.submittedCauseCode = 'No Client Action';
            }
        }
        else if (this.initiatorPreferredComms === 'Client to Switch') {
            if(this.editDO){
                if(this.selectedDO?.Withdrawn_Cause_Code__c == null ){
                    this.submittedCauseCode = 'Client to Action';
                }
            }
            else{
                this.submittedCauseCode = 'Client to Action';
            }
        }
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }


    handleSave(event) {
        this.showSpinner = true;
        this.isSaveAndNew = false;
        this.errorMessage = '';
        this.showErr = false;
    }

    handleSaveAndNew(event) {
        this.showSpinner = true;
        this.isSaveAndNew = true;
        this.errorMessage = '';
        this.showErr = false;
    }

    handleSubmit(event) {
        console.log('##SAU handleSubmit:',JSON.stringify(event.detail.fields));
        event.preventDefault();

        const inputFields = this.template.querySelectorAll('lightning-input-field');
        let isValid = true;

        inputFields.forEach(field => {
            if (!field.reportValidity()) {
                isValid = false;
            }
        });

        if (!isValid) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill in all required fields.',
                    variant: 'error'
                })
            );
            this.showSpinner = false;
            return;
        }

        if (this.dateErr !== '') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Submitted Date Incorrect',
                    message: this.dateErr,
                    variant: 'error'
                })
            );
            this.showSpinner = false;
            return;
        }

        const fields = event.detail.fields;
        fields.Debit_Order_Initiator__c = this.selectedDOIId;

        console.log('##Fields:' + JSON.stringify(fields));

        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    updateCaseStatus(statusToUpdate) {
         console.log('##SAU updateCase started')
         updateCaseStatus({ caseId: this.recordId, status: statusToUpdate })
                            .then(result => {
                                if (result) {
                                    this.showToast('Success', 'Case status updated to Confirmed', 'success');
                                } 
                                this.showSpinner = false;
                                this.closeModal();
                                window.location.reload();
                            })
                            .catch(error => {
                                console.error('Error updating case status:', error);
                                this.showSpinner = false;
                        });
    }

    handleSubmittedChange(event) {
        const value = event.detail.value;
        this.disableWithdrawnCode = !!value;
    }

    handleWithdrawnChange(event) {
        const value = event.detail.value;
        this.disableSubmittedCode = !!value;
    }
    handleConfirmationChange(event) {
        const value = event.detail.value;
        if(this.caseRecord.Status == 'Submitted' && value != null){
            this.updateCase = true;
        }
    }

    handleSuccess(event) {
        let toastMsg = (this.editDO) ? 'Debit Order Updated Successfully' : 'Debit Order Created Successfully';
        this.showToast('Success', toastMsg, 'success');

        this.refreshData();

        if (this.isSaveAndNew) {
            this.showSpinner = false;
            this.handleReset();
        }
       else if(this.updateCase){
            this.dispatchEvent(new CustomEvent('showrefreshmsg'));
            this.showSpinner = false;
            this.closeModal();
        }
        else{
            this.showSpinner = false;
            this.closeModal();
        }
    }

    handleReset() {
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }


        const caseField = this.template.querySelector('[data-id="caseField"]');
        if (caseField) {
            caseField.value = this.caseRecord?.Id;
        }
        this.recordId  = this.caseRecord?.Id;
        this.initiatorPreferredComms = '';
        this.initiatorEmail = '';
    }

    refreshData() {
       this.dispatchEvent(new CustomEvent('updatesuccess'));
    }

    handleError(event) {
        console.error('handleError INIT:', JSON.stringify(event.detail));

        this.showSpinner = false;

        this.errorMessage = '';
        this.showErr = false;

        let errorMsg = '';
        if (event.detail.output && event.detail.output.errors && event.detail.output.errors.length > 0) {
            errorMsg = event.detail.output.errors[0].message;
            this.errorMessage = errorMsg;
            this.showErr = true;
        }

        this.showToast('Validation Error', errorMsg, 'error');
        this.showSpinner = false;
    }

    //COCONV-1934
    handleSubmissionChanged(event) {
        const dateValue = event.target.value;
        if (!dateValue) return;

        const selectedDate = new Date(dateValue);
        const today = new Date();
        today.setHours(0,0,0,0);

        const maxDate = new Date(today);
        maxDate.setDate(maxDate.getDate() + 90);

        this.dateErr = '';
        this.submissionDate = selectedDate;

        if (selectedDate < today) {
            this.dateErr = 'Date cannot be earlier than today.';
            this.showToast('Submitted Date Incorrect', this.dateErr, 'error');
        }
        else if (selectedDate.getDay() === 0) {
            console.log('##sunday triggered:', selectedDate.getDay());
            this.dateErr = 'Sundays are not allowed.';
            this.showToast('Submitted Date Incorrect', this.dateErr, 'error');
        }
        else if (selectedDate > maxDate) {
            this.dateErr = 'Date cannot be more than 90 days from today.';
            this.showToast('Submitted Date Incorrect', this.dateErr, 'error');
        }
        else {
            const date = new Date(event.target.value);
            const dayMonth = date.getDate() + date.toLocaleString('default', { month: 'long' });;

            console.log('##daymonth:', dayMonth);

            if(this.lstHolidays.includes(dayMonth)) {
                this.dateErr = 'Selected date is a public holiday!';
                this.showToast('Submitted Date Incorrect', this.dateErr, 'error');
            } 
        }

        if(this.dateErr != ''){
            const inputField = this.template.querySelector('[data-id="submissionDate"]');
            if (inputField) {
                inputField.reset(); 
            }
        }
    }

    handleCategoryChanged(event){
        const value = event.target.value;

        if(value == 'FD Debit Order Switch'){
            this.futureDated = true;
        }
        else{
            this.futureDated = false;
        }
    }

    handleDOIssueChange(event) {
        let values = event.detail.value;

        if (typeof values === 'string') {
            values = values ? values.split(';') : [];
        }

        const hasOther = values.includes('Other');
        const invalid = hasOther && values.length > 1;

        const field = this.template.querySelector('[data-id="doIssue"]');

        if (invalid) {
            this.showToast(
                'Invalid selection',
                'You cannot select “Other” along with any other values. Please select only “Other” or remove it',
                'error'
            );

            if (field) {
                field.value = this.lastValidDOIssues;
            }
            return;
        }
        this.lastValidDOIssues = [...values];
        this.showOtherIssue = hasOther;
    }

    handleFlagIssueChange(event){
        this.flagIssue = event.target.checked;

        if(this.editDO == true && this.flagIssue == false){
            console.log('## Point 1');
            const field = this.template.querySelector('[data-id="doIssue"]');
            console.log('## Point 2');

            if (field) {
                field.reset();
            }
        }
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