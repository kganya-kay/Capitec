import { LightningElement, api, wire, track } from 'lwc';
import getBeneficiariesByCaseId from "@salesforce/apex/IC_ParticipantsController.getBeneficiariesByCaseId";

export default class Ic_Beneficiaries extends LightningElement {
    @api recordId;
    @api _showAllPolicies = false; //ICS-1644 :Samiirah Aujub- Show All button

    @track data = [];
    @track allPolicies = [];
    size = 0;
    errors;
    columns = columns;

    mainLifeData = [];
    otherLifeData = [];
    mainLifeSize = 0;
    otherLifeSize = 0;

    connectedCallback() { }

    @api set showAllPolicies(value) {
        this._showAllPolicies = value;

        if(this._showAllPolicies){
            this.handleShowAllPolicies();
        }
    }
    get showAllPolicies() {
        return this._showAllPolicies;
    }

    @wire(getBeneficiariesByCaseId, {
        caseId: "$recordId"
    })
    getBeneficiaries(result) {
        if (result.data) {
            let resultJSON = JSON.parse(result.data);
            
            if(resultJSON != null){
                this.allPolicies = resultJSON['allParticipants'];
    
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
        this.size = resultData.length;
        let mainLifeData = resultData.filter(row => row.IC_Relationship__c === 'Main Life');
        let otherLifeData = resultData.filter(row => row.IC_Relationship__c !== 'Main Life');
        
        this.mainLifeSize = mainLifeData.length;
        this.otherLifeSize = otherLifeData.length;
        
        const processData = (data) => {
            let currentPolicyNumber = null; 
            let applyTheme = true; 
            let firstInBlock = true;  

            return data.map(row => {
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

                return  { 
                    ...row, 
                    PolicyNumber: policyNumber, 
                    PolicyUrl: policyURL, 
                    RowTheme: rowTheme,
                    RecordURL: recordURL,
                    IdNumber: idNumber
                };
            });
        };
        
        this.mainLifeData = processData(mainLifeData);
        this.otherLifeData = processData(otherLifeData);

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
        label: 'Title',
        fieldName: 'IC_Title__c',
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
        label: 'Phone number',
        fieldName: 'IC_Phone_Number__c',
        type: 'phone',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Email',
        fieldName: 'IC_Email__c',
        type: 'email',
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
        label: 'Benefit amount',
        fieldName: 'IC_BenefitAmount__c',
        type: 'currency',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Bank name',
        fieldName: 'IC_Bank_Name__c',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Account number',
        fieldName: 'IC_Account_Number__c',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Account type',
        fieldName: 'IC_Account_Type__c',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Branch code',
        fieldName: 'IC_Branch_Code__c ',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    },
    {
        label: 'Created by Salesforce',
        fieldName: 'IC_CreatedBySalesforce__c',
        type: 'boolean',
        cellAttributes: {
            class: { fieldName: "RowTheme" },
        }
    }
];