public without sharing class Capitec_TrackAndTraceController {

    /**
     * Created by: Radosław
     * fetchCoreBankingTransactions Method
     *
     * @param accountNumber string, specifies the account number for the request
     * @param startDate stringified starting Date in yyyy-MM-dd format. NOT DateTime
     * @param endDate stringified ending Date in yyyy-MM-dd format. NOT DateTime
     * @return returns a String containing either JSON response or error message
     *
     * This method calls callout method and can be invoke from lwc/aura components
     */

    @AuraEnabled
    public static string fetchCoreBankingTransactions(String accountNumber, String startDate, String endDate){ 
        String result = Capitec_TrackAndTraceCalloutHandler.makeCoreBankingTransactionCallout(accountNumber, startDate, endDate);
        System.debug('controller result: '+ result);
        return result;
    }

    /**
     * Created by: Radosław
     * fetchCardTransactions Method
     *
     * @param fromAccountNumber string, specifies the account number for the request
     * @param startDate stringified starting Date in yyyy-MM-dd format. NOT DateTime
     * @param endDate stringified ending Date in yyyy-MM-dd format. NOT DateTime
     * @return returns a String containing either JSON response or error message
     *
     * This method calls callout method and can be invoke from lwc/aura components
     */

    @AuraEnabled
    public static string fetchCardTransactions(String fromAccountNumber, String startDate, String endDate){
        String result =  Capitec_TrackAndTraceCalloutHandler.makeCardTransactionCallout(fromAccountNumber, startDate, endDate);
        System.debug('controller result: '+ result);
        return result;
    }

    /**
     * Created by: Radosław
     * fetchATMTransactionEvents Method
     *
     * @param @param deviceId string, specifies the device Id for the request
     * @param startDate stringified starting Date in yyyy-MM-dd format. NOT DateTime
     * @param endDate stringified ending Date in yyyy-MM-dd format. NOT DateTime
     * @return returns a String containing either JSON response or error message
     *
     * This method calls callout method and can be invoke from lwc/aura components
     */

    @AuraEnabled
    public static string fetchATMTransactionEvents(String deviceId, String startDate, String endDate){
        String result = Capitec_TrackAndTraceCalloutHandler.makeATMEventsTransactionCallout(deviceId, startDate, endDate);
        System.debug('controller result: '+ result);
        return result;
    }

    /**
     * Created by: Radosław
     * fetchATMDeviceEvents Method
     *
     * @param deviceId string, specifies the device Id for the request
     * @param startDate stringified starting Date in yyyy-MM-dd format. NOT DateTime
     * @param endDate stringified ending Date in yyyy-MM-dd format. NOT DateTime
     * @return returns a String containing either JSON response or error message
     *
     * This method calls callout method and can be invoke from lwc/aura components
     */

    @AuraEnabled
    public static string fetchATMDeviceEvents(String deviceId, String startDate, String endDate){
        String result = Capitec_TrackAndTraceCalloutHandler.makeATMEventsDeviceCallout(deviceId, startDate, endDate);
        System.debug('controller result: '+ result);
        return result;
    }

    /**
     * Created by: Radosław
     * saveCoreBankingTransactions Method
     *
     * @param data string, JSON data passed to convert to a record
     *
     * This method calls flagging handler method and can be invoke from lwc/aura components
     */

    @AuraEnabled
    public static void saveCoreBankingTransactions(String data){ 
        System.debug('data from controller' + data);
        Capitec_TrackAndTraceFlaggingHandler.saveFlaggedCoreBankingTransactions(data);
    }

    /**
     * Created by: Radosław
     * saveCardTransactions Method
     *
     * @param data string, JSON data passed to convert to a record
     * @return returns a String containing either JSON response or error message
     *
     * This method calls flagging handler method and can be invoke from lwc/aura components
     */

    @AuraEnabled
    public static void saveCardTransactions(String data){
        System.debug('data from controller' + data);
        Capitec_TrackAndTraceFlaggingHandler.saveFlaggedCardTransactions(data);
    }

    /**
     * Created by: Radosław
     * saveATMTransactionEvents Method
     *
     * @param data string, JSON data passed to convert to a record
     *
     * This method calls flagging handler method and can be invoke from lwc/aura components
     */

    @AuraEnabled
    public static void saveATMTransactionEvents(String data){
        System.debug('data from controller' + data);
        Capitec_TrackAndTraceFlaggingHandler.saveFlaggedCardATMTransactionEvents(data);
    }

    /**
     * Created by: Radosław
     * saveATMDeviceEvents Method
     *
     * @param data string, JSON data passed to convert to a record
     *
     * This method calls flagging handler method and can be invoke from lwc/aura components
     */

    @AuraEnabled
    public static void saveATMDeviceEvents(String data){
        System.debug('data from controller' + data);
        Capitec_TrackAndTraceFlaggingHandler.saveFlaggedCardATMDeviceEvents(data);
    }
}