/**
 * Created by Steffan on 26.02.2023.
 */

import {api, LightningElement, track} from 'lwc';
import {formatDate, getTransactionHistory} from 'c/capitec_FraudTHDataHandler'
import LightningAlert from "lightning/alert";

export default class Capitec_GlobalTransactionHistory extends LightningElement {

    @api recordId;

    @track jsonString;
    @track itemsToDisplay;
    @track startDate;
    @track endDate;
    @track showSpinner = false;
    @track disableActions = true;
    
    async connectedCallback() {
        this.getLast7Dates();
    }

    async getLast7Dates(event){
        let today = new Date();
        let sevenDaysAgo = new Date(today);
        sevenDaysAgo.setDate(today.getDate() - 7);

        this.startDate = await formatDate(sevenDaysAgo);
        this.endDate = await formatDate(today);
    }


    async getLast30Dates(event){
        var today = new Date();
        var thirtyDaysAgo = new Date(today);
        thirtyDaysAgo.setDate(today.getDate() - 30);

        this.startDate = await formatDate(thirtyDaysAgo);
        this.endDate = await formatDate(today);
    }

    async getLastyear(event){
        var today = new Date();
        var yearAgo = new Date(today);
        yearAgo.setDate(today.getDate() - 365);

        this.startDate = await formatDate(yearAgo);
        this.endDate = await formatDate(today);
    }

    async handleGetTransactions(event){
        this.showSpinner = true;
        this.itemsToDisplay = [];
        let startDateVal = this.template.querySelector('[data-id="startDateInput"]').value;
        let endDateVal = this.template.querySelector('[data-id="endDateInput"]').value;
        let FinNumber = this.template.querySelector('[data-id="fin-id"]').value;
        const regex = /^\d{7,}$/;

        if(startDateVal > endDateVal){
            await this.displayWrongDateWarning();
            this.itemsToDisplay = null;
            this.showSpinner = false;
            return;
        }

        if (!regex.test(FinNumber)) {
            await this.displayAccountNumberWarning();
            this.itemsToDisplay = null;
            this.showSpinner = false;
            return;
        }
        await this.performGetCallouts(FinNumber, this.recordId, startDateVal, endDateVal);

        this.showSpinner = false;
    }


    async displayWrongDateWarning(){
        await LightningAlert.open({
            message: 'Please ensure that the Start Date is before the End Date',
            theme:'warning',
            label: 'Warning',
        });
    }
    async displayAccountNumberWarning(){
        await LightningAlert.open({
            message: 'Account number must be at least 8 digits long and contain only numbers.',
            theme:'warning',
            label: 'Warning',
        });
    }

    async performGetCallouts(FinNumber, caseId, startDateVal, endDateVal) {
        try {
            const result = await getTransactionHistory(FinNumber, caseId, startDateVal, endDateVal);
            this.disableActions = false;
            this.itemsToDisplay.push(...result);
        } catch (e) {
            console.log(JSON.stringify(e.message));
        }
    }
}