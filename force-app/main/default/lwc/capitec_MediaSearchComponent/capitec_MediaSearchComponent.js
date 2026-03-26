/**
 * Created by Sebastian on 20.03.2023.
 */

import {LightningElement, api, wire} from 'lwc';
import getMediaSearchHistory from '@salesforce/apex/capitec_MediaSearchController.getMediaSearchHistory';
import createMediaSearchHistoryRecord from '@salesforce/apex/capitec_MediaSearchController.createMediaSearchHistoryRecord';
import getCaseRecord from '@salesforce/apex/capitec_MediaSearchController.getCaseRecord';
import {refreshApex} from "@salesforce/apex";

const COLUMNS = [
    { label: 'User Name', fieldName: 'User_Name', type: 'text'},
    { label: 'Date Time', fieldName: 'Click_Date__c', type: 'date',
        typeAttributes: { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true}, },
];

export default class capitec_MediaSearchComponent extends LightningElement {
    @api recordId;
    @wire(getCaseRecord, {caseId: '$recordId'})
    caseRecord;

    @wire(getMediaSearchHistory, {caseId: '$recordId'})
    dataToDisplay;
    columns = COLUMNS;

    handleOnClick() {
        window.open(this.caseRecord.data.Media_Search_URL__c, '_blank');
        createMediaSearchHistoryRecord({caseId: this.recordId})
            .then(() => {
                refreshApex(this.dataToDisplay).then(() => {});
            })
    }
}