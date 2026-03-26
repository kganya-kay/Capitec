/*******************************************************************
* @Class Name        :  IC_MinimumDocTypeChecker
* @Test Class        :  IC_MinimumDocTypeChecker_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 28-Nov-2023, Jira Tickets: ICS-225, ICS-399, ICS-840
* @Version           :  1.0
*
*******************************************************************/

public class IC_AllDocCompleteDataChecker {
    
    public class FlowInputs {
        @InvocableVariable(label='Case Id' required=true)
        public String caseId;
        
        @InvocableVariable(label='Product Type' required=true)
        public String productType;
    }
    
    @InvocableMethod(label='Check If Documents Are Completed' description='Checks if the Case documents have completed Sanlam Code and Name')
    public static List<String> doesDocumentTypeMatch(List<FlowInputs> inputs) {
        
        Boolean documentsCompleted = true;
        
        for(FlowInputs input : inputs) {
            List<DocumentChecklistItem> caseDocuments = [SELECT DocumentTypeId, IC_Sanlam_Document_Name__c, IC_Sanlam_Document_Code__c, IC_Sent_to_Sanlam__c, Status FROM DocumentChecklistItem WHERE ParentRecordId = :input.caseId AND Status = 'Verified'];
            
            Set<Id> documentTypeIds = new Set<Id>();
            if(input.productType.equals('Funeral')) {
            for(DocumentChecklistItem item : caseDocuments) {
                    if(
                        item.Status == 'Verified' &&
                        item.IC_Sent_to_Sanlam__c == false &&
                        !(String.isBlank(item.IC_Sanlam_Document_Name__c) || String.isEmpty(item.IC_Sanlam_Document_Name__c)) &&
                        !(String.isBlank(item.IC_Sanlam_Document_Code__c) || String.isEmpty(item.IC_Sanlam_Document_Code__c))
                    )  {
                        continue;   
                    }
                    else {
                        documentsCompleted = false;
                        break;
                    }
                }
            }
            
        }

        System.debug('documentCompleted: '+documentsCompleted);
            return new List<String>{documentsCompleted ? 'Pass' : 'Fail'};
        }
}