/**
 * @description       : Cloned from the capitec_GenericTransactionHistory LWC and 
 *                      updated for use in client care omniscripts;
 *                      Handles server-side logic for the transaction history component
 * @author            : Kevin Nundran
 * @group             :
 * @last modified on  : 19-12-2024
 * @last modified by  : Cornelia Smit
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   19-11-2024   Cornelia Smit             Initial Version
 **/

import {api, LightningElement, track} from 'lwc';
import {transactionHistoryGetAccs, formatDate, getStartDate, formatTHDateDisplay, getTransactionHistory} from 'c/capitec_ClientCareTHDataHandler'
import LightningAlert from "lightning/alert";
import getHandleFlagToCase from '@salesforce/apex/Capitec_ClientCareTHController.getHandleFlagToCase';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Capitec_ClientCareTransactionHistory extends OmniscriptBaseMixin(LightningElement) {

    @api recordId;
    @api processType;
    @api serviceType;

    @track jsonString;
    @track itemsToDisplay;
    @track financialAccountsNumbers;
    @track startDate;
    @track endDate;
    @track comboboxValue
    @track showSpinner = false;
    @track disableActions = true;

    @track isRecallRequest = false;
    @track isCashDeposit = false;
    @track isCashWithdrawal = false;
    @track availableBalance = '';
    @track accounts = [];

    @track rndFormat = new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'RND',
    });

    async connectedCallback() {
        this.isRecallRequest = this.serviceType === 'Recall Request' ? true : false;
        this.isCashDeposit = this.serviceType === 'Cash Deposit' ? true : false;
        this.isCashWithdrawal = this.serviceType === 'Cash Withdrawal' ? true : false;
        this.handleInitiateData(this.recordId);
        this.handleGetTransactions = this.handleGetTransactions.bind(this);
    }

    async getLast7Dates(event) {
        var today = new Date();
        var sevenDaysAgo = new Date(today);
        sevenDaysAgo.setDate(today.getDate() - 7);
        var todayDate = new Date(today);

        var startDateInput = this.template.querySelector('[data-id="startDateInput"]');
        var endDateInput = this.template.querySelector('[data-id="endDateInput"]');

        await formatDate(sevenDaysAgo).then(result => {
            startDateInput.value = result;
        })

        await formatDate(todayDate).then(result => {
            endDateInput.value = result;
        })
    }

    async getLast30Dates(event) {
        var today = new Date();
        var thirtyDaysAgo = new Date(today);
        thirtyDaysAgo.setDate(today.getDate() - 30);
        var todayDate = new Date(today);

        var startDateInput = this.template.querySelector('[data-id="startDateInput"]');
        var endDateInput = this.template.querySelector('[data-id="endDateInput"]');

        await formatDate(thirtyDaysAgo).then(result => {
            startDateInput.value = result;
        })

        await formatDate(todayDate).then(result => {
            endDateInput.value = result;
        })
    }

    async handleGetTransactions(event) {
        this.showSpinner = true;
        
        let trPreviousKeyValueObj = null;
        let trPreviousSelectedRowsObj = null;
        if(sessionStorage.getItem("trPreviousKeyValue_" + this.recordId) !== null){
            trPreviousKeyValueObj = JSON.parse(sessionStorage.getItem("trPreviousKeyValue_" + this.recordId));
        }

        if(sessionStorage.getItem("trPreviousSelectedRows_" + this.recordId) !== null){
            trPreviousSelectedRowsObj = JSON.parse(sessionStorage.getItem("trPreviousSelectedRows_" + this.recordId));
        }

        this.itemsToDisplay = [];
        let startDateVal = null;
        let endDateVal = null;
        let comboBoxVal = null;
        if(trPreviousKeyValueObj != null && trPreviousSelectedRowsObj != null){
            startDateVal = trPreviousKeyValueObj["startDate"];
            endDateVal = trPreviousKeyValueObj["endDate"];
            comboBoxVal = trPreviousKeyValueObj["accountNumber"];
        }else{
            startDateVal = this.template.querySelector('[data-id="startDateInput"]').value;
            endDateVal = this.template.querySelector('[data-id="endDateInput"]').value;
            comboBoxVal = this.template.querySelector('[data-id="combobox-fin-id"]').value;
        }

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

    handleFlag(event) {
        if(this.isRecallRequest){
            const selectedIndex = parseInt(event.target.dataset.itemId, 10); // Get the index
            const isChecked = event.target.checked;

            if(isChecked){
                this.disableActions = false;
            }else{
                this.disableActions = true;
            }

            this.toggleCheckbox(selectedIndex, isChecked);
        }

        this.itemsToDisplay[event.target.dataset.itemId].newFraudFlagged = event.target.checked;
    }

    toggleCheckbox(selectedIndex, isChecked){
        // Retrieve the indices of checkboxes that are disabled by default
        const disabledIndexes = JSON.parse(sessionStorage.getItem('disabledIndexes')) || [];

        this.itemsToDisplay = this.itemsToDisplay.map((item, index) => {
            if (index === selectedIndex) {
                // Update the clicked checkbox's fraudFlagged state
                return { ...item, fraudFlagged: isChecked };
            }

            // Handle enabling/disabling of checkboxes
            if (isChecked) {
                // Disable other checkboxes that are not initially disabled
                return { 
                    ...item, 
                    disableFlag: disabledIndexes.includes(index) || index !== selectedIndex 
                };
            } else {
                // Re-enable all checkboxes except those initially disabled
                return { 
                    ...item, 
                    disableFlag: disabledIndexes.includes(index) 
                };
            }
        });
    }

    async handleInitiateData(recordId) {
        let trPreviousKeyValueObj = null;
        let trPreviousSelectedRowsObj = null;
        if(sessionStorage.getItem("trPreviousKeyValue_" + this.recordId) !== null){
            trPreviousKeyValueObj = JSON.parse(sessionStorage.getItem("trPreviousKeyValue_" + this.recordId));
        }

        if(sessionStorage.getItem("trPreviousSelectedRows_" + this.recordId) !== null){
            trPreviousSelectedRowsObj = JSON.parse(sessionStorage.getItem("trPreviousSelectedRows_" + this.recordId));
        }

        if(trPreviousKeyValueObj !== null){
            this.startDate = trPreviousKeyValueObj["startDate"];
            this.endDate = trPreviousKeyValueObj["endDate"];
        }else{
            await getStartDate(recordId).then(result => {
                this.startDate = new Date(result).toISOString().split('T')[0];
                this.endDate = new Date().toISOString().split('T')[0];
            })
        }

        await transactionHistoryGetAccs(recordId).then(result => {
            try {
                this.accounts = result;
                this.financialAccountsNumbers = result;
                this.comboboxValue = result[0].value;
                if(trPreviousSelectedRowsObj != null){
                    this.comboboxValue = trPreviousKeyValueObj["accountNumber"];
                }

                if(this.isRecallRequest){
                    this.availableBalance = this.rndFormat.format(result[0].detail);
                    this.accounts.forEach((element) => {
                        if((element.label.toUpperCase().includes('MAIN ACCOUNT'))){
                            this.comboboxValue = element.value;
                            this.availableBalance = this.rndFormat.format(element.detail);
                        }
                    });
                    this.availableBalance = this.availableBalance.replace("RND", "R").replace(/\s/g, "");;
                }
            } catch (e) {
                console.log(JSON.stringify(e));
            }
        });

        if(trPreviousKeyValueObj !== null && trPreviousSelectedRowsObj !== null){
            await this.handleGetTransactions(this);
        }
    }

    async performGetCallouts(calloutAccountNumbers, caseId, startDateVal, endDateVal) {
        let trPreviousSelectedRowsObj = null;
        let selectedTRMap = new Map();
        if(sessionStorage.getItem("trPreviousSelectedRows_" + this.recordId) !== null){
            trPreviousSelectedRowsObj = JSON.parse(sessionStorage.getItem("trPreviousSelectedRows_" + this.recordId));

            trPreviousSelectedRowsObj.forEach(item => {
                selectedTRMap.set(item.tranId, item);
            });
        }

        let promises = calloutAccountNumbers.map(accNumber => {
            //Remove leading zeros if processType is NOT Fraud
            const formattedAccNumber = this.processType === 'Fraud' ? accNumber : accNumber.replace(/^0+/, '');

            return getTransactionHistory(formattedAccNumber, caseId, startDateVal, endDateVal, this.processType, this.serviceType)
                .then(result => {
                    try {
                        if(!this.isRecallRequest){
                            this.disableActions = false;
                        }
                        result.forEach(currentItem => {
                            if (currentItem.transactionDateTime) {
                                const dateObj = new Date(currentItem.transactionDateTime);
                                currentItem.transactionDateFormatted = formatTHDateDisplay(dateObj);
                            }
                            if(selectedTRMap.size > 0){
                                if(selectedTRMap.get(currentItem.tranId)){
                                    currentItem.fraudFlagged = true;
                                    currentItem.newFraudFlagged = true;
                                }
                            }
                            //Add the full acc number with leading zeros for local flagging
                            currentItem.accNumberFull = accNumber;
                        });
                        this.itemsToDisplay.push(...result);

                        if(this.isRecallRequest && this.itemsToDisplay != null){
                            // Initialize sessionStorage to store initially disabled checkboxes
                            const disabledIndexes = this.itemsToDisplay
                            .map((item, index) => (item.disableFlag ? index : null))
                            .filter((index) => index !== null); // Get indices of disabled checkboxes

                            this.itemsToDisplay.forEach((item, index) => {
                                if (item.fraudFlagged) {
                                    // Call the toggleCheckbox method with the item index and fraudFlagged value
                                    this.toggleCheckbox(index, item.fraudFlagged);
                                }
                            });

                            sessionStorage.setItem('disabledIndexes', JSON.stringify(disabledIndexes));
                        }
                    } catch (e) {
                        alert(e.message);
                        console.log(JSON.stringify(e.message), e);
                    }
                });
        });

        // Wait for all promises to resolve
        await Promise.all(promises);

        //CEDT-3305 - Filter out duplicate card transactions
        this.itemsToDisplay = this.itemsToDisplay.filter(
            item => !(item.classificationType === 'CARD_AUTH_FINANCIAL' && item.tranGroupType === 'CARD_TRANSACTION')
        );

        //CEDT-3500 - enable inflow items for cash deposits
        if (this.isCashDeposit) {
            this.itemsToDisplay.forEach(item => {
                item.disableFlag = !(item.moneyIn);
            });
        }

        //CEDT-3500 - only enable cash withdrawal rows
        if (this.isCashWithdrawal) {
            this.itemsToDisplay.forEach(item => {
                item.disableFlag = item.tranGroupType === 'CASH_WITHDRAWAL' ? false : true;
            });
        }
        
        //CEDT-3261 - Sort by date desc
        this.itemsToDisplay.sort((a, b) => 
            new Date(b.transactionDateTime) - new Date(a.transactionDateTime)
        );
    }

    selectAccNumberForCallout(comboBoxVal) {
        let calloutAccountNumbers = [];
        if (comboBoxVal === 'allAccounts') {

            this.financialAccountsNumbers.forEach(comboBoxAccVal => {
                calloutAccountNumbers.push(comboBoxAccVal.value);
            });
            calloutAccountNumbers.shift();
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
        
        if (this.isRecallRequest && selectedItems.length > 1) {
            this.showToast('Error', 'Please Select only one Transaction', 'error');
            return;
        }

        try {
            var result = await getHandleFlagToCase({
                caseId: this.recordId,
                selectedItems: selectedItems
            });

            if (result === 'success') {
                this.showToast('Saved', 'Records saved successfully.', 'success');

                this.handleLocalStorage(event);
            } else if (result === 'duplicateTransactionId') {
                this.showToast('Error', 'An existing record with the same Transaction ID exists. Please check your selection.', 'error');
            } else {
                this.showToast('Error', result, 'error');
            }
        } catch (error) {
            console.error('Error in handleFlagToCase:', error);
            this.showToast('Error', 'An unexpected error occurred.', 'error');
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleLocalStorage(event){
        let data = {};  // Initialize the data object

        let trKeyValue = {
            "startDate" : this.template.querySelector('[data-id="startDateInput"]').value,
            "endDate" : this.template.querySelector('[data-id="endDateInput"]').value,
            "accountNumber" : this.template.querySelector('[data-id="combobox-fin-id"]').value
        };

        // Save key-value pair in sessionStorage
        sessionStorage.setItem("trPreviousKeyValue_" + this.recordId, JSON.stringify(trKeyValue));

        // Initialize selected items only if itemsToDisplay is valid
        var selectedItems = [];
        if (this.itemsToDisplay && this.itemsToDisplay.length) {
            selectedItems = this.itemsToDisplay.filter(row => row.newFraudFlagged);
            sessionStorage.setItem("trPreviousSelectedRows_" + this.recordId, JSON.stringify(selectedItems));
        }

        try{
            let trPreviousSelectedRows = sessionStorage.getItem("trPreviousSelectedRows_" + this.recordId);
            data["chkCashWithdrawal"] = false;
            data["chkSendCash"] = false;
            data["chkEFT"] = false;
            data["chkCard"] = false;
            if (trPreviousSelectedRows) {
                let trPreviousSelectedRowsJSON = JSON.parse(sessionStorage.getItem("trPreviousSelectedRows_" + this.recordId));
                trPreviousSelectedRowsJSON.forEach((item) => {
                    if(item.transactionType === "Withdrawal"){
                        data["chkCashWithdrawal"] = true;
                    }
                    if(item.transactionType === "Digital"){
                        data["chkSendCash"] = true;
                    }
                    if(item.transactionType === "EFT"){
                        data["chkEFT"] = true;
                    }
                    if(item.transactionType === "Card"){
                        data["chkCard"] = true;
                    }
                });
            }
        }catch(e){
            console.log(e);
        }
    }

    handleACChange(event) {
        this.accounts.forEach((element) => {
            if(event.detail.value == element.value){
                this.availableBalance = this.rndFormat.format(element.detail);
                this.availableBalance = this.availableBalance.replace("RND", "R");
            }
        });
        this.availableBalance = this.availableBalance.replace("RND", "R").replace(/\s/g, "");
    }
}