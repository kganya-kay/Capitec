import { LightningElement, api, wire, track } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import getDebitOrders from '@salesforce/apex/Capitec_DebitOrderController.getDebitOrders';
import getCaseInfo from '@salesforce/apex/Capitec_DebitOrderController.getCaseInfo';
import submitCase from '@salesforce/apex/Capitec_DebitOrderController.caseSubmission';
import checkFiles from '@salesforce/apex/Capitec_DebitOrderController.getUnclassifiedFiles';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import Conversions_BulkWithdrawal from 'c/conversions_BulkWithdrawal';

export default class Capitec_ConversionsDebitOrders extends LightningElement {
    @api recordId;
    @api selectedDO;
    @api editDO = false;
    @track debitOrders = [];
    @track allDebitOrders = [];
    @track selectedDOs = [];
    @track caseRecord;
    @track showSpinner = false;
    @track showDeditOrderModal = false;
    @track showRefreshMessage = false;
    @track selectedDebitOrderId = null;
    @track hideSubmit = false;
    @track disableSubmitBtn = false;
    @track showDelete = false;
    @track showConfirmModal = false;
    @track caseInProgress = false;
    @track manualCase = false;
    @track showWithdraw = false;
    @track modalTitle = 'New Debit Order';
    @track modalInstruction = 'Please enter the following details related to the debit order switch.';
    @track confirmationMsg = 'Please ensure that you want to permanently delete the selected debit order.';
    @track helpMsg = 'Select the debit order(s) from the list below to submit.';
    wiredDebitOrdersResult;


    connectedCallback() {
        this.getCaseInfo();
    }

    @wire(getDebitOrders, { caseId: '$recordId' })
    wiredDebitOrders(result) {
        this.wiredDebitOrdersResult = result;
        this.disableSubmitBtn =  false;
        this.helpMsg = 'Select the debit order(s) from the list below to submit.';

        console.log('## SAU result:', JSON.stringify(result));

        if (result.data) {
            this.debitOrders = result.data.map(order => {
                if(order.DO_Issue__c != null){
                    this.disableSubmitBtn =  true;
                    this.helpMsg = 'All debit order flags must be cleared before submission';
                }

                return {
                    ...order,
                    InitiatorName: order.Debit_Order_Initiator__r?.Name || '',
                    InitiatorPreferredComms: order.Debit_Order_Initiator__r?.Preferred_Comms__c || '',
                    InitiatorEmail: order.Debit_Order_Initiator__r?.DOI_Contact_Email__c || '',
                    isFlagged:order.DO_Issue__c != null ? true : false,
                    isSelected: false
                };
            });

            this.allDebitOrders = [...this.debitOrders];
            console.log('##SAU wired result:', JSON.stringify(this.debitOrders));

            if(this.caseInProgress && this.allDebitOrders.length == 0){
                this.hideSubmit = true;
            }
        } else if (result.error) {
            this.showToast('Error', 'Failed to load debit orders', 'error');
            this.hideSubmit = true;
            console.error(result.error);
        }
    }

    get debitOrderCountTitle() {
        const count = this.allDebitOrders ? this.allDebitOrders.length : 0;
        return 'Debit Orders [' + count + ']';
    }

    get showSubmit() {
        return (
            this.caseInProgress === true &&
            this.allDebitOrders &&
            this.allDebitOrders.length !== 0
        );
    }

    getCaseInfo() {
        getCaseInfo({ caseId: this.recordId })
            .then(result => {
                this.caseRecord = result.caseRecord;

                this.caseInProgress = this.caseRecord?.Status === 'In Progress';
                this.manualCase = result.manualCase;

                if (!this.caseInProgress || this.allDebitOrders.length === 0) {
                    this.hideSubmit = true;
                } else {
                    this.hideSubmit = false;
                }

                console.log('##SAU Case fetched:', JSON.stringify(result));
                console.log('##SAU Case record:', JSON.stringify(this.caseRecord));
                console.log('##SAU this.showDelete:', this.showDelete);
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load case details', 'error');
                console.error(error);
            });
    }

    handleSearch(event) {
        const searchTerm = event.target.value.toLowerCase();

        if (!searchTerm) {
            this.debitOrders = [...this.allDebitOrders];
        } else {
            this.debitOrders = this.allDebitOrders.filter(order =>
                                    order.Name && order.Name.toLowerCase().includes(searchTerm)
                               );
        }
    }
        
    handleViewDetails(event) {
        const selectedId = event.currentTarget.dataset.id;

        const selectedRow = this.debitOrders.find(
            order => order.Id === selectedId
        );

        if (selectedRow) {
            console.log('## Selected row:' + JSON.stringify(selectedRow));
            this.editDO = true;
            this.selectedDebitOrderId = selectedRow.Id;
            this.selectedDO = selectedRow;
            this.showDeditOrderModal = true;
        }
    }

    handleNewClick() {
        this.editDO = false;
        this.selectedDO = null;
        this.showDeditOrderModal = true;
    }

    handleSubmit(event){
        this.showSpinner = true;

        const hasUnreviewed = this.allDebitOrders?.some(order => order.Reviewed__c === false);
        console.log('##hasUnreviewed:' + hasUnreviewed);

        if (hasUnreviewed) {
            this.showToast(
                'Error',
                'Please review all debit orders before Submitting.',
                'error'
            );
            this.showSpinner = false;
        }
        else{
            let hasUnclassifiedFiles = false;

            checkFiles({caseId: this.recordId })
                        .then(result => {
                            hasUnclassifiedFiles = result;
                            console.log('## hasUnclassifiedFiles:' + JSON.stringify(result));

                            if(hasUnclassifiedFiles){
                                this.showToast(
                                    'Error',
                                    'Please classify all files before Submitting.',
                                    'error'
                                );
                                this.showSpinner = false;
                            }
                            else{
                                this.submitCase();
                            }
                        })
                        .catch(error => {
                            console.error('Error:', error);
                        });
        }
    }

    handleDelete(event) {
        let numDOs = this.selectedDOs.length;
        console.log('## Number of selected DOs:' + numDOs);

        this.showConfirmModal = true;
        this.confirmationMsg = ( numDOs > 1) ? 'Please ensure that you want to permanently delete the selected ' + numDOs + ' debit orders.' : 
                                               'Please ensure that you want to permanently delete the selected debit order.';
      
    }
    handleRowSelect(event) {
        const selectedId = event.target.dataset.id;
        const checked = event.target.checked;

        this.debitOrders = this.debitOrders.map(order =>
            order.Id === selectedId
                ? { ...order, isSelected: checked }
                : order
        );

        this.updateSelectionState();
    }

    handleSelectAll(event) {
        const checked = event.target.checked;

        this.debitOrders = this.debitOrders.map(order => ({
            ...order,
            isSelected: checked
        }));

        this.updateSelectionState();
    }
    async handleWithdraw(){
        const result = await Conversions_BulkWithdrawal.open({
            size: 'small',
            description: 'Bulk Withdrawal',
            debitOrders: this.selectedDOs
        });

        if (result === true) {
            this.showToast('Success', 'Debit Orders withdrawn successfully', 'success');
        }
        
   
        this.debitOrders = this.debitOrders.map(order => ({
            ...order,
            isSelected: false
        }));

                const selectAll = this.template.querySelector('[data-id="selectAll"]');
        if (selectAll) {
            selectAll.checked = false;
        }

        this.selectedDOs = [];
        this.showWithdraw = false;
        this.showDelete = false;
    }

    updateSelectionState() {
        this.selectedDOs  = this.debitOrders.filter(order => order.isSelected);
        this.hideSubmit   = this.selectedDOs.length != 0;
        this.showDelete   = this.caseInProgress && this.selectedDOs.length > 0 && !this.manualCase;
        this.showWithdraw = this.caseInProgress && this.selectedDOs.length > 1;

        console.log('Selected rows:', JSON.stringify(this.selectedDOs));
    }

    submitCase() {
        console.log('##SAU submitCase started')
        submitCase({ caseId: this.recordId, lstDOs: this.allDebitOrders})
                        .then(result => {
                            console.log('##result:' + JSON.stringify(result));
                            if (result) {
                                this.showToast('Success', 'Case status updated.', 'success');
                            } 
                            this.showSpinner = false;
                            window.location.reload();
                        })
                        .catch(error => {
                            console.error('submitCase Error updating case status:', error);
                            this.showSpinner = false;
                        });
    }
    
    closeModal() {
        this.showDeditOrderModal = false;               
    }

    closeConfirmationModal() {
        this.showConfirmModal = false;
    }

    refreshData() {
        return refreshApex(this.wiredDebitOrdersResult);
    }

    async confirmDelete() {
        this.showConfirmModal = false;
        this.showSpinner = true;
        const idsToDelete = this.selectedDOs.map(row => row.Id);

        try {
            await Promise.all(idsToDelete.map(id => deleteRecord(id)));

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Selected debit order(s) deleted successfully.',
                    variant: 'success'
                })
            );

            this.refreshData();
            this.selectedDOs = [];
            this.showDelete = false;
            this.showSpinner = false;
            this.hideSubmit = this.selectedDOs.length != 0;
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error deleting records',
                    message: error.body?.message || error.message,
                    variant: 'error'
                })
            );
            this.showSpinner = false;
        }
    }

    handleShowRefreshMessage() {
        this.showRefreshMessage = true;
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