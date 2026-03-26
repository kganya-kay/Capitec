/**
 * Created by dawid on 13.04.2023.
 */

import {api, track, LightningElement} from 'lwc';
import getFinancialAccountsNumbers from  '@salesforce/apex/Capitec_TransactionHistoryController.getFinancialAccountsNumbers';
import getClientTransactionHistory from  '@salesforce/apex/Capitec_TransactionHistoryController.getClientTransactionHistory';
import getDateRange from  '@salesforce/apex/Capitec_TransactionHistoryController.getDateRange';
import flagTransactions from  '@salesforce/apex/Capitec_TransactionHistoryController.flagTransactions';
import unflagTransactions from  '@salesforce/apex/Capitec_TransactionHistoryController.unflagTransactions';
import updateFlaggedTransactionTotalValue from  '@salesforce/apex/Capitec_TransactionHistoryController.updateFlaggedTransactionTotalValue';
import LightningConfirm from 'lightning/confirm';
import LightningAlert from 'lightning/alert';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

const FLAG_TRANSACTION_ACTION = 'flagTransaction';
const HOLD_FUNDS_ACTION = 'holdFunds';
const STYLING_ATTRIBUTE = 'c-capitec_transactionhistorylistview_capitec_transactionhistorylistview';
const FINANCIAL_ACCOUNT_RETRIEVE_ERROR = 'Could not retrieve any products numbers';

const filename = 'data.csv';
const mimeType = 'text/plain';
export default class CapitecTransactionHistoryListView extends OmniscriptBaseMixin(LightningElement) {

    @api recordId;
    @track elementsInitialized = false;

    @track messageModalHeader
    @track messageModalMessage
    @track showTable = false;
    @track showError = false;
    @track startDate;
    @track endDate;
    @track financialAccountsNumbers;
    @track comboboxValue = 'new';

    @track loadTable = false;
    @track result;
    @track csvData = [];

    accountNumbers = [];
    flagCheckboxesById = new Map();
    holdFundsCheckboxesById = new Map();
    blockAccountCheckboxesById = new Map();
    selectCodeOptions = [];


    connectedCallback() {
        this.injectContext();

        let today = new Date();
        this.endDate = today.toISOString();
        this.financialAccountsNumbers = [];

        getFinancialAccountsNumbers({caseId : this.recordId}).then(result => {
            console.log(result);
            if(result[0] === '500'){
                this.financialAccountsNumbers.push({
                    value : FINANCIAL_ACCOUNT_RETRIEVE_ERROR,
                    label : FINANCIAL_ACCOUNT_RETRIEVE_ERROR,
                });
                this.hideSpinner();
                return;
            }

            this.financialAccountsNumbers = [{value: 'all', label : 'All Accounts'}];
            result.forEach(accNumber => {
                this.financialAccountsNumbers.push({value : accNumber, label : accNumber});
                this.accountNumbers.push(accNumber);
            })

            this.comboboxValue = this.financialAccountsNumbers[0].value;
            this.hideSpinner()
        }).catch(e => {
            console.log(e.message);
            this.hideSpinner()
        });


        getDateRange({caseId: this.recordId}).then(result => {
            console.log(result);
            this.startDate = new Date(result).toISOString() ;
        }).catch(e => {
            console.log(e);
        })


    }

    renderedCallback() {
        // this.showSpinner()
        if(this.loadTable){
            this.handleResultDate(this.result);
        }
        // this.hideSpinner();
    }

    async refreshComponent(){

        if(new Date(this.startDate) > new Date(this.endDate)){
            await LightningAlert.open({
                message: 'Please ensure that "From Date" is earlier than or equal to "To Date".',
                theme:'warning',
                label: 'Wrong date',
            });
            return;
        }

        this.showSpinner();
        this.clearScreen();

        //need to make copy of the initialized account numbers array so that when the combobox has a single value selected
        //we can handle that through firing a loop for a single element array
        //also need to work on a local results aggregator and only update this.result at the end of the function because the component will re-render as soon as this value is updated,
        //yet we still need to wait for the rest of the calls to finish before the component should re-render

        let accNumberCombobox = this.template.querySelector('[data-id="combobox-fin-id"]');
        let accNumbers = this.accountNumbers;
        let resultsContainer = {
            transactions : []
        };

        if(accNumberCombobox.value !== 'all') {
            accNumbers = [accNumberCombobox.value];
        }

        //asynchronous server side calls doing REST callouts with await so that we can get all the necessary transactions with much lesser risk of running into limits issue
        //promise will be returned as resolved if response 200 and rejected when anything other but that

        for(const accNumber of accNumbers){
            try{
                let result = await this.getTransactionsInAsync(accNumber);

                if(resultsContainer.transactions.length === 0){
                    resultsContainer = result;
                }
                else{
                    if(typeof result.transactions !== 'undefined' && typeof resultsContainer.transactions !== 'undefined'){
                        resultsContainer.transactions = (resultsContainer.transactions.concat(result.transactions));
                    }
                }
            }
            catch (failedCallout){

                let transactionElement = {
                    accountNumber: accNumber,
                    transactionDate : (' -- error while retrieving data --'),
                    transactionCode : ('status code: ' + (failedCallout.statusCode)),
                    originalDescription : '',
                    teller : '',
                    moneyIn : '',
                    balance : '',
                    transferAccount : '',
                    transTypeDesc : '',
                    statementDescription : '',
                    branch : '',
                    amount : '',
                    channel : ''
                }

                resultsContainer.transactions.push(transactionElement);
            }

        }

        this.result = resultsContainer;
        this.loadTable = true;
        this.showTable = true;

        this.hideSpinner();
    }

    async getTransactionsInAsync(accNumber){
        try{
            let result = await getClientTransactionHistory({finAccountNumber : accNumber, startDate : this.startDate, endDate : this.endDate});
            if(result.statusCode !== 200){
                return Promise.reject(result);
            }
            return Promise.resolve(result);
        }
        catch (e){
            return Promise.reject(e);
        }
    }

    handleSaveCSV(){
        try{
            const csvContent = this.csvData.join('\n');
            const blob = new Blob([csvContent], { type: mimeType });
            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = filename;
            link.style.display = 'none';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
        catch (error){
            console.log(error.message);
        }
    }

    handleResultDate(result){

        this.flagCheckboxesById = new Map();
        this.holdFundsCheckboxesById = new Map();

        try{
            let transactionTable = this.template.querySelector('[data-id="transactions-table"]');
            this.csvData = [];
            this.csvData.push(this.newCSVDataWithHeaders());

            result.transactions.forEach(transaction =>{
                let newCSVRow = this.createCSVRow(transaction);
                this.csvData.push(newCSVRow);
                transactionTable.appendChild(this.createTableRow(transaction));
            })

        }catch(error){
            this.showErrorAlarm(error.message);
        }
        this.loadTable = false;

        return Promise.resolve();
    }

    newCSVDataWithHeaders(){
        let newCSVHeaders = [];

        newCSVHeaders.push('Account Number');
        newCSVHeaders.push('Transaction Date');
        newCSVHeaders.push('Transaction Code');
        newCSVHeaders.push('Transaction Description');
        newCSVHeaders.push('Teller Name');
        newCSVHeaders.push('Value Inwards');
        newCSVHeaders.push('Balance');
        newCSVHeaders.push('Transfer account number');
        newCSVHeaders.push('Transfer Product');
        newCSVHeaders.push('Statement Description');
        newCSVHeaders.push('Branch Name');
        newCSVHeaders.push('Amount');
        newCSVHeaders.push('Channel');
        newCSVHeaders.push('Flag Transaction');

        return newCSVHeaders.join(',');
    }

    createCSVRow(transactionElement){
        let newValuesRow = [];

        newValuesRow.push(String(transactionElement.accountNumber));
        newValuesRow.push(String(transactionElement.transactionDate));

        newValuesRow.push(String(transactionElement.transactionCode));
        newValuesRow.push(String(transactionElement.originalDescription));
        newValuesRow.push(String(transactionElement.teller));
        newValuesRow.push(String(transactionElement.moneyIn));

        newValuesRow.push(String(transactionElement.balance));
        newValuesRow.push(String(transactionElement.transferAccount));
        newValuesRow.push(String(transactionElement.transTypeDesc));
        newValuesRow.push(String(transactionElement.statementDescription));
        newValuesRow.push(String(transactionElement.branch));
        newValuesRow.push(String(transactionElement.amount));
        newValuesRow.push(String(transactionElement.channel));
        newValuesRow.push(String(transactionElement.riskFlagged));

        return newValuesRow.join(',');
    }
    createTableRow(transactionElement){

        let newTR = document.createElement('tr');
        newTR.setAttribute(STYLING_ATTRIBUTE,'');

        newTR.appendChild(this.createTableDataCell(transactionElement.accountNumber));
        newTR.appendChild(this.createTableDataCell(transactionElement.transactionDate));
        newTR.appendChild(this.createTableDataCell(transactionElement.transactionCode));
        newTR.appendChild(this.createTableDataCell(transactionElement.originalDescription));
        newTR.appendChild(this.createTableDataCell(transactionElement.teller));
        newTR.appendChild(this.createTableDataCell(transactionElement.moneyIn));
        newTR.appendChild(this.createTableDataCell(transactionElement.balance));
        newTR.appendChild(this.createTableDataCell(transactionElement.transferAccount));
        newTR.appendChild(this.createTableDataCell(transactionElement.transTypeDesc));
        newTR.appendChild(this.createTableDataCell(transactionElement.statementDescription));
        newTR.appendChild(this.createTableDataCell(transactionElement.branch));
        newTR.appendChild(this.createTableDataCell(transactionElement.amount));
        newTR.appendChild(this.createTableDataCell(transactionElement.channel));

        newTR.appendChild(this.createCheckboxCell(transactionElement.transactionId, transactionElement.riskFlagged, transactionElement.accountNumber, FLAG_TRANSACTION_ACTION));
        if(transactionElement.riskFlagged){
            newTR.classList.add('already-flagged');
        }

        return newTR;
    }


    createTableDataCell(value){
        let newTD = document.createElement('td');

        newTD.setAttribute(STYLING_ATTRIBUTE,'');
        newTD.classList.add('slds-border_right');

        if(typeof value === 'undefined'){
            value = '---';
        }

        newTD.innerHTML += value;
        return newTD;
    }

    createCheckboxCell(transactionId, alreadyFlagged, accountNumber, actionType){
        let newTD = document.createElement('td');
        newTD.classList.add('justify-center');
        newTD.classList.add('slds-border_right');
        newTD.setAttribute(STYLING_ATTRIBUTE,'');

        let newFlagCheckbox = document.createElement('input');
        newFlagCheckbox.type = 'checkbox';
        newFlagCheckbox.setAttribute('data-id', transactionId);
        newFlagCheckbox.setAttribute('data-accId', accountNumber);
        newFlagCheckbox.addEventListener('change', this.handleFlagCheckboxChange)

        if(alreadyFlagged === true){
            newFlagCheckbox.checked = true;
            // newFlagCheckbox.disabled = true;
        }
        else if(typeof alreadyFlagged === 'undefined'){
            newFlagCheckbox.disabled = true;
            alreadyFlagged = false;
        }

        //This was supposed to handle other types of operations but as of now other operations than transaction flagging were removed from the scope
        // ***

        switch(actionType){
            case FLAG_TRANSACTION_ACTION:
                let currentCheckbox = {
                    htmlElement : newFlagCheckbox,
                    originalValue : alreadyFlagged
                }
                this.flagCheckboxesById.set(transactionId, currentCheckbox);
                break;
            case HOLD_FUNDS_ACTION:
                this.holdFundsCheckboxesById.set(transactionId, newFlagCheckbox);
                break;
        }
        // ***

        newTD.appendChild(newFlagCheckbox);
        return newTD;
    }

    createComboboxCell(transactionId, alreadyFlagged, accountNumber){
        let newTD = document.createElement('td');
        newTD.setAttribute(STYLING_ATTRIBUTE,'');
        newTD.classList.add('justify-center');

        let newBlockAccCheckbox = document.createElement('input')
        let newSelectList = document.createElement('Select');

        newBlockAccCheckbox.type = 'checkbox';
        newBlockAccCheckbox.setAttribute('data-block-acc-checkbox-id', transactionId);
        newBlockAccCheckbox.setAttribute('data-accId', accountNumber);
        newBlockAccCheckbox.classList.add('slds-m-right_medium');


        this.selectCodeOptions.forEach(selectOption =>{
            newSelectList.appendChild(selectOption.cloneNode(true));
        })

        newSelectList.setAttribute('data-select-code-id', transactionId);
        newSelectList.setAttribute('data-accId', accountNumber);

        if(alreadyFlagged === true){
            newBlockAccCheckbox.checked = true;
            // newBlockAccCheckbox.disabled = true;
            // newSelectList.disabled = true;
        }
        else{
            newBlockAccCheckbox.checked = false;
            // newSelectList.disabled = true;

            newBlockAccCheckbox.addEventListener('change', this.handleBlockAccountCheckboxChange)
        }

        this.blockAccountCheckboxesById.set(transactionId, newSelectList);


        newTD.appendChild(newBlockAccCheckbox);
        newTD.appendChild(newSelectList);
        return newTD;

    }

    handleFlagCheckboxChange(event){
        try{
            let checkboxWrapper = this.flagCheckboxesById.get(event.target.getAttribute('data-id'));

            console.log(checkboxWrapper);
            if(checkboxWrapper.originalValue){
                if(checkboxWrapper.htmlElement.checked){
                    console.log('unflag')
                    checkboxWrapper.htmlElement.parentElement.parentElement.classList.remove('unflag');
                    checkboxWrapper.htmlElement.parentElement.parentElement.classList.add('already-flagged');
                }
                else{
                    console.log('nothing')
                    checkboxWrapper.htmlElement.parentElement.parentElement.classList.add('unflag');
                    checkboxWrapper.htmlElement.parentElement.parentElement.classList.remove('already-flagged');
                }
            }
            else{
                if(checkboxWrapper.htmlElement.checked){
                    console.log('flag')
                    checkboxWrapper.htmlElement.parentElement.parentElement.classList.add('flag')
                }
                else{
                    console.log('nothing')
                    checkboxWrapper.htmlElement.parentElement.parentElement.classList.remove('flag')
                }
            }

        }
        catch (e){
            console.log(e);
            console.log(e.message);
        }
    }

    handleBlockAccountCheckboxChange(event){
        try{
            let selectElement = this.template.querySelector('[data-select-code-id="' + event.target.getAttribute('data-block-acc-checkbox-id') + '"]');
            selectElement.disabled = !event.target.checked;
            if(!event.target.checked){
                selectElement.value = 'None';
            }

        }
        catch (e){
            console.log(e);
            console.log(e.message);
        }
    }

    injectContext(){
        this.handleFlagButton = this.handleFlagButton.bind(this);
        this.refreshComponent = this.refreshComponent.bind(this);
        this.handleStartDateChange = this.handleStartDateChange.bind(this);
        this.handleEndDateChange = this.handleEndDateChange.bind(this);
        this.handleSaveCSV =  this.handleSaveCSV.bind(this);
        this.createComboboxCell = this.createComboboxCell.bind(this);
        this.handleBlockAccountCheckboxChange = this.handleBlockAccountCheckboxChange.bind(this);
        this.getTransactionsInAsync = this.getTransactionsInAsync.bind(this);
        this.handleFlagCheckboxChange = this.handleFlagCheckboxChange.bind(this);

        this.elementsInitialized = true;
    }

    clearScreen(){
        this.showTable = false;
    }

    hideSpinner(){
        let spinner = this.template.querySelector('[data-id="spinner"]');
        spinner.setAttribute('hidden', 'hidden');
    }
    showSpinner(){
        let spinner = this.template.querySelector('[data-id="spinner"]');
        spinner.removeAttribute('hidden');
    }

    async handleFlagButton(){

        this.showSpinner();
        let flaggedTransactionsIds = [];
        let flaggedAccountNumbers = [];
        let unflaggedTransactionsIds = [];
        let unflaggedAccountNumbers = [];
        let calloutResult;

        // In order to flag the transactions through external API we need to check which of the transactions were flagged by the user and which came already flagged and became unflagged

        for(const transId of this.flagCheckboxesById.keys()){
            let currentCheckbox = this.flagCheckboxesById.get(transId);
            if(currentCheckbox.htmlElement.checked && !currentCheckbox.originalValue){
                flaggedTransactionsIds.push(transId);
                flaggedAccountNumbers.push(currentCheckbox.htmlElement.getAttribute('data-accId'));
            }
            else if(!currentCheckbox.htmlElement.checked && currentCheckbox.originalValue){
                unflaggedTransactionsIds.push(transId);
                unflaggedAccountNumbers.push(currentCheckbox.htmlElement.getAttribute('data-accId'));
            }
        }

        // --- vvv User has to confirm before proceeding any further vvv ---

        const confirmFlag = await LightningConfirm.open({
            message: 'The chosen transactions will be marked as potentially suspicious. Would you like to proceed?',
            variant: 'headerless',
            label: 'Confirm action',
        });


        if(!confirmFlag){
            this.hideSpinner();
            return;
        }

        // --- ^^^ User has to confirm before proceeding any further ^^^ ---


        await flagTransactions({flaggedIds: flaggedTransactionsIds, caseId: this.recordId}).then(result =>{
            calloutResult = result.statusCode;
        }).catch(error =>{
            this.hideSpinner();
            this.showErrorAlarm(error.message);
        })

        if(calloutResult === 200){
            await LightningAlert.open({
                message: 'Successfully flagged selected transactions',
                theme:'success',
                label: 'Success',
            });
        }
        else{
            await LightningAlert.open({
                message: result.errorMessage,
                theme:'error',
                label: 'Something went wrong',
            });
        }


        try{
            // const delay = ms => new Promise(res => setTimeout(res, ms));
            // await delay(3000);
            await updateFlaggedTransactionTotalValue({caseId: this.recordId, accountNumberList: flaggedAccountNumbers});
        }catch (error){
            console.log(error.message);
        }
        

        if(unflaggedTransactionsIds.length === 0){
            this.hideSpinner();
            await this.refreshComponent();
            return;
        }

        // --- vvv User has to confirm before proceeding any further vvv ---

        const confirmUnflag = await LightningConfirm.open({
            message: 'Deselected transactions that were previously flagged as potentially suspicious will have their flagged status removed . Would you like to proceed?',
            variant: 'headerless',
            label: 'Confirm action',
        });


        if(!confirmUnflag){
            this.hideSpinner();
            return;
        }

        // --- ^^^ User has to confirm before proceeding any further ^^^ ---

        await unflagTransactions({flaggedIds: unflaggedTransactionsIds, caseId: this.recordId}).then(result =>{
            calloutResult = result.statusCode;
        }).catch(error =>{
            this.hideSpinner();
            this.showErrorAlarm(error.message);
        })

        if(calloutResult === 200){
            await LightningAlert.open({
                message: 'Successfully unflagged selected transactions',
                theme:'success',
                label: 'Success',
            });
        }
        else{
            await LightningAlert.open({
                message: result.errorMessage,
                theme:'error',
                label: 'Something went wrong',
            });
        }


        this.showSpinner();
        await this.refreshComponent();

    }

    handleStartDateChange(event){
        this.startDate = event.target.value;
    }

    handleEndDateChange(event){
        this.endDate = event.target.value;
    }

    showErrorAlarm(message){
        LightningAlert.open({
            message: message,
            theme:'error',
            label: 'Something went wrong',
        });
    }


}