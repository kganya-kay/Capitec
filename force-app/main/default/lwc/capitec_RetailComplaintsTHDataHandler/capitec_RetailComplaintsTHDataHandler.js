/**
 * Created by Pako on 16.02.2024.
 */

import fetchFlaggedTransactions from '@salesforce/apex/Capitec_RetailComplaintsTHController.getFlaggedTransactions'
import fetchTransactionHistory from '@salesforce/apex/Capitec_RetailComplaintsTHController.getTransactionHistory'
import fetchAccountNumbers from '@salesforce/apex/Capitec_RetailComplaintsTHController.getProductsByCase'
import fetchStartDate from '@salesforce/apex/Capitec_RetailComplaintsTHController.getDateRange'
import fetchConsultantCP from '@salesforce/apex/Capitec_RetailComplaintsTHController.getConsultantCP'
import postApplyActionsCallout from '@salesforce/apex/Capitec_RetailComplaintsTHController.postApplyActions'

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

    const caseActionsGetFlagged = async (recordId) => {
        let chasedTransactions;

        try{
            await fetchFlaggedTransactions({caseId: recordId}).then(result => {
                chasedTransactions = JSON.parse(result);
                console.log(result);
                if(!chasedTransactions.error)
                {
                    console.log('*******');
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

    const getTransactionHistory = async(capiAccNo, caseId, startDate, endDate) => {
        let transactionsWrapper = {};
        let itemsToReturn = [];

        try{
            await fetchTransactionHistory({capiAccountNumber: capiAccNo , caseId: caseId, startDate : startDate, endDate : endDate}).then(result => {
                transactionsWrapper = JSON.parse(result);

                if(transactionsWrapper.error || !transactionsWrapper.transactions){
                    let tempItem = {};
                    tempItem.disableFlag = true;
                    tempItem.account = capiAccNo;
                    tempItem.tranCode = transactionsWrapper.statusCode;
                    tempItem.originalDescription = transactionsWrapper.message? transactionsWrapper.message : 'No Transaction History available for this account number';

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

    const getStartDate = async(recordId) => {
        return fetchStartDate({caseId : recordId});
    }

    const formatDate = async(dateToBeFormatted) => {
        var year = dateToBeFormatted.getFullYear();
        var month = (dateToBeFormatted.getMonth() + 1).toString().padStart(2, '0');
        var day = dateToBeFormatted.getDate().toString().padStart(2, '0');
        console.log(year + '-' + month + '-' + day);
        return (year + '-' + month + '-' + day);
    }

    const processItem = (item, label) =>{

        if(label){
            item.popUpLabel = label;
            item.showHelpText = true;
        }
        else{
            item.popUpLabel = null;
            item.showHelpText = false;
        }

        item.disableFlag = !(!item.moneyIn);
        item.newFraudFlagged = item.fraudFlagged;

        return item;
    }

    const postApplyActions = async (transactionsWrapper) => {
        if(transactionsWrapper.transactions.length < 1) return "204";
        let deepWrapperCopy = JSON.parse(JSON.stringify(transactionsWrapper));
        
        processPostWrapper(deepWrapperCopy);
        let response = await postApplyActionsCallout({jsonString : JSON.stringify(deepWrapperCopy)});

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

        console.log(JSON.stringify(labelsBySpendGroups));
        return labelsBySpendGroups;
    }

    const processPostWrapper = (deepWrapperCopy) => {
        
        deepWrapperCopy.transactions.forEach(transItem => {
            transItem.fraudFlagged = transItem.newFraudFlagged;

            delete transItem.newFraudFlagged;

            delete transItem.disableFlag;

            delete transItem.popUpLabel;
            delete transItem.showHelpText;
        });
    }


export {caseActionsLoadData, transactionHistoryGetAccs, getStartDate, formatDate, caseActionsGetFlagged,
    getTransactionHistory, getLabelsMap, postApplyActions, fetchConsultantCPByCaseId,
    changeSpendGroupToLabels, preparePopupsContent};