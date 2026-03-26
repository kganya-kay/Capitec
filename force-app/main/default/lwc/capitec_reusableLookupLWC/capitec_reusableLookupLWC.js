import { LightningElement,api,track } from 'lwc';
import searchRecords from '@salesforce/apex/capitec_LookupController.searchRecords';

export default class Capitec_reusableLookupLWC extends LightningElement {
    @api label;
    @api sObjectApiName;
    @api fieldApiName = 'Name';
    @api placeholder = 'Search...';

    @track searchKey = '';
    @track results = [];

    handleInputChange(event) {
        this.searchKey = event.target.value;
        if (this.searchKey.length >= 2) {
            searchRecords({ sObjectApiName: this.sObjectApiName, searchKey: this.searchKey, fieldApiName: this.fieldApiName })
                .then(res => {
                    this.results = res;
                });
        } else {
            this.results = [];
        }
    }

    handleFocus() {
        this.results = [];
    }

    selectRecord(event) {
        const name = event.target.innerText;
        const record = this.results.find(r => r.Name === name);
        if(record){
            this.results = [];
            this.searchKey = name;

            const selectedEvent = new CustomEvent('lookupupdate', {
                detail: { id: record.Id, name: record.Name }
            });
            this.dispatchEvent(selectedEvent);
        }
    }

}