import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { IsConsoleNavigation, getFocusedTabInfo, getAllTabInfo, focusTab, refreshTab, closeTab, openTab } from 'lightning/platformWorkspaceApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Object + Field schema imports
import CONVERSIONS_OBJECT      from '@salesforce/schema/Conversion__c';
import ISSUE_FIELD             from '@salesforce/schema/Conversion__c.Issue__c';
import OLD_BANK_NAME_FIELD     from '@salesforce/schema/Conversion__c.Old_Bank_Name__c';
import OLD_BRANCH_CODE_FIELD   from '@salesforce/schema/Conversion__c.Old_Branch_Code__c';

// Apex methods
import searchClient              from '@salesforce/apex/CapitecManualCaseCreationController.searchClient';
import submitCaseToApi           from '@salesforce/apex/CapitecManualCaseCreationController.submitCaseToApi';
import getDebitOrderInitiatorName from '@salesforce/apex/CapitecManualCaseCreationController.getDebitOrderInitiatorName';
import retryOcrExtraction        from '@salesforce/apex/CapitecOcrRetryHandler.retryOcrExtraction';

// ─────────────────────────────────────────────────────────────────────────────
// Constant: Debit Orders datatable column definitions
// ─────────────────────────────────────────────────────────────────────────────
const DEBIT_ORDER_COLUMNS = [
    { label: 'DO Reference Number', fieldName: 'doReferenceNumber', type: 'text',     sortable: true },
    { label: 'DOI Name',            fieldName: 'doiName',           type: 'text',     sortable: true },
    { label: 'Debit Order Date',    fieldName: 'debitOrderDate',    type: 'date',     sortable: true,
      typeAttributes: { year: 'numeric', month: '2-digit', day: '2-digit' } },
    { label: 'Amount',              fieldName: 'amount',            type: 'currency', sortable: true,
      typeAttributes: { currencyCode: 'ZAR', minimumFractionDigits: 2 },
      cellAttributes: { alignment: 'left' } },
    { label: 'Category',            fieldName: 'category',          type: 'text',     sortable: true }
];

// ─────────────────────────────────────────────────────────────────────────────
// Constant: Static picklist options (not from SF picklists)
// ─────────────────────────────────────────────────────────────────────────────
const IDENTIFICATION_TYPE_OPTIONS = [
    { label: 'ID number',       value: 'ID number' },
    { label: 'Passport number', value: 'Passport number' },
    { label: 'CIF number',      value: 'CIF number' },
    { label: 'Account number',  value: 'Account number' }
];

const DOCUMENT_TYPE_OPTIONS = [
    { label: 'Bank Statement',      value: 'Bank Statement' },
    { label: 'Authorisation Form',  value: 'Authorisation Form' },
    { label: 'ID Copy',             value: 'ID Copy' }
];

const DEBIT_ORDER_CATEGORY_OPTIONS = [
    { label: 'Immediate',    value: 'Immediate' },
    { label: 'Future Dated', value: 'Future Dated' }
];

// ─────────────────────────────────────────────────────────────────────────────
// Constant: Source (Case Origin) – static values, no wire needed
// ─────────────────────────────────────────────────────────────────────────────
const SOURCE_OPTIONS = [
    { label: 'Client Care', value: 'Client Care' },
    { label: 'WhatsApp',    value: 'WhatsApp' },
    { label: 'Website',     value: 'Website' }
];

export default class CapitecConversionsManualCaseCreationLWC extends NavigationMixin(LightningElement) {

    @api title;
    @wire(IsConsoleNavigation) isConsoleNavigation;

    /**
     * API name of the object whose list view the button lives on.
     * Defaults to 'Case'. Pass 'Conversion__c' if the button is on the
     * Conversions object list view instead.
     * Set via the List View Button URL parameter or the FlexiPage property.
     */
    @api listViewObjectApiName = 'Case';
    @api returnObjectApiName;
    @api returnFilterName;
    // ─── Step Navigation ────────────────────────────────────────────────────
    @track currentStep = 1;

    // ─── Loading flags ───────────────────────────────────────────────────────
    @track isLoading      = false;
    @track isOcrLoading   = false;

    // ─── OCR retry counter (max 3) ───────────────────────────────────────────    
    @track ocrRetryCount  = 0;

    // ─── Debit order search filter ───────────────────────────────────────────
    @track debitOrderSearch = '';

    // ─── Cancel confirmation modal ───────────────────────────────────────────
    @track showCancelConfirm = false;

    // ─── New debit order modal ───────────────────────────────────────────────
    @track showNewDebitOrderForm = false;
    @track newDebitOrder = this._emptyDebitOrder();

    // ─── Picklist options ────────────────────────────────────────────────────
    // Source: static — no wire required
    sourceOptions  = SOURCE_OPTIONS;
    // Issue, Old Bank Name, Old Branch Code: wired from Conversion__c picklists
    @track issueOptions         = [];
    @track bankNameOptions      = [];
    @track oldBranchCodeOptions = [];

    // ─── Client information (populated from Apex after Step 1) ───────────────
    @track clientInfo = {
        cifNumber         : '',
        idNumber          : '',
        passportNumber    : '',
        salutation        : '',
        firstName         : '',
        lastName          : '',
        homeContactNumber : 'N/A',
        workContactNumber : 'N/A',
        mobileNumber      : '',
        emailAddress      : ''
    };

    // ─── Central form data – ALL steps stored here ───────────────────────────
    @track formData = {
        // Step 1
        identificationType   : '',
        identificationNumber : '',
        // Step 2
        preferredContactTime : '',
        // Step 3
        source : '',
        issue  : '',
        // Step 4
        oldBranchCode   : '',
        oldBankName     : '',
        oldAccountNumber: '',
        // Step 5
        additionalComments: ''
    };

    // ─── Uploaded files (File objects + metadata) ────────────────────────────
    @track uploadedFiles = [];

    // ─── Debit orders (from OCR or manual entry) ─────────────────────────────
    @track debitOrders = [];

    // ─── Static options (constants exposed to template) ─────────────────────
    identificationTypeOptions   = IDENTIFICATION_TYPE_OPTIONS;
    documentTypeOptions         = DOCUMENT_TYPE_OPTIONS;
    debitOrderCategoryOptions   = DEBIT_ORDER_CATEGORY_OPTIONS;
    debitOrderColumns           = DEBIT_ORDER_COLUMNS;

    // =========================================================================
    // WIRE ADAPTERS
    // =========================================================================

    conversionsDefaultRecordTypeId;
    @wire(getObjectInfo, { objectApiName: CONVERSIONS_OBJECT })
    wiredConversionsObjectInfo({ data }) {
        if (data) {
            this.conversionsDefaultRecordTypeId = data.defaultRecordTypeId;
        }
    }

    /**
     * 2. Issue picklist – Conversion__c.Issue__c filtered by Conversions record type.
     */
    @wire(getPicklistValues, {
        recordTypeId : '$conversionsDefaultRecordTypeId',
        fieldApiName : ISSUE_FIELD
    })
    wiredIssueOptions({ data, error }) {
        if (data) {
            this.issueOptions = data.values.map(v => ({ label: v.label, value: v.value }));
        }
        if (error) {
            console.error('Error loading Issue picklist:', error);
        }
    }

    /**
     * 4. Old Bank Name picklist – Conversion__c.Old_Bank_Name__c filtered by Conversions record type.
     */
    @wire(getPicklistValues, {
        recordTypeId : '$conversionsDefaultRecordTypeId',
        fieldApiName : OLD_BANK_NAME_FIELD
    })
    wiredBankNameOptions({ data, error }) {
        if (data) {
            this.bankNameOptions = data.values.map(v => ({ label: v.label, value: v.value }));
        }
        if (error) {
            console.error('Error loading Bank Name picklist:', error);
        }
    }

    /**
     * 5. Old Branch Code picklist – Conversion__c.Old_Branch_Code__c filtered by Conversions record type.
     */
    @wire(getPicklistValues, {
        recordTypeId : '$conversionsDefaultRecordTypeId',
        fieldApiName : OLD_BRANCH_CODE_FIELD
    })
    wiredOldBranchCodeOptions({ data, error }) {
        if (data) {
            this.oldBranchCodeOptions = data.values.map(v => ({ label: v.label, value: v.value }));
        }
        if (error) {
            console.error('Error loading Old Branch Code picklist:', error);
        }
    }

    // =========================================================================
    // COMPUTED PROPERTIES – Step Visibility
    // =========================================================================

    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isStep3() { return this.currentStep === 3; }
    get isStep4() { return this.currentStep === 4; }
    get isStep5() { return this.currentStep === 5; }

    // =========================================================================
    // COMPUTED PROPERTIES – Step Indicator Sidebar
    // =========================================================================

    get steps() {
        return [
            { id: 1, label: 'Client Identification', liClass: this._liClass(1), dotClass: this._dotClass(1), labelClass: this._labelClass(1) },
            { id: 2, label: 'Client Details',        liClass: this._liClass(2), dotClass: this._dotClass(2), labelClass: this._labelClass(2) },
            { id: 3, label: 'Case Details',           liClass: this._liClass(3), dotClass: this._dotClass(3), labelClass: this._labelClass(3) },
            { id: 4, label: 'Debit Order Details',    liClass: this._liClass(4), dotClass: this._dotClass(4), labelClass: this._labelClass(4) },
            { id: 5, label: 'Summary',                liClass: this._liClass(5), dotClass: this._dotClass(5), labelClass: this._labelClass(5) }
        ];
    }

    _dotClass(n) {
        if (n < this.currentStep)  return 'step-dot step-dot_completed';
        if (n === this.currentStep) return 'step-dot step-dot_current';
        return 'step-dot step-dot_pending';
    }

    _liClass(n) {
        return n < 5 ? 'step-item step-item_with-line' : 'step-item';
    }

    _labelClass(n) {
        return n === this.currentStep ? 'step-label step-label_active' : 'step-label';
    }

    // =========================================================================
    // COMPUTED PROPERTIES – Misc
    // =========================================================================

    get hasUploadedFiles()    { return this.uploadedFiles.length > 0; }
    get uploadedFilesCount()  { return this.uploadedFiles.length; }
    get hasDebitOrders()      { return this.debitOrders.length > 0; }
    get debitOrdersCount()    { return this.debitOrders.length; }
    get isOcrRetryDisabled()  { return this.ocrRetryCount >= 3 || this.isOcrLoading; }

    get filteredDebitOrders() {
        if (!this.debitOrderSearch) return this.debitOrders;
        const q = this.debitOrderSearch.toLowerCase();
        return this.debitOrders.filter(o =>
            (o.doReferenceNumber && o.doReferenceNumber.toLowerCase().includes(q)) ||
            (o.doiName           && o.doiName.toLowerCase().includes(q))           ||
            (o.category          && o.category.toLowerCase().includes(q))
        );
    }

    // =========================================================================
    // EVENT HANDLERS – Generic form inputs
    // =========================================================================

    /** Handles lightning-input change events */
    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        this.formData = { ...this.formData, [field]: value };
    }

    /** Handles lightning-combobox change events */
    handleComboChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        this.formData = { ...this.formData, [field]: value };
    }

    // =========================================================================
    // EVENT HANDLERS – File Upload (Step 3)
    // =========================================================================

    handleAddFiles() {
        const fileInput = this.template.querySelector('[data-id="fileInput"]');
        if (fileInput) fileInput.click();
    }

    handleFileSelected(event) {
        const rawFiles = Array.from(event.target.files);
        const mapped = rawFiles.map((f, i) => ({
            id           : `file_${Date.now()}_${i}`,
            name         : f.name,
            size         : f.size,
            mimeType     : f.type,
            fileRef      : f,          // native File object for later base64 conversion
            documentType : 'Bank Statement'
        }));
        this.uploadedFiles = [...this.uploadedFiles, ...mapped];
        // Reset the input so the same file can be re-selected if needed
        event.target.value = '';
    }

    handleDocumentTypeChange(event) {
        const fileId  = event.target.dataset.fileId;
        const newType = event.detail.value;
        this.uploadedFiles = this.uploadedFiles.map(f =>
            f.id === fileId ? { ...f, documentType: newType } : f
        );
    }

    handleRemoveFile(event) {
        const fileId = event.target.dataset.fileId;
        this.uploadedFiles = this.uploadedFiles.filter(f => f.id !== fileId);
    }

    handlePreviewFile(event) {
        const fileId = event.target.dataset.fileId;
        const file   = this.uploadedFiles.find(f => f.id === fileId);
        if (file && file.fileRef) {
            const url = URL.createObjectURL(file.fileRef);
            window.open(url, '_blank');
        }
    }

    // =========================================================================
    // EVENT HANDLERS – Debit Order (Step 4)
    // =========================================================================

    handleDebitOrderSearch(event) {
        this.debitOrderSearch = event.detail.value;
    }

    /** Opens the New Debit Order modal */
    handleNewDebitOrder() {
        this.newDebitOrder = this._emptyDebitOrder();
        this.showNewDebitOrderForm = true;
    }

    handleNewDebitOrderFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        this.newDebitOrder = { ...this.newDebitOrder, [field]: value };
    }

    handleNewDebitOrderComboChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        this.newDebitOrder = { ...this.newDebitOrder, [field]: value };
    }

    handleSaveNewDebitOrder() {
        if (!this.newDebitOrder.doReferenceNumber) {
            this._toast('Error', 'DO Reference Number is required.', 'error');
            return;
        }
        this.debitOrders = [...this.debitOrders, { ...this.newDebitOrder }];
        this.showNewDebitOrderForm = false;
        this.newDebitOrder = this._emptyDebitOrder();
    }

    handleCancelNewDebitOrder() {
        this.showNewDebitOrderForm = false;
        this.newDebitOrder = this._emptyDebitOrder();
    }

    /** Handles DOI Name record picker selection – fetches name via Apex */
    async handleDoiChange(event) {
        const recordId = event.detail.recordId;
        if (recordId) {
            try {
                const name = await getDebitOrderInitiatorName({ recordId });
                this.newDebitOrder = { ...this.newDebitOrder, doiId: recordId, doiName: name };
            } catch (err) {
                console.error('Error fetching DOI name:', err);
                this.newDebitOrder = { ...this.newDebitOrder, doiId: recordId, doiName: '' };
            }
        } else {
            // User cleared the picker
            this.newDebitOrder = { ...this.newDebitOrder, doiId: '', doiName: '' };
        }
    }

    /** Retry OCR extraction – capped at 3 attempts */
    async handleRetryOcr() {
        if (this.ocrRetryCount >= 3 || this.isOcrLoading) return;

        this.isOcrLoading = true;
        this.ocrRetryCount++;

        try {
            const fileIds = JSON.stringify(this.uploadedFiles.map(f => f.id));
            const result  = await retryOcrExtraction({ fileIds });

            if (result && result.length > 0) {
                this.debitOrders = result;
                this._toast('Success', 'OCR extraction successful.', 'success');
            } else {
                const remaining = 3 - this.ocrRetryCount;
                if (remaining > 0) {
                    this._toast('Info', `No debit orders returned. ${remaining} attempt(s) remaining.`, 'info');
                } else {
                    this._toast('Warning', 'OCR unsuccessful after 3 attempts. Please add debit orders manually.', 'warning');
                }
            }
        } catch (err) {
            this._toast('Error', 'OCR failed: ' + (err.body?.message || err.message), 'error');
        } finally {
            this.isOcrLoading = false;
        }
    }

    // =========================================================================
    // EVENT HANDLERS – Navigation
    // =========================================================================

    /** Shows the cancel confirmation modal */
    handleCancelClick() {
        this.showCancelConfirm = true;
    }

    /** User chose "Go Back" – dismiss the modal, stay on the wizard */
    handleDismissCancel() {
        this.showCancelConfirm = false;
    }

    /** User confirmed cancel – close modal then navigate away */
    async handleConfirmCancel() {
        this.showCancelConfirm = false;
        this.dispatchEvent(new CustomEvent('cancel'));
        await this._returnToListAndCloseCurrentTabIfConsole();
    }

    handlePrevious() {
        if (this.currentStep > 1) {
            this.currentStep--;
        }
    }

    async handleNext() {
        if (!this._validateCurrentStep()) return;

        // Step 1 → 2: Fetch client info from Apex
        if (this.currentStep === 1) {
            const success = await this._fetchClientInfo();
            if (!success) return;
        }

        if (this.currentStep < 5) {
            this.currentStep++;
        }
    }

    /** Summary "Next" button triggers API submission */
    async handleSubmit() {
        this.isLoading = true;
        try {
            const payload = this._buildPayload();
            await submitCaseToApi({ payload: JSON.stringify(payload) });
            this._toast('Success', 'Case submitted successfully.', 'success');
            // Dispatch for Aura wrapper context
            this.dispatchEvent(new CustomEvent('casesubmitted', { detail: payload }));
            // Navigate back to list view for standalone page context
            this._navigateToListView();
        } catch (err) {
            this._toast('Error', 'Submission failed: ' + (err.body?.message || err.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // =========================================================================
    // VALIDATION
    // =========================================================================

    _validateCurrentStep() {
        switch (this.currentStep) {
            case 1: return this._validateStep1();
            case 2: return this._validateStep2();
            case 3: return this._validateStep3();
            case 4: return this._validateStep4();
            default: return true;
        }
    }

    _validateStep1() {
        const { identificationType, identificationNumber } = this.formData;

        if (!identificationType || !identificationNumber) {
            this._toast('Error', 'Please select an Identification Type and enter the Identification Number.', 'error');
            return false;
        }

        // SA ID number – must be exactly 13 digits
        if (identificationType === 'ID number' && !/^\d{13}$/.test(identificationNumber)) {
            this._toast('Error', 'ID number must be exactly 13 digits.', 'error');
            return false;
        }

        // Account number – must be numeric
        if (identificationType === 'Account number' && !/^\d+$/.test(identificationNumber)) {
            this._toast('Error', 'Account number must be numeric.', 'error');
            return false;
        }

        return true;
    }

    _validateStep2() {
        if (!this.formData.preferredContactTime) {
            this._toast('Error', 'Preferred Contact Time is required.', 'error');
            return false;
        }
        return true;
    }

    _validateStep3() {
        if (!this.formData.source || !this.formData.issue) {
            this._toast('Error', 'Please select a Source and an Issue.', 'error');
            return false;
        }
        return true;
    }

    _validateStep4() {
        const { oldBranchCode, oldBankName, oldAccountNumber } = this.formData;
        if (!oldBranchCode || !oldBankName || !oldAccountNumber) {
            this._toast('Error', 'Please complete all Old Bank Information fields.', 'error');
            return false;
        }
        return true;
    }

    // =========================================================================
    // APEX INTERACTIONS
    // =========================================================================

    async _fetchClientInfo() {
        this.isLoading = true;
        try {
            const result = await searchClient({
                idType  : this.formData.identificationType,
                idNumber: this.formData.identificationNumber
            });

            if (result) {
                this.clientInfo = { ...result };
                return true;
            }

            this._toast('Warning', 'No client found with the provided identification details.', 'warning');
            return false;

        } catch (err) {
            this._toast('Error', 'Client lookup failed: ' + (err.body?.message || err.message), 'error');
            return false;
        } finally {
            this.isLoading = false;
        }
    }

    // =========================================================================
    // HELPERS
    // =========================================================================

    /**
     * Navigates the agent back to the object list view.
     * Used when the component runs as a standalone Lightning App Page
     * (launched from a URL-type list view button).
     * In the Aura Quick Action context this is a no-op because
     * force:closeQuickAction has already closed the modal.
     */
    _navigateToListView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.listViewObjectApiName || 'Case',
                actionName   : 'list'
            }
        });
    }

    async _returnToListAndCloseCurrentTabIfConsole() {
        if (!this.isConsoleNavigation) {
            this._navigateToListView();
            return;
        }

        try {
            // 1. Capture the wizard tab ID before touching anything else.
            const currentTabInfo = await getFocusedTabInfo();
            const currentTabId   = currentTabInfo?.tabId;

            // 2. Find an already-open Cases list view tab.
            const objectApiName = this.listViewObjectApiName || 'Case';
            const allTabs       = await getAllTabInfo();

            const existingListTab = allTabs.find(tab => {
                // Match by URL segment  e.g.  /lightning/o/Case/list
                const url = (tab.url || '').toLowerCase();
                if (url.includes(`/o/${objectApiName.toLowerCase()}/list`)) return true;

                // Match by pageReference (more reliable when URL is encoded)
                const pr = tab.pageReference;
                return (
                    pr?.type                          === 'standard__objectPage' &&
                    pr?.attributes?.objectApiName     === objectApiName          &&
                    pr?.attributes?.actionName        === 'list'
                );
            });

            if (existingListTab) {
                // 3a. Cases tab already open – focus it and refresh so the list
                //     view reflects any changes (e.g. new record created).
                await focusTab(existingListTab.tabId);
                await refreshTab(existingListTab.tabId, { hasSidePanel: false });
            } else {
                // 3b. No Cases tab found – open a fresh one.
                const pageRef = {
                    type: 'standard__objectPage',
                    attributes: { objectApiName, actionName: 'list' }
                };
                const url = await this[NavigationMixin.GenerateUrl](pageRef);
                if (url) {
                    await openTab({ url, focus: true });
                }
            }

            // 4. Close the wizard tab now that the user is back on Cases.
            if (currentTabId) {
                await closeTab(currentTabId);
            }

        } catch (error) {
            console.error('Console tab management failed, falling back to navigation:', error);
            this._navigateToListView();
        }
    }

    /** Builds the full case payload object for API submission */
    _buildPayload() {
        return {
            clientInfo           : { ...this.clientInfo },
            identificationType   : this.formData.identificationType,
            identificationNumber : this.formData.identificationNumber,
            preferredContactTime : this.formData.preferredContactTime,
            source               : this.formData.source,
            issue                : this.formData.issue,
            oldBranchCode        : this.formData.oldBranchCode,
            oldBankName          : this.formData.oldBankName,
            oldAccountNumber     : this.formData.oldAccountNumber,
            debitOrders          : this.debitOrders.map(d => ({ ...d })),
            additionalComments   : this.formData.additionalComments,
            uploadedFiles        : this.uploadedFiles.map(f => ({
                fileName     : f.name,
                documentType : f.documentType
                // Note: base64 content will be added during API integration phase
            }))
        };
    }

    /** Returns a fresh empty debit order object for the modal */
    _emptyDebitOrder() {
        return {
            doReferenceNumber : '',
            doiId             : '',
            doiName           : '',
            debitOrderDate    : '',
            amount            : null,
            category          : ''
        };
    }

    /** Shorthand for ShowToastEvent */
    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}