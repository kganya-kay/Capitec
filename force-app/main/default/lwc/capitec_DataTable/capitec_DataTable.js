import { LightningElement ,api,track} from 'lwc';
import {DATA_SOURCE_TYPE} from 'c/capitec_TrackAndTraceDataLoader';
import fetchCardTransactionsFlagged from '@salesforce/apex/Capitec_TrackAndTraceFlaggingHandler.selectCardTransactionsIds'
import fetchATMDeviceEventsFlagged from '@salesforce/apex/Capitec_TrackAndTraceFlaggingHandler.selectATMDeviceEventsIds'
import fetchATMTransactionEventsFlagged from '@salesforce/apex/Capitec_TrackAndTraceFlaggingHandler.selectATMTransactionEventIds'
import fetchCoreBankingAlreadyFlagged from '@salesforce/apex/Capitec_TrackAndTraceFlaggingHandler.selectCDDRIndicatorIds'

/**
 * This component is responsible for represents a table component for displaying data passed from a parent component.
 * @module c/capitec_TrackAndTrace
 * 
 * Created by Tomasz
 */

const CORE_BANKING_HEADERS = [
    'CR/DR Indicator',
    'Branch / Terminal',
    'Transaction Id',
    'Transaction Date',
    'Transaction Code',
    'Account Number',
    'Posting Date',
    'Journal Number',
    'Transaction Amount',
    'Promo Number',
    'Auth Id',
    'Narrative',
    'Available Balance'
];
const CARD_TRANSACTIONS = [
    'Postilion Transaction Id',
    'Office Transaction Number',
    'Timestamp',
    'Site Name',
    'Terminal ID',
    'Source Node',
    'Sink Node',
    'Tran postilion originated',
    'Card Product',
    'Transaction Type',
    'Response Code',
    'Card Number',
    'Retrieval Reference',
    'Auth ID',
    'Transaction Message Type',
    'Stan Number',
    'Recon Batch Number',
    'From Account',
    'To Account',
    'Request Amount',
    'Response Amount',
    'Settle Request Amount',
];

const ATM_TRANSACTION_EVENTS = [
    'Timestamp',
    'Site Name',
    'Terminal ID',
    'Event ID',
    'Severity',
    'Message',
];
const ATM_DEVICE_EVENTS = [
    'Source',
    'ATM ID',
    'Event Number',
    'Timestamp',
    'Event Description',
    'Original Message',
];


export default class Capitec_DataTable extends LightningElement {
    @track _itemsToDisplay; 
    @track flaggedItems = [];
    @track flaggedItemCount = 0;
    @api recordId
    @api source

    get isBankingTransactionTab() {
        return this.source==DATA_SOURCE_TYPE.CORE_BANKING_TRANSACTIONS;
    }

    get isCardTransactionTab() {
        return this.source==DATA_SOURCE_TYPE.CARD_TRANSACTIONS;
    }

    get isTransationEventsTab() {
        return this.source==DATA_SOURCE_TYPE.ATM_TRANSACTION_EVENTS;
    }

    get isATMEventsTab() {
        return this.source==DATA_SOURCE_TYPE.ATM_DEVICE_EVENTS;
    }

    @api
    set itemsToDisplay(val) {
        this._itemsToDisplay = JSON.parse(JSON.stringify(val));
        this._itemsToDisplay.content = this._itemsToDisplay.content?.reduce((acc, el) => (
            [...acc, Object.keys(el).reduce((acc2, key) => ({
                ...acc2,
                [key]: el[key] ?? '-'
                }), {})
            ]).sort((a, b) => {
                if(a?.transactionId == null) {
                    const dateA = new Date(a?.eventDateTime  ?? a?.transactionDateTime ?? a?.transactionDate);
                    const dateB = new Date(b?.eventDateTime ?? b?.transactionDateTime ?? b?.transactionDate);
                    return dateB - dateA;
                }else {
                    return b?.transactionId - a?.transactionId;
                }
                
            }), [])
            this._itemsToDisplay.content = this._itemsToDisplay.content?.map(item => {
                const isYellow = ['2', '30', '34', '46', '85'].includes(item.eventId);
                return {
                    ...item,
                    rowColor:  isYellow ? 'yellow-row' : '',
                };
            }
            );

        if(this.isBankingTransactionTab && this._itemsToDisplay.content) {
            fetchCoreBankingAlreadyFlagged({caseId: this.recordId}).then( result =>{
                this.markCheckboxes(result);
            });
        }
        else if(this.isCardTransactionTab){
            fetchCardTransactionsFlagged({caseId: this.recordId}).then( result =>{
                this.markCheckboxes(result);
            });
        }
        else if (this.isTransationEventsTab){
            fetchATMTransactionEventsFlagged({caseId: this.recordId}).then( result =>{
                this.markCheckboxes(result);
            });
        }
        else if(this.isATMEventsTab){
            fetchATMDeviceEventsFlagged({caseId: this.recordId}).then( result =>{
                this.markCheckboxes(result);
            });
        }

        try{
            this._itemsToDisplay.content.forEach(item => {
                if('eventDateTime' in item){
                    item.eventDateTime = this.ensureTimezoneCharacter(item.eventDateTime);
                    item.parsedEventDateTime = this.formatDateTime(item.eventDateTime);
                    return;
                }
                if('transactionDateTime' in item){
                    item.transactionDateTime = this.ensureTimezoneCharacter(item.transactionDateTime);
                    item.parsedTransactionDateTime = this.formatDateTime(item.transactionDateTime)
                }
            });
        }
        catch (e){
            console.log(e.message);
        }
   }

   ensureTimezoneCharacter(str) {
        if (!str.endsWith('Z')) {
            return str + 'Z';
        }
        return str;
    }

    formatDateTime(dateTimeString) {
        // Parse the date from the input string
        let date = new Date(dateTimeString);

        // Extract day, month, year, hours, and minutes
        let day = String(date.getUTCDate()).padStart(2, '0');
        let month = String(date.getUTCMonth() + 1).padStart(2, '0'); // Months are 0-indexed
        let year = date.getUTCFullYear();
        let hours = String(date.getUTCHours()).padStart(2, '0');
        let minutes = String(date.getUTCMinutes()).padStart(2, '0');
        let seconds = String(date.getSeconds()).padStart(2, '0');

        // Format the date and time
        return `${day}/${month}/${year}, ${hours}:${minutes}:${seconds}`;
    }

    

    markCheckboxes(transactionIds){
        try{
            this._itemsToDisplay.content.forEach(transaction => {
                if(transactionIds.includes(transaction.id)){
                    transaction.checked = true;
                }
            })
        }
        catch (e){
            console.log(e.message);
        }
    }


    get itemsToDisplay() {
        return this._itemsToDisplay;
    }
    get tableRowClass() {
        if (this.isTransationEventsTab ) {
            return 'yellow-row'; 
        }
        return ''; 
    }

    @api
    handleFlagData() {
        if (this.flaggedItems && this.flaggedItems.length > 0) {
            try {
                return this.flaggedItems;
            } catch (error) {
                console.error('Error while stringifying flaggedItems: ', error);
                return 'Error: Unable to stringify data';
            }
        } else {
            return 'No data to stringify';
        }
    }

    @api
    handleExportToCSV(caseId, source){

        let rows = this.template.querySelectorAll('[data-id="table-tr"]');
        let ths = this.template.querySelectorAll('th');
        let checkboxes = this.template.querySelectorAll('[data-id="checkbox"]');
        let csv_data = [];
        let csvHeaders = [];

        ths.forEach(header => {
           csvHeaders.push(header.innerHTML);
        });

        csv_data.push(csvHeaders.join(","));

        for (let i = 0; i < rows.length; i++) {
            let csvrow = [];
            let cols = rows[i].querySelectorAll('td,th');
            try{
                csvrow.push(checkboxes[i].checked);
            }
            catch(e){
                console.log(e.message);
            }
            for (var j = 1; j < cols.length; j++) {
                csvrow.push(escapeForCSV(cols[j].innerHTML));
            }
            csv_data.push(csvrow.join(","));
        }

        function escapeForCSV(text) {
            // If the text contains a comma, newline, or double quote,
            // wrap the text in double quotes and escape any double quotes inside it.
            if (text.includes(',') || text.includes('\n') || text.includes('"')) {
                return '"' + text.replace(/"/g, '""') + '"';
            }
            return text;
        }

        try{
            const csvContent = csv_data.join('\n');
            const blob = new Blob([csvContent], { type: 'text/plain' });
            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');

            link.href = url;


            switch(source){
                case DATA_SOURCE_TYPE.CORE_BANKING_TRANSACTIONS:
                    link.download = 'Annexure A_Core Banking Transactions_' + caseId + '.csv';
                    break;
                case DATA_SOURCE_TYPE.CARD_TRANSACTIONS:
                    link.download = 'Annexure B_Card Transaction_' + caseId + '.csv';
                    break;
                case DATA_SOURCE_TYPE.ATM_TRANSACTION_EVENTS:
                    link.download = 'Annexure C_ATM Transaction Events_' + caseId + '.csv';
                    break;
                case DATA_SOURCE_TYPE.ATM_DEVICE_EVENTS:
                    link.download = 'Annexure D_ATM Device Events_' + caseId + '.csv';
                    break;
                default:
                    console.log('flagged error');
                    console.log(source);
                    break;
            }
            link.style.display = 'none';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
        catch (error){
            console.log(error.message);
        }
    }

    handleCheckboxChange(event) {
        const itemId = event.target.dataset.itemId;
        if (event.target.checked) {
            const selectedItem = this.itemsToDisplay.content.find(item => item.id === itemId);
            if (selectedItem) {
                this.flaggedItems.push(selectedItem);
            }
        } else {
            this.flaggedItems = this.flaggedItems.filter(item => item.id !== itemId);
        }
        this.flaggedItemCount = this.flaggedItems.length;
        const countEvent = new CustomEvent('count', {
            detail: {
                 message: 'data flaged items',
                count: this.flaggedItemCount
            }
        });
        this.dispatchEvent(countEvent);
    }


    get headers() {
        if (this.itemsToDisplay && this.itemsToDisplay.content ) {
            if (this.source==DATA_SOURCE_TYPE.CORE_BANKING_TRANSACTIONS) {
                return ['Flagged items', ...CORE_BANKING_HEADERS];
            } else if( this.source==DATA_SOURCE_TYPE.CARD_TRANSACTIONS){
                return ['Flagged items', ...CARD_TRANSACTIONS];
            }else if(this.source==DATA_SOURCE_TYPE.ATM_TRANSACTION_EVENTS){
                return ['Flagged items', ...ATM_TRANSACTION_EVENTS];
            }else if(this.source==DATA_SOURCE_TYPE.ATM_DEVICE_EVENTS){
                return ['Flagged items', ...ATM_DEVICE_EVENTS];
            }
        }
        return [];
    }



    capitalizeFirstLetter(str) {
        return str.charAt(0).toUpperCase() + str.slice(1).replace(/([A-Z])/g, ' $1');
    }
}