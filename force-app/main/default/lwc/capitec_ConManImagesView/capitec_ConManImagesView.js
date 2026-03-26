import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import postRequest from '@salesforce/apex/capitec_ConManGetImage.postRequest';
import processFile from '@salesforce/apex/capitec_ConManGetImage.processFile';

// Define the field that contains the cifValue
const FIELDS = ['Case.CIF_Number__c']; 


export default class Capitec_ConManImagesView extends LightningElement {
    @api recordId;  
    cifValue;     
    imageitems = [];     
    imageprofileitems = [];  
    docitems = [];     
    @track imageUrl;
    documentId;
    @track showSpinner = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        console.log('recordId: ', this.recordId);

        if (data) {
            this.cifValue = data.fields.CIF_Number__c.value; 
            console.log('cifValue: ', this.cifValue);

        } else if (error) {
            console.error('Error retrieving CIF value: ', error);
        }
    }
  
    // Handle "Retrieve Documents" button click to populate imageitems and docitems in the list
    handleRetrieveDocuments() { //handleRetrieveImage
        console.log('handleRetrieveDocuments caseId: ', this.recordId);

        this.showSpinner = true; 
        postRequest({ cifValue: this.cifValue, caseId: this.recordId })
            .then(result => {
                console.log('handleRetrieveDocuments Result: ', result);
                const sortByMostRecent = (list) => list.sort((a, b) => new Date(b.createdDate) - new Date(a.createdDate));
                const documents = sortByMostRecent(result[0].documents);
                const images = sortByMostRecent(result[0].images);
                const imageprofiles = sortByMostRecent(result[0].imageprofiles);


                this.imageitems = images.map((doc, index) => ({
                    id: doc.documentId,                       
                    documentId: doc.documentId,           
                    name: 'Selfie ' + (index + 1),     
                    createdDate: doc.createdDate ? new Date(doc.createdDate).toISOString().split('T')[0] + ' ' + new Date(doc.createdDate).toISOString().split('T')[1].split('.')[0] : '',        
                    lastModifiedDate: doc.lastModifiedDate,  
                    ownerName: doc.ownerName,             
                    contentType: doc.contentType,         
                    fileUrl: null,
                    contentDocumentId: doc.contentDocumentId                     
                }));
                this.imageprofileitems = imageprofiles.map((doc, index) => ({
                    id: doc.documentId,                       
                    documentId: doc.documentId,           
                    name: 'Enrolment image ' + (index + 1),       
                    createdDate: doc.createdDate ? new Date(doc.createdDate).toISOString().split('T')[0] + ' ' + new Date(doc.createdDate).toISOString().split('T')[1].split('.')[0] : '',        
                    lastModifiedDate: doc.lastModifiedDate,  
                    ownerName: doc.ownerName,             
                    contentType: doc.contentType,         
                    fileUrl: null,
                    contentDocumentId: doc.contentDocumentId                     
                }));
                this.docitems = documents.map((doc, index) => ({
                    id: doc.documentId,                       
                    documentId: doc.documentId,           
                    name: 'Identification Document ' + (index + 1),      
                    createdDate: doc.createdDate ? new Date(doc.createdDate).toISOString().split('T')[0] + ' ' + new Date(doc.createdDate).toISOString().split('T')[1].split('.')[0] : '',        
                    lastModifiedDate: doc.lastModifiedDate,  
                    ownerName: doc.ownerName,             
                    contentType: doc.contentType,         
                    fileUrl: null,
                    contentDocumentId: doc.contentDocumentId               
                }));
            })
            .catch(error => {
                console.error('Error retrieving documents:', error);
            })
            .finally(() => {
                this.showSpinner = false; // Ensure spinner is hidden after data load or error
            });
    }
     // Method to handle retrieve documents
     handleRetrieveDoc(event) {
        console.log('handleRetrieveDoc');
    
        this.showSpinner = true; 
    
        this.documentId = event.currentTarget.dataset.id;
    
        const itemIndex = this.docitems.findIndex(item => item.documentId === this.documentId);
    
        if (itemIndex !== -1) {
            processFile({ documentId: this.documentId, caseId: this.recordId, contentType: this.docitems[itemIndex].contentType })
                .then(result => {
                    console.log('handleRetrieveDoc result: ', result);
                    this.docitems[itemIndex].fileUrl = result.fileUrl;
                    this.docitems[itemIndex].contentDocumentId = result.contentDocumentId;
                    this.docitems = [...this.docitems];
                })
                .catch(error => {
                    console.error('Error retrieving file: ', error);
                })
                .finally(() => {
                    this.showSpinner = false; // Ensure spinner is hidden after data load or error
                });
        }
    }
      
    // Method to handle retrieve images
    handleRetrieveImage(event) {
        console.log(' handleRetrieveImage ');

        this.showSpinner = true; 
        this.documentId = event.currentTarget.dataset.id;
        const itemIndex = this.imageitems.findIndex(item => item.documentId === this.documentId);
        
        if (itemIndex !== -1) {
            processFile({ documentId: this.documentId, caseId: this.recordId, contentType: this.imageitems[itemIndex].contentType })
                .then(result => {
                    console.log('handleRetrieveImage result: ', result);
                    this.imageitems[itemIndex].imageUrl = result.fileUrl;
                    this.imageitems[itemIndex].contentDocumentId = result.contentDocumentId;
                    this.imageitems = [...this.imageitems];
                })
                .catch(error => {
                    console.error('Error retrieving image ', error);
                })
                .finally(() => {
                    this.showSpinner = false; // Ensure spinner is hidden after data load or error
                });
        }

    }
    // Method to handle retrieve profile picture
    handleRetrieveProfileImage(event) {
        console.log(' handleRetrieveImage ');

        this.showSpinner = true; 
        this.documentId = event.currentTarget.dataset.id;
        const itemIndex = this.imageprofileitems.findIndex(item => item.documentId === this.documentId);
        
        if (itemIndex !== -1) {
            processFile({ documentId: this.documentId, caseId: this.recordId, contentType: this.imageprofileitems[itemIndex].contentType })
                .then(result => {
                    console.log('handleRetrieveImage result: ', result);
                    this.imageprofileitems[itemIndex].imageUrl = result.fileUrl;
                    this.imageprofileitems[itemIndex].contentDocumentId = result.contentDocumentId;

                    // Refresh the imageprofileitems array 
                    this.imageprofileitems = [...this.imageprofileitems];
                })
                .catch(error => {
                    console.error('Error retrieving image ', error);
                })
                .finally(() => {
                    this.showSpinner = false; // Ensure spinner is hidden after data load or error
                });
        }
    }
    handlePreviewDoc(event) {
        const contentDocumentId = event.currentTarget.dataset.id;
        console.log(' handlePreviewDoc contentDocumentId ', contentDocumentId);

        if (contentDocumentId) {
        console.log(' navigation contentDocumentId ', contentDocumentId);

        const previewUrl = `/lightning/r/ContentDocument/${contentDocumentId}/view`;

        // Open in a new tab for preview
        window.open(previewUrl, '_blank');
        } else {
            console.error('Content Document ID is missing.');
        }
    }
}