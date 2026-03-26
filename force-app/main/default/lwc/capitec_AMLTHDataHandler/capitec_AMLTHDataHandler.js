/* AS Kandula - for Transaction history (AML2)
*/

import fetchTransactionHistory from "@salesforce/apex/Capitec_GenericTHController.getTransactionHistory";
import fetchAccountNumbers from "@salesforce/apex/Capitec_GenericTHController.getProductsByCase";
import fetchStartDate from "@salesforce/apex/Capitec_GenericTHController.getDateRange";
import fetchConsultantCP from "@salesforce/apex/Capitec_GenericTHController.getConsultantCP";

const caseActionsLoadData = async (id) => {
  let jsonString;
  let itemsToDisplay;
  itemsToDisplay = JSON.parse(jsonString);

  if (Array.isArray(itemsToDisplay) && itemsToDisplay.length > 0) {
    itemsToDisplay.forEach(item => {
      item = applyRules(item);
    });
  }

  return itemsToDisplay;
};

const fetchConsultantCPByCaseId = async (recordId) => {
  let consultantCp;
  await fetchConsultantCP({ recordId: recordId }).then(result => {
    consultantCp = result;
  });

  return (consultantCp);
};

const transactionHistoryGetAccs = async (recordId) => {
  let jsonString;
  let productsWrapper;
  let accountComboboxValues = [];

  try {
    await fetchAccountNumbers({ caseId: recordId }).then(result => {
      jsonString = result;
      // console.log(JSON.stringify(result));
    });
    productsWrapper = JSON.parse(jsonString);
  } catch (e) {
    console.error(JSON.stringify(e.message), e);
  }


  if (!productsWrapper.error) {
    productsWrapper.accounts.forEach(acc => {
      accountComboboxValues.push({
        value: (acc.accountNumber),
        label: (acc.accountName + " " + acc.accountNumber.replace(/^0+/, ""))
      });
    });

    accountComboboxValues = [{ value: "allAccounts", label: "All Accounts" }, ...accountComboboxValues];
    return accountComboboxValues;
  } else {
    accountComboboxValues.push({
      value: "",
      label: "No accounts available"
    });

    return accountComboboxValues;
  }
};

const getTransactionHistory = async (capiAccNo, startDate, endDate) => {
  let transactionsWrapper = {};
  let itemsToReturn = [];

  try {
    await fetchTransactionHistory({
      capiAccountNumber: capiAccNo,
      startDate: startDate,
      endDate: endDate
    }).then(result => {
      transactionsWrapper = JSON.parse(result);

      if (transactionsWrapper.error || !transactionsWrapper.transactions) {
        let tempItem = {};
        tempItem.disableFlag = true;
        tempItem.account = capiAccNo;
        tempItem.tranCode = transactionsWrapper.statusCode;
        tempItem.originalDesc = transactionsWrapper.message ? transactionsWrapper.message : "No Transaction History available for this account number";

        itemsToReturn.push(tempItem);
      } else {
        itemsToReturn = transactionsWrapper.transactions;
        itemsToReturn.forEach(item => {
          item.disableFlag = !(!item.moneyIn);
        });
      }
    });
  } catch (e) {
    console.error(JSON.stringify(e.message), e);
  }
  return itemsToReturn;
};

const getStartDate = async (recordId) => {
  return fetchStartDate({ caseId: recordId });
};

const formatDate = async (dateToBeFormatted) => {
  var year = dateToBeFormatted.getFullYear();
  var month = (dateToBeFormatted.getMonth() + 1).toString().padStart(2, "0");
  var day = dateToBeFormatted.getDate().toString().padStart(2, "0");
  return (year + "-" + month + "-" + day);
};

const formatTHDateDisplay = (dateObj) => {
  const options = { year: "numeric", month: "2-digit", day: "2-digit" };
  const datePart = dateObj.toLocaleDateString("en-GB", options).split("/").join("-"); // Format: DD-MM-YYYY
  const timePart = dateObj.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" }); // Format: hh:mm
  return `${datePart} ${timePart}`; // Combine the date and time
};

export {
  caseActionsLoadData, transactionHistoryGetAccs, getStartDate, formatDate, formatTHDateDisplay,
  getTransactionHistory, fetchConsultantCPByCaseId
};