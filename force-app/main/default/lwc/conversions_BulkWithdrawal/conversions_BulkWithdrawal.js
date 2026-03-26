import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DEBIT_ORDER_OBJECT from '@salesforce/schema/Debit_Order__c';
import WITHDRAWAL_FIELD from '@salesforce/schema/Debit_Order__c.Withdrawn_Cause_Code__c';
import updateDebitOrders from '@salesforce/apex/Capitec_DebitOrderController.updateDebitOrders';

export default class Conversions_BulkWithdrawal extends LightningModal {
    @api debitOrders = [];
    withdrawalOptions = [];
    selectedWithdrawalValue = '';
    showSpinner = false;

    @wire(getObjectInfo, { objectApiName: DEBIT_ORDER_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: WITHDRAWAL_FIELD
    })
    wiredPicklistValues({ data, error }) {
        if (data) {
            this.withdrawalOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Picklist error', error);
        }
    }

    handleWithdrawalChange(event) {
        this.selectedWithdrawalValue = event.detail.value;
    }

    handleCancel() {
        this.close();
    }

    async handleSave() {
        const combo = this.template.querySelector('lightning-combobox');

        if (!combo.checkValidity()) {
            combo.reportValidity();
            return;
        }

        this.showSpinner = true;

        try {
            const result = await updateDebitOrders({
                lstDOs: this.debitOrders,
                causeCode: this.selectedWithdrawalValue
            });
            console.log('## result:' + result);

            if (result == true) {
                this.showToast('Success', 'Debit order(s) updated successfully.', 'success');
                this.close(true);
            } else {
                this.showToast('Error', 'Failed to update debit orders.', 'error');
            }
            this.showSpinner = false;
            
        } catch (error) {
            this.showSpinner = false;
            this.showToast('Error', 'Failed to update debit orders.', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}