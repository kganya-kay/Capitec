/**
 * @description       : 
 * @author            : Samiirah Aujub
 * @group             : 
 * @last modified on  : 03-23-2026
 * @last modified by  : Samiirah Aujub
**/
global with sharing class Conversions_DebitOrderAsyncProcessor
    implements Queueable, Database.AllowsCallouts {

    private Id caseId;
    private Conversions_DebitOrderSwitchCaseCreation.RequestWrapper input;

    global Conversions_DebitOrderAsyncProcessor(
        Id caseId,
        Conversions_DebitOrderSwitchCaseCreation.RequestWrapper input
    ) {
        this.caseId = caseId;
        this.input  = input;
    }

    global void execute(QueueableContext context) {

        Conversion__c conv = new Conversion__c(
            Case__c                     = caseId,
            Preferred_Contact_Time__c   = input.preferredTime,
            Preferred_Language__c       = input.preferredLanguage,
            Preferred_Contact_Method__c = input.preferredContactMethod,
            Additional_Comments__c      = input.comments,
            Old_Account_Number__c       = input.oldAccount,
            Old_Bank_Name__c            = input.oldBank,
            Old_Branch_Code__c          = input.oldBranchCode,
            Manual_Case__c              = input.manualCase == true //COCONV-2417

        );
        insert conv;

        if (input.debitOrders != null && !input.debitOrders.isEmpty()) {
            List<Debit_Order__c> dos = new List<Debit_Order__c>();

            for (Conversions_DebitOrderSwitchCaseCreation.DebitOrderWrapper d : input.debitOrders) {
                dos.add(new Debit_Order__c(
                    Case__c                                = caseId,
                    From_Account__c                        = d.fromAccount,
                    To_Capitec_Account__c                  = d.toCapitecAccount,
                    Amount__c                              = d.amount,
                    Debit_OrderDate__c                     = d.debitOrderDate,
                    Name                                   = d.name,
                    External_Debit_Order_Initiator_ID__c   = d.externalInitiatorId,
                    External_Debit_Order_Initiator_Name__c = d.externalInitiatorName,
                    Category__c                            = d.category,
                    Submission_Date__c                     = d.submissionDate
                ));
            }

            if (!dos.isEmpty()) {
                insert dos;
            }
        }

        if (input.documents != null && !input.documents.isEmpty()) {
            List<DocumentChecklistItem> docItems = new List<DocumentChecklistItem>();

            for (Conversions_DebitOrderSwitchCaseCreation.DocumentChecklistItemWrapper doc : input.documents) {
                docItems.add(new DocumentChecklistItem(
                    Name                 = doc.name,
                    ParentRecordId       = caseId,
                    Document_Link__c     = doc.documentLink,
                    IC_ExternalContentDocumentId__c  = doc.documentumId,
                    CON_Document_Type__c = doc.documentType
                ));
            }

            if (!docItems.isEmpty()) {
                insert docItems;
            }
        }
    }
}