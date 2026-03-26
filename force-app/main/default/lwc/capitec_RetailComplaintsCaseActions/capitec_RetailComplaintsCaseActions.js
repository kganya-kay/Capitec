/**
 * 
 * Created by Pako on 16.02.2024.
 * 
 */


import {api, LightningElement, track, wire} from 'lwc';
import {caseActionsGetFlagged, postApplyActions, preparePopupsContent, postConfirmHold, fetchConsultantCPByCaseId} from 'c/capitec_RetailComplaintsTHDataHandler'
import LightningAlert from "lightning/alert";
import retailComplaintsModal from 'c/capitec_RetailComplaintsModal';
import {NavigationMixin} from 'lightning/navigation'; //FFSF-428: added to use NavigationMixin

export default class CapitecRetailComplaintsCaseActions extends NavigationMixin(LightningElement) { //FFSF-428: added NavigationMixin to use NavigationMixin.Navigate

    @api recordId;
    @api isFlow;

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
    }

    async connectedCallback() { //FFSF-424: added async
        this.handleLoadData();
        this.handleApplyActions = this.handleApplyActions.bind(this);
        this.consultantCP = await fetchConsultantCPByCaseId(this.recordId); //FFSF-424: added to call fetchConsultantCPByCaseId and populate consultantCP
    }

    handleFlag(event){
        this.itemsToDisplay[event.target.dataset.itemId].newRetailComplaintsFlagged = event.target.checked;
    }

    handleConfirm(event){
        this.itemsToDisplay[event.target.dataset.itemId].newConfirmHold = event.target.checked;
    }

    async handleLoadData(){

        this.showSpinner = true;

        await caseActionsGetFlagged(this.recordId).then(result =>{

            this.itemsToDisplay = result;

            if(Array.isArray(this.itemsToDisplay) === false || this.itemsToDisplay.length < 1){
                this.displayCommunicate = true;
                this.contentEmpty = true;
            }
            else{
                this.displayCommunicate = false;
                this.contentEmpty = false;
            }
        });

        this.showSpinner = false;
    }

    async handleApplyActions(event){
        this.showSpinner = true;
        console.log('***' + JSON.stringify(this.consultantCP)); //FFSF-424: added to check consultantCP value

        let itemsToRetailComplaintsHoldFlag = {transactions : [], caseNumber : this.recordId, consultantIdentifier : this.consultantCP};
        let itemsToConfirmHold = []; // this should link to the consultant CP number

        this.itemsToDisplay.forEach(item => {
            if((item.retailComplaintsFlagged !== item.newRetailComplaintsFlagged)){
                itemsToRetailComplaintsHoldFlag.transactions.push(item);
            }
        });

        let modalContent = preparePopupsContent(itemsToRetailComplaintsHoldFlag);
        let userConfirmed = await this.showModal(modalContent, 'You are about to mark selected records as retail complaints flagged, do you wish to proceed?');
        let promises = [];
        if(!userConfirmed) return;

        let actionsSuccessful = true;

        if(itemsToRetailComplaintsHoldFlag.transactions.length > 0) {
            promises.push(postApplyActions(itemsToRetailComplaintsHoldFlag).then(result => {
                try {
                    if (!(JSON.stringify(result) === "204" || JSON.stringify(result) === "200")) {
                        actionsSuccessful = false;
                    }
                } catch (e) {
                    console.log(JSON.stringify(e.message));
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
                    console.log(JSON.stringify(e.message));
                    actionsSuccessful = false;
                    window.location.reload();
                }
            }));
        }

        Promise.all(promises)
            .then((results) => {
                // All promises resolved successfully
                console.log('All promises resolved:', results);
            })
            .catch((error) => {
                // At least one promise rejected
                console.log('A promise failed:', error);
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
    }

    async showModal(modalContent, header){
        const confirmFlag = await retailComplaintsModal.open({
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