import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class CapitecConversionsRelatedListLWC extends LightningElement {

    @api showNewButton;

    @track records = [];
    @track draftValues = [];

    @track isModalOpen = false;
    @track currentRecord = {};
    @track isEditMode = false;

    @api stagingRecords;

    /* ---------------- FLOW INPUT ---------------- */
    @api
    get preloadedRecords() {
        return JSON.stringify(this.records);
    }

    set preloadedRecords(value) {
        if (value) {
            try {
                const parsed = JSON.parse(value);
                this.records = parsed.map((rec, index) => ({
                    ...rec,
                    tempId: `row-${index}`
                }));
            } catch (e) {
                this.records = [];
            }
        } else {
            this.records = [];
        }
    }

    connectedCallback() {
        if (this.showNewButton === undefined || this.showNewButton === null) {
            this.showNewButton = true;
        }
    }

    /* ---------------- GETTERS ---------------- */
    get recordCount() {
        return this.records.length;
    }

    get isEmpty() {
        return this.records.length === 0;
    }

    get modalTitle() {
        return this.isEditMode ? 'Edit Debit Order' : 'New Debit Order';
    }

    get categoryOptions() {
        return [
            { label: 'FD Debit Order Switch', value: 'FD Debit Order Switch' },
            { label: 'WS Debit Order Switch', value: 'WS Debit Order Switch' }
        ];
    }

    /* ---------------- DATATABLE ---------------- */
    columns = [
        { label: 'DO Reference Number', fieldName: 'Reference__c', editable: true },
        {
            label: 'DOI Name',
            fieldName: 'DOIName',
            type: 'text',
            cellAttributes: { 
                class: 'slds-pill slds-pill_link slds-pill_small' 
            },
            editable: false
        },
        { label: 'Date', fieldName: 'Date__c', type: 'date', editable: true },
        { 
            label: 'Amount', 
            fieldName: 'Amount__c', 
            type: 'currency', 
            editable: true, 
            typeAttributes: { currencyCode: 'ZAR' } 
        },
        { label: 'Category', fieldName: 'Category__c', editable: true },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Edit', name: 'edit' },
                    { label: 'Delete', name: 'delete' }
                ]
            }
        }
    ];

    /* ---------------- INLINE EDIT ---------------- */
    handleSaveDrafts(event) {
        const updates = event.detail.draftValues;
        this.records = this.records.map(record => {
            const updated = updates.find(d => d.tempId === record.tempId);
            return updated ? { ...record, ...updated } : record;
        });
        this.draftValues = [];
        this.pushToFlow();
    }

    handleCancel() {
        this.draftValues = [];
    }

    /* ---------------- MODAL HANDLING ---------------- */
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
        this.isModalOpen = true;
    }
    

    handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;

        if (action === 'edit') {
            this.isEditMode = true;
            this.currentRecord = { ...row };
            this.isModalOpen = true;
        }

        if (action === 'delete') {
            this.records = this.records.filter(r => r.tempId !== row.tempId);
            this.pushToFlow();
        }
    }

    handleInputChange(event) {
        const field = event.target.name;
        this.currentRecord = { ...this.currentRecord, [field]: event.target.value };
    }

    handleLookupSelect(event) {
        // DOI lookup selection
        this.currentRecord.DOIId = event.detail.id;
        this.currentRecord.DOIName = event.detail.name;
    }

    saveRecord() {
        const form = this.template.querySelector('.lookup-form');
        if (form) {
            form.submit(); // commits the lookup value
        }
    
        if (!this.currentRecord.DOIId ||
            !this.currentRecord.Reference__c ||
            !this.currentRecord.Date__c ||
            !this.currentRecord.Amount__c ||
            !this.currentRecord.Category__c) {
            return;
        }
    
        if (this.isEditMode) {
            this.records = this.records.map(r => r.tempId === this.currentRecord.tempId ? this.currentRecord : r);
        } else {
            this.currentRecord.tempId = `row-${Date.now()}`;
            this.records = [this.currentRecord, ...this.records];
        }
    
        this.isModalOpen = false;
        this.pushToFlow();
    }
    closeModal() {
        this.isModalOpen = false;
    }

    refreshTable() {
        this.pushToFlow();
    }

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
        this.dispatchEvent(
            new FlowAttributeChangeEvent('stagingRecords', this.stagingRecords)
        );
    }

}