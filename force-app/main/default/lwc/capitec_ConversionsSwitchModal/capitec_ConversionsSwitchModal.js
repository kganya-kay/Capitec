import { LightningElement, api, track } from 'lwc';

export default class Capitec_ConversionsSwitchModal extends LightningElement {

    currentStep = 'step1';

    @api isOpen = false;
    @api debitOrders = [];
       
    @track fromAccount = '12345678';
    @track toAccount = 'main';
    @track initiator = 'Outsurance';
    @track referenceNumber = 'OT12345678';
    @track amount = '1200.00';
    @track paymentDate = '2025-05-01';
    @track futureDate;

    @track showScreen1 = true;
    @track showScreen2 = false;



    connectedCallback() {
        console.log('##SAU Child Modal launched');
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }


    get fromAccountOptions() {
        return [
            { label: 'Account Name - 12345678', value: '12345678' }
        ];
    }

    get toAccountOptions() {
        return [
            { label: 'Main Account - 12345678', value: 'main' }
        ];
    }

    handleFromAccountChange(event) {
        this.fromAccount = event.detail.value;
    }

    handleToAccountChange(event) {
        this.toAccount = event.detail.value;
    }

    handleInitiatorChange(event) {
        this.initiator = event.detail.value;
    }

    handleReferenceChange(event) {
        this.referenceNumber = event.detail.value;
    }

    handleAmountChange(event) {
        this.amount = event.detail.value;
    }

    handlePaymentDateChange(event) {
        this.paymentDate = event.detail.value;
    }

    handleFutureDateChange(event) {
        this.futureDate = event.detail.value;
    }

    handleNext() {
        console.log('Next clicked. Form values:', {
            fromAccount: this.fromAccount,
            toAccount: this.toAccount,
            initiator: this.initiator,
            referenceNumber: this.referenceNumber,
            amount: this.amount,
            paymentDate: this.paymentDate,
            futureDate: this.futureDate
        });

        this.showScreen1 = false;
        this.showScreen2 = true;
        this.currentStep = 'step2';
    }
}