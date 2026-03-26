import { LightningElement,wire, api, track } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getRequestItems from '@salesforce/apex/Conversions_DocumentManagerController.getRequestItems';
import createDocChecklistItem from '@salesforce/apex/Conversions_DocumentManagerController.createDocChecklistItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import DCI_OBJECT from '@salesforce/schema/DocumentChecklistItem';
import DOC_TYPE_FIELD from '@salesforce/schema/DocumentChecklistItem.CON_Document_Type__c';

export default class Conversions_Document_Manager_TileList extends LightningElement {
    @api recordId;
    @track showModal = false;
    @track isLoading = false;
    @track showOtherField = false;
    @track selectedDocId;
    @track selectedDocType;
    @track documentTypeOptions = [];

    requestListItems = [];

    @wire(getObjectInfo, { objectApiName: DCI_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: "$objectInfo.data.defaultRecordTypeId",
        fieldApiName: DOC_TYPE_FIELD
    })
    wiredPicklist({ data, error }) {
        if (data) {
            this.documentTypeOptions = data.values;
        } else if (error) {
            console.error('Picklist error:', error);
        }
    }

    @wire(getRequestItems, { caseId: '$recordId' })
    wiredItems({ data, error }) {
        console.log('## init data: ', JSON.stringify(data));
        if (data) {
            this.requestListItems = data.map(item => ({
                ...item,
                preview: item.DocumentName__c
                    ? item.DocumentName__c.substring(0, 100)
                    : ''
            }));

            console.log('## init requestListItems: ', JSON.stringify(this.requestListItems));
        } else if (error) {
            console.error(error);
        }
    }

    connectedCallback() {
        console.log('Document manager recordId:', this.recordId);
    }

    get hasItems() {
        return this.requestListItems && this.requestListItems.length > 0;
    }

    openPreview(event) {
        this.selectedDocId = event.target.dataset.id;
        this.showModal = true;
    }

    handleClose() {
        this.showModal = false;
    }

    handleDocTypeChange(event) {
        this.showOtherField = false;
        this.isLoading = true;
        
        const selectedValue = event.detail.value;
        const rowId = event.target.dataset.id;

        console.log('##Selected Value:', selectedValue);
        console.log('##Row ID:', rowId);

        const currentItem = this.requestListItems.find(item => item.Id === rowId);
        console.log('##Current Item:', JSON.stringify(currentItem));

        if (!currentItem) {
            console.error('##Item not found in list');

            this.isLoading = false;
            this.showToast('Error', 'Classification failed.', 'error');
            return;
        }

        if(selectedValue == null) {
            console.error('##No selected value');
            this.isLoading = false;
            this.showToast('Error', 'Select a valid document type for classification.', 'error');
            return;
        }
        else if(selectedValue == 'Other'){
            this.showOtherField = true;
            this.isLoading = false;
            return;
        }

        this.selectedDocType = selectedValue;
        this.classifyDocument(currentItem.Id,currentItem.CON_Content_Document_Id__c);
    }


    handleClassify(event) {
        this.isLoading = true;
        const rowId = event.target.dataset.rowid;
        console.log("##rowId:" + rowId);

        const currentItem = this.requestListItems.find(item => item.Id === rowId);

        const input = this.template.querySelector( `lightning-input.otherInput[data-rowid="${rowId}"]`);

        if (!input) {
            this.isLoading = false;
            this.showToast('Error', 'Input field not found.', 'error');
            return;
        }

        const value = input.value;

        if (!value || value.trim() === '') {
            this.isLoading = false;
            this.showToast('Error', 'Please enter a mandatory value for other document type.', 'error');
            input.reportValidity();
            return;
        }

        this.selectedDocType = value;
        this.classifyDocument(currentItem.Id,currentItem.CON_Content_Document_Id__c);

    }

    classifyDocument(itemId, contentDocId){
        createDocChecklistItem({caseId: this.recordId,
                                requestId: itemId,              
                                contentDocId: contentDocId,             
                                docType: this.selectedDocType})
        .then(result => {
            console.log('## Apex returned:', result);
            if (result === true) {
                this.requestListItems = this.requestListItems.filter(
                    item => item.Id !== itemId
                );

            this.showToast('Success', 'Classification Succeeded.', 'success');
            } 
            else {
                this.showToast('Error', 'Classification failed.', 'error');
            }
            this.isLoading = false;

        })
        .catch(error => {
            console.error('Error creating checklist item:', JSON.stringify(error));
            this.isLoading = false;
            this.showToast('Error', 'Classification failed.', 'error');

        });
    }


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            })
        );
    }


}