/**
 * Created by Blusky on 08.05.2024.
 */

import {api, LightningElement, track} from 'lwc';
import {transactionHistoryGetAccs,formatDate, getStartDate, getTransactionHistory, postApplyActions, postChase, fetchConsultantCPByCaseId, preparePopupsContent} from 'c/capitec_FraudTHDataHandler'
import LightningAlert from "lightning/alert";
import fraudModal from 'c/capitec_FraudModal';


export default class Capitec_FraudGeneralTransactionHistoryV0 extends LightningElement {

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
    async getLast7Dates(event){
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
    async getLast30Dates(event){
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

    async handleGetTransactions(event){
        this.showSpinner = true;
        this.itemsToDisplay = [];
        let startDateVal = this.template.querySelector('[data-id="startDateInput"]').value;
        let endDateVal = this.template.querySelector('[data-id="endDateInput"]').value;
        let comboBoxVal = this.template.querySelector('[data-id="combobox-fin-id"]').value;
        let calloutAccountNumbers = [];

        if(startDateVal > endDateVal){
            await this.displayWrongDateWarning();
            this.itemsToDisplay = null;
            this.showSpinner = false;
            return;
        }

        calloutAccountNumbers = this.selectAccNumberForCallout(comboBoxVal);
        await this.performGetCallouts(calloutAccountNumbers, this.recordId, startDateVal, endDateVal);

        this.showSpinner = false;
    }



    async handleApplyActions(event){
        this.showSpinner = true;
        console.log('***' + JSON.stringify(this.consultantCP));

        let itemsToFraudHoldChaseFlag = {transactions : [], caseNumber : this.recordId, consultantIdentifier : this.consultantCP}; // this should link to the consultant CP number

        this.itemsToDisplay.forEach(item => {
           if((item.fraudFlagged !== item.newFraudFlagged) || (item.holdFlagged !== item.newHoldFlagged) || (item.chaseFlagged !== item.newChaseFlagged)){ //FFSF-407 - Chase Flag added to the condition
               itemsToFraudHoldChaseFlag.transactions.push(item);
           }
        });

        if (itemsToFraudHoldChaseFlag.transactions.length < 1){
            await this.displayNoRecordsSelectedWarning();
            this.showSpinner = false;
            return;
        }

        let modalContent = preparePopupsContent(itemsToFraudHoldChaseFlag);
        let userConfirmed = await this.showModal(modalContent, 'You have marked records to Flag, Hold or Chase, do You wish to proceed?');
        let promises = [];
        if(!userConfirmed) return;

        promises.push(postApplyActions(itemsToFraudHoldChaseFlag).then(result => {
            try{
                if (JSON.stringify(result) === "204" || JSON.stringify(result) === "200"){
                    LightningAlert.open({
                        message: 'Success',
                        theme:'success',
                        label: 'Success',
                    });
                    this.handleGetTransactions('');
                }
                else{
                    LightningAlert.open({
                        message: 'An issue has occured',
                        theme:'warning',
                        label: 'One of more actions did not succeed. Please try again later',
                    });
                    this.handleGetTransactions('');
                }
            }
            catch (e){
                console.log(JSON.stringify(e.message));
            }
        }));

        // Wait for all promises to resolve
        await Promise.all(promises);
        this.showSpinner = false;
    }



    async handlePostChased(event){ //FFSF-407 - Chase Flag moved to fire under the Apply Actions Button

        this.showSpinner = true;
        let itemsToChaseFlag = {transactions : [], caseNumber : this.recordId, consultantIdentifier : this.consultantCP};

        this.itemsToDisplay.forEach(item => {
            if(item.chaseFlagged !== item.newChaseFlagged){
                itemsToChaseFlag.transactions.push(item)
            }
        });
        
        if (itemsToChaseFlag.transactions.length < 1){
            await this.displayNoRecordsSelectedWarning();
            this.showSpinner = false;
            return;
        }

        let modalContent = preparePopupsContent(itemsToChaseFlag);
        let userConfirmed = await this.showModal(modalContent, 'You are about to mark selected records as chased, do You wish to proceed?');
        if(!userConfirmed) return;
        let promises = [];


        promises.push(postChase(itemsToChaseFlag).then(result => {
            try{
                // console.log(JSON.stringify(result));
                if (JSON.stringify(result) === "204" || JSON.stringify(result) === "200"){
                    LightningAlert.open({
                        message: 'Success',
                        theme:'success',
                        label: 'Success',
                    });
                    this.handleGetTransactions('');
                }
                else{
                    LightningAlert.open({
                        message: 'An issue has occured',
                        theme:'warning',
                        label: 'One of more actions did not succeed. Please try again later',
                    });
                    this.handleGetTransactions('');
                }
            }
            catch (e){
                console.log(JSON.stringify(e.message));
            }
        }));

        // Wait for all promises to resolve
        await Promise.all(promises);
        this.showSpinner = false;
    }



    async showModal(modalContent, header){
        const confirmFlag = await fraudModal.open({
            size: 'large',
            description: 'Accessible description of modal\'s purpose',
            content: modalContent,
            header: header
        });

        if(!confirmFlag){
            this.showSpinner = false;
            return false
        }

        return true;
    }
    

    
    handleFlag(event){
        this.itemsToDisplay[event.target.dataset.itemId].newFraudFlagged = event.target.checked;
    }



    handleHold(event){
        this.itemsToDisplay[event.target.dataset.itemId].newHoldFlagged = event.target.checked;
    }



    handleChase(event){
        this.itemsToDisplay[event.target.dataset.itemId].newChaseFlagged = event.target.checked;
    }



    async handleInitiateData(recordId){
        // console.log(recordId);

        await getStartDate(recordId).then(result => {
            this.startDate = new Date(result).toISOString().split('T')[0];
            this.endDate = new Date().toISOString().split('T')[0];
        })

        await transactionHistoryGetAccs(recordId).then(result =>{
            try{
                this.financialAccountsNumbers = result;
                this.comboboxValue = result[0].value;
            }
            catch (e){
                console.log(JSON.stringify(e));
            }

            // console.log(JSON.stringify(result));
        });
    }



    async performGetCallouts(calloutAccountNumbers, caseId, startDateVal, endDateVal){
        let promises = calloutAccountNumbers.map(accNumber => {
            return getTransactionHistory(accNumber, caseId, startDateVal, endDateVal)
                .then(result => {
                    try{
                        this.disableActions = false;
                        this.itemsToDisplay.push(...result);
                    }
                    catch (e){
                        console.log(JSON.stringify(e.message));
                    }
                });
        });

        // Wait for all promises to resolve
        await Promise.all(promises);
    }



    selectAccNumberForCallout(comboBoxVal){
        let calloutAccountNumbers = [];
        if(comboBoxVal === 'allAccounts'){

            this.financialAccountsNumbers.forEach(comboBoxAccVal => {
                calloutAccountNumbers.push(comboBoxAccVal.value);
            });
            calloutAccountNumbers.shift();

            // console.log(JSON.stringify(calloutAccountNumbers));
        }
        else{
            calloutAccountNumbers.push(comboBoxVal);
        }

        return calloutAccountNumbers;
    }



    async displayWrongDateWarning(){
        await LightningAlert.open({
            message: 'Please ensure that the Start Date is before the End Date',
            theme:'warning',
            label: 'Warning',
        });
    }

    async displayNoRecordsSelectedWarning(){
        await LightningAlert.open({
            message: 'No records were selected',
            theme:'warning',
            label: 'Warning',
        });
    }

}