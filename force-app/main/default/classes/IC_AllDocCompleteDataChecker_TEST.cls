@IsTest
public class IC_AllDocCompleteDataChecker_TEST {
    
    @testSetup
    static void setup() {
        IC_TestDataFactory.createSingleCase();

        Case testCase = [SELECT Id FROM Case LIMIT 1];
        testCase.Status = 'Verified';
        update testCase;
    }

    @IsTest
    static void testDoesDocumentTypeMatch() {
        // Arrange
        IC_AllDocCompleteDataChecker.FlowInputs input = new IC_AllDocCompleteDataChecker.FlowInputs();
        Case testCase = [SELECT CaseNumber, IC_Policy_Number_child__c, CIF_Number__c, IC_Claim_Number_of_Payments__c, IC_Insurer_Underwriter_at_Event_Date__c, IC_Claim_Lump_Sum_Amount__c, IC_Claim_Annuity_Amount__c, IC_Remaining_Term_at_Event_Date__c, IC_Remaining_Term_at_Last_Working_Date__c, IC_Payment_Frequency__c, IC_Number_of_Catch_Up_Payments__c, IC_Group_of_Insurance_Contracts__c FROM Case LIMIT 1];
        input.productType = 'Funeral';
        List<IC_AllDocCompleteDataChecker.FlowInputs> inputs = new List<IC_AllDocCompleteDataChecker.FlowInputs>{input};
        
        
        // Insert DocumentChecklistItems that will be queried
        List<DocumentChecklistItem> checklistItems = new List<DocumentChecklistItem>{
            new DocumentChecklistItem(
                Name = 'test1',
                ParentRecordId = testCase.Id,
                Status = 'Verified',
                IC_Sanlam_Document_Name__c = 'TestName1',
                IC_Sanlam_Document_Code__c = 'TestCode1',
                IC_Sent_to_Sanlam__c = false
            ),
            new DocumentChecklistItem(
                Name = 'test2',
                ParentRecordId = testCase.Id,
                Status = 'Verified',
                IC_Sanlam_Document_Name__c = 'TestName2',
                IC_Sanlam_Document_Code__c = 'TestCode2',
                IC_Sent_to_Sanlam__c = false
            )
        };
        insert checklistItems;

        // Act
        Test.startTest();
        List<String> result = IC_AllDocCompleteDataChecker.doesDocumentTypeMatch(inputs);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, result.size(), 'There should be one result');
        System.assertEquals('Pass', result[0], 'The result should be Pass because all documents are completed');
    }
}