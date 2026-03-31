/**
 * @description       : 
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 09-09-2025
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class Capitec_ConversionVFController {

    public String ClientName { get; private set; }
    public String IdNumber { get; private set; }
    public String CellNumber { get; private set; }

    public String OldBankName { get; private set; }
    public String OldBranchCode { get; private set; }
    public String OldAccountNumber { get; private set; }

    public String NewBankName { get; private set; }
    public String NewBranchCode { get; private set; }
    public String NewAccountType { get; private set; }
    public String NewAccountNumber { get; private set; }

    public String InitiatorName { get; private set; }
    public String ReferenceNumber { get; private set; }
    public String Frequency { get; private set; }
    public Decimal Amount { get; private set; }

    public Capitec_ConversionVFController(ApexPages.StandardController std) {
        Id caseId = (Id) std.getId();

        Conversion__c conversionRecord = [SELECT Id,
                                                  Old_Account_Number__c,
                                                  Old_Bank_Name__c,
                                                  Old_Branch_Code__c
                                            FROM Conversion__c
                                            WHERE Case__c =:caseId
                                            LIMIT 1
                                         ];

        Debit_Order__c doRec = [ SELECT Id,
                                        Name,
                                        Amount__c,
                                        To_Capitec_Account__c,
                                        Case__r.Account.Name,
                                        Case__r.Account.Identity_Number__c,
                                        Case__r.Account.PersonMobilePhone,
                                        Debit_Order_Initiator__r.Name
                                    FROM Debit_Order__c
                                    WHERE Case__c = :caseId
                                    LIMIT 1
                                ];

        //ClientName       = doRec.Case__r.Account.Name;
        //IdNumber         = doRec.Account.Identity_Number__c;
        //CellNumber       = doRec.Account.PersonMobilePhone;

        OldBankName      = conversionRecord.Old_Bank_Name__c;
        OldBranchCode    = conversionRecord.Old_Branch_Code__c;
        OldAccountNumber = conversionRecord.Old_Account_Number__c;

        NewAccountNumber = doRec.To_Capitec_Account__c;

        InitiatorName    = doRec.Debit_Order_Initiator__r.Name;
        ReferenceNumber  = doRec.Name;
        Amount           = doRec.Amount__c;
    }
}