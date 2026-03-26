/**
 * @description       : Apex Controller For Email Templates[Manual]
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 01-28-2026
 * @last modified by  : Samiirah Aujub
**/
public with sharing class Conversions_EmailTemplatesController {
    public Id caseRecordId { get; set; }
    public String emailThreadId { get; private set; }


    public Case getCaseRecord() {
        if (caseRecordId != null) {
            Case caseRecord = [
                SELECT Id, 
                       Account.Name, 
                       Account.PersonMobilePhone,
                       ID_Number__c, 
                       CreatedDate, 
                       Owner.Name, 
                       Branch_Code__c
                FROM Case
                WHERE Id = :caseRecordId
                LIMIT 1
            ];

            emailThreadId = EmailMessages.getFormattedThreadingToken(caseRecordId);
            return caseRecord;
        }
        return null;
    }

    public Conversion__c getConversion() {
        if (caseRecordId != null) {
            List<Conversion__c> convs = [
                SELECT Preferred_Contact_Time__c
                FROM Conversion__c
                WHERE Case__c = :caseRecordId
                LIMIT 1
            ];
            return convs.isEmpty() ? null : convs[0];
        }
        return null;
    }

    private List<Debit_Order__c> getDebitOrdersWithIssues() {
        if (caseRecordId == null) return new List<Debit_Order__c>();

        List<Debit_Order__c> lstDebitOrders = new List<Debit_Order__c>();
        lstDebitOrders = [SELECT Id,
                                 Name,
                                 DO_Issue__c,
                                 Other_Debit_Order_Issue__c,
                                 Debit_Order_Initiator__r.Name
                           FROM Debit_Order__c
                           WHERE Case__c = :caseRecordId
                           AND DO_Issue__c != null
                           ORDER BY CreatedDate ASC
                        ];

        return lstDebitOrders;
    }

    public Boolean getHasIssues() {
        return !getDebitOrdersWithIssues().isEmpty();
    }

    public List<String> getDebitOrderIssueLines() {
        List<String> lines = new List<String>();

        for (Debit_Order__c debitOrder : getDebitOrdersWithIssues()) {
            String doiName = (debitOrder.Debit_Order_Initiator__r != null && !String.isBlank(debitOrder.Debit_Order_Initiator__r.Name))
                            ? debitOrder.Debit_Order_Initiator__r.Name
                            : 'N/A';

            String refNo = String.isBlank(debitOrder.Name) ? 'N/A' : debitOrder.Name;


            String issueSummary = '';
            if (!String.isBlank(debitOrder.DO_Issue__c)) {
                issueSummary = debitOrder.DO_Issue__c.replace(';', ', ');
            }

            if (!String.isBlank(debitOrder.DO_Issue__c)
                && debitOrder.DO_Issue__c.contains('Other')
                && !String.isBlank(debitOrder.Other_Debit_Order_Issue__c)) {

                issueSummary += ' - ' + debitOrder.Other_Debit_Order_Issue__c;
            }

            if (String.isBlank(issueSummary)) {
                issueSummary = 'N/A';
            }
            lines.add(doiName + ' , Ref: ' + refNo + ' , Issue: ' + issueSummary);
        }
        return lines;
    }
}