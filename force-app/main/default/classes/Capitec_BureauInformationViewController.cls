/**
 * Created by dawid on 18.04.2023.
 */

public with sharing class Capitec_BureauInformationViewController {


    @AuraEnabled
    public static Capitec_BureauInformationViewHelper.BureauResponseWrapper getBureauInfo(String accountId){

        Capitec_BureauInformationViewHelper.BureauResponseWrapper wrapper = Capitec_BureauInformationViewHelper.getBureauInfo(accountId);
        return wrapper;
    }
}