import { LightningElement, api, wire, track } from 'lwc';
import getLivesAssuredByCaseId from "@salesforce/apex/IC_ParticipantsController.getLivesAssuredByCaseId";
import { updateRecord } from "lightning/uiRecordApi"
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from "@salesforce/apex";
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class Ic_LivesAssured extends LightningElement {
    @api recordId;
    @api _showAllPolicies = false; //ICS-1644 :Samiirah Aujub- Show All button

    @track data = [];
    @track allPolicies = [];
    size = 0;
    dataRefresh;
    errors;
    draftValues = [];
    columns = columns;

    subscription = null;
    channelName = '/event/IC_RefreshLivesAssured__e';

    connectedCallback() { 
        console.log('hereConnect');
        this.subscribeToPlatformEvent();
    }

    subscribeToPlatformEvent() {
        const self = this;
        const callback = function (response) {
            console.log('New Platform Event Received:', response);
            // Handle the Platform Event
            if (response && response.data && response.data.payload) {
                const payload = response.data.payload;
                if (payload.Case_Id__c === self.recordId) { 
                    self.refreshData();
                }
            }
        };

        subscribe(self.channelName, -1, callback).then(response => {
            console.log('Subscribed to Platform Event:', response.channel);
            this.subscription = response;
        }).catch(error => {
            console.error('Subscription error:', error);
        });

        onError(error => {
            console.error('Streaming API On error:', error);
        });
    }

    refreshData() {
        console.log('Refreshing data due to Platform Event');
        refreshApex(this.dataRefresh);
    }

    disconnectedCallback() {
        console.log('hereDisconnect');
        this.unsubscribeFromPlatformEvent();
    }

    unsubscribeFromPlatformEvent() {
        if (this.subscription) {
            unsubscribe(this.subscription, response => {
                console.log('Unsubscribed from Platform Event:', response);
            }).catch(error => {
                console.error('Unsubscription error:', error);
            });
        }
    }

    @api set showAllPolicies(value) {
        this._showAllPolicies = value;

        console.log('##SAU Child:',this._showAllPolicies);
        if(this._showAllPolicies){
            this.handleShowAllPolicies();
        }
       
    }
    get showAllPolicies() {
        return this._showAllPolicies;
    }

    @wire(getLivesAssuredByCaseId, {
        caseId: "$recordId"
    })
    getLivesAssured(result) {
        this.dataRefresh = result;

        console.log('##SAU init Assured:', result);
        console.log('##SAU init Assured data:', result.data);
        if (result.data) {
            let resultJSON = JSON.parse(result.data);

            if(resultJSON != null){
                this.allPolicies = resultJSON['allParticipants'];
                console.log('##SAU Assured allPolicies:', this.allPolicies);
    
               if(resultJSON['validParticipants']){
                this.prepareDataToDisplay(resultJSON['validParticipants']);
               }
            }

        } else if (result.error) {
            console.log(result.error);
        }
    }

    handleShowAllPolicies(event){
        if(this.allPolicies != null){
            this.prepareDataToDisplay(this.allPolicies);
        }
    }

    prepareDataToDisplay(resultData){

        let currentPolicyNumber = null; 
        let applyTheme = true; 
        let firstInBlock = true;  
        this.size = resultData.length;
        this.data = resultData.map(row => {
            console.log('##Analysing row:', row);
            if (row.IC_Policy_Number__r.Name !== currentPolicyNumber) {
                currentPolicyNumber = row.IC_Policy_Number__r.Name;
                applyTheme = !applyTheme;
                firstInBlock = true;
            } else {
                firstInBlock = false;
            }
            
            let rowTheme = applyTheme ? "slds-theme_shade" : "";
            let policyNumber = firstInBlock ? row.IC_Policy_Number__r.Name : '';
            let policyURL = firstInBlock ? '/' + row.IC_Policy_Number__c : '';
            let recordURL = '/' + row.Id;
            let idNumber = row.IC_Identity_Number__c ? row.IC_Identity_Number__c : 'view details';

            return { 
                ...row, 
                PolicyNumber: policyNumber, 
                PolicyUrl: policyURL, 
                RowTheme: rowTheme,
                RecordURL: recordURL,
                IdNumber: idNumber
            };
        });
    }

    async handleSave(event) {
        let records = event.detail.draftValues;
        let updatedRecords = records.map((currItem) => {
            let fieldInput = { ...currItem };
            return {
                fields: fieldInput
            };
        });

        this.draftValues = [];

        let updatedRecordsPromise = updatedRecords.map(currItem => updateRecord(currItem));

        await Promise.all(updatedRecordsPromise)
            .then(results => {
                results.forEach(result => console.log(result));

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Saved",
                        message: '',
                        variant: "success",
                    }),
                );

                return refreshApex(this.dataRefresh);
            })
            .catch(error => {
                console.log(error);
                try {
                    if (error.body.output.fieldErrors.IC_Deceased_Indicator__c[0].errorCode) {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: error.body.output.fieldErrors.IC_Deceased_Indicator__c[0].errorCode,
                                message: error.body.output.fieldErrors.IC_Deceased_Indicator__c[0].message,
                                variant: "error",
                            }),
                        );
                        return;
                    }
                } catch (error) {
                    console.log(error);
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: error.body.message,
                        variant: "error",
                    }),
                );
            });
    }


}

const columns = [
    {
        label: 'Policy number',
        fieldName: 'PolicyNumber',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Name',
        fieldName: 'IC_Name__c',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Surname',
        fieldName: 'IC_Surname__c',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Date of birth',
        fieldName: 'IC_Date_of_Birth__c',
        type: 'date',
        typeAttributes: {
            day: 'numeric',
            month: 'numeric',
            year: 'numeric'
        },
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'ID number',
        fieldName: 'RecordURL',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'IdNumber' },
            target: '_self'
        },
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Relationship',
        fieldName: 'IC_Relationship__c',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Cover amount',
        fieldName: 'IC_Cover_Amount__c',
        type: 'currency',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Calculated Cover amount',
        fieldName: 'IC_Calculated_Cover_Amount__c',
        type: 'currency',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Waiting flag',
        fieldName: 'IC_In_Waiting_Period__c',
        type: 'boolean',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Deceased indicator',
        fieldName: 'IC_Deceased_Indicator__c',
        type: 'boolean',
        editable: true,
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    }
];