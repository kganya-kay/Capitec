/**
 * Created by dawid on 02.11.2023.
 */


import {api, LightningElement, track, wire} from 'lwc';
import {calculateTotalFlaggedTransactionValueAndUpdateCase, caseActionsGetChased, caseActionsGetFlaggedChased,caseActionsGetFlaggedChasedInit, postApplyActions, preparePopupsContent, postConfirmHold, fetchConsultantCPByCaseId} from 'c/capitec_FraudTHDataHandler' //FFSF-424: added fetchConsultantCPByCaseId
import LightningAlert from "lightning/alert";
import fraudModal from 'c/capitec_FraudModal';
import {NavigationMixin} from 'lightning/navigation'; //FFSF-428: added to use NavigationMixin

export default class CapitecFraudCaseActions extends NavigationMixin(LightningElement) { //FFSF-428: added NavigationMixin to use NavigationMixin.Navigate

    @api recordId;

    @track showSpinner;
    @track consultantCP;
    @track jsonString;
    @track itemsToDisplay;
    @track contentEmpty = false;
    @track displayCommunicate = false;
    @track emptyTableCommunicate = 'There are no Items to be displayed for this case Id  ';

    handleRowClick(event) { //FFSF-428: added to handle row click
        const recordId = event.currentTarget.dataset.recordId;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Case',
                actionName: 'view',
            },
        });
    }

    refreshComponent(event){ //FFSF-579 Refresh button
        this.connectedCallback(); 
        //this.handleLoadData();
    }

    async recalculateAmtDefrauded(event){ //FFSF-851 Re-calculate amount defrauded
        this.showSpinner = true;
        // Run calculateTotalFlaggedTransactionValueAndUpdateCase() after all promises have completed
            await calculateTotalFlaggedTransactionValueAndUpdateCase(this.recordId); //FFSF-448 - Added function to update the Total Amount Defrauded on the Case record
        this.showSpinner = false;
    }

    async connectedCallback() { //FFSF-424: added async
        this.handleLoadData();
        this.handleApplyActions = this.handleApplyActions.bind(this);
        this.consultantCP = await fetchConsultantCPByCaseId(this.recordId); //FFSF-424: added to call fetchConsultantCPByCaseId and populate consultantCP
    }


    handleFlag(event){
      this.itemsToDisplay[event.target.dataset.itemId].newFraudFlagged = event.target.checked;
    }



    handleHold(event){
        if(event.target.checked){
            this.itemsToDisplay[event.target.dataset.itemId].newHoldFlagged = event.target.checked;
        }
        else{
            this.itemsToDisplay[event.target.dataset.itemId].newHoldFlagged = event.target.checked;
            this.itemsToDisplay[event.target.dataset.itemId].newConfirmHold = event.target.checked;
        }
    }



    handleConfirm(event){
        this.itemsToDisplay[event.target.dataset.itemId].newConfirmHold = event.target.checked;
    }



    async handleLoadData(){
        this.itemsToDisplay = [];

        this.showSpinner = true;

        await caseActionsGetFlaggedChasedInit(this.recordId).then(result =>{
            this.itemsToDisplay = result;

            if(Array.isArray(this.itemsToDisplay) === false || this.itemsToDisplay.length < 1){
                this.displayCommunicate = true;
                this.contentEmpty = true;
            }
            else{
                this.displayCommunicate = false;
                this.contentEmpty = false            }
        });

        this.showSpinner = false;
    }



    async handleApplyActions(event){
        this.showSpinner = true;

        let itemsToFraudHoldFlag = {transactions : [], caseId : this.recordId, consultantIdentifier : this.consultantCP};
        let itemsToConfirmHold = []; // this should link to the consultant CP number

        this.itemsToDisplay.forEach(item => {
            if((item.flaggedFraud !== item.newFraudFlagged) || (item.flaggedHold !== item.newHoldFlagged)){
                itemsToFraudHoldFlag.transactions.push(item);
            }
        });

        this.itemsToDisplay.forEach(item => {
            if(!item.confirmHold && item.newConfirmHold){
                itemsToConfirmHold.push({transactionId : item.tranId, caseId : item.caseId});
            }
        });

        if (itemsToFraudHoldFlag.transactions.length < 1 && itemsToConfirmHold.length < 1){
            await this.displayNoRecordsSelectedWarning();
            this.showSpinner = false;
            return;
        }

        let modalContent = preparePopupsContent(itemsToFraudHoldFlag);
        let userConfirmed = await this.showModal(modalContent, 'You are about to mark selected records as fraud or hold flagged, do You wish to proceed?');
        let promises = [];
        if(!userConfirmed) return;

        let actionsSuccessful = true;

        if(itemsToFraudHoldFlag.transactions.length > 0) { //FFSF-423: added to check if there are any items to be fraud or hold flagged before calling postApplyActions
            promises.push(postApplyActions(itemsToFraudHoldFlag).then(result => {
                try {
                    if (!(JSON.stringify(result) === "204" || JSON.stringify(result) === "200")) {
                        actionsSuccessful = false;
                    }
                } catch (e) {
                    actionsSuccessful = false;
                }
            }));
        }

        if(itemsToConfirmHold.length > 0) { //FFSF-423: added to check if there are any items to be confirmed before calling postConfirmHold
            promises.push(postConfirmHold(itemsToConfirmHold).then(result => {
                try {
                    if (!(JSON.stringify(result) === "204" || JSON.stringify(result) === "200")) {
                        actionsSuccessful = false;
                    }
                } catch (e) {
                    actionsSuccessful = false;
                    window.location.reload();
                }
            }));
        }


        Promise.all(promises)
            .then((results) => {
                // All promises resolved successfully
            })
            .catch((error) => {
                // At least one promise rejected
            });

        // Wait for all promises to resolve
        await Promise.all(promises);


        if(actionsSuccessful){
            await LightningAlert.open({
                message: 'Success',
                theme:'success',
                label: 'Success!',
            });
        }
        else{
            await LightningAlert.open({
                message: 'An issue has occured',
                theme:'warning',
                label: 'One of more actions did not succeed. Please try again later',
            });
            window.location.reload();
        }

        this.showSpinner = false;
        // await this.handleGetTransactions('');

        // Run calculateTotalFlaggedTransactionValueAndUpdateCase() after all promises have completed
        calculateTotalFlaggedTransactionValueAndUpdateCase(this.recordId); //FFSF-448 - Added function to update the Total Amount Defrauded on the Case record

    }

    async showModal(modalContent, header){
        const confirmFlag = await fraudModal.open({
            size: 'large',
            description: 'Accessible description of modal\'s purpose',
            content: modalContent,
            header: header
        });

        if(!confirmFlag){
            this.showSpinner = false;
            return false
        }

        return true;
    }



    async displayNoRecordsSelectedWarning(){
        await LightningAlert.open({
            message: 'No records were selected',
            theme:'warning',
            label: 'Warning',
        });
    }



}