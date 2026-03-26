/**
 * Created by dawid on 09.11.2023.
 */

public with sharing class Capitec_CaseUtils {
    public static String getCIFByRecordId(String caseId) {
        try{
            Case caseRec = [SELECT Id, CIF_Number__c, Account_CIF_Number__c FROM Case WHERE Id = :caseId LIMIT 1];
            return  caseRec.CIF_Number__c == null ? caseRec.Account_CIF_Number__c : caseRec.CIF_Number__c;
        }
        catch (QueryException e){
            System.debug(e.getMessage());
            return null;
        }
    }

    public static String getConsultantCP(String caseId){
        try{
            Case caseRec = [SELECT Id, capitec_Employee_Code__c FROM Case WHERE Id = :caseId LIMIT 1];
            return  caseRec.capitec_Employee_Code__c;
        }
        catch (QueryException e){
            System.debug(e.getMessage());
            return null;
        }
    }

}