import { LightningElement, track, api, wire} from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import CASE_NUMBER from "@salesforce/schema/Case.CaseNumber";
import {
    DATA_SOURCE_TYPE, 
    handleFetchCoreBankingTransactions, 
    handleFetchCardTransactions, 
    handleFetchATMTransactionEvents, 
    handleFetchATMDeviceEvents,
    handleSaveCoreBankingTransactions, 
    handleSaveCardTransactions, 
    handleSaveATMTransactionEvents, 
    handleSaveATMDeviceEvents
} from 'c/capitec_TrackAndTraceDataLoader';
/**
 * manage track&trace process and display
 * modules dependant on current process step.
 */


export default class Capitec_TrackAndTrace extends LightningElement {
    isLoading = false;
    dataFetchError = false;
    storedIdError = false;
    flaggedItemsError = false;
    isItemsFlagged = false;

    storedDeviceId = null;

    flaggedItemsCount = 0;
    record = null;

    @api recordId;
    @api source;
    @api active;
    @track fetchedData = [];
    @track flaggedItems={};
    @track inputs = {
        startDate: new Date(Date.now()).toISOString(),
        endDate: new Date(Date.now()+ 3600).toISOString(),
        accountNumber: '',
        fromAccountNumber: '',
        toAccountNumber: '',
        deviceId: '',
        startDateTime: new Date(Date.now()).toISOString(),
        endDateTime: new Date(Date.now()+ 3600).toISOString(),
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [CASE_NUMBER]
      })
      wiredRecordUI({ error, data }) {
        if(data){
            this.record = data;
        } else if (error) {
            console.error(error)
        }
      }

    handleInputChange = (event) => {   
        this.inputs[event.target.name] = event.target.value;
    }

    handleFetchData = async () => {
        this.dataFetchError = false;
        this.storedIdError = false;
        this.isLoading = true;

        switch(this.source){
            case DATA_SOURCE_TYPE.CORE_BANKING_TRANSACTIONS:
                this.fetchedData = JSON.parse(await handleFetchCoreBankingTransactions(this.inputs.accountNumber, this.inputs.startDate, this.inputs.endDate), null);
                break;
            case DATA_SOURCE_TYPE.CARD_TRANSACTIONS:
                this.fetchedData = JSON.parse(await handleFetchCardTransactions(this.inputs.fromAccountNumber, this.inputs.startDate, this.inputs.endDate), null);
                break;
            case DATA_SOURCE_TYPE.ATM_TRANSACTION_EVENTS:
                console.log(this.handleAddTwoHours(this.inputs.startDateTime), this.handleAddTwoHours(this.inputs.endDateTime));
                this.fetchedData = JSON.parse(await handleFetchATMTransactionEvents(this.inputs.deviceId, this.handleAddTwoHours(this.inputs.startDateTime), this.handleAddTwoHours(this.inputs.endDateTime)), null);
                break;
            case DATA_SOURCE_TYPE.ATM_DEVICE_EVENTS:
                console.log(this.handleAddTwoHours(this.inputs.startDateTime), this.handleAddTwoHours(this.inputs.endDateTime));
                if(this.inputs.deviceId){
                    this.fetchedData = JSON.parse(await handleFetchATMDeviceEvents(this.inputs.deviceId, this.handleAddTwoHours(this.inputs.startDateTime), this.handleAddTwoHours(this.inputs.endDateTime)), null);
                } else {
                    this.storedIdError = true;
                }
                break;
            default:
                console.log('default');
                break;
        }
        console.log(JSON.stringify(this.fetchedData));
        this.isLoading = false;
    }

    handleSaveCSV(){
        try{
            this.flaggedItems = this.template.querySelector('c-capitec_-data-table').handleExportToCSV(this.record?.fields?.CaseNumber?.value, this.source);
        }
        catch (error){
            console.log(error.message);
        }
    }

    handleSaveFlaggedData = () => {
        this.flaggedItemsError = false
        this.isLoading = true;

        this.flaggedItems = this.template.querySelector('c-capitec_-data-table').handleFlagData();
        this.flaggedItems = { caseId: this.recordId, content: this.flaggedItems };
        switch(this.source){
            case DATA_SOURCE_TYPE.CORE_BANKING_TRANSACTIONS:
                handleSaveCoreBankingTransactions(this.flaggedItems);
                break;
            case DATA_SOURCE_TYPE.CARD_TRANSACTIONS:
                handleSaveCardTransactions(this.flaggedItems);
                break;
            case DATA_SOURCE_TYPE.ATM_TRANSACTION_EVENTS:
                handleSaveATMTransactionEvents(this.flaggedItems);
                break;
            case DATA_SOURCE_TYPE.ATM_DEVICE_EVENTS:
                handleSaveATMDeviceEvents(this.flaggedItems);
                break;
            default:
                console.log('flagged error');
                break;
        }
        this.isItemsFlagged = true;
        setTimeout(() => {
            this.isItemsFlagged = false;
        }, 3000);
        this.isLoading = false;
    }

    handleOnCount = (event) => {
        this.flaggedItemsCount = event.detail.count;
    }

    handleAddTwoHours = (datestring) => {
        const hours = (+(datestring[11] + datestring[12]) + 2 > 23 ? +(datestring[11] + datestring[12]) - 22 : +(datestring[11] + datestring[12]) + 2) + '';
        const date =  (+(datestring[11] + datestring[12]) + 2 > 23 ? +(datestring[8] + datestring[9]) + 1 : (datestring[8] + datestring[9]));
        const hoursString = hours.length > 1 ? hours : `0${hours}`;
        return datestring.substring(0, 8) + date + 'T' + hoursString + datestring.substring(13);
    }

    get isFirstStep(){
        return  this.source === DATA_SOURCE_TYPE.CORE_BANKING_TRANSACTIONS;
    }
    get isSecondStep(){
        return  this.source === DATA_SOURCE_TYPE.CARD_TRANSACTIONS;
    }
    get isThirOrFourthStep(){
        return  this.source === DATA_SOURCE_TYPE.ATM_TRANSACTION_EVENTS || this.source === DATA_SOURCE_TYPE.ATM_DEVICE_EVENTS;
    }
    get isSendFlaggedItemsButtonActive(){
        return !this.flaggedItemsCount;
    }

    get isSendCSVButtonActive(){
        return !this.fetchedData?.content?.length;
    }
    get buttonClasses(){
        return this.source === DATA_SOURCE_TYPE.ATM_DEVICE_EVENTS ? "slds-button slds-button_brand slds-m-top_medium panel-button last-button" : "slds-button slds-button_brand slds-m-top_medium panel-button";
    }
    get iconClass(){
        return this.flaggedItemsCount ? "icon" : "icon-disabled";
    }
}