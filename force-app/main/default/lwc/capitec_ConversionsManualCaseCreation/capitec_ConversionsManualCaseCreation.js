import { LightningElement, track } from 'lwc';

export default class Capitec_ConversionsManualCaseCreation extends LightningElement {

    @track currentStep = 1;

    // Sidebar Steps
    stepList = [
        { id: 1, label: 'Client Identification' },
        { id: 2, label: 'Consent Form' },
        { id: 3, label: 'Case Information' },
        { id: 4, label: 'Debit Order Details' },
        { id: 5, label: 'Summary' }
    ];

    get steps() {
        return this.stepList.map(step => ({
            ...step,
            class: step.id === this.currentStep ? 'step active' : 'step'
        }));
    }

    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isStep3() { return this.currentStep === 3; }
    get isStep4() { return this.currentStep === 4; }
    get isStep5() { return this.currentStep === 5; }

    get isFirstStep() { return this.currentStep === 1; }
    get isLastStep() { return this.currentStep === 5; }

    // Collected data for Summary
    summaryData = {
        caseorigin: '',
        issue: '',
        cifNumber: '',
        idNumber: '',
        passportNumber: '',
        salutation: '',
        firstName: '',
        lastName: '',
        primaryNumber: '',
        secondaryNumber: '',
        mobileNumber: '',
        email: '',
        preferredContactTime: '',
        oldBranchCode: '',
        oldBankName: '',
        oldAccountNumber: '',
        debitOrders: [],
        additionalComments: ''
    };

    handleNext() {
        if (this.currentStep === 1) {
            const clientLwc = this.refs.clientIdentification;
            if (clientLwc) {
                const validation = clientLwc.validate();
                if (!validation.isValid) return;
                const clientData = clientLwc.getClientData();
                Object.assign(this.summaryData, {
                    cifNumber: clientData.clientInfo.CIFNumber,
                    idNumber: clientData.clientInfo.IDNumber,
                    passportNumber: clientData.clientInfo.PassportNumber,
                    salutation: clientData.clientInfo.Salutation,
                    firstName: clientData.clientInfo.FirstName,
                    lastName: clientData.clientInfo.LastName,
                    primaryNumber: clientData.clientInfo.HomeContactNumber,
                    secondaryNumber: clientData.clientInfo.WorkContactNumber,
                    mobileNumber: clientData.clientInfo.MobileNumber,
                    email: clientData.clientInfo.EmailAddress
                });
            }
        }

        if (this.currentStep === 4) {
            const relatedLwc = this.refs.relatedList;
            if (relatedLwc) {
                if (relatedLwc.validate && !relatedLwc.validate()) return;
                this.summaryData.debitOrders = relatedLwc.getDebitOrders();
            }
        }

        if (this.currentStep < 5) this.currentStep++;
    }

    handlePrevious() {
        if (this.currentStep > 1) this.currentStep--;
    }

    handleCancel() {
        this.currentStep = 1;
    }

    handleSubmit() {
        const relatedLwc = this.refs.relatedList;
        if (relatedLwc) this.summaryData.debitOrders = relatedLwc.getDebitOrders();

        console.log('Wizard Submitted:', this.summaryData);
        alert('Wizard Submitted! Check console for final data.');
    }

    handleStepClick(event) {
        const stepId = parseInt(event.currentTarget.dataset.id, 10);
        this.currentStep = stepId;
    }
}