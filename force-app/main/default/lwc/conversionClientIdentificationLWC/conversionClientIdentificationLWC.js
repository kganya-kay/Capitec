import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import searchClientByField from '@salesforce/apex/capitec_ClientVerificationController.searchClientByField';

export default class ClientIdentification extends LightningElement {
    @api recordId;
    @api idType;
    @api idNumber;
    @api contentDocumentId = '';
    @api contentDocumentIds = '';
    @api contentDocumentNames = '';
    @track activeSections = ['idSection', 'bankSection']; 
    @track acceptedFormats = ['.pdf', '.png', '.jpg', '.jpeg'];
    @track errorMessage = '';
    @track uploadedFiles = [];
    @track clientInfo = {};
    @track hasClientInfo = false;
    @track isSearching = false;

    idTypeOptions = [
        { label: 'Identification Number', value: 'ID' },
        { label: 'Passport Number', value: 'PASSPORT' },
        { label: 'CIF Number', value: 'CIF' },
        { label: 'Account Number', value: 'ACCOUNT' }
    ];

    get filePills() {
        return (this.uploadedFiles || []).map(file => ({
            label: file.name,
            name: file.documentId,
            iconName: 'standard:file'
        }));
    }

    get hasUploadedFiles() {
        return this.uploadedFiles && this.uploadedFiles.length > 0;
    }

    // Vertical fields for client info
    get clientFields() {
        if (!this.clientInfo) return [];
        return [
            { key: 'cif', label: 'CIF Number', value: this.clientInfo.CIFNumber },
            { key: 'id', label: 'ID Number', value: this.clientInfo.IDNumber },
            { key: 'passport', label: 'Passport Number', value: this.clientInfo.PassportNumber },
            { key: 'salutation', label: 'Salutation', value: this.clientInfo.Salutation },
            { key: 'firstName', label: 'First Name', value: this.clientInfo.FirstName },
            { key: 'lastName', label: 'Last Name', value: this.clientInfo.LastName },
            { key: 'homeContact', label: 'Home Contact', value: this.clientInfo.HomeContactNumber },
            { key: 'workContact', label: 'Work Contact', value: this.clientInfo.WorkContactNumber },
            { key: 'mobile', label: 'Mobile Number', value: this.clientInfo.MobileNumber },
            { key: 'email', label: 'Email Address', value: this.clientInfo.EmailAddress }
        ];
    }

    handleTypeChange(event) {
        this.idType = event.detail.value;
        this.idNumber = '';
        this.errorMessage = '';
        this.clearClientInfo();
    }

    handleNumberChange(event) {
        this.idNumber = event.target.value;
        this.errorMessage = '';
        this.clearClientInfo();
    }

    clearClientInfo() {
        this.clientInfo = {};
        this.hasClientInfo = false;
        this.activeSections = ['idSection', 'bankSection'];
    }

    async handleSubmit() {
        this.errorMessage = '';
        this.clearClientInfo();
        
        if (!this.idType || this.idType.trim() === '') {
            this.errorMessage = 'Please select an Identification type.';
            return;
        }

        if (!this.idNumber || this.idNumber.trim() === '') {
            this.errorMessage = `Please enter ${this.getLabelForType(this.idType)} number.`;
            return;
        }

        const validationResult = this.validateFormat();
        if (!validationResult.isValid) {
            this.errorMessage = validationResult.errorMessage;
            return;
        }

        this.isSearching = true;

        try {
            const result = await searchClientByField({
                searchType: this.idType,
                searchValue: this.idNumber.trim()
            });

            if (result && Object.keys(result).length > 0) {
                this.clientInfo = {
                    CIFNumber: result.CIF_Number__c || '',
                    IDNumber: result.Identity_Number__c || '',
                    PassportNumber: result.Passport_Number__c || '',
                    Salutation: result.Salutation || '',
                    FirstName: result.FirstName || '',
                    LastName: result.LastName || '',
                    HomeContactNumber: result.Phone || '',
                    WorkContactNumber: result.Work_Contact_Number__c || '',
                    MobileNumber: result.PersonMobilePhone || '',
                    EmailAddress: result.PersonEmail || ''
                };

                this.hasClientInfo = true;
                this.activeSections = ['idSection', 'clientSection', 'bankSection'];
                this.errorMessage = '';
            } else {
                this.errorMessage = 'No client found with the provided details.';
                this.activeSections = ['idSection', 'bankSection'];
            }
        } catch (error) {
            this.errorMessage = error.body ? error.body.message : 'An error occurred while searching for the client.';
            this.activeSections = ['idSection', 'bankSection'];
        } finally {
            this.isSearching = false;
        }
    }

    getLabelForType(type) {
        const option = this.idTypeOptions.find(opt => opt.value === type);
        return option ? option.label : type;
    }

    validateFormat() {
        if (!this.idType || !this.idNumber) return { isValid: false, errorMessage: 'Please provide both ID type and number.' };
        const trimmed = this.idNumber.trim();
        if (this.idType === 'ID' && !/^\d{13}$/.test(trimmed)) return { isValid: false, errorMessage: 'Identification Number must be 13 digits.' };
        if (this.idType === 'PASSPORT' && !/^[A-Za-z0-9]{6,9}$/.test(trimmed)) return { isValid: false, errorMessage: 'Passport number must be 6-9 alphanumeric characters.' };
        if ((this.idType === 'CIF' || this.idType === 'ACCOUNT') && !/^\d+$/.test(trimmed)) return { isValid: false, errorMessage: `${this.getLabelForType(this.idType)} must contain only digits.` };
        return { isValid: true };
    }

    handleUploadFinished(event) {
        if (!event?.detail?.files) return;
        this.uploadedFiles = [...this.uploadedFiles, ...event.detail.files];
        this.updateFlowAttribute();
    }

    handleRemoveFile(event) {
        const docId = event?.detail?.item?.name;
        if (!docId) return;
        this.uploadedFiles = this.uploadedFiles.filter(f => f.documentId !== docId);
        this.updateFlowAttribute();
    }

    updateFlowAttribute() {
        this.contentDocumentIds = this.uploadedFiles.map(f => f.documentId).join(',');
        this.contentDocumentId = this.uploadedFiles[0]?.documentId || '';
        this.contentDocumentNames = this.uploadedFiles.map(f => f.name).join(',');

        this.dispatchEvent(new FlowAttributeChangeEvent('contentDocumentIds', this.contentDocumentIds));
        this.dispatchEvent(new FlowAttributeChangeEvent('contentDocumentId', this.contentDocumentId));
        this.dispatchEvent(new FlowAttributeChangeEvent('contentDocumentNames', this.contentDocumentNames));
    }

    @api
    validate() {
        this.errorMessage = '';
        if (!this.idType) { this.errorMessage = 'Please select an Identification type.'; return { isValid:false, errorMessage:this.errorMessage }; }
        if (!this.idNumber) { this.errorMessage = `Please enter ${this.getLabelForType(this.idType)} number.`; return { isValid:false, errorMessage:this.errorMessage }; }
        const validationResult = this.validateFormat();
        if (!validationResult.isValid) { this.errorMessage = validationResult.errorMessage; return { isValid:false, errorMessage:this.errorMessage }; }
        if (!this.hasClientInfo) { this.errorMessage = 'Please search and select a valid client before proceeding.'; return { isValid:false, errorMessage:this.errorMessage }; }
        return { isValid:true };
    }
}