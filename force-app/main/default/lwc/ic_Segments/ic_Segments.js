import { LightningElement, api, wire, track } from 'lwc';
import getSegments from "@salesforce/apex/IC_SegmentsTabController.getSegments";

export default class Ic_Segments extends LightningElement {
    @api recordId;

    @track segmentsTodisplay = [];
    size = 0;
    dataRefresh;
    columns = columns;

    connectedCallback() { }

    @wire(getSegments, {
        caseId: "$recordId"
    })
    getSegments(result) {
        this.dataRefresh = result;

        console.log('##SAU init:', result);
        console.log('##SAU init data:', result.data);
        if (result.data) {
            let resultJSON = JSON.parse(result.data);
            this.size = resultJSON.length;

            console.log('##SAU resultJSON:',resultJSON);
            console.log('##SAU size:',this.size);

            if(resultJSON != null){
                console.log('##SAU not null:',resultJSON);
                this.segmentsTodisplay = resultJSON.map(segment => ({
                    ...segment,
                    segmentUrl: '/' + segment.Id
                }));
            }

        } else if (result.error) {
            console.log(result.error);
        }
    }

}


const columns = [
    {
        label: 'Segment Name',
        fieldName: 'Name'
    },
    {
        label: 'Cover Amount',
        fieldName: 'IC_Cover_Amount__c'
    },
    {
        label: 'Start Date',
        fieldName: 'IC_Start_Date__c',
        type: 'date',
        typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric'
        }
    },
    {
        label: 'End date',
        fieldName: 'IC_End_Date__c',
        type: 'date',
        typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric'
        }
    }
];