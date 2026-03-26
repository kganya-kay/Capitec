import { LightningElement, track, api, wire } from 'lwc';
import getBadBadBeneficiary from '@salesforce/apex/Capitec_BadBeneficiariesController.getBadBadBeneficiary';
import updateBeneficiaryStatus from '@salesforce/apex/Capitec_BadBeneficiariesController.putUpdateBeneficiaryStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadAndPostData from '@salesforce/apex/Capitec_BadBeneficiariesController.uploadAndPostData'; 
import isUserInPermissionSet from '@salesforce/apex/Capitec_BadBeneficiariesController.isUserInPermissionSet';


export default class Capitec_BadBenefiaciaryListView extends LightningElement {
    @track sortDirection = 'asc';
    @track currentSortColumn = '';
    @track items = [];
    @track showModal = false;
    @track benIdToUpdate = false;
    @track benStatusToUpdate = false;
    @track prevVale='';
    @track itemsToDisplay = [];
    @track showSpinner = false;
    @track hasInvalidRows = false; 
    @track errorMessage = ''; 
    @track hasFileError = false; 
    @api isButtonVisible = false;


    @track badBenStatusOptions = [
        { label: 'Trusted', value: 'NO_FRAUD' },
        { label: 'Emerging', value: 'PENDING_FRAUD' },
        { label: 'Confirmed', value: 'CONFIRMED_FRAUD' },
        { label: 'Approved', value: 'APPROVED' },
        { label: 'Payments not Allowed', value: 'PAYMENTS_NOT_ALLOWED' },
        { label: 'Unmapped', value: 'Unmapped', disabled: true }

    ];

    badBenStatusOptionsDef = [
        { label: 'None', value: '' },
        { label: 'Trusted', value: 'NO_FRAUD' },
        { label: 'Emerging', value: 'PENDING_FRAUD' },
        { label: 'Confirmed', value: 'CONFIRMED_FRAUD' },
        { label: 'Approved', value: 'APPROVED' },
        { label: 'Payments not Allowed', value: 'PAYMENTS_NOT_ALLOWED' }

    ];

    @track selectedBadBenStatus = '';
    @track searchText = '';

    // Sample data to display in the table
    allItems = [];

    itemsPerPage = 50;
    currentPage = 1;
    totalPages = 0;


    // Compute page options for the dropdown
    get pageOptions() {
        const options = [];
        for (let i = 1; i <= this.totalPages; i++) {
            options.push({ label: `Page ${i}`, value: i });
        }
        console.log(JSON.stringify(options));
        return options;
    }

        
   

    connectedCallback() {
        isUserInPermissionSet({ permissionSetName: 'FR_Hide_Upload_Risky_Beneficiary' })
            .then((result) => {
                this.isButtonVisible = result;
            })
            .catch((error) => {
                console.error('Error checking permission set:', error);
            });
    }

    // Handle the change in selected page from dropdown
    handlePageChange(event) {
        this.currentPage = parseInt(event.detail.value, 10); // Convert selected value to number
        console.log("Selected page:", this.currentPage);
        this.getBadBen(); // Fetch items for the selected page
    }

    handleCancel() {
        console.log('canecl');
        
        const itemIndex = this.items.findIndex(item => item.benIdentifier === this.benIdToUpdate);
        if (itemIndex !== -1) {
            // Restore the previous status before closing the modal
            this.items[itemIndex].badBenStatus = this.prevVale; 
            console.log(this.prevVale);
        }


        this.showModal = false; // Close the modal
    }

    handleConfirm() {

        const itemIndex = this.items.findIndex(item => item.benIdentifier === this.benIdToUpdate);
        var institution = '';
        if (itemIndex !== -1) {
            // Get the current item from the array
            const item = this.items[itemIndex];
            // Update the badBenStatus with the new value
            institution = this.items[itemIndex].institution;
   
        }
         //Proceed with updating the beneficiary status
        if (this.benIdToUpdate && this.benStatusToUpdate && institution!='') {
            // Call Apex to update the beneficiary status
            
            updateBeneficiaryStatus({ sIdentifier: this.benIdToUpdate, sBenStatus: this.benStatusToUpdate, sInstitution:institution })
                .then(response => {
                    if (response == 200 || response == 204) {
                        console.log('Beneficiary status updated successfully:', response);
                        // Optionally, show a success toast or message to the user
                        this.showToast('Success', 'Beneficiary status updated successfully. Success Code: ' + response, 'success');
                    } else {
                        console.error('Error updating beneficiary status:', response);
                        // Show an error toast with the response status code
                     this.showToast('Error', 'Failed to update beneficiary status. Error code: ' + response, 'error');
                    }
                })
                .catch(error => {
                    console.error('Error updating beneficiary status:', error);
                    // Optionally, show an error toast or message to the user
                    this.showToast('Error', 'Failed to update beneficiary status', 'error');
                });
        } else {
            console.error('No beneficiary ID or status to update');
        }

        this.showModal= false;

    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }

    getBadBen() {

         this.showSpinner = true; 
         this.allItems = [];


         getBadBadBeneficiary({ sAccountNumber: this.searchText, sStatus: this.selectedBadBenStatus, sPageSize:this.itemsPerPage, sCurrentPage:this.currentPage })
            .then(result => {
                 // Check if beneficiaries is present and is an array
            if (result.beneficiaries && Array.isArray(result.beneficiaries)) {
                this.allItems = result.beneficiaries;
            } else {
                console.warn('No beneficiaries found or beneficiaries is not an array:', result.beneficiaries);
                this.allItems = [];
            }
               this.totalPages = result.totalNumberOfPages;
               this.itemsPerPage = result.pageSize;
               this.allItems = result.beneficiaries;
               this.items =  this.processItems(this.allItems);
            })
            .catch(error => {
                console.error(error);
        }) .finally(() => {
             this.showSpinner = false; // Hide the spinner once the data has been fetched or an error has occurred
        });;

    }

    handleBadBenStatusChange(event) {
        this.selectedBadBenStatus = event.detail.value;
        console.log(this.selectedBadBenStatus);
    }

    handleSearchTextChange(event) {
        this.searchText = event.target.value;
    }

    processItems(items) {
        // Ensure there is data to process
        if (items && items.length > 0) {
            return items.map(item => {
                // Safely convert the turnover value to a float, and then fix to 2 decimal places
                let turnoverValue = parseFloat(item.turnover);

                // Check if the turnover is a valid number
                if (isNaN(turnoverValue)) {
                    turnoverValue = '0.00';
                } else {
                    turnoverValue = turnoverValue.toFixed(2); // Format to 2 decimals
                }

                // Check if badBenStatus is in the list of options; if not, set to 'Unmapped'
                const statusInOptions = this.badBenStatusOptions.some(
                    option => option.value === item.badBenStatus
                );

                // Return a new object with all original properties plus the formatted turnover
                return {
                    ...item,
                    turnover: turnoverValue,
                    badBenStatus: statusInOptions ? item.badBenStatus : 'Unmapped'
                };
            });
        } else {
                // Return an empty array if no items are passed
                return [];
        }
    }


    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.getBadBen();
            console.log('3');
        }
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.getBadBen();  
        }
    }

    sortByColumn(event) {
        const column = event.target.dataset.column;
        const direction = this.sortDirection === 'asc' ? 1 : -1;
        this.allItems.sort((a, b) => {
            if (a[column] > b[column]) return direction;
            if (a[column] < b[column]) return -direction;
            return 0;
        });
        this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        this.currentSortColumn = column;
        this.items = this.processItems(this.allItems);; // Recalculate items after sorting
    }

    get sortDirectionIcon() {
        return this.sortDirection === 'asc' ? 'utility:arrowdown' : 'utility:arrowup';
    }

    get benTypeSortIcon() {
        return this.currentSortColumn === 'benType' ? this.sortDirectionIcon : '';
    }

    get createDateSortIcon() {
        return this.currentSortColumn === 'createDate' ? this.sortDirectionIcon : '';
    }

    get updatedDateSortIcon() {
        return this.currentSortColumn === 'updatedDate' ? this.sortDirectionIcon : '';
    }

    get benIdentifierSortIcon() {
        return this.currentSortColumn === 'benIdentifier' ? this.sortDirectionIcon : '';
    }

    get institutionSortIcon() {
        return this.currentSortColumn === 'institution' ? this.sortDirectionIcon : '';
    }

    get ageInMonthsSortIcon() {
        return this.currentSortColumn === 'ageInMonths' ? this.sortDirectionIcon : '';
    }

    get numberOfPaymentsSortIcon() {
        return this.currentSortColumn === 'numberOfPayments' ? this.sortDirectionIcon : '';
    }

    get turnoverSortIcon() {
        return this.currentSortColumn === 'turnover' ? this.sortDirectionIcon : '';
    }

    get badBenStatusSortIcon() {
        return this.currentSortColumn === 'badBenStatus' ? this.sortDirectionIcon : '';
    }

    get riskScoreSortIcon() {
        return this.currentSortColumn === 'riskScore' ? this.sortDirectionIcon : '';
    }

    get caseCountSortIcon() {
        return this.currentSortColumn === 'caseCount' ? this.sortDirectionIcon : '';
    }

    get idSortIcon() {
        return this.currentSortColumn === 'id' ? this.sortDirectionIcon : '';
    }

    handleStatusChange(event) {
      
        const selectedValue = event.detail.value;
        const itemId = event.target.dataset.id;
        console.log(selectedValue);
        console.log(itemId);


       
        const itemIndex = this.items.findIndex(item => item.benIdentifier === itemId);

        if (itemIndex !== -1) {
            // Get the current item from the array
            const item = this.items[itemIndex];

            // Store the previous value for reference if needed
            const previousValue = item.badBenStatus;

        if (selectedValue == 'Unmapped') {
               event.target.value = previousValue; 
               this.showToast('Error', 'Changing status to "Unmapped" is not allowed.', 'error');
               return; // Exit early to prevent any changes
        }

            console.log('Previous Value:', previousValue);
            console.log('New Value:', selectedValue);

            // Update the badBenStatus with the new value
            this.items[itemIndex].badBenStatus = selectedValue;

            // Trigger any additional logic (like showing a modal)
            this.benIdToUpdate = itemId;
            this.benStatusToUpdate = selectedValue;
            this.prevVale = previousValue;

        }

         this.showModal = true; // Show modal f

     
    }

    showSpinner = false;
 
 
    // Risky Beneficiary Upload

    @track isModalOpen = false;
    @track isLoading = false;
    @track data = [];
    payload;

    columns1 = [
        { label: 'identifier', fieldName: 'identifier' },
        { label: 'identifierType', fieldName: 'identifierType' },
        { label: 'institution', fieldName: 'institution' },
        { label: 'fraudStatus', fieldName: 'fraudStatus' },
        { label: 'defaultBranchCode', fieldName: 'defaultBranchCode' }
    ];
    columns = [
        {
            label: 'Identifier',
            fieldName: 'identifier',
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'identifierClass' }
            }
        },
        { label: 'Identifier Type', fieldName: 'identifierType', type: 'text' },
        { label: 'Institution', fieldName: 'institution', type: 'text' },
        { label: 'Fraud Status', fieldName: 'fraudStatus', type: 'text' },
        { label: 'Default Branch Code', fieldName: 'defaultBranchCode', type: 'text' }
    ];
    

    // Open the modal
    openUploadModal() {
        this.isModalOpen = true;
    }

    // Close the modal
    closeModal() {
        this.isModalOpen = false;
        this.data = null;
    }

    handleFileUpload(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
    
            // Callback when file is read
            reader.onload = () => {
                const csvData = reader.result;
                this.data = this.parseCSV(csvData);
               // this.uploadData = this.data.filter(record => !record.isInvalid); \
                this.hasInvalidRows = this.data.some(row => row.isInvalid);

                if (this.hasInvalidRows) {
                    this.errorMessage = 'The uploaded file has some invalid identifiers marked in red. Please fix them and try again.';
                    this.hasFileError = true;
                } else {
                    this.errorMessage = '';
                    this.hasFileError = false;
                }
            };
    
            reader.readAsText(file); // Read the file as text
        }
    }
    
    parseCSV(csvData) {
        const rows = csvData.split('\n');
        const headers = rows.shift().split(','); // Remove the header row
    
        return rows
            .filter(row => row.trim() !== '') // Ignore empty rows
            .map(row => {
                const values = row.split(',');
    
                const identifier = values[0]?.trim() || '';
                const identifierType = values[1]?.trim() || '';
                const isInvalid = identifierType === 'ACCOUNT_NUMBER' && !/^\d+$/.test(identifier);
    
                return {
                    identifier,
                    identifierType,
                    institution: values[2]?.trim() || '',
                    fraudStatus: values[3]?.trim() || '',
                    defaultBranchCode: values[4]?.trim() || '',
                    isInvalid, // Add validation flag
                    identifierClass: isInvalid ? 'slds-text-color_error' : '' // Style invalid rows in red
                };
            })
            .filter(record => record.identifier !== ''); // Ignore rows with empty identifier
            
    }

    async handleUpload() {
        try {
            this.payload = this.data
            .filter(row => !row.isInvalid)
            .map(row => ({
                identifier: row.identifier,
                identifierType: row.identifierType,
                institution: row.institution,
                fraudStatus: row.fraudStatus,
                defaultBranchCode: row.defaultBranchCode
            }));
        } catch (error) {
            console.error('Error sending data to server:', error);
        }
        if (!this.data) {
            this.showToast('Error', 'Please select a valid Excel file.', 'error');
            return;
        }

        console.log('Payload : ',JSON.stringify(this.payload ));

        this.isLoading = true;
        try {
            const response = await uploadAndPostData({ payload: JSON.stringify(this.payload ) });
            if (response  === '204') { // Ensure the response indicates success
                this.showToast('Success', 'Records uploaded and posted successfully!', 'success');
                this.closeModal();
            } else {
                this.showToast('Error', 'Failed to upload and post records.', 'error');
            }
        } catch (error) {
            console.error('Error uploading data:', error);
            this.showToast('Error', 'Failed to upload and post records.', 'error');
        } finally {
            this.isLoading = false;
        }
    }
}