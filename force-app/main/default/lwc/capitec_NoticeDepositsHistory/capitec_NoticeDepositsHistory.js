import { LightningElement, track, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getNoticeHistories from '@salesforce/apex/capitec_NoticeDepositHistoryController.noticeHistoryCallout';
import getNoticeStatusMapping from '@salesforce/apex/capitec_NoticeDepositHistoryController.getNoticeStatusMapping';
import updateNoticeCallout from '@salesforce/apex/capitec_NoticeDepositHistoryController.updateNoticeCallout';
import updateCaseOutcome from '@salesforce/apex/capitec_NoticeDepositHistoryController.updateCaseOutcome';
import updateCase from '@salesforce/apex/capitec_NoticeDepositHistoryController.updateCase';
import CASE_OBJECT from '@salesforce/schema/Case';
import ASSIGNMENT_REASON_FIELD from '@salesforce/schema/Case.Assignment_Reason__c';

const FIELDS = ['Case.Notice_Deposit_Account_Number__c','Case.Account.CIF_Number__c', 'Case.Assignment_Reason__c']

//CECSF-201 - Improve class formatting and error handling; add async/await for navigation; remove console logs
export default class capitec_NoticeDepositsHistory extends NavigationMixin(LightningElement) {
    @track showSpinner = false;
    @track showEmailOnParent = false;
    @track noticePeriod;
    @track selectedNoticeId;
    @track selectedNoticeStatus;
    @track caseOutcome;
    @track disableInvalidBtn = false;
    @track assignmentReason;
    
    @track assignmentReasonOptions = []; //CECSF-200 - store Assignment reason picklist values
    @track hasError = false;

    @api recordId;
    @api accountNumber;
    @api cifNumber;
    @api errorMessage;

    @track noticeHistories = [];
    @track statusNoticeStatusMap = {};

    //CECSF-200 - retrieve case object info and Assignment reason picklist values
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ASSIGNMENT_REASON_FIELD })
    wiredPicklistValues({ error, data }) {
        if (data) {
            const filteredValues = data.values.filter(option => option.value !== 'Unable to submit withdrawal'); // CECSF-200 - Filter out the undesired option
            this.assignmentReasonOptions = filteredValues;
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        this.showSpinner = true;
        if (data) {
            this.accountNumber = data.fields.Notice_Deposit_Account_Number__c?.value || null;
            this.cifNumber = data.fields.Account?.value.fields.CIF_Number__c?.value || null;
            this.assignmentReason = data.fields.Assignment_Reason__c?.value || null;
            this.handleNoticeDepositHistoryCallout();
        } else if (error) {
            this.showSpinner = false;
            console.error('Error fetching data: ' + error);
        }
    }

    @wire(getNoticeStatusMapping)
    wiredStatusNoticeStatusMap({ error, data }) {
        if (data) {
            this.statusNoticeStatusMap = data;
        } else if (error) {
            console.error('Error fetching status notice status map:', error);
        }
    }

    connectedCallback() {
        // Component initialization code
    }

    handleFlag(event) {
        this.selectedNoticeId = event.target.dataset.itemId || null;
        this.selectedNoticeStatus = event.target.dataset.status || null;
        this.disableInvalidBtn = event.target.checked;

        if (!this.disableInvalidBtn) {
            this.selectedNoticeId = null;
            this.selectedNoticeStatus = null;
        }

        const updatedNoticeHistories = this.noticeHistories.map(item => ({
            ...item,
            selectedCheckbox: item.noticeReferenceId === this.selectedNoticeId,
            disabled: !!this.selectedNoticeId && item.noticeReferenceId !== this.selectedNoticeId,
        }));
        this.noticeHistories = updatedNoticeHistories;
    }

    async handleInvalidRequest() {
        this.showSpinner = true;
        if (this.selectedNoticeStatus === 'Paid out') {
            this.caseOutcome = 'Invalid - Paid Out';
        } else if (this.selectedNoticeStatus === 'Cancelled') {
            this.caseOutcome = 'Invalid - Cancelled';
        }
        await this.handleUpdateCaseOutcome();
    }

    //CECSF-201 - Add async/await for page navigation
    async handleContinue() {
        this.showSpinner = true;
        this.hasError = false;
        try {
            //No notice selected and 'Continue' is clicked --> launch email OR update status
            if (this.selectedNoticeId == null && this.selectedNoticeStatus == null) {
                await this.showModal(false);
            } else if (this.selectedNoticeStatus !== 'Pending') {
                await this.handleInvalidRequest();
            } else if (this.selectedNoticeStatus === 'Pending') {
                await this.updateCaseUUID();
            }

            if (['Cancelled', 'Paid out'].includes(this.selectedNoticeStatus)) {
                if (!this.hasError) {
                    this.navigateToCaseDetails();
                }
            } else {
                await this.waitForModalClose();
                this.navigateToCaseDetails();
            }
        } catch (error) {
            console.error('Error in handleContinue: ', error);
        }
    }
    //CECSF-201 - Wait for event from Notice Deposit Modal for navigation
    waitForModalClose() {
        return new Promise((resolve) => {
            const modalComponent = this.template.querySelector('c-capitec-_-notice-deposit-modal');
            if (modalComponent) {
                modalComponent.addEventListener('modalclose', resolve);
            }
        });
    }
    //CECSF-201 - Add page navigation to Details tab
    navigateToCaseDetails() {
        const baseUrl = window.location.origin;
        const url = `${baseUrl}/lightning/r/Case/${this.recordId}/view?c__tabName=Details`;
        window.location.href = url;
    }

    async handleUpdateCaseOutcome() {
        const result = await updateCaseOutcome({ caseId: this.recordId, status: this.caseOutcome });
        this.showSpinner = false;
        
        if (result === 'Success') {
            this.showToast('Success', 'Outcome updated successfully!', 'success');
        } else {
            this.showToast('Error', `Failed to update outcome. ${result}`, 'error');
            this.hasError = true; // CECSF-201 - if true, do not navigate to case details
        }
    }

    async handleNoticeAmendCallout() {
        try {
            const result = await updateNoticeCallout({ accNumber: this.accountNumber, accCIFKey: this.cifNumber, noticeRefId: this.selectedNoticeId });
            this.showSpinner = false;
            //CECSF-376 - show response error in toast
            if(result !== null && result.includes('Error')){
                this.showToast('Error', result, 'error');
            }
            else {
                const resultJSON = JSON.parse(result);
                //CECSF-378 - fix JSON node name
                if (resultJSON?.noticeDepositInstructions) {
                    this.caseOutcome = 'Successful';
                    await this.showModal(true);
                } else {
                    this.assignmentReason = 'Unable to submit withdrawal';
                    await this.showModal(false);
                }
            } 
        } 
        catch (error) {
            console.error('Error in handleNoticeAmendCallout: ', error);
            this.hasError = true;
        }
    }

    async handleNoticeDepositHistoryCallout() {
        //CECSF-376: Add try-catch for error handling; show toast if error
        try {
            const result = await getNoticeHistories({ accNumber: this.accountNumber, accCIFKey: this.cifNumber });
            this.showSpinner = false;

            if(result.includes('Error')){
                this.showToast('Error', result, 'error');
            }
            else{
                const resultJSON = JSON.parse(result);
                this.noticePeriod = resultJSON.noticePeriod || null;
                this.noticeHistories = (resultJSON.noticeDepositInstructions || []).map(item => {
                    const paymentDate = new Date(item.paymentDate);
                    const today = new Date();
                    const status = this.statusNoticeStatusMap[item.noticeStatus];
                    const isPending = status === 'Pending';
                    //CECSF-201 - add colour to status text
                    const statusClass = status === 'Paid out' ? 'custom-text-green' :
                        (status === 'Pending' ? 'custom-text-yellow' :
                        (status === 'Cancelled' ? 'custom-text-red' : ''));
                    return {
                        ...item,
                        showNotice: paymentDate < today, // Business rule: Only past notices are shown on the table
                        noticeStatus: status,
                        isPendingCheckbox: isPending,
                        statusClass,
                    };
                });
            }

        } catch (error) {
            this.showSpinner = false;
            console.error('Error in retrieving notice deposit histories: ', error);
        }
    }

    async updateCaseUUID() {
        try {
            const caseRecord = { sobjectType: 'Case', Id: this.recordId, Notice_Deposit_UUID__c: this.selectedNoticeId };
            const result = await updateCase({ caseObj: caseRecord });
            if (result !== 'Success') {
                this.showSpinner = false;
                this.showToast('Error', `Failed to update UUID. ${result}`, 'error');
                this.hasError = true;
            } else {
                await this.handleNoticeAmendCallout();
            }
        } catch (error) {
            console.error('Error in updateCaseUUID: ', error);
            this.hasError = true;
        }
    }

    showModal(success) {
        return new Promise((resolve) => {
            const modalComponent = this.template.querySelector('c-capitec-_-notice-deposit-modal');
            if (modalComponent) {
                this.showSpinner = false;
                modalComponent.isShowModal = true;
                modalComponent.caseOutcome = this.caseOutcome;
                modalComponent.isSuccess = success;
                modalComponent.showSpinner = false;
                modalComponent.assignmentReason = this.assignmentReason;
                modalComponent.confirmEvidence = (this.selectedNoticeId == null) ? true : false; //CECSF-201 - true if notice selected
                modalComponent.assignmentReasonOptions = this.assignmentReasonOptions; //CECSF-200 - pass filtered picklist values to modal
            }
            resolve();
        });
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(toastEvent);
    }

    handleShowEmail(event) {
        this.showEmailOnParent = event.detail.value;
        this.assignmentReason = event.detail.reason;
        this.showEmail();
    }

    showEmail() {
        this.showSpinner = false;
        setTimeout(() => {
            const emailComponent = this.template.querySelector('c-noticedeposit-email-quick-action[data-id="emailQuickAction"]');
            if (emailComponent) {
                emailComponent.assignmentReason = this.assignmentReason;
                emailComponent.invoke();
            }
        }, 0);
    }
}