/*******************************************************************
* @Class Name        :  IC_TestDataFactory
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 31-Oct-2023
* @Version           :  1.0
*
*******************************************************************/

@IsTest
public class IC_TestDataFactory {

    /**
* Creates a single Case record with predefined values for testing purposes.
* The Case is of type 'Insurance Claims' and has specific field values set.
*
* @return Case The inserted Case record
*/
    public static Case createSingleCase() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();

        Case c = new Case(
                Subject = 'Test Case - ICS-225',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                IC_Type__c = 'Unemployment/ITEI',
                Sub_Type__c = 'Retrenchment',
                Sub_Type_Reason__c = 'New Technology',
                RecordTypeId = insuranceClaimsRTId,
                IC_Duration_of_Condition__c = 5,
                Product_Type__c = 'Credit Life'
        );
        insert c;
        return c;
    }

    public static Case createSingleCase_CL_Disability() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();

        Case c = new Case(
                Subject = 'Test Case - ICS-840',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                IC_Type__c = 'Disability',
                Sub_Type__c = 'Temporary',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Credit Life',
                IC_Duration_of_Condition__c = 3
        );
        insert c;
        return c;
    }

    public static Case createSingleCase_CL_Disability_NoDocs() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();

        Case c = new Case(
                Subject = 'Test Case - ICS-840 - No Docs',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                IC_Type__c = 'Disability',
                Sub_Type__c = 'Temporary',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Credit Life'
        );
        insert c;
        return c;
    }

    public static Case createSingleCase_Funeral() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();

        Case c = new Case(
                Subject = 'Test Case - ICS-485',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                IC_Type__c = 'Death',
                Sub_Type__c = 'Natural',
                Sub_Type_Reason__c = 'Other life',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Funeral'
        );
        insert c;
        return c;
    }

    public static Case createSingleCase_Funeral_Claimant() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();

        Case c = new Case(
                Subject = 'Test Case - ICS-1368',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                IC_Type__c = 'Death',
                Sub_Type__c = 'Natural',
                Sub_Type_Reason__c = 'Other life',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Funeral',
                ID_Number__c = '0000000000000'
        );
        insert c;
        return c;
    }

    //START ICS-630
    public static List<Case> createStillbornCases() {
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();

        Case case1 = new Case(
                Subject = 'Test Case - ICS-630 V1',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                IC_Type__c = 'Death',
                Sub_Type__c = 'Stillborn',
                Sub_Type_Reason__c = 'Other life',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Funeral',
                IC_No_ID_number_available__c = true
        );

        Case case2 = new Case(
                Subject = 'Test Case - ICS-630 V2',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                IC_Type__c = 'Death',
                Sub_Type__c = 'Stillborn',
                Sub_Type_Reason__c = 'Other life',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Funeral',
                IC_No_ID_number_available__c = false
        );

        List<Case> cases = new List<Case>{
                case1, case2
        };
        insert cases;

        return cases;
    }

    //END ICS-630

    /** ICS-391 **/
    public static Case createSingleChildCase() {
        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();

        Case c = new Case(
                Subject = 'Test Case - ICS-391',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                ID_Number__c = '12345',
                IC_Policy_Number_child__c = 'PolNumber12345',
                IC_Type__c = 'Unemployment/ITEI',
                Sub_Type__c = 'Retrenchment',
                Sub_Type_Reason__c = 'New Technology',
                RecordTypeId = insuranceClaimsAssessmentRTId,
                Product_Type__c = 'Credit Life',
                AccountId = createSingleAccount().Id
        );
        insert c;
        return c;
    }

    public static Case createSingleChildCaseWithoutAccount() {
        Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();

        Case c = new Case(
                Subject = 'Test Case - ICS-391',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                ID_Number__c = '12345',
                IC_Policy_Number_child__c = 'PolNumber12345',
                IC_Type__c = 'Unemployment/ITEI',
                Sub_Type__c = 'Retrenchment',
                Sub_Type_Reason__c = 'New Technology',
                RecordTypeId = insuranceClaimsAssessmentRTId,
                Product_Type__c = 'Credit Life'
        );
        insert c;
        return c;
    }

    public static Case createSingleAstuteCase() {
        //Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        Case c = new Case(
                Subject = 'Test Case - ICS-642',
                Status = 'Administration',
                Sub_Status__c = 'Allocated',
                IC_Type__c = 'Death',
                Sub_Type__c = 'Natural',
                Sub_Type_Reason__c = 'Main life',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Funeral',
                IC_Deceased_Date_of_Death__c = Date.today(),
                IC_Deceased_First_Name__c = 'TestName',
                IC_Deceased_Surname__c = 'TestSurname',
                IC_Deceased_Date_of_Birth__c = Date.today().addYears(-60),
                IC_BI_Number__c = '123456',
                IC_Deceased_ID_Number__c = true,
                IC_Deceased_Identity_Number__c = '1231231231233'
        );
        insert c;
        return c;
    }

    public static Account createSingleAccount() {

        Id personAccountRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        Account a = new Account(
                FirstName = 'Test Case - ICS-391',
                LastName = 'Test Case - ICS-391',
                CIF_Number__c = '12345',
                PersonEmail = 'test@email.com',
                RecordTypeId = personAccountRTId
        );
        insert a;
        return a;
    }

    /**
* Creates a single DocumentChecklistItem record related to the provided Case.
* The DocumentChecklistItem is created with the specified DocumentType and DocumentName.
*
* @param testCase The parent Case record for the DocumentChecklistItem
* @param DocTypes The DocumentType records to associate with the DocumentChecklistItem
* @param DocumentName The name of the DocumentChecklistItem
*
* @return List<DocumentChecklistItem> The inserted DocumentChecklistItem record in a list
*/
    public static List<DocumentChecklistItem> createDocumentChecklistItem(Case testCase, List<DocumentType> DocTypes, String DocumentName) {
        DocumentChecklistItem dci1 = new DocumentChecklistItem(ParentRecordId = testCase.Id, DocumentTypeId = DocTypes[0].Id, Name = DocumentName, Status = 'Verified');
        insert new List<DocumentChecklistItem>{
                dci1
        };

        return new List<DocumentChecklistItem>{
                dci1
        };
    }


    public static List<DocumentChecklistItem> createDocumentChecklistItems(Map<Case, List<DocumentType>> caseDocsMap) {//ICS-840
        List<DocumentChecklistItem> checklistItems = new List<DocumentChecklistItem>();
        for (Case testCase : caseDocsMap.keySet()) {
            List<DocumentType> docTypes = caseDocsMap.get(testCase);
            for (DocumentType docType : docTypes) {
                checklistItems.add(new DocumentChecklistItem(ParentRecordId = testCase.Id, DocumentTypeId = docType.Id, IC_ExternalContentDocumentId__c = '12345689', Name = docType.MasterLabel, Status = 'Verified'));
            }
        }
        insert checklistItems;
        return checklistItems;
    }
}