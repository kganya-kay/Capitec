import { api, LightningElement, track } from 'lwc';
import { transactionHistoryGetAccs,formatDate, getTransactionHistoryGen,getStartDate } from 'c/capitec_FraudTHDataHandler';

export default class CapitecFraudCaseActions extends LightningElement {
    @api recordId;
    @track startDate;
    @track endDate;
    @track itemsToDisplay = []; // Stores table data
    @track financialAccountsNumbers; // Stores account numbers for dropdown
    @track comboboxValue; // Current account number selection
    @track showSpinner = false; // Spinner visibility
    @track disableActions = true; // Disable "Apply Actions" button by default
    @track accType = ''; 
    accountTypeOptions = [
        { label: 'All', value: 'All' },
        { label: 'Card Authorisation', value: 'CARD_AUTHORISATION' },
        { label: 'Financial', value: 'FINANCIAL' },
        { label: 'Non-Financial', value: 'NON_FINANCIAL' },
        { label: 'Financial & Non-Financial', value: 'FINANCIALNONFINANCIAL' }
    ];

    accType = 'All';


    async connectedCallback() {
        this.handleInitiateData(this.recordId);
    }

    async getLast7Dates(event){
        var today = new Date();
        var sevenDaysAgo = new Date(today);
        sevenDaysAgo.setDate(today.getDate() - 7);
        var todayDate = new Date(today);
        console.log('12');
        var startDateInput = this.template.querySelector('[data-id="startDateInput"]');
        var endDateInput = this.template.querySelector('[data-id="endDateInput"]');
         console.log('1');
        await formatDate(sevenDaysAgo).then(result => {
            console.log(result);
            startDateInput.value = result;
        })

        await formatDate(todayDate).then(result => {
            console.log(result);
            endDateInput.value = result;
        })
    }
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

    // Fetch transactions based on selected filters
    async handleGetTransactions() {
        this.showSpinner = true;
        this.itemsToDisplay = []; // Clear previous data

        // Fetch the start and end date values from the input fields
        const startDateVal = this.template.querySelector('[data-id="startDateInput"]').value;
        const endDateVal = this.template.querySelector('[data-id="endDateInput"]').value;
        const comboBoxVal = this.template.querySelector('[data-id="combobox-fin-id"]').value;
        const accTypeVal = 'all';

        // Check if both start and end dates are provided
        if (!startDateVal || !endDateVal) {
            alert('Please select both start and end dates.');
            this.showSpinner = false;
            return;
        }

        // Ensure start date is before end date
        const startDate = new Date(startDateVal);
        const endDate = new Date(endDateVal);

        if (startDate > endDate) {
            await this.displayWrongDateWarning();
            this.showSpinner = false;
            return;
        }

        // Proceed with fetching the data
        const calloutAccountNumbers = this.selectAccNumberForCallout(comboBoxVal);
        await this.performGetCallouts(calloutAccountNumbers, this.recordId, startDateVal, endDateVal, accTypeVal);
        this.showSpinner = false;
    }

    // Initialize account data for dropdown
    async handleInitiateData(recordId) {
        await getStartDate(recordId).then(result => {
            this.startDate = new Date(result).toISOString().split('T')[0];
            this.endDate = new Date().toISOString().split('T')[0];
        })

        await transactionHistoryGetAccs(recordId).then(result => {
            this.financialAccountsNumbers = result;
            this.comboboxValue = result[0].value; // Default selection to the first account
        });
    }

    // Fetch transaction data based on selected account numbers and other filters
    async performGetCallouts(calloutAccountNumbers, caseId, startDateVal, endDateVal, accTypeVal) {
        accTypeVal = '';
        const promises = calloutAccountNumbers.map(accNumber => {
            return getTransactionHistoryGen(accNumber, caseId, startDateVal, endDateVal, accTypeVal).then(result => {
                this.disableActions = false;
                this.itemsToDisplay.push(...result);
            });
        });

        await Promise.all(promises); // Wait for all promises to resolve
    }

    // Select accounts for API callout based on dropdown selection
    selectAccNumberForCallout(comboBoxVal) {
        const calloutAccountNumbers = [];
        if (comboBoxVal === 'allAccounts') {
            this.financialAccountsNumbers.forEach(comboBoxAccVal => {
                calloutAccountNumbers.push(comboBoxAccVal.value);
            });
        } else {
            calloutAccountNumbers.push(comboBoxVal);
        }
        return calloutAccountNumbers;
    }

    // Display warning if start date is after end date
    async displayWrongDateWarning() {
        await LightningAlert.open({
            message: 'Please ensure that the Start Date is before the End Date',
            theme: 'warning',
            label: 'Warning',
        });
    }
}