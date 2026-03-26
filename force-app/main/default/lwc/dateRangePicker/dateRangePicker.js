import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getRecordNotifyChange } from "lightning/uiRecordApi";
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent } from 'lightning/refresh';
import getIncidents from '@salesforce/apex/STrackController.getIncidents'; 
import addRelatedIncidents from '@salesforce/apex/capitec_AddRelatedIncidents.addRelatedIncidents';
import getCurrentUserProfile from '@salesforce/apex/STrackUserProfile.getCurrentUserProfile';
import Base_URL from '@salesforce/label/c.Base_URL';

const actions = [
    { label: 'Show details', name: 'show_details' }
];

const columns = [
    { label: 'Incident Number', fieldName: 'Incident_ID__c' },
    { label: 'Category', fieldName: 'Category__c' },
    { label: 'Sub Category', fieldName: 'Subcategory__c' },
    { label: 'Issue', fieldName: 'Issue__c' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Date', fieldName: 'Created_On__c' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    }
];

const FIELDS = [
    'Case.CaseNumber',
    'Case.CIF_Number__c'
];

const FIELDS_ACCOUNT = ['Account.CIF_Number__c'];

export default class DateRangePicker extends LightningElement {
    @api recordId;
    @api objectApiName;
    @wire(getRecord, { recordId: '$recordId', fields: '$computedFields' })
    recordData;

    get computedFields() {
        return this.objectApiName === 'Account' ? FIELDS_ACCOUNT : FIELDS;
    }

    @track data = [];
    columns = columns;
    @track sortedBy;
    @track sortedDirection;
    @track showDetails = false;
    @track fromDate;
    @track toDate;
    @track showData = false;
    @track showError = false;
    @track showSuccess = false;
    @track spinner = false;
    @track disableAddIncidents = true;
    @track incidentDetails = null;
    @track selectedIncidents = [];
    @track filteredDetails = [];
    @track description;
    @track resolution;
    @track journal;
    @track strackURL = '';
    @track displayMessage = '';
    @track hideSelection = false;
    @track userProfile;
    @track hideAddIncidentButtons = false;
    wiredIncidentsResult;
    currentIncident = null;

    connectedCallback() {     

        let today = new Date();
        this.toDate = today.toISOString().split('T')[0];
        this.fromDate = new Date(new Date().setDate(today.getDate() - 30)).toISOString().split('T')[0];
    }

    get today(){
        const today = new Date();
        return today.toISOString().split('T')[0];
    }

    get sixMonthsAgo() {
        const today = new Date();
        today.setMonth(today.getMonth() - 6);
        return today.toISOString().split('T')[0];
    }

    get minFromDate() {
        return this.sixMonthsAgo;
    }

    get maxDate() {
        return this.today;
    }

    get minToDate() {
        return this.fromDate || this.sixMonthsAgo;
    }

    handleDateRangeSelected(event) {
        this.fromDate = event.detail.fromDate;
        this.toDate = event.detail.toDate;
        this.getIncidents();
    }

    get formattedData() {
        return this.data.map(row => ({
            ...row,
            Created_On__c: row.Created_On__c ? row.Created_On__c.slice(0, 10) : ''
        }));
    }
    
    validateDateRange() {
        let fromDateInput = this.template.querySelector('[data-field="fromDate"]');
        let toDateInput = this.template.querySelector('[data-field="toDate"]');

        if (this.fromDate && this.toDate) {
            let fromDate = new Date(this.fromDate);
            let toDate = new Date(this.toDate);
            if (fromDate > toDate) {
                fromDateInput.setCustomValidity('From date cannot be after To date.');
                toDateInput.setCustomValidity('To date cannot be before From date.');
            } else {
                fromDateInput.setCustomValidity('');
                toDateInput.setCustomValidity('');
            }
        } else {
            fromDateInput.setCustomValidity('Please select a valid From date.');
            toDateInput.setCustomValidity('Please select a valid To date.');
        }

        fromDateInput.reportValidity();
        toDateInput.reportValidity();
    }

    @wire(getCurrentUserProfile)
    wiredProfile({ error, data }) {
        if (data) {
            this.userProfile = data;
            this.hideAddIncidentButtons = ['Client Escalations', 'Client Care', 'Client Care Agent', 'Client Care Operations Manager', 'Client Care Team Leader'].includes(this.userProfile);
            this.hideSelection = ['Client Escalations', 'Client Care', 'Client Care Agent', 'Client Care Operations Manager', 'Client Care Team Leader'].includes(this.userProfile);

            console.log('User Profile: ', this.userProfile);
        }
        else if (error) {
            console.error('Error fetching user profile:', error);
        }
    }

   getStrackIncidents() {
        this.spinner = true; 
        this.validateDateRange();
        const fromDateInput = this.template.querySelector('[data-field="fromDate"]');
        const toDateInput = this.template.querySelector('[data-field="toDate"]');

        if (!fromDateInput.checkValidity() || !toDateInput.checkValidity()) {
            this.showData = false;
            this.data = [];
            this.spinner = false;
            return;
        }

        let caseId = null;
        let cifNumber = null;

        if (this.objectApiName === 'Case' && this.recordData?.data) {
            caseId = this.recordData.data.id;
            cifNumber = this.recordData.data.fields.CIF_Number__c.value;
        } else if (this.objectApiName === 'Account' && this.recordData?.data) {
            cifNumber = this.recordData.data.fields.CIF_Number__c?.value;
        }

       getIncidents({ cifNumber, caseId, fromDate: this.fromDate, toDate: this.toDate })
      .then(result => {
        this.showData = true;
            if(result == null || result.length === 0) {
                this.displayMessage = `No incidents found for the client on this date range`;
                this.data = [];
                this.showError = false;
            } else {
                this.data = result
                .filter(record => record.Created_On__c)
                .sort((a, b) => {
                    const dateA = a.Created_On__c ? new Date(a.Created_On__c) : new Date(0); // Default to epoch
                    const dateB = b.Created_On__c ? new Date(b.Created_On__c) : new Date(0); // Default to epoch
                    return dateB - dateA; // Descending order
                });
            } 

        }).catch(() => {
            let errorMessage = 'There was an issue while trying to reach STrack';
            this.displayMessage = `Error : ${errorMessage}`;
            this.showError = true;
            this.showData = false;
        }).finally(() => {
            this.spinner = false;
        });  

    }
   
    handleRowAction(event) {     
        // Expecting an API call to get specific incident details

        const rowDetails = event.detail.row;

        const incidentIndex = this.selectedIncidents.findIndex(incident => incident.Incident_ID__c === rowDetails.Incident_ID__c);
    
        if (incidentIndex === -1) {
            // Add the incident to selectedIncidents if not already selected
            this.selectedIncidents.push(rowDetails);
        }

        this.openDetails(rowDetails);

    }

    isNotDescriptionSolutionOrJournal(key) {
        return key !== 'Description' && key !== 'Resolution' && key !== 'Journal';
    }

    capitalizeFirstLetter(string) {
        return string.charAt(0).toUpperCase() + string.slice(1).replace(/([A-Z])/g, ' $1');
    }

    async addIncidents() {
        // this.selectedIncidents now has all the selected rows
        
        let caseId = this.recordData.data.id;
        let selectedIncident = this.selectedIncidents.map(incident => {
            return {
                Incident_ID__c: incident.Incident_ID__c,
                Category__c: incident.Category__c,
                Subcategory__c: incident.Subcategory__c,
                Issue__c: incident.Issue__c,
                Summary__c: incident.Summary__c,
                Type__c: incident.Type__c,
                Status__c: incident.Status__c,
                recId__c: incident.recId__c,
                VoiceRefNo__c: incident.VoiceRefNo__c,
                CallerPhone__c: incident.CallerPhone__c,
                OrgUnitID__c: incident.OrgUnitID__c,
                vDN__c: incident.vDN__c,
                Source__c: incident.Source__c,
                NetworkUsername__c: incident.NetworkUsername__c,
                Impact__c: incident.Impact__c,
                Urgency__c: incident.Urgency__c,
                BranchID__c: incident.BranchID__c,
                CauseCode__c: incident.CauseCode__c,
                Owner_Team__c: incident.Owner_Team__c,
                Owner__c: incident.Owner__c,
                Created_On__c: incident.Created_On__c,
                Description__c: incident.Description__c,
                Solution__c: incident.Solution__c
            };
        });

        if (this.currentIncident && 
            !this.selectedIncidents.some(incident => incident.Incident_ID__c === this.currentIncident.Incident_ID__c)) {
            selectedIncident.push({
                Incident_ID__c: this.currentIncident.Incident_ID__c,
                Category__c: this.currentIncident.Category__c,
                Subcategory__c: this.currentIncident.Subcategory__c,
                Issue__c: this.currentIncident.Issue__c,
                Summary__c: this.currentIncident.Summary__c,
                Type__c: this.currentIncident.Type__c,
                Status__c: this.currentIncident.Status__c,
                recId__c: this.currentIncident.recId__c,
                VoiceRefNo__c: this.currentIncident.VoiceRefNo__c,
                CallerPhone__c: this.currentIncident.CallerPhone__c,
                OrgUnitID__c: this.currentIncident.OrgUnitID__c,
                vDN__c: this.currentIncident.vDN__c,
                Source__c: this.currentIncident.Source__c,
                NetworkUsername__c: this.currentIncident.NetworkUsername__c,
                Impact__c: this.currentIncident.Impact__c,
                Urgency__c: this.currentIncident.Urgency__c,
                BranchID__c: this.currentIncident.BranchID__c,
                CauseCode__c: this.currentIncident.CauseCode__c,
                Owner_Team__c: this.currentIncident.Owner_Team__c,
                Owner__c: this.currentIncident.Owner__c,
                Created_On__c: this.currentIncident.Created_On__c,
                Description__c: this.currentIncident.Description__c,
                Solution__c: this.currentIncident.Solution__c
            });
        }


        if (selectedIncident.length > 0){
       try {
           await addRelatedIncidents({ lstIncidents: selectedIncident, caseId: caseId });
                    
                    this.displayMessage = "Incident(s) successfully related to the case.";
                    this.showSuccess = true;
                    this.showError = false;

                    this.data = this.data.filter(incident =>
                        !this.selectedIncidents.some(selected => selected.Incident_ID__c === incident.Incident_ID__c) &&
                        !(this.currentIncident && this.currentIncident.Incident_ID__c === incident.Incident_ID__c)
                    );

                    await refreshApex(this.wiredIncidentsResult);
                    getRecordNotifyChange([{ recordId: this.recordId}]);
                    this.dispatchEvent(new RefreshEvent());

                    if (this.showSuccess) {
                        this.closeDetails();
                    }
                
                    
                    
            } catch (error) {
                const errorMessage = error?.body?.message || 'Unknown error occurred.';
                
                this.displayMessage = `Error: ${errorMessage}`;
                this.showError = true;
                this.showSuccess = false;

                if (this.showError) {
                    this.closeDetails();
                }
            
                
       }
    }
    }

    closeModal() {
        this.showError = false;
        this.showSuccess = false;
    }

    getSelectedIncidents(event) {
         console.log(event.detail.selectedRows);

        this.selectedIncidents = event.detail.selectedRows;
        this.disableAddIncidents = this.selectedIncidents.length === 0;
    }

    fromDateChange(event) {
        this.fromDate = event.target.value;
        this.validateDateRange();

    }

    toDateChange(event) {
        this.toDate = event.target.value;
        this.validateDateRange();
    }

    closeDetails() {
        this.showDetails = false;
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort((a, b) => {
            let aValue = a[sortedBy];
            let bValue = b[sortedBy];

            if (sortedBy === 'Created_On__c') {
                aValue = new Date(aValue);
                bValue = new Date(bValue);
            }
            if (aValue < bValue) {
                return sortDirection === 'asc' ? -1 : 1;
            }
            if (aValue > bValue) {
                return sortDirection === 'asc' ? 1 : -1;
            }
            return 0;
        });
        this.data = cloneData;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;
    }
    openDetails(incident) {
        this.currentIncident = incident;

        this.description = incident.Description__c;
        this.resolution = incident.Solution__c;
        this.journal = incident.Journal__c;
        this.incidentNumber = incident.Incident_ID__c;
        this.category = incident.Category__c;
        this.subCategory = incident.Subcategory__c;
        this.issue = incident.Issue__c;
        this.summary = incident.Summary__c;
        this.type = incident.Type__c;
        this.status = incident.Status__c;
        this.recordId = incident.recId__c;
        this.voiceRefNo = incident.VoiceRefNo__c;
        this.callerPhone = incident.CallerPhone__c;
        this.organizationUnitId = incident.OrgUnitID__c;
        this.vdn = incident.vDN__c;
        this.source = incident.Source__c;
        this.networkUsername = incident.NetworkUsername__c;
        this.impact = incident.Impact__c;
        this.urgency = incident.Urgency__c;
        this.branchId = incident.BranchID__c;
        this.causeCode = incident.CauseCode__c;
        this.ownerTeam = incident.Owner_Team__c;
        this.owner = incident.Owner__c;
        this.createdOnDate = incident.Created_On__c;
    
        this.filteredDetails = [
            { key: 'Incident Number', value: this.incidentNumber },
            { key: 'Category', value: this.category },
            { key: 'Sub Category', value: this.subCategory },
            { key: 'Issue', value: this.issue },
            { key: 'Summary', value: this.summary },
            { key: 'Type', value: this.type },
            { key: 'Status', value: this.status },
            { key: 'Record ID', value: this.recordId },
            { key: 'Voice Reference Number', value: this.voiceRefNo },
            { key: 'Caller Phone', value: this.callerPhone },
            { key: 'Organization Unit ID', value: this.organizationUnitId },
            { key: 'VDN', value: this.vdn },
            { key: 'Source', value: this.source },
            { key: 'Network Username', value: this.networkUsername },
            { key: 'Impact', value: this.impact },
            { key: 'Urgency', value: this.urgency },
            { key: 'Branch ID', value: this.branchId },
            { key: 'Cause Code', value: this.causeCode },
            { key: 'Owner Team', value: this.ownerTeam },
            { key: 'Owner', value: this.owner },
            { key: 'Created On Date', value: this.createdOnDate },
        ].filter((item) => item !== undefined);
    
        this.showDetails = true;
        this.strackURL = `${Base_URL}/HEAT/Default.aspx?Scope=SelfService&CommandId=Open&Tab=Incident%23&ItemId=${incident.recId__c}&frameless=false`;
    }
}