/**
 * Created by dawid on 08.11.2023.
 */

import {api, LightningElement, track} from 'lwc';
import {transactionHistoryGetAccs,formatDate, getStartDate, getTransactionHistory, postApplyActions, postChase, fetchConsultantCPByCaseId, preparePopupsContent} from 'c/capitec_RetailComplaintsTHDataHandler'
import LightningAlert from "lightning/alert";
import retailComplaintsModal from 'c/capitec_RetailComplaintsModal';
import { updateRecord } from 'lightning/uiRecordApi'; //FFSF-448 - Added uiRecordApi to update the case record
import gethandleFlagToCase from '@salesforce/apex/Capitec_RetailComplaintsTHController.gethandleFlagToCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CapitecRetailComplaintsCaseActions extends LightningElement {

    @api recordId;

    @track jsonString;
    @track itemsToDisplay;
    @track financialAccountsNumbers;
    @track startDate;
    @track endDate;
    @track comboboxValue
    @track showSpinner = false;
    @track consultantCP
    @track disableActions = true;

    async connectedCallback() {
        this.handleInitiateData(this.recordId);
        this.handleGetTransactions = this.handleGetTransactions.bind(this);
        this.consultantCP = await fetchConsultantCPByCaseId(this.recordId);
    }

    //FFSF-461 get Dates to update filter
    async getLast7Dates(event) {
        var today = new Date();
        var sevenDaysAgo = new Date(today);
        sevenDaysAgo.setDate(today.getDate() - 7);
        var todayDate = new Date(today);

        var startDateInput = this.template.querySelector('[data-id="startDateInput"]');
        var endDateInput = this.template.querySelector('[data-id="endDateInput"]');

        await formatDate(sevenDaysAgo).then(result => {
            console.log(result);
            startDateInput.value = result;
        })

        await formatDate(todayDate).then(result => {
            console.log(result);
            endDateInput.value = result;
        })
    }

    //FFSF-461 get Dates to update filter
    async getLast30Dates(event) {
        var today = new Date();
        var thirtyDaysAgo = new Date(today);
        thirtyDaysAgo.setDate(today.getDate() - 30);
        var todayDate = new Date(today);

        var startDateInput = this.template.querySelector('[data-id="startDateInput"]');
        var endDateInput = this.template.querySelector('[data-id="endDateInput"]');

        await formatDate(thirtyDaysAgo).then(result => {
            console.log(result);
            startDateInput.value = result;
        })

        await formatDate(todayDate).then(result => {
            console.log(result);
            endDateInput.value = result;
        })
    }

    async handleGetTransactions(event) {
        this.showSpinner = true;
        this.itemsToDisplay = [];
        let startDateVal = this.template.querySelector('[data-id="startDateInput"]').value;
        let endDateVal = this.template.querySelector('[data-id="endDateInput"]').value;
        let comboBoxVal = this.template.querySelector('[data-id="combobox-fin-id"]').value;
        let calloutAccountNumbers = [];

        if (startDateVal > endDateVal) {
            await this.displayWrongDateWarning();
            this.itemsToDisplay = null;
            this.showSpinner = false;
            return;
        }

        calloutAccountNumbers = this.selectAccNumberForCallout(comboBoxVal);
        await this.performGetCallouts(calloutAccountNumbers, this.recordId, startDateVal, endDateVal);

        this.showSpinner = false;
    }



    async handleApplyActions(event) {
        this.showSpinner = true;
        console.log('***' + JSON.stringify(this.consultantCP));

        let itemsToFraudHoldChaseFlag = {
            transactions: [],
            caseNumber: this.recordId,
            consultantIdentifier: this.consultantCP
        }; // this should link to the consultant CP number

        this.itemsToDisplay.forEach(item => {
            if ((item.fraudFlagged !== item.newFraudFlagged)) {
                itemsToFraudHoldChaseFlag.transactions.push(item);
            }
        });

        if (itemsToFraudHoldChaseFlag.transactions.length < 1) {
            await this.displayNoRecordsSelectedWarning();
            this.showSpinner = false;
            return;
        }

        let modalContent = preparePopupsContent(itemsToFraudHoldChaseFlag);
        let userConfirmed = await this.showModal(modalContent, 'You have marked records to Flag, do you wish to proceed?');
        let promises = [];
        if (!userConfirmed) return;

        promises.push(postApplyActions(itemsToFraudHoldChaseFlag).then(result => {
            try {
                if (JSON.stringify(result) === "204" || JSON.stringify(result) === "200") {
                    LightningAlert.open({
                        message: 'Success',
                        theme: 'success',
                        label: 'Success',
                    });
                    this.calculateTotalFlaggedTransactionValueAndUpdateCase(); //FFSF-448 - Added function to update the Total Amount Defrauded on the Case record
                    this.handleGetTransactions('');
                } else {
                    LightningAlert.open({
                        message: 'An issue has occured',
                        theme: 'warning',
                        label: 'One of more actions did not succeed. Please try again later',
                    });
                    this.handleGetTransactions('');
                }
            } catch (e) {
                console.log(JSON.stringify(e.message));
            }
        }));

        // Wait for all promises to resolve
        await Promise.all(promises);
        this.showSpinner = false;
    }

    //FFSF-448 - Added function to update the Total Amount Defrauded on the Case record
    async calculateTotalFlaggedTransactionValueAndUpdateCase() {

        let FlaggedTotal = 0;
        this.itemsToDisplay.forEach(item => {
            if (item.fraudFlagged) {
                FlaggedTotal += item.amount;
            }
        });

        const fields = {};
        fields['Id'] = this.recordId;
        fields['Total_Amount_Defrauded__c'] = FlaggedTotal;

        const recordInput = {
            fields
        };

        try {
            await updateRecord(recordInput);
            console.log('Total Amount Defrauded successfully: ', FlaggedTotal);
        } catch (error) {
            console.error('Error updating Total Amount Defrauded: ', error.body.message);
        }
    }

    async handlePostChased(event) { //FFSF-407 - Chase Flag moved to fire under the Apply Actions Button

        this.showSpinner = true;
        let itemsToChaseFlag = {
            transactions: [],
            caseNumber: this.recordId,
            consultantIdentifier: this.consultantCP
        };

        this.itemsToDisplay.forEach(item => {
            if (item.chaseFlagged !== item.newChaseFlagged) {
                itemsToChaseFlag.transactions.push(item)
            }
        });

        if (itemsToChaseFlag.transactions.length < 1) {
            await this.displayNoRecordsSelectedWarning();
            this.showSpinner = false;
            return;
        }

        let modalContent = preparePopupsContent(itemsToChaseFlag);
        let userConfirmed = await this.showModal(modalContent, 'You are about to mark selected records as chased, do You wish to proceed?');
        if (!userConfirmed) return;
        let promises = [];


        promises.push(postChase(itemsToChaseFlag).then(result => {
            try {
                // console.log(JSON.stringify(result));
                if (JSON.stringify(result) === "204" || JSON.stringify(result) === "200") {
                    LightningAlert.open({
                        message: 'Success',
                        theme: 'success',
                        label: 'Success',
                    });
                    this.handleGetTransactions('');
                } else {
                    LightningAlert.open({
                        message: 'An issue has occured',
                        theme: 'warning',
                        label: 'One of more actions did not succeed. Please try again later',
                    });
                    this.handleGetTransactions('');
                }
            } catch (e) {
                console.log(JSON.stringify(e.message));
            }
        }));

        // Wait for all promises to resolve
        await Promise.all(promises);
        this.showSpinner = false;
    }

    async showModal(modalContent, header) {
        const confirmFlag = await retailComplaintsModal.open({
            size: 'large',
            description: 'Accessible description of modal\'s purpose',
            content: modalContent,
            header: header
        });

        if (!confirmFlag) {
            this.showSpinner = false;
            return false
        }

        return true;
    }

    handleFlag(event) {
        this.itemsToDisplay[event.target.dataset.itemId].newFraudFlagged = event.target.checked;
    }

    async handleInitiateData(recordId) {
        // console.log(recordId);

        await getStartDate(recordId).then(result => {
            this.startDate = new Date(result).toISOString().split('T')[0];
            this.endDate = new Date().toISOString().split('T')[0];
        })

        await transactionHistoryGetAccs(recordId).then(result => {
            try {
                this.financialAccountsNumbers = result;
                this.comboboxValue = result[0].value;
            } catch (e) {
                console.log(JSON.stringify(e));
            }

            // console.log(JSON.stringify(result));
        });
    }
    
    async performGetCallouts(calloutAccountNumbers, caseId, startDateVal, endDateVal) {
        let promises = calloutAccountNumbers.map(accNumber => {
            return getTransactionHistory(accNumber, caseId, startDateVal, endDateVal)
                .then(result => {
                    try {
                        this.disableActions = false;
                        result.forEach(currentItem => {
                            if (currentItem.transactionDate) {
                                currentItem.transactionDate = currentItem.transactionDate.substring(0, 10);
                            }
                        });
                        this.itemsToDisplay.push(...result);
                    } catch (e) {
                        console.log(JSON.stringify(e.message));
                    }
                });
        });

        // Wait for all promises to resolve
        await Promise.all(promises);
    }



    selectAccNumberForCallout(comboBoxVal) {
        let calloutAccountNumbers = [];
        if (comboBoxVal === 'allAccounts') {

            this.financialAccountsNumbers.forEach(comboBoxAccVal => {
                calloutAccountNumbers.push(comboBoxAccVal.value);
            });
            calloutAccountNumbers.shift();

            // console.log(JSON.stringify(calloutAccountNumbers));
        } else {
            calloutAccountNumbers.push(comboBoxVal);
        }

        return calloutAccountNumbers;
    }



    async displayWrongDateWarning() {
        await LightningAlert.open({
            message: 'Please ensure that the Start Date is before the End Date',
            theme: 'warning',
            label: 'Warning',
        });
    }

    async displayNoRecordsSelectedWarning() {
        await LightningAlert.open({
            message: 'No records were selected',
            theme: 'warning',
            label: 'Warning',
        });
    }
    async displayNoTransactionsFoundWarning() {
        await LightningAlert.open({
            message: 'No transactions found for this account',
            theme: 'warning',
            label: 'Warning',
        });
    }

    async handleFlagToCase(event) {
        var selectedItems = [];
        selectedItems = this.itemsToDisplay.filter(row => row.newFraudFlagged);

        if (selectedItems.length === 0) {
            this.showToast('Error', 'Please Select a Transaction', 'error');
            return;
        }

        console.log('Selected items:', selectedItems);

        try {
            var result = await gethandleFlagToCase({
                caseId: this.recordId,
                selectedItems: selectedItems
            });
            console.log('Result from gethandleFlagToCase:', result);

            if (result === 'success') {
                this.showToast('Saved', 'Records saved successfully.', 'success');
            } else if (result === 'duplicateTransactionId') {
                this.showToast('Error', 'An existing record with the same Transaction ID exists. Please check your selection.', 'error');
            } else {
                console.log('Error result:', result);
                this.showToast('Error', result, 'error');
            }
        } catch (error) {
            console.error('Error in handleFlagToCase:', error);
            this.showToast('Error', 'An unexpected error occurred.', 'error');
        }
    }

    showToast(title, message, variant) {
        console.log('ShowToast called with:', title, message, variant);
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}