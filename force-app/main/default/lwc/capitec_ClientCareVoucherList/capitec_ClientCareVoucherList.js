import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getVoucherList from '@salesforce/apex/capitec_SendCashVoucherController.getVoucherList';
import blockVoucher from '@salesforce/apex/capitec_SendCashVoucherController.callHoldVoucher';
import releaseVoucher from '@salesforce/apex/capitec_SendCashVoucherController.callReleaseVoucher';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import { refreshApex } from '@salesforce/apex'; // Import refreshApex

export default class Capitec_ClientCareVoucherList extends OmniscriptBaseMixin(LightningElement) {
    @api recordId; // Account Id passed from the parent component
    @api actionType;

    @track vouchers = []; // To hold the voucher data
    @track error;
    @track actionTypelabel;
    @track showHoldRelease = true;

    //CEDT-3492 - Add flag option
    connectedCallback(){
        if(this.actionType === 'Hold'){
            this.actionTypeLabel = 'Hold';
            this.showHoldRelease = true;
        }else if(this.actionType === 'Release'){
            this.actionTypeLabel = 'Release';
            this.showHoldRelease = true;
        } else if(this.actionType === 'Flag') {
            this.actionTypeLabel = 'Flag';
            this.showHoldRelease = false;
        }
    }

    // Store the wired results for refresh
    wiredVoucherResult;

    // Apex call to get external object data
    @wire(getVoucherList, { recordId: '$recordId', actionType: '$actionType' })
    wiredVouchers(result) {
        this.wiredVoucherResult = result; // Store the result
        this.handleVoucherData(result);
    }

    // Handle the voucher data and error
    handleVoucherData(result) {
        const { error, data } = result; // Destructure result

        if (data) {
            const parsedData = JSON.parse(data);

            // Format dates in the parsed data
            parsedData.forEach(currentItem => {
                if (currentItem.DateCreated) {
                    const dateObj = new Date(currentItem.DateCreated);
                    currentItem.DateCreatedFormatted = this.formatDate(dateObj);
                }
                if (currentItem.DateModified) {
                    const dateObj = new Date(currentItem.DateModified);
                    currentItem.DateModifiedFormatted = this.formatDate(dateObj);
                }
            });

            this.vouchers = parsedData;
        } else if (error) {
            this.error = error;
        }
    }

    // Method to handle button click in each row
    handleHoldAction(event) {
        const accountId = this.recordId;
        const voucherNumber = event.target.dataset.voucher;

        blockVoucher({ accountId, orderReference: voucherNumber })
            .then(() => {
                this.showToast('Success', 'Voucher Blocked Successfully', 'success');
                const data = {
                    "VoucherOutcome": 'The Send Cash Voucher has been blocked'
                };
                this.omniApplyCallResp(data);

                // Clear and refresh the table after success
                return this.refreshTable();
            })
            .catch(error => {
                this.showToast('Error', 'Error blocking voucher: ' + error, 'error');
            });
    }

    // Method to handle button click in each row
    handleReleaseAction(event) {
        const accountId = this.recordId;
        const voucherNumber = event.target.dataset.voucher;

        releaseVoucher({ accountId, orderReference: voucherNumber })
            .then(() => {
                this.showToast('Success', 'Voucher Released Successfully', 'success');
                const data = {
                    "HoldOnVoucherReleased": true
                };
                this.omniApplyCallResp(data);

                // Clear and refresh the table after success
                return this.refreshTable();
            })
            .catch(error => {
                this.showToast('Error', 'Error releasing voucher: ' + error, 'error');
            });
    }

    //CEDT-3492 - Add flag option
    handleFlagAction(event) {
        const voucherNumber = event.target.dataset.voucher;

        const data = {
            "cdVoucherNumber": voucherNumber.slice(-4)
        };
        this.omniApplyCallResp(data);
    }

    // Method to refresh the table data
    refreshTable() {
        return refreshApex(this.wiredVoucherResult) // Re-trigger @wire to fetch updated data
            .catch(error => {
                this.showToast('Error', 'Error refreshing data: ' + error, 'error');
            });
    }

    // Utility method to show toast messages
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(toastEvent);
    }

    formatDate(dateObj) {
        const options = { year: 'numeric', month: '2-digit', day: '2-digit' };
        const datePart = dateObj.toLocaleDateString('en-GB', options).split('/').join('-'); // Format: DD-MM-YYYY
        const timePart = dateObj.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' }); // Format: hh:mm
        return `${datePart} ${timePart}`; // Combine the date and time
    }
}