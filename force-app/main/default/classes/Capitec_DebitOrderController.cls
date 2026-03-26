/**
 * @description       : Apex controller for Capitec_ConversionsDebitOrders LWC
 * @author            : Samiirah.A@bsky.co.za
 * @group             : Capitec Conversions
 * @last modified on  : 03-24-2026
 * @last modified by  : Samiirah Aujub
**/
public with sharing class Capitec_DebitOrderController {

    private static final String API_USER = 'API ';

    public class CaseWrapper {
        @AuraEnabled public Case caseRecord;
        @AuraEnabled public Boolean manualCase;
    }

    @AuraEnabled(cacheable=true)
    public static List<Debit_Order__c> getDebitOrders(Id caseId) {
        return [SELECT Id, 
                       Name, 
                       Amount__c,
                       From_Account_Formula__c,
                       Category__c,
                       Submission_Date__c,
                       To_Capitec_Account__c,
                       Debit_Order_Initiator__c,
                       Debit_Order_Initiator__r.Name,
                       Debit_Order_Initiator__r.Preferred_Comms__c,
                       Debit_Order_Initiator__r.DOI_Contact_Email__c,
                       Debit_OrderDate__c,
                       Confirmation_Cause_Code__c,
                       Submitted_Cause_Code__c,
                       Withdrawn_Cause_Code__c,
                       DOI_Sub_Name__c,
                       DO_Issue__c,
                       Reviewed__c,
                       Preferred_Comms__c,
                       Not_yet_onboarded__c
                FROM Debit_Order__c 
                WHERE Case__c = :caseId];
    }

    @AuraEnabled(cacheable=true)
    public static CaseWrapper getCaseInfo(Id caseId) {
        Case caseRec = [SELECT  Id, 
                                Subject,
                                CaseNumber, 
                                Status,
                                Sub_Status__c,
                                Capitec_Category__c,
                                Origin,
                                Account.Name,
                                Account.PersonEmail,
                                Account.PersonContactId,
                                Conversion__r.Old_Account_Number__c,
                                Conversion__r.Manual_Case__c
                        FROM Case 
                        WHERE Id = :caseId
                        LIMIT 1];

        CaseWrapper caseWrapper = new CaseWrapper();
        caseWrapper.caseRecord = caseRec;
        caseWrapper.manualCase = caseRec.Conversion__r.Manual_Case__c;

        return caseWrapper;
    }
    
    @AuraEnabled(cacheable=true)
    public static Conversion__c getConversionRecord(Id caseId) {
        return [SELECT Id,
                       Old_Account_Number__c
                FROM Conversion__c 
                WHERE Case__c = :caseId];
    }


    /*

    @AuraEnabled(cacheable=true)
    public static Debit_Order_Initiator__c getDOIDetails(Id doiId) {
        List<Debit_Order_Initiator__c> lstDOIs = [ SELECT Id, 
                                                          Preferred_Comms__c,
                                                          DOI_Contact_Email__c
                                                   FROM Debit_Order_Initiator__c 
                                                   WHERE Id = :doiId 
                                                   LIMIT 1];
        if (!lstDOIs.isEmpty()) {
            return lstDOIs[0];
        }
        return null;
    }*/

    
    @AuraEnabled(cacheable=true)
    public static List<Debit_Order_Initiator__c> searchDOI(String searchKey) {
        String likeKey = '%' + searchKey + '%';

        List<Debit_Order_Initiator__c> lstDOIs = [ SELECT Id, 
                                                          Name,
                                                          Preferred_Comms__c,
                                                          DOI_Contact_Email__c
                                                   FROM Debit_Order_Initiator__c 
                                                   WHERE Name LIKE :likeKey
                                                   LIMIT 10];
        if (!lstDOIs.isEmpty()) {
            return lstDOIs;
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static  List<String> getHolidays() {
        List<String> lstHolidays = new List<String>();

        for(Holiday holiday : [SELECT Id, 
                                     Name,     
                                     RecurrenceDayOfMonth, 
                                     RecurrenceMonthOfYear
                              FROM Holiday])
        {
            String keyStr = holiday.RecurrenceDayOfMonth + holiday.RecurrenceMonthOfYear;
            lstHolidays.add(keyStr);
        }
        return lstHolidays;
    }

    public static Id getOrgWideEmailAddress(){
        OrgWideEmailAddress orgWideEmailAdd = [ SELECT Id
                                                FROM OrgWideEmailAddress
                                                WHERE Address = 'conversions@capitecbank.co.za' LIMIT 1];
        
        if(orgWideEmailAdd != null){
            return orgWideEmailAdd.Id;
        }
        else{
            return null;
        }
    }

    @AuraEnabled
    public static Boolean caseSubmission(Id caseId, List<Debit_Order__c> lstDOs){
        Boolean closeCase = true;
        
        try {
            for(Debit_Order__c debitOrder : lstDOs){
                if(debitOrder.Debit_Order_Initiator__r.Preferred_Comms__c != 'Client to Switch'){
                    closeCase = false;
                }
            }

            if(closeCase){
                publishCommsEvent(caseId);
            }
            else{
                updateCaseStatus(caseId, 'Submitted');
            }

            return true;
        }
        catch(Exception e) {
            System.debug('##Error case submission:' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled
    public static void updateCaseStatus(Id caseId, String status) {
        Case caseToUpdate = new Case(Id=caseId, Status=status);
        update caseToUpdate;
    }

    
    @AuraEnabled
    public static Boolean getUnclassifiedFiles(Id caseId) {
        Integer countRecords = [
            SELECT COUNT()
            FROM IC_DocumentRequestList__c
            WHERE Case__c = :caseId
            AND CON_Classified__c = false
        ];

        return countRecords > 0;
    }


    public static void publishCommsEvent(String caseId) {

        Conversion_Comms__e eventMsg = new Conversion_Comms__e(
            Case__c = caseId,
            Case_Status__c = 'Closed',
            EventName__c = 'Conversion Comms',
            Type__c = 'Client To Switch'

        );

        Database.SaveResult sr = EventBus.publish(eventMsg);

        if (!sr.isSuccess()) {
            throw new AuraHandledException('Error publishing event');
        }
        else{
            updateCaseStatus(caseId, 'Closed');
        }
    }

    @AuraEnabled
    public static Boolean updateDebitOrders(List<Debit_Order__c> lstDOs, String causeCode) {
        System.debug('##causeCode:' + causeCode);
        System.debug('##causeCode length:' + causeCode.length());

        if (lstDOs == null || lstDOs.isEmpty() || String.isBlank(causeCode)) {
            return false;
        }

        List<Debit_Order__c> lstDOsToUpdate = new List<Debit_Order__c>();

        for (Debit_Order__c debitOrder : lstDOs) {
            if (debitOrder.Id != null) {
                lstDOsToUpdate.add(new Debit_Order__c(
                    Id = debitOrder.Id,
                    Withdrawn_Cause_Code__c = causeCode,
                    Submitted_Cause_Code__c = null
                ));
            }
        }

        if (lstDOsToUpdate.isEmpty()) {
            return false;
        }

        try {
            update lstDOsToUpdate;
            return true;
        } catch (Exception e) {
            System.debug('##Error updating debit orders: ' + e.getMessage());
            return false;
        }
    }
}