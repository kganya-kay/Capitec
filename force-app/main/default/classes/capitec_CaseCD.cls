/**
* Created by UrvashiRagobur on 2023/09/21.
* Updated by Cornelia Smit on 2025/01/30 - CEDT-3523: update validations for client care non-client
*/
public class capitec_CaseCD {
    private static final String CASH_DISPUTES_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Cash_Disputes').getRecordTypeId();
    
    public static void checkCashDisputeCreationRequiredFields(List<Case> cashDisputes) {
        for(Case c : cashDisputes) {
            if(c.recordTypeId == CASH_DISPUTES_RECORD_TYPE_ID && c.CD_IncidentID__c == null) {
                if(c.Dispute_Type__c == null) {
                    c.Dispute_Type__c.addError('Please complete this field');
                }
                if(c.Dispute_Category__c == null) {
                    c.Dispute_Category__c.addError('Please complete this field');
                }
                if(c.Dispute_Reported_by_3rdparty__c == null && c.Cash_Dispute_Owner_Team__c != 'Interbank') {
                    c.Dispute_Reported_by_3rdparty__c.addError('Please complete this field');
                }
                if(c.AccountId == null && c.Cash_Dispute_Owner_Team__c != 'Interbank' && c.Cash_Dispute_Owner_Team__c != 'Business Bank Complaints' && c.Cash_Dispute_Owner_Team__c != 'Business Bank Customer Resolution' && c.Origin != 'Client Care') {
                    c.AccountId.addError('Please complete this field');
                }
                if(c.Cash_Dispute_Owner_Team__c == 'Business Bank Complaints' || c.Cash_Dispute_Owner_Team__c == 'Business Bank Customer Resolution') {
                    if(c.Business_Bank_Account_Number__c == null) {
                        c.Business_Bank_Account_Number__c.addError('Please complete this field'); 
                    }
                    if(c.Business_Bank_Client_Name__c == null) {
                        c.Business_Bank_Client_Name__c.addError('Please complete this field'); 
                    }
                    if(c.Business_Bank_Contact_Number__c == null) {
                        c.Business_Bank_Contact_Number__c.addError('Please complete this field'); 
                    }
                    if(c.Business_Bank_ID_Number__c == null) {
                        c.Business_Bank_ID_Number__c.addError('Please complete this field'); 
                    }
                }
                if(c.Cash_Dispute_Owner_Team__c == 'Interbank') {
                    if(c.Interbank_Dispute_External_Ref_Number__c == null) {
                        c.Interbank_Dispute_External_Ref_Number__c.addError('This Interbank Dispute Capture field is required');
                    }
                    if(c.Interbank_Dispute_ATM_ID__c == null) {
                        c.Interbank_Dispute_ATM_ID__c.addError('This Interbank Dispute Capture field is required');
                    }
                    if(c.Interbank_Dispute_Transaction_Amount__c  == null) {
                        c.Interbank_Dispute_Transaction_Amount__c.addError('This Interbank Dispute Capture field is required');
                    }
                    if(c.Interbank_Transaction_Timestamp__c  == null) {
                        c.Interbank_Transaction_Timestamp__c.addError('This Interbank Dispute Capture field is required');
                    }
                    if(c.Interbank_Dispute_RRN_Number__c  == null) {
                        c.Interbank_Dispute_RRN_Number__c.addError('This Interbank Dispute Capture field is required');
                    }
                   }
                else {
                    if(c.Date_of_Transaction__c  == null) {
                        c.Date_of_Transaction__c.addError('This General Dispute Capture field is required');
                    }
                    if(c.Time_of_Transaction__c  == null) {
                        c.Time_of_Transaction__c.addError('This General Dispute Capture field is required');
                    }
                    if(c.Deposited_Amount__c == null && c.Dispute_Type__c != null && c.Dispute_Type__c != 'Cash Withdrawal' && c.Dispute_Type__c != 'Send Cash') {
                        c.Deposited_Amount__c.addError('This General Dispute Capture field is required');
                    }
                    if(c.CD_Return_Amount__c == null && c.Dispute_Type__c != null && c.Dispute_Type__c != 'Cash Withdrawal' && c.Dispute_Type__c != 'Send Cash') {
                        c.CD_Return_Amount__c.addError('This General Dispute Capture field is required');
                    }
                    if(c.Requested_Amount__c == null && c.Dispute_Type__c != null && c.Dispute_Type__c != 'Cash Deposit') {
                        c.Requested_Amount__c.addError('This General Dispute Capture field is required');
                    }
                    if(c.Received_Amount__c == null && c.Dispute_Type__c != null && c.Dispute_Type__c != 'Cash Deposit') {
                        c.Received_Amount__c.addError('This General Dispute Capture field is required');
                    }
                    if(c.Disputed_Amount__c == null) {
                        c.Disputed_Amount__c.addError('This General Dispute Capture field is required');
                    }
                    if(c.Voucher_Number__c == null && c.Dispute_Type__c != null && c.Dispute_Type__c != 'Cash Withdrawal' && c.Dispute_Type__c != 'Cash Deposit') {
                        c.Voucher_Number__c.addError('This General Dispute Capture field is required');
                    }
                    if(c.CD_IBank_Merchant_ID__c  == null && c.Dispute_Type__c != null && c.Dispute_Type__c == 'Send Cash') {
                        c.CD_IBank_Merchant_ID__c.addError('This General Dispute Capture field is required');
                    } 
                    if(c.CD_Mobile_Number_of_Sender__c == null && c.Dispute_Type__c != null && c.Dispute_Type__c == 'Send Cash') {
                        c.CD_Mobile_Number_of_Sender__c.addError('This General Dispute Capture field is required');
                    }
                            
                    if(c.Dispute_Reported_by_3rdparty__c == 'Yes' && c.Origin != 'Client Care') {
                        if(c.Depositor_Name__c == null) {
                            c.Depositor_Name__c.addError('3rd Party Depositor Detail is required');
                        }
                        if(c.Depositor_Surname__c == null) {
                            c.Depositor_Surname__c.addError('3rd Party Depositor Detail is required');
                        }
                        if(c.Depositor_ID_Number__c == null) {
                            c.Depositor_ID_Number__c.addError('3rd Party Depositor Detail is required');
                        }
                        if(c.Depositor_Contact_Number__c == null) {
                            c.Depositor_Contact_Number__c.addError('3rd Party Depositor Detail is required');
                        }
                	}
                
                    if(c.Nothing_Received__c && 
                       (c.Denomination_Breakdown_10__c != null || 
                        c.Denomination_Breakdown_20__c != null || 
                        c.Denomination_Breakdown_50__c != null || 
                        c.Denomination_Breakdown_100__c != null || 
                        c.Denomination_Breakdown_200__c != null)) {
                            c.Nothing_Received__c.addError('Please uncheck this checkbox if notes have been received');
                        }else if(!c.Nothing_Received__c && 
                                 !c.CD_Cannot_Confirm_Deposit_Counts__c && 
                                 c.Denomination_Breakdown_10__c == null && 
                                 c.Denomination_Breakdown_20__c == null && 
                                 c.Denomination_Breakdown_50__c == null && 
                                 c.Denomination_Breakdown_100__c == null && 
                                 c.Denomination_Breakdown_200__c == null) {
                                     c.Nothing_Received__c.addError('Please indicate if no notes have been received or if deposit counts cannot be confirmed');
                                     c.CD_Cannot_Confirm_Deposit_Counts__c.addError('Please indicate if no notes have been received or if deposit counts cannot be confirmed');
                                  }
                }                
            }
        }
    }

    public static void setCashDisputeStatusNewOnCreation(List<Case> cashDisputes) {
        List<Entitlement> entitlement = [SELECT Id, Name FROM Entitlement WHERE Name = 'Cash Dispute Entitlement'];
        for(Case c : cashDisputes) {
            if(c.recordTypeId == CASH_DISPUTES_RECORD_TYPE_ID) {
                c.Open_Time__c = System.now().time();
                c.status = 'New';
                c.Sub_Status__c = 'Not Yet Started';
                c.EntitlementId = !entitlement.isEmpty() ? entitlement.get(0).Id : null;
            }
        }
    }
    
    public static void makePersonOfInterestRequired(Map<Id, Case> cashDisputesOldMap, List<Case> cashDisputesNewList) {
        Set<Id> poiCaseIds = new Set<Id>();
        for(Persons_of_Interest__c poi : [SELECT Id, Name, Case__c FROM Persons_of_Interest__c WHERE Case__c IN :cashDisputesOldMap.KeySet() AND Main_Person_of_Interest__c = True]) {
            poiCaseIds.add(poi.Case__c);
        }
        
        for(Case cd : cashDisputesNewList) {
            if(cd.recordTypeId == CASH_DISPUTES_RECORD_TYPE_ID &&
               cd.Cash_Investigation_Person_of_Interest__c != cashDisputesOldMap.get(cd.Id).Cash_Investigation_Person_of_Interest__c &&
               cd.Cash_Investigation_Person_of_Interest__c == 'Yes'&& 
               !poiCaseIds.contains(cd.Id)) {
                   cd.Cash_Investigation_Person_of_Interest__c.addError('Provide the details for a main person of interest.');
               }
        }
    }
    
    public static void checkIfQATeamBeforeClosing(Map<Id, Case> cashDisputesOldMap, List<Case> cashDisputesNewList) {
        List<Id> QAUserIds = new List<Id>();
        for(GroupMember gm : [SELECT Id, UserOrGroupId, GroupId, Group.DeveloperName FROM GroupMember WHERE Group.DeveloperName = 'CD_Quality_Assurance']) {
            QAUserIds.add(gm.UserOrGroupId);
        }
        
        for(Case c : cashDisputesNewList) {
            if(c.recordTypeId == CASH_DISPUTES_RECORD_TYPE_ID && c.Status != cashDisputesOldMap.get(c.Id).Status && c.Status == 'Closed' && !QAUserIds.contains(UserInfo.getUserId())) {
                c.addError('Only members of the Quality Assurance can close a cash dispute.');
            }
        }        
    }
    
}