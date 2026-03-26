import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class CapitecFilesComboBoxLWC extends LightningElement {
    
    @api fileIdsString = ''; 
    @api fileNamesString = '';
    @api selectedFileId;

    @track fileOptions = [];

    connectedCallback() {
        const ids = this.fileIdsString ? this.fileIdsString.split(',').map(id => id.trim()) : [];
        const names = this.fileNamesString ? this.fileNamesString.split(',').map(n => n.trim()) : [];

        this.fileOptions = ids.map((id, index) => ({
            label: names[index] || `File ${index + 1}`,
            value: id
        }));

        if (this.fileOptions.length) {
            this.selectedFileId = this.fileOptions[0].value;
            this.dispatchEvent(new FlowAttributeChangeEvent('selectedFileId', this.selectedFileId));
        }
    }

    handleChange(event) {
        this.selectedFileId = event.detail.value;
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedFileId', this.selectedFileId));
    }
}