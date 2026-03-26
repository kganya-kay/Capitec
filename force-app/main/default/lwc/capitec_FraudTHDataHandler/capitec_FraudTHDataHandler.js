/**
 * Created by dawid on 02.11.2023.
 */

import fetchChasedTransactions from '@salesforce/apex/Capitec_FraudTHController.getChasedTransactions'
import fetchChasedFlaggedTransactions from '@salesforce/apex/Capitec_FraudTHController.getChasedFlaggedTransactions'
import fetchTransactionHistory from '@salesforce/apex/Capitec_FraudTHController.getTransactionHistory'
import fetchTransactionHistoryGen from '@salesforce/apex/Capitec_FraudTHController.getTransactionHistoryGen'
import fetchAccountNumbers from '@salesforce/apex/Capitec_FraudTHController.getProductsByCase'
import fetchStartDate from '@salesforce/apex/Capitec_FraudTHController.getDateRange'
import fetchConsultantCP from '@salesforce/apex/Capitec_FraudTHController.getConsultantCP'
import postApplyActionsCallout from '@salesforce/apex/Capitec_FraudTHController.postApplyActions'
import postChaseCallout from '@salesforce/apex/Capitec_FraudTHController.postChase'
import postConfirmHoldCallout from '@salesforce/apex/Capitec_FraudTHController.postConfirmHold'

import billPaymentsLabel from '@salesforce/label/c.Fraud_Popup_BillPayments';
import cardAuthorisationTransactionLabel from '@salesforce/label/c.Fraud_Popup_CardAuthorisationTransaction';
import cardSubscriptionForExcludedMerchantsLabel
    from '@salesforce/label/c.Fraud_Popup_CardSubscriptionForExcludedMerchants';
import cardSubscriptionLabel from '@salesforce/label/c.Fraud_Popup_CardSubscription';
import cardTransactionABULabel from '@salesforce/label/c.Fraud_Popup_CardTransactionABU';
import cardTransactionChargebackLabel from '@salesforce/label/c.Fraud_Popup_CardTransactionChargeback';
import cashDepositLabel from '@salesforce/label/c.Fraud_Popup_PrepaidCapitecConnect';
import liveBetterBenefitLabel from '@salesforce/label/c.Fraud_Popup_PrepaidCapitecConnect';
import prepaidCapitecConnectLabel from '@salesforce/label/c.Fraud_Popup_PrepaidCapitecConnect';
import cashWithdrawalLabel from '@salesforce/label/c.Fraud_Popup_CashWithdrawal';
import debitOrderLabel from '@salesforce/label/c.Fraud_Popup_DebitOrder';
import paymentInternalOrTransferLabel from '@salesforce/label/c.Fraud_Popup_Lottery';
import prepaidLabel from '@salesforce/label/c.Fraud_Popup_Prepaid';
import sendCashLabel from '@salesforce/label/c.Fraud_Popup_SendCash';
import standingOrderPaymentExternalLabel from '@salesforce/label/c.Fraud_Popup_StandingOrderPaymentExternal';
import standingOrderPaymentInternalLabel from '@salesforce/label/c.Fraud_Popup_StandingOrderPaymentInternal';
import unpaidOrBouncedDebitOrderLabel from '@salesforce/label/c.Fraud_Popup_UnpaidOrBouncedDebitOrder';
import unpaidOrBouncedStandingOrderLabel from '@salesforce/label/c.Fraud_Popup_UnpaidOrBouncedStandingOrder';
import vouchersLabel from '@salesforce/label/c.Fraud_Popup_Vouchers';
import { updateRecord } from 'lightning/uiRecordApi'; //FFSF-448 - Added uiRecordApi to update the case record


    const caseActionsLoadData = async (id) => {
        let jsonString;
        let itemsToDisplay;
        await fetchFlaggedTransactions({caseId : id}).then(result => {
            jsonString = result;
        });
        itemsToDisplay = JSON.parse(jsonString);

        if(Array.isArray(itemsToDisplay) && itemsToDisplay.length > 0){
            itemsToDisplay.forEach(item => {
                item = applyRules(item);
            })

        }

        return itemsToDisplay;
    }

    //FFSF-448 - Added function to update the Total Amount Defrauded on the Case record
    const calculateTotalFlaggedTransactionValueAndUpdateCase = async (recordId) =>  {
        try {
            const lstItems = await caseActionsGetFlaggedChased(recordId);
            let FlaggedTotal = 0;
            if (Array.isArray(lstItems) && lstItems.length > 0) {
                lstItems.forEach(item => {
                    //FFSF-775 Fadded filter to calculate amount defrauded from items related to the current case only
                    if (item.flaggedFraud && !item.moneyIn && item.caseId==recordId) {  
                        FlaggedTotal += item.amount;
                    }
                });
            }
            FlaggedTotal = Math.abs(FlaggedTotal);
            const fields = {
                Id: recordId,
                Total_Amount_Defrauded__c: FlaggedTotal
            };
            await updateRecord({ fields });
        } catch (error) {
            console.error('Error2 updating Total Amount Defrauded: ', error.body ? error.body.message : error);
        }
    }

    const fetchConsultantCPByCaseId = async (recordId) => {
        let consultantCp;
        await fetchConsultantCP({recordId: recordId}).then( result => {
            consultantCp = result;
        });

        return (consultantCp);
    }

    const transactionHistoryGetAccs = async(recordId) => {
        let jsonString;
        let productsWrapper;
        let accountComboboxValues = [];

        try{
            await fetchAccountNumbers({caseId: recordId}).then(result => {
                jsonString = result;
                // console.log(JSON.stringify(result));
            })
            productsWrapper = JSON.parse(jsonString);
        }
        catch (e){
            console.log(JSON.stringify(e.message));
        }


        if(!productsWrapper.error)
        {
            productsWrapper.accounts.forEach(acc => {
                accountComboboxValues.push({
                    value : (acc.accountNumber),
                    label : (acc.accountName + ' ' +acc.accountNumber.replace(/^0+/, ''))
                })
            })

            accountComboboxValues = [{value : 'allAccounts', label : 'All Accounts'}, ...accountComboboxValues];
            return accountComboboxValues;
        }
        else{
            accountComboboxValues.push({
                value : '',
                label : 'No accounts available'
            })

            return accountComboboxValues;
        }
    }

    const caseActionsGetChased = async (recordId) => {
        let chasedTransactions;

        try{
            await fetchChasedTransactions({caseId: recordId}).then(result => {
                chasedTransactions = JSON.parse(result);
                if(!chasedTransactions.error)
                {
                    chasedTransactions.forEach(trans => {
                        trans = processItem(trans);
                    })
                }
            })
        }
        catch (e){
            console.log(JSON.stringify(e.message));
        }
        return chasedTransactions;
    }

    const caseActionsGetFlaggedChased = async (recordId) => {
        let chasedTransactions;

        try{
            await fetchChasedFlaggedTransactions({caseId: recordId,findHolds: false}).then(result => {
                chasedTransactions = JSON.parse(result);
                if(!chasedTransactions.error)
                {
                    chasedTransactions.forEach(trans => {
                        trans = processItem(trans);
                    })
                }
            })
        }
        catch (e){
            console.log(JSON.stringify(e.message));
        }
        return chasedTransactions;
    }

    const caseActionsGetFlaggedChasedInit = async (recordId) => {
        let chasedTransactions;

        try{
            await fetchChasedFlaggedTransactions({caseId: recordId,findHolds: true}).then(result => {
                chasedTransactions = JSON.parse(result);
                if(!chasedTransactions.error)
                {
                    chasedTransactions.forEach(trans => {
                        trans = processItem(trans);
                    })
                }
            })
        }
        catch (e){
            console.log(JSON.stringify(e.message));
        }
        return chasedTransactions;
    }

    const getTransactionHistory = async(capiAccNo, caseId, startDate, endDate, accTypeVal) => {
        let transactionsWrapper = {};
        let itemsToReturn = [];

        try{
            await fetchTransactionHistory({capiAccountNumber: capiAccNo , caseId: caseId, startDate : startDate, endDate : endDate, accTypeVal:accTypeVal}).then(result => {
                transactionsWrapper = JSON.parse(result);

                if(transactionsWrapper.error || !transactionsWrapper.transactions){
                    let tempItem = {};
                    tempItem.disableFlag = true;
                    tempItem.disableHold = true;
                    tempItem.disableChase = true;
                    tempItem.accountNr = capiAccNo;
                    tempItem.tranCode = transactionsWrapper.statusCode;
                    tempItem.originalDesc = transactionsWrapper.message? transactionsWrapper.message : 'No Transaction History available for this account number';

                    itemsToReturn.push(tempItem);
                }
                else{
                    itemsToReturn = transactionsWrapper.transactions;
                    let labelsBySpendGroup = getLabelsMap();
                    itemsToReturn.forEach(item =>{
                        item = processItem(item, labelsBySpendGroup.get(item.spendGroup));
                    })
                }
            });
        }
        catch (e){
            console.log(JSON.stringify(e.message));
        }
        return itemsToReturn;
    }

        const getTransactionHistoryGen = async(capiAccNo, caseId, startDate, endDate, accTypeVal) => {
        let transactionsWrapper = {};
        let itemsToReturn = [];

        try{
            await fetchTransactionHistoryGen({capiAccountNumber: capiAccNo , caseId: caseId, startDate : startDate, endDate : endDate, accTypeVal:accTypeVal}).then(result => {
                transactionsWrapper = JSON.parse(result);

                if(transactionsWrapper.error || !transactionsWrapper.transactions){
                    let tempItem = {};
                    tempItem.accountNr = capiAccNo;
                    tempItem.tranCode = transactionsWrapper.statusCode;
                    tempItem.originalDesc = transactionsWrapper.message? transactionsWrapper.message : 'No Transaction History available for this account number';

                    itemsToReturn.push(tempItem);
                }
                else{
                    itemsToReturn = transactionsWrapper.transactions;
                    let labelsBySpendGroup = getLabelsMap();
                    itemsToReturn.forEach(item =>{
                        console.log('lgo item ',JSON.stringify(item));
                        item = processItem(item, labelsBySpendGroup.get(item.spendGroup));
                    })
                }
            });
        }
        catch (e){
            console.log(JSON.stringify(e.message));
        }
        return itemsToReturn;
    }

    const getStartDate = async(recordId) => {
        return fetchStartDate({caseId : recordId});
    }

    const formatDate = async(dateToBeFormatted) => {
        var year = dateToBeFormatted.getFullYear();
        var month = (dateToBeFormatted.getMonth() + 1).toString().padStart(2, '0');
        var day = dateToBeFormatted.getDate().toString().padStart(2, '0');
        return (year + '-' + month + '-' + day);
    }

    const processItem = (item, label) =>{
    
        const formattedTransactionDate = convertStringToDate(item.transactionDateTime);
        item.newtransactionDate = formattedTransactionDate;

        const formattedlastUpdatedAt = convertStringToDate(item.updatedAt);
        item.newlastUpdatedAt = formattedlastUpdatedAt;

        if(label){
            item.popUpLabel = label;
            item.showHelpText = true;
        }
        else{
            item.popUpLabel = null;
            item.showHelpText = false;
        }

        if(!item.autoUnholdDate && item.flaggedHold){
            item.confirmHold = true;
            item.confirmHoldDisabled = true;
        }

        item.disableFlag = !(!item.moneyIn);
        item.newFraudFlagged = item.flaggedFraud;

        item.disableHold = !(item.moneyIn);
        item.confirmHoldDisabled = !(item.moneyIn);

        item.newHoldFlagged = item.flaggedHold;

        if(!(!item.moneyIn) || item.flaggedChase){
            item.disableChase = true;
        }
        item.newChaseFlagged = item.flaggedChase;

        return item;
    }

    const postApplyActions = async (transactionsWrapper) => {
        if(transactionsWrapper.transactions.length < 1) return "204";
        let deepWrapperCopy = JSON.parse(JSON.stringify(transactionsWrapper));
        
        processPostWrapper(deepWrapperCopy);
        let response = await postApplyActionsCallout({jsonString : JSON.stringify(deepWrapperCopy)});

        return JSON.parse(response);
    }

    const postChase = async (transactionsWrapper) => {
        if(transactionsWrapper.transactions.length < 1) return "204";
        let deepWrapperCopy = JSON.parse(JSON.stringify(transactionsWrapper));

        processPostWrapper(deepWrapperCopy);
        let response = await postChaseCallout({jsonString : JSON.stringify(deepWrapperCopy)});

        return JSON.parse(response);
    }



    const postConfirmHold = async (transactionsWrapper) => {
        if(transactionsWrapper.length < 1) return "204";
        let response = await postConfirmHoldCallout({jsonString : JSON.stringify(transactionsWrapper)});

        return JSON.parse(response);
    }

    const changeSpendGroupToLabels = (spendGroupSet) => {
        let labelsMap = getLabelsMap();
        let prefix = 'Additional information:';
        let fullString = '';

        console.log(JSON.stringify(spendGroupSet));

        if(!spendGroupSet) return;
        spendGroupSet.forEach(sGroup => {
            if(labelsMap.has(sGroup)){
                fullString += '\n\n' ;
                fullString += labelsMap.get(sGroup);
            }
        })

        if(fullString === ''){
            fullString = '\n\nNone'
        }

        return (fullString);
    }

    const preparePopupsContent = (itemsToFlag) => {
        let selectedSpendGroups = new Set();

        itemsToFlag.transactions.forEach(item => {
            console.log(JSON.stringify(item.showHelpText));
            if(item.showHelpText === true){
                selectedSpendGroups.add(item.spendGroup);
            }
        })

        return changeSpendGroupToLabels(selectedSpendGroups);
    }

    const getLabelsMap = () => {
        let labelsBySpendGroups = new Map();

        labelsBySpendGroups.set("BillPayments", billPaymentsLabel);
        labelsBySpendGroups.set("CardAuthorisationTransaction", cardAuthorisationTransactionLabel);
        labelsBySpendGroups.set("CardSubscriptionForExcludedMerchants", cardSubscriptionForExcludedMerchantsLabel);
        labelsBySpendGroups.set("CardSubscription", cardSubscriptionLabel);
        labelsBySpendGroups.set("CardTransactionABU", cardTransactionABULabel);
        labelsBySpendGroups.set("CardTransactionChargeback", cardTransactionChargebackLabel);
        labelsBySpendGroups.set("CashDeposit", cashDepositLabel);
        labelsBySpendGroups.set("CashWithdrawal", cashWithdrawalLabel);
        labelsBySpendGroups.set("DebitOrder", debitOrderLabel);
        labelsBySpendGroups.set("LiveBetterBenefit", liveBetterBenefitLabel);
        labelsBySpendGroups.set("PaymentInternalOrTransfer", paymentInternalOrTransferLabel);
        labelsBySpendGroups.set("Prepaid", prepaidLabel);
        labelsBySpendGroups.set("PrepaidCapitecConnect", prepaidCapitecConnectLabel);
        labelsBySpendGroups.set("SendCash", sendCashLabel);
        labelsBySpendGroups.set("StandingOrderPaymentExternal", standingOrderPaymentExternalLabel);
        labelsBySpendGroups.set("StandingOrderPaymentInternal", standingOrderPaymentInternalLabel);
        labelsBySpendGroups.set("UnpaidOrBouncedDebitOrder", unpaidOrBouncedDebitOrderLabel);
        labelsBySpendGroups.set("UnpaidOrBouncedStandingOrder", unpaidOrBouncedStandingOrderLabel);
        labelsBySpendGroups.set("Vouchers", vouchersLabel);

        return labelsBySpendGroups;
    }

    const processPostWrapper = (deepWrapperCopy) => {
        
        deepWrapperCopy.transactions.forEach(transItem => {
            transItem.flaggedFraud = transItem.newFraudFlagged;
            transItem.flaggedHold = transItem.newHoldFlagged;
            transItem.flaggedChase = transItem.newChaseFlagged;

            delete transItem.newFraudFlagged;
            delete transItem.newHoldFlagged;
            delete transItem.newChaseFlagged;


            delete transItem.disableFlag;
            delete transItem.disableHold;
            delete transItem.disableChase;
            delete transItem.confirmHoldDisabled;

            delete transItem.popUpLabel;
            delete transItem.showHelpText;
        });
    }

    const convertStringToDate = (tempDate) => {
        // lgo convert string date to datetime dd/mm/yy, hh:min
        const transDate = new Date(tempDate);


        const yyyy = transDate.getFullYear();
        let mm = transDate.getMonth() + 1; // Months start at 0!
        let dd = transDate.getDate();
        let hh = transDate.getHours();
        let min = transDate.getMinutes();

        if (dd < 10) dd = '0' + dd;
        if (mm < 10) mm = '0' + mm;
        if (hh < 10) hh = '0' + hh;
        if (min < 10) min = '0' + min;

        // let currentTime = new Date().getTime();
        // let updatedTIme = new Date(currentTime + 2 * 60 * 60 * 1000);

        const formattedToday = dd + '/' + mm + '/' + yyyy + ', '+ hh + ':' + min;
        return formattedToday;
    }


export {caseActionsLoadData, transactionHistoryGetAccs, getStartDate, formatDate, caseActionsGetChased, caseActionsGetFlaggedChased,caseActionsGetFlaggedChasedInit,
    getTransactionHistory,getTransactionHistoryGen, getLabelsMap, postApplyActions, postChase, fetchConsultantCPByCaseId,
    changeSpendGroupToLabels, preparePopupsContent, postConfirmHold, calculateTotalFlaggedTransactionValueAndUpdateCase};