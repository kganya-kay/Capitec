import { LightningElement, api } from 'lwc';

export default class ConversionManualCaseSummaryLWC extends LightningElement {

    @api caseorigin;
    @api issue;
    @api cifNumber;
    @api idNumber;
    @api passportNumber;
    @api salutation;
    @api firstName;
    @api lastName;
    @api primaryNumber;
    @api secondaryNumber;
    @api mobileNumber;
    @api email;
    @api preferredContactTime;

    @api oldBranchCode;
    @api oldAccountNumber;
    @api oldBankName;

    @api additionalComments;
    activeSections = ['caseInfo','clientInfo', 'oldBankInfo', 'debitOrders', 'notes'];

    _debitOrders = [];

    @api
    get debitOrders() {
        return JSON.stringify(this._debitOrders);
    }

    set debitOrders(value) {
        try {
            this._debitOrders = typeof value === 'string'
                ? JSON.parse(value)
                : value;
        } catch (e) {
            this._debitOrders = [];
            console.error('Error parsing debitOrders JSON:', e);
        }
    }

    get parsedDebitOrders() {
        return this._debitOrders || [];
    }

    columns = [
        { label: 'DO Reference Number', fieldName: 'Name' },
        { label: 'DOI Name', fieldName: 'Debit_Order_Initiator__c' },
        { label: 'Debit Order Date', fieldName: 'Debit_Order_Date__c', type: 'date' },
        { label: 'Amount', fieldName: 'Amount__c', type: 'currency', typeAttributes: { currencyCode: 'ZAR' } },
        { label: 'Category', fieldName: 'Category__c' }
    ];

    handleCommentsChange(event) {
        this.additionalComments = event.detail.value;
    }
}