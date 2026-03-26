import fetchCoreBankingTransactions from '@salesforce/apex/Capitec_TrackAndTraceController.fetchCoreBankingTransactions'
import fetchCardTransactions from '@salesforce/apex/Capitec_TrackAndTraceController.fetchCardTransactions'
import fetchATMTransactionEvents from '@salesforce/apex/Capitec_TrackAndTraceController.fetchATMTransactionEvents'
import fetchATMDeviceEvents from '@salesforce/apex/Capitec_TrackAndTraceController.fetchATMDeviceEvents'

import saveCoreBankingTransactions from '@salesforce/apex/Capitec_TrackAndTraceController.saveCoreBankingTransactions'
import saveCardTransactions from '@salesforce/apex/Capitec_TrackAndTraceController.saveCardTransactions';
import saveATMTransactionEvents from '@salesforce/apex/Capitec_TrackAndTraceController.saveATMTransactionEvents';
import saveATMDeviceEvents from '@salesforce/apex/Capitec_TrackAndTraceController.saveATMDeviceEvents';

const DATA_SOURCE_TYPE = {
    CORE_BANKING_TRANSACTIONS: 'Core Banking Transactions',
    CARD_TRANSACTIONS: 'Card Transactions',
    ATM_TRANSACTION_EVENTS: 'ATM Transaction Events',
    ATM_DEVICE_EVENTS: 'ATM Device Events',
}

const handleFetchCoreBankingTransactions = (accountNumber, startDate, endDate) => {
    let data = fetchCoreBankingTransactions({accountNumber, startDate, endDate})
    return data;
}

const handleFetchCardTransactions = (fromAccountNumber, startDate, endDate) => {
    let data = fetchCardTransactions({fromAccountNumber, startDate, endDate})
    return data;
}

const handleFetchATMTransactionEvents = (deviceId, startDate, endDate) => {
    let data = fetchATMTransactionEvents({deviceId, startDate, endDate})
    return data;
}

const handleFetchATMDeviceEvents = (deviceId, startDate, endDate) => {
    let data = fetchATMDeviceEvents({deviceId, startDate, endDate})
    return data;
}

const handleSaveCoreBankingTransactions = (data) => {
    saveCoreBankingTransactions({data : (JSON.stringify(data))});
}

const handleSaveCardTransactions = (data) => {
    saveCardTransactions({data : (JSON.stringify(data))})
}

const handleSaveATMTransactionEvents = (data) => {
    saveATMTransactionEvents({data : (JSON.stringify(data))})
}

const handleSaveATMDeviceEvents = (data) => {
    saveATMDeviceEvents({data : (JSON.stringify(data))})
}


export {
    DATA_SOURCE_TYPE, 
    handleFetchCoreBankingTransactions, 
    handleFetchCardTransactions, 
    handleFetchATMTransactionEvents, 
    handleFetchATMDeviceEvents,
    handleSaveCoreBankingTransactions, 
    handleSaveCardTransactions, 
    handleSaveATMTransactionEvents, 
    handleSaveATMDeviceEvents
};