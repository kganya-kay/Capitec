import { api, LightningElement, track, wire } from "lwc";
import {
  transactionHistoryGetAccs,
  formatDate,
  getStartDate,
  formatTHDateDisplay,
  getTransactionHistory
} from "c/capitec_AMLTHDataHandler";
import LightningAlert from "lightning/alert";
import getRecordTypeName from "@salesforce/apex/Capitec_GenericTHController.getRecordTypeName";
import getHandleFlagToCase from "@salesforce/apex/Capitec_GenericTHController.getHandleFlagToCase";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import ALERT_CREATE_DATE_FIELD from "@salesforce/schema/Case.Alert_Create_Date__c";
const FIELDS = [ALERT_CREATE_DATE_FIELD];
const filename = 'data.csv';



export default class Capitec_AMLTransactionHistory extends LightningElement {

  @api recordId;
 
  @track jsonString;
  @track itemsToDisplay;
  @track financialAccountsNumbers;
  @track startDate;
  @track endDate;
  @track comboboxValue;
  @track showSpinner = false;
  @track disableActions = true;
  @track showTable = false;

  recordTypeName;
  error;
  isAmlRecordType = false;
  amlRecordTypes = ['AML Record Type', 'AML CRA Onboarding'];

@wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredRecord({ error, data }) {
    if (data) {
      const alertCreateDate = data.fields.Alert_Create_Date__c.value;
      if (alertCreateDate) {
        const alertDate = new Date(alertCreateDate);
        this.endDate = alertDate.toISOString().split("T")[0];

        const endDate = new Date(alertDate);
        endDate.setDate(alertDate.getDate() - 90);
        this.startDate = endDate.toISOString().split("T")[0];
        
      }else{
        const alertDate = new Date();
        this.endDate = alertDate.toISOString().split("T")[0];

        const endDate = new Date(alertDate);
        endDate.setDate(alertDate.getDate() - 90);
        this.startDate = endDate.toISOString().split("T")[0];
      }
    } else if (error) {
      console.error("Error fetching Alert_Create_Date__c:", error);
      const alertDate = new Date();
        this.endDate = alertDate.toISOString().split("T")[0];

        const endDate = new Date(alertDate);
        endDate.setDate(alertDate.getDate() - 90);
        this.startDate = endDate.toISOString().split("T")[0];
    }
  }

 

  @wire(getRecordTypeName, { recordId: '$recordId' })
    wiredRecordType({ error, data }) {
        if (data) {
            this.recordTypeName = data;
            this.isAmlRecordType = this.amlRecordTypes.includes(data);
            this.error = undefined;

        } else if (error) {
            this.error = error;
            this.recordTypeName = undefined;
            this.isAmlRecordType = false; // Reset flag
            console.error('Error fetching record type: ', error);
        }
    }
  async connectedCallback() {
    this.handleInitiateData(this.recordId);
    this.handleGetTransactions = this.handleGetTransactions.bind(this);
  }

  async getLast7Dates(event) {
    var today = new Date();
    var sevenDaysAgo = new Date(today);
    sevenDaysAgo.setDate(today.getDate() - 7);
    var todayDate = new Date(today);

    var startDateInput = this.template.querySelector("[data-id=\"startDateInput\"]");
    var endDateInput = this.template.querySelector("[data-id=\"endDateInput\"]");

    await formatDate(sevenDaysAgo).then(result => {
      startDateInput.value = result;
    });

    await formatDate(todayDate).then(result => {
      endDateInput.value = result;
    });
  }

  async getLast30Dates(event) {
    var today = new Date();
    var thirtyDaysAgo = new Date(today);
    thirtyDaysAgo.setDate(today.getDate() - 30);
    var todayDate = new Date(today);

    var startDateInput = this.template.querySelector("[data-id=\"startDateInput\"]");
    var endDateInput = this.template.querySelector("[data-id=\"endDateInput\"]");

    await formatDate(thirtyDaysAgo).then(result => {
      startDateInput.value = result;
    });

    await formatDate(todayDate).then(result => {
      endDateInput.value = result;
    });
  }

  async handleGetTransactions(event) {
    this.showSpinner = true;
    this.itemsToDisplay = [];
    let startDateVal = this.template.querySelector("[data-id=\"startDateInput\"]").value;
    let endDateVal = this.template.querySelector("[data-id=\"endDateInput\"]").value;
    let comboBoxVal = this.template.querySelector("[data-id=\"combobox-fin-id\"]").value;
    let calloutAccountNumbers = [];

    if (startDateVal > endDateVal) {
      await this.displayWrongDateWarning();
      this.itemsToDisplay = null;
      this.showSpinner = false;
      return;
    }

    calloutAccountNumbers = this.selectAccNumberForCallout(comboBoxVal);
    await this.performGetCallouts(calloutAccountNumbers, startDateVal, endDateVal);

    this.showSpinner = false;
  }

  handleFlag(event) {
    this.itemsToDisplay[event.target.dataset.itemId].newFraudFlagged = event.target.checked;
  }

  async handleInitiateData(recordId) {
    // console.log(recordId);

   /* await getStartDate(recordId).then(result => {
      this.startDate = new Date(result).toISOString().split("T")[0];
      this.endDate = new Date().toISOString().split("T")[0];
    });
*/
    await transactionHistoryGetAccs(recordId).then(result => {
      try {
        this.financialAccountsNumbers = result;
        this.comboboxValue = result[0].value;
      } catch (e) {
        console.error(JSON.stringify(e.message), e);
      }

      //console.log(JSON.stringify(result));
    });
  }

  async performGetCallouts(calloutAccountNumbers, startDateVal, endDateVal) {
    let promises = calloutAccountNumbers.map(accNumber => {
      return getTransactionHistory(accNumber.replace(/^0+/, ""), startDateVal, endDateVal)
        .then(result => {
          try {
            this.disableActions = false;
            result.forEach(currentItem => {
              if (currentItem.transactionDateTime) {
                const dateObj = new Date(currentItem.transactionDateTime);
                currentItem.transactionDateFormatted = formatTHDateDisplay(dateObj);
              }
              //Add the full acc number with leading zeros for local flagging
              currentItem.accNumberFull = accNumber;
            });
            this.itemsToDisplay.push(...result);
            this.showTable = true;
           
          } catch (e) {
            console.error(JSON.stringify(e.message), e);
          }
        });
    });

    // Wait for all promises to resolve
    await Promise.all(promises);
    
  }

  selectAccNumberForCallout(comboBoxVal) {
    let calloutAccountNumbers = [];
    if (comboBoxVal === "allAccounts") {

      this.financialAccountsNumbers.forEach(comboBoxAccVal => {
        calloutAccountNumbers.push(comboBoxAccVal.value);
      });
      calloutAccountNumbers.shift();

      // console.log(JSON.stringify(calloutAccountNumbers));
    } else {
      calloutAccountNumbers.push(comboBoxVal);
    }

    return calloutAccountNumbers;
  }

  async displayWrongDateWarning() {
    await LightningAlert.open({
      message: "Please ensure that the Start Date is before the End Date",
      theme: "warning",
      label: "Warning"
    });
  }

  async displayNoRecordsSelectedWarning() {
    await LightningAlert.open({
      message: "No records were selected",
      theme: "warning",
      label: "Warning"
    });
  }

  async displayNoTransactionsFoundWarning() {
    await LightningAlert.open({
      message: "No transactions found for this account",
      theme: "warning",
      label: "Warning"
    });
  }

  async handleFlagToCase(event) {
    var selectedItems = [];
    selectedItems = this.itemsToDisplay.filter(row => row.newFraudFlagged);

    if (selectedItems.length === 0) {
      this.showToast("Error", "Please Select a Transaction", "error");
      return;
    }

    try {
      var result = await getHandleFlagToCase({
        caseId: this.recordId,
        selectedItems: selectedItems
      });

      if (result === "success") {
        this.showToast("Saved", "Records saved successfully.", "success");
      } else if (result === "duplicateTransactionId") {
        this.showToast("Error", "An existing record with the same Transaction ID exists. Please check your selection.", "error");
      } else {
        this.showToast("Error", result, "error");
      }
    } catch (error) {
      console.error("Error in handleFlagToCase:", error);
      this.showToast("Error", "An unexpected error occurred.", "error");
    }
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

// csv file
handleSaveCSV() {
  console.log('1.button clicked');
  console.log("2.Items to Display: ", this.itemsToDisplay); 
    if (!this.itemsToDisplay || this.itemsToDisplay.length === 0) {
      this.showToast("Error", "No transactions to export.", "error");
      return;
    }

    const csvContent = this.generateCSV(this.itemsToDisplay);
    const blob = new Blob([csvContent], { type: 'text/plain' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = filename;
    link.style.display = 'none';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  generateCSV(data) {
     console.log('--3--');
    const headers = [
      "Account", "Transaction Date", "Transaction Code", "Transaction Description",
      "Teller Name", "Money In", "Balance", "To Account", "Transaction Type",
      "Statement Description", "Branch Name", "Amount", "Channel", "Journal Number"
    ];

    const rows = data.map(item => ([
      item.accountNr, item.transactionDateFormatted, item.tranCode, item.originalDesc,
      item.teller, item.moneyIn, item.balance, item.transferAccountNr,
      item.tranGroupType, item.statementDesc, item.branch, item.amount,
      item.channelTypeDesc, item.journalNr
    ]));

    return [
      headers.join(","),
      ...rows.map(row => row.join(","))
    ].join("\n");
  }

 
}