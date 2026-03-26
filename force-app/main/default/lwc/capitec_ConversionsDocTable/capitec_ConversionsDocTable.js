import { LightningElement, api, wire, track } from 'lwc';
import fetchDocs from '@salesforce/apex/capitec_ConversionsDocTableHandler.fetchDocs';
import fetchNotes from '@salesforce/apex/capitec_ConversionsDocTableHandler.fetchNotes';


export default class Capitec_ConversionsDocTable extends LightningElement {
    @api recordId;
    @api selectionMode = 'multiple'; // 'single', 'multiple', 'none'
    @api iconName; //Icon to display on table
    @api title;
    @api recordsFromFlow;
    @api type; //Dtermine what the table is going to display

    @track records = [];

    error;
    selectedRowIds = [];

    get maxRowSelection() {
        if (this.selectionMode === 'single') return 1;
        if (this.selectionMode === 'multiple') return 999;
        return 0;
    }

    columns = [
            {
                label: 'Title',
                fieldName: 'url',
                type: 'url',
                typeAttributes: {
                    label: { fieldName: 'title' },
                    target: '_blank'
                }
            },
            {
                label: 'Created By',
                fieldName: 'createdByName',
                type: 'text'
            },
            {
                label: 'Created Date',
                fieldName: 'createdDate',
                type: 'date'
            }
        ];



    connectedCallback() {
       console.log('Component is initialized : recordsFromFlow' + this.recordsFromFlow);

       //this.filterRecords();

       if(this.type == 'SNOTE'){
        this.fetchNotes();
       }
       else{
        this.fetchDocs();
       }

    }

    fetchNotes(){
        fetchNotes({ recordId: this.recordId})
            .then(result => {
                this.records = JSON.parse(result);
            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching Notes:', error);
            });
    }

    fetchDocs(){
        fetchDocs({ recordId: this.recordId})
            .then(result => {
                this.records = JSON.parse(result);;
            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching documents:', error);
        });
    }

    filterRecords(){
        console.log('filterRecords INIT');
        if (this.recordsFromFlow) {

            if(this.type == 'SNOTE'){
              this.records = this.recordsFromFlow.map(row => ({
                                                                ...row,
                                                                documentLabel: row.ContentDocument.Title,
                                                                documentUrl: '/lightning/r/ContentDocument/' + row.ContentDocumentId + '/view',
                                                                createdByName: row.ContentDocument.CreatedBy.Name,
                                                                createdByUrl: '/' + row.ContentDocument.CreatedById
                                                            }));

            }
            else{

                this.records = this.recordsFromFlow.map(row => ({
                                                            ...row,
                                                            documentUrl: row.IC_DocumentLink__c,
                                                            documentLabel: row.Name,
                                                            createdByName: row.CON_Created_By_Name__c,
                                                            createdByUrl: '/' + row.CreatedById
                                                        }));

            }
            console.log('## this.recordsFromFlow filtered:', this.recordsFromFlow);

           

            console.log('##Filtered & Updated records:', this.records);
        } else {
            console.warn('No recordsFromFlow provided');
            this.records = [];
        }

        console.log('##Updated records:', this.records);

    }
    

    handleRowSelection(event) {
        this.selectedRowIds = event.detail.selectedRows.map(row => row.Id);
    }
}