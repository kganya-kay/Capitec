import { LightningElement, api, wire } from 'lwc';
import getClaimParticipantsByCaseId from "@salesforce/apex/IC_ParticipantsController.getClaimParticipantsByCaseId";
export default class Ic_ClaimParticipants extends LightningElement {
    @api recordId;

    data = [];
    size = 0;
    errors;
    columns = columns;

    connectedCallback() { }

    @wire(getClaimParticipantsByCaseId, {
        caseId: "$recordId"
    })
    getClaimParticipants(result) {
        if (result.data) {
            this.size = result.data.length;
            this.data = result.data.map(row => {
                let recordURL = '/' + row.Id;
                let idNumber = row.IC_Claim_Participant_ID_Number__c ? row.IC_Claim_Participant_ID_Number__c : 'view details';

                return { 
                    ...row, 
                    RecordURL: recordURL,
                    IdNumber: idNumber
                };
            });
        } else if (result.error) {
            console.log(result.error);
        }
    }
}

const columns = [
    {
        label: 'Name',
        fieldName: 'IC_Claim_Participant_FirstName__c',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Surname',
        fieldName: 'IC_Claim_Participant_Surname__c',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'ID type',
        fieldName: 'IC_Claim_Participant_ID_Type__c',
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
            target: '_blank'
        },
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Email',
        fieldName: 'IC_Claim_Participant_Email_Address__c',
        type: 'email',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Mobile number',
        fieldName: 'IC_Claim_Participant_Mobile_Number__c',
        type: 'phone',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Bank name',
        fieldName: 'IC_Claim_Participant_Bank_Name__c',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Acount number',
        fieldName: 'IC_Claim_Participant_Account_Number__c',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Acount type',
        fieldName: 'IC_Claim_Participant_Account_Type__c',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    }
];