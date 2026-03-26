import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Capitec_ConversionsStatements extends LightningElement {

    @api recordId;

    @track records = [];
    @track selectedRowIds = [];
    @track selectedRows = [];
    @track showModal = false;
    @track isSubmitDisabled = false;
    @track fromDate;
    @track toDate;
    @track searchKey = '';
    @track notListed = false;

    columns = [
            {
                label: 'Statement Description',
                fieldName: 'desc',
               type: 'text'
            },
            {
                label: 'Reference Number',
                fieldName: 'ref',
                type: 'text'
            },
            {
                label: 'Transaction Date -Time',
                fieldName: 'transacDate',
                type: 'date'
            },
            {
                label: 'Amount',
                fieldName: 'amount',
                type: 'currency',
                typeAttributes: { currencyCode: 'ZAR' } 
            }
        ];

    
    get filteredRecords() {
        let filtered = this.records;

        if (this.searchKey) {
            const search = this.searchKey.toLowerCase();
            filtered = filtered.filter(
                rec => rec.desc.toLowerCase().includes(search)
            );
        }

        return filtered;
    }

    connectedCallback() {
        console.log('##SAU Table init with Id:', this.recordId);
        this.records = [
            {
                id: 'a1', 
                desc: 'Online Purchase',
                ref: 'REF12345',
                transacDate: '2025-06-10T10:30:00Z', 
                amount: 125.50
            },
            {
                id: 'a2',
                desc: 'Cash Withdrawal',
                ref: 'REF67890',
                transacDate: '2025-06-09T15:45:00Z',
                amount: 500.00
            },
            {
                id: 'a3',
                desc: 'Subscription Renewal',
                ref: 'REF00112',
                transacDate: '2025-06-08T08:00:00Z',
                amount: 19.99
            },
            {
                id: 'a4',
                desc: 'Bank Transfer',
                ref: 'REF33445',
                transacDate: '2025-06-07T20:10:00Z',
                amount: 750.25
            },
            {
                id: 'a5',
                desc: 'Grocery Shopping',
                ref: 'REF98765',
                transacDate: '2025-06-06T11:20:00Z',
                amount: 88.75
            }
        ];
    }

    handleNewDebitOrder() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Debit_Order_Detail__c',
                actionName: 'new'
            }
        });
    }

    handleFromDateChange(event) {
        this.fromDate = event.detail.value;
    }

    handleSearch(event) {
        this.searchKey = event.detail.value;
    }

    handleNotListedToggle(event) {
        this.notListed = event.detail.checked;
    }

    handleRowSelection(event){
        this.selectedRows = event.detail.selectedRows;
        console.log('##Selected rows:', JSON.stringify(this.selectedRows));
    }

     handleSubmit(event) {
        this.showModal = true;
    }

    handleModalClose() {
        this.showModal = false;
    }



        



}