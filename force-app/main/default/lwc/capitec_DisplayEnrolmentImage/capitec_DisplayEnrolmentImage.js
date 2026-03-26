import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getAccountImage from '@salesforce/apex/capitec_GetEnrolmentImage.getAccountImage';

export default class Capitec_DisplayEnrolmentImage extends LightningElement {
    @api recordId;  
    imageUrl;


    @wire(getAccountImage, { caseId: '$recordId' })
    wiredAccountImage({ error, data }) {
        if (data) {
            console.error('Success fetching image:', data);

            this.imageUrl = data;
        } else if (error) {
            console.error('Error fetching image:', error);
            this.imageUrl = null;
        }
    }
}