import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import searchDOIs from '@salesforce/apex/capitec_DebitOrderLookupController.searchDOIs';

export default class conversionsDebitOrdersListLWC extends LightningElement {
    @api showNewButton;
    @api stagingRecords;

    @track records = [];
    @track draftValues = [];
    @track isModalOpen = false;
    @track currentRecord = {};
    @track isEditMode = false;

    /* Type-ahead lookup */
    @track doiSearchKey = '';
    @track doiOptions = [];
    @track doiSelectedId = '';
    @track doiSelectedName = '';

    /* ---------------- DATATABLE ---------------- */
    columns = [
        { label: 'DO Reference Number', fieldName: 'Reference__c', editable: true },
        { 
            label: 'DOI Name', 
            fieldName: 'DOIName', 
            type: 'text',
            cellAttributes: { class: 'slds-pill slds-pill_link slds-pill_small' },
            editable: false 
        },
        { label: 'Date', fieldName: 'Date__c', type: 'date', editable: true },
        { label: 'Amount', fieldName: 'Amount__c', type: 'currency', editable: true, typeAttributes: { currencyCode: 'ZAR' } },
        { label: 'Category', fieldName: 'Category__c', editable: true },
        { type: 'action', typeAttributes: { rowActions: [{ label: 'Edit', name: 'edit' }, { label: 'Delete', name: 'delete' }] } }
    ];

    connectedCallback() {
        // Set default value for @api boolean
        if (this.showNewButton === undefined || this.showNewButton === null) {
            this.showNewButton = true;
        }
    }

    /* ---------------- GETTERS ---------------- */
    get recordCount() { return this.records.length; }
    get isEmpty() { return this.records.length === 0; }
    get modalTitle() { return this.isEditMode ? 'Edit Debit Order' : 'New Debit Order'; }
    get categoryOptions() {
        return [
            { label: 'FD Debit Order Switch', value: 'FD Debit Order Switch' },
            { label: 'WS Debit Order Switch', value: 'WS Debit Order Switch' }
        ];
    }

    /* ---------------- MODAL & INPUT ---------------- */
    openNewForm() {
        this.isEditMode = false;
        this.currentRecord = {
            DOIId: '',
            DOIName: '',
            Reference__c: '',
            Date__c: new Date().toISOString().split('T')[0],
            Amount__c: null,
            Category__c: ''
        };
        this.doiSearchKey = '';
        this.doiOptions = [];
        this.doiSelectedId = '';
        this.doiSelectedName = '';
        this.isModalOpen = true;
    }

    handleRowAction(event) {
        const { name } = event.detail.action;
        const row = event.detail.row;
        if (name === 'edit') {
            this.isEditMode = true;
            this.currentRecord = { ...row };
            this.doiSelectedId = row.DOIId;
            this.doiSelectedName = row.DOIName;
            this.doiSearchKey = row.DOIName;
            this.isModalOpen = true;
        } else if (name === 'delete') {
            this.records = this.records.filter(r => r.tempId !== row.tempId);
            this.pushToFlow();
        }
    }

    handleInputChange(event) {
        const field = event.target.name;
        this.currentRecord = { ...this.currentRecord, [field]: event.target.value };
    }

    /* ---------------- DOI TYPE-AHEAD ---------------- */
    handleDOISearch(event) {
        this.doiSearchKey = event.target.value;
        if (this.doiSearchKey.length >= 2) {
            searchDOIs({ searchKey: this.doiSearchKey })
                .then(result => {
                    this.doiOptions = result.map(r => ({ label: r.Name, value: r.Id }));
                })
                .catch(error => { console.error('DOI search error:', error); });
        } else {
            this.doiOptions = [];
        }
    }

    handleDOISelect(event) {
        this.doiSelectedId = event.detail.value;
        const selected = this.doiOptions.find(opt => opt.value === this.doiSelectedId);
        this.doiSelectedName = selected ? selected.label : '';
        this.currentRecord.DOIId = this.doiSelectedId;
        this.currentRecord.DOIName = this.doiSelectedName;
    }

    /* ---------------- SAVE ---------------- */
    saveRecord() {
        if (!this.currentRecord.DOIId ||
            !this.currentRecord.Reference__c ||
            !this.currentRecord.Date__c ||
            !this.currentRecord.Amount__c ||
            !this.currentRecord.Category__c) return;

        if (this.isEditMode) {
            this.records = this.records.map(r =>
                r.tempId === this.currentRecord.tempId ? this.currentRecord : r
            );
        } else {
            this.currentRecord.tempId = `row-${Date.now()}`;
            this.records = [this.currentRecord, ...this.records];
        }

        this.isModalOpen = false;
        this.pushToFlow();
    }

    closeModal() { this.isModalOpen = false; }
    refreshTable() { this.pushToFlow(); }

    /* ---------------- FLOW INTEGRATION ---------------- */
    pushToFlow() {
        const cleanRecords = this.records.map(rec => ({
            Name: rec.Reference__c,
            Debit_Order_Initiator__c: rec.DOIId,
            Debit_Order_Initiator_Name__c: rec.DOIName,
            Debit_Order_Date__c: rec.Date__c,
            Amount__c: rec.Amount__c,
            Category__c: rec.Category__c
        }));
        this.stagingRecords = JSON.stringify(cleanRecords);
        this.dispatchEvent(new FlowAttributeChangeEvent('stagingRecords', this.stagingRecords));
    }
}