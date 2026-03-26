/*******************************************************************
* @Class Name        :  IC_MinimumDocTypeChecker_TEST
* @Author            :  Dhriven
* @Last Modified By  : Samiirah.A@bsky.co.za
* @Version           :  1.0
*
*******************************************************************/

@IsTest
public class IC_MinimumDocTypeChecker_TEST {
    @testSetup
    static void setup() {  
 
        Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
        
        Case retrenchmentCase = new Case(
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
        
        Case funeralCase = new Case(
            Subject = 'Test Case - ICS-485',
            Status = 'Administration',
            Sub_Status__c = 'Allocated',
            IC_Type__c = 'Death',
            Sub_Type__c = 'Natural',
            Sub_Type_Reason__c = 'Other life',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Funeral'
        );        

        Case creditLifeDisabilityCase = new Case(
            Subject = 'Test Case - ICS-840',
            Status = 'Administration',
            Sub_Status__c = 'Allocated',
            IC_Type__c = 'Disability',
            Sub_Type__c = 'Temporary',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Credit Life',
            IC_Duration_of_Condition__c = 3
        );

        Case creditLifeDisabilityCaseNoDocs = new Case(
            Subject = 'Test Case - ICS-840 - No Docs',
            Status = 'Administration',
            Sub_Status__c = 'Allocated',
            IC_Type__c = 'Disability',
            Sub_Type__c = 'Temporary',
            RecordTypeId = insuranceClaimsRTId,
            Product_Type__c = 'Credit Life'
        );        
        
        Case stillborn1 = new Case(
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
        
        Case stillborn2 = new Case(
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
        
        List<Case> cases = new List<Case>{retrenchmentCase, funeralCase, creditLifeDisabilityCase, creditLifeDisabilityCaseNoDocs, stillborn1, stillborn2};
            insert cases;        
        
        
        
        // Query for existing DocumentType records with a single SOQL query
        List<DocumentType> allDocTypes = [
            SELECT Id, MasterLabel 
            FROM DocumentType 
            WHERE MasterLabel IN ('Retrenchment Letter', 'Death certificate', 'Employer Declaration', 'Confidential Medical Report', 'Unabridged birth certificate',
                                 'Claimant\'s ID', 'BI-1663 / DHA-1663', 'Gestation Period Note', 'Antenatal clinic card', 'Medical certificates')
        ];
        
        // Initialize maps to hold specific DocumentTypes
        Map<String, List<DocumentType>> docTypeMap = new Map<String, List<DocumentType>>();
        for (DocumentType dt : allDocTypes) {
            if (!docTypeMap.containsKey(dt.MasterLabel)) {
                docTypeMap.put(dt.MasterLabel, new List<DocumentType>());
            }
            docTypeMap.get(dt.MasterLabel).add(dt);
        }
        
        // Ensure that each document type list is initialized even if no corresponding records are found
        List<DocumentType> retrenchmentLetterDocType = docTypeMap.get('Retrenchment Letter') != null ? docTypeMap.get('Retrenchment Letter') : new List<DocumentType>();
        List<DocumentType> deathCertDocType = docTypeMap.get('Death certificate') != null ? docTypeMap.get('Death certificate') : new List<DocumentType>();
        List<DocumentType> employerDecDocType = docTypeMap.get('Employer Declaration') != null ? docTypeMap.get('Employer Declaration') : new List<DocumentType>();
        List<DocumentType> confidentialDocType = docTypeMap.get('Confidential Medical Report') != null ? docTypeMap.get('Confidential Medical Report') : new List<DocumentType>();
        List<DocumentType> claimantsIdDocType = docTypeMap.get('Claimant\'s ID') != null ? docTypeMap.get('Claimant\'s ID') : new List<DocumentType>();//ICS-630
        List<DocumentType> gpnDocType = docTypeMap.get('Gestation Period Note') != null ? docTypeMap.get('Gestation Period Note') : new List<DocumentType>();
        List<DocumentType> accDocType = docTypeMap.get('Antenatal clinic card') != null ? docTypeMap.get('Antenatal clinic card') : new List<DocumentType>();
        List<DocumentType> medCertDocType = docTypeMap.get('Medical certificates') != null ? docTypeMap.get('Medical certificates') : new List<DocumentType>();
        List<DocumentType> unabridgedDocType = docTypeMap.get('Unabridged birth certificate') != null ? docTypeMap.get('Unabridged birth certificate') : new List<DocumentType>();
        List<DocumentType> biDocType = docTypeMap.get('BI-1663 / DHA-1663') != null ? docTypeMap.get('BI-1663 / DHA-1663') : new List<DocumentType>();
        
        // Prepare the map for DocumentChecklistItems creation
        Map<Case, List<DocumentType>> caseDocsMap = new Map<Case, List<DocumentType>>();
        caseDocsMap.put(retrenchmentCase, retrenchmentLetterDocType);
        caseDocsMap.put(funeralCase, deathCertDocType);
        caseDocsMap.put(creditLifeDisabilityCase, new List<DocumentType>{employerDecDocType[0], confidentialDocType[0]});//ICS-840
        caseDocsMap.put(stillborn1, new List<DocumentType>{deathCertDocType[0], claimantsIdDocType[0], gpnDocType[0],accDocType[0], biDocType[0] });//ICS-630
        caseDocsMap.put(stillborn2, new List<DocumentType>{deathCertDocType[0], claimantsIdDocType[0], biDocType[0], unabridgedDocType[0]});//ICS-630
        
        // Using IC_TestDataFactory to create DocumentChecklistItem records
        IC_TestDataFactory.createDocumentChecklistItems(caseDocsMap);
        
        // Note: You cannot insert Custom Metadata through DML in test methods, 
        // so you would ensure those records exist in your org for IC_Minimum_Doc_Checklist__mdt.
    }
    
    @isTest
    static void testDoesDocumentTypeMatch() {
        // Fetch the created case for reference
        Case retrenchmentCase = [SELECT Id, IC_Type__c, Sub_Type__c, Subject FROM Case WHERE Subject = 'Test Case - ICS-225' LIMIT 1];
        
        IC_MinimumDocTypeChecker.FlowInputs inputs = new IC_MinimumDocTypeChecker.FlowInputs();
        inputs.caseId = retrenchmentCase.Id;
        inputs.caseType = retrenchmentCase.IC_Type__c;
        inputs.subType = retrenchmentCase.Sub_Type__c;
        inputs.productType = 'Credit Life';
        inputs.caseOrigin = 'Email';
        
        Test.startTest();
        List<String> result = IC_MinimumDocTypeChecker.doesDocumentTypeMatch(new List<IC_MinimumDocTypeChecker.FlowInputs>{inputs});
        Test.stopTest();
        
        // Assert based on the expected output
        System.assert(result != null && !result.isEmpty(), 'Result should not be empty.');
        System.assertEquals('Pass', result[0], 'Expecting a Pass because DocumentType matches with Metadata.');
    }
    
    @isTest
    static void testDoesDocumentTypeMatch_CL_Disability() {
        // Fetch the created case for reference
        Case creditLifeDisabilityCase = [SELECT Id, IC_Type__c, Sub_Type__c, Subject FROM Case WHERE Subject = 'Test Case - ICS-840' LIMIT 1];
        
        IC_MinimumDocTypeChecker.FlowInputs inputs = new IC_MinimumDocTypeChecker.FlowInputs();
        inputs.caseId = creditLifeDisabilityCase.Id;
        inputs.caseType = creditLifeDisabilityCase.IC_Type__c;
        inputs.subType = creditLifeDisabilityCase.Sub_Type__c;
        inputs.productType = 'Credit Life';
        inputs.caseOrigin = 'Email';
        
        Test.startTest();
        List<String> result = IC_MinimumDocTypeChecker.doesDocumentTypeMatch(new List<IC_MinimumDocTypeChecker.FlowInputs>{inputs});
        Test.stopTest();
        
        // Assert based on the expected output
        System.assert(result != null && !result.isEmpty(), 'Result should not be empty.');
        System.assertEquals('Pass', result[0], 'Expecting a Pass because DocumentType matches with Metadata.');
    }
    
    @isTest
    static void testDoesDocumentTypeMatch_CL_Disability_Fail() {
        // Fetch the created case for reference
        Case creditLifeDisabilityCaseNoDocs = [SELECT Id, IC_Type__c, Sub_Type__c, Subject FROM Case WHERE Subject = 'Test Case - ICS-840 - No Docs' LIMIT 1];
        
        IC_MinimumDocTypeChecker.FlowInputs inputs = new IC_MinimumDocTypeChecker.FlowInputs();
        inputs.caseId = creditLifeDisabilityCaseNoDocs.Id;
        inputs.caseType = creditLifeDisabilityCaseNoDocs.IC_Type__c;
        inputs.subType = creditLifeDisabilityCaseNoDocs.Sub_Type__c;
        inputs.productType = 'Credit Life';
        inputs.caseOrigin = 'Email';
        
        Test.startTest();
        List<String> result = IC_MinimumDocTypeChecker.doesDocumentTypeMatch(new List<IC_MinimumDocTypeChecker.FlowInputs>{inputs});
        Test.stopTest();
        
        // Assert based on the expected output
        System.assert(result != null && !result.isEmpty(), 'Result should not be empty.');
        System.assertEquals('Fail', result[0], 'Expecting a Fail as other docs are missing');
    }
    
    @isTest
    static void testDoesDocumentTypeMatch_Funeral() {
        // Fetch the created case for reference
        Case funeralCase = [SELECT Id, IC_Type__c, Sub_Type__c, Sub_Type_Reason__c, Surname__c, Subject FROM Case WHERE Subject = 'Test Case - ICS-485' LIMIT 1];
        
        IC_MinimumDocTypeChecker.FlowInputs inputs = new IC_MinimumDocTypeChecker.FlowInputs();
        inputs.caseId = funeralCase.Id;
        inputs.caseType = funeralCase.IC_Type__c;
        inputs.subType = funeralCase.Sub_Type__c;
        inputs.subTypeReason = funeralCase.Sub_Type_Reason__c;
        inputs.productType = 'Funeral';
        inputs.caseOrigin = 'Email';
        inputs.claimantSurname = '';
        
        Test.startTest();
        List<String> result = IC_MinimumDocTypeChecker.doesDocumentTypeMatch(new List<IC_MinimumDocTypeChecker.FlowInputs>{inputs});
        Test.stopTest();
        
        // Assert based on the expected output
        System.assert(result != null && !result.isEmpty(), 'Result should not be empty.');
        System.assertEquals('Fail', result[0], 'Expecting a Fail as other docs are missing');
    }
    
    @isTest
    static void teststillborn1() {
        // Fetch the created case for reference
        Case stillborn1Case = [SELECT Id, IC_Type__c, Sub_Type__c, Subject, Sub_Type_Reason__c FROM Case WHERE Subject = 'Test Case - ICS-630 V1' LIMIT 1];
        
        IC_MinimumDocTypeChecker.FlowInputs inputs = new IC_MinimumDocTypeChecker.FlowInputs();
        inputs.caseId = stillborn1Case.Id;
        inputs.caseType = stillborn1Case.IC_Type__c;
        inputs.subType = stillborn1Case.Sub_Type__c;
        inputs.subTypeReason = stillborn1Case.Sub_Type_Reason__c;
        inputs.productType = 'Funeral';
        inputs.caseOrigin = 'Email';
        inputs.noIDNumberAvailable = true;
        
        Test.startTest();
        List<String> result = IC_MinimumDocTypeChecker.doesDocumentTypeMatch(new List<IC_MinimumDocTypeChecker.FlowInputs>{inputs});
        Test.stopTest();
        
        // Assert based on the expected output
        System.assert(result != null && !result.isEmpty(), 'Result should not be empty.');
        System.assertEquals('Pass', result[0], 'Expecting a Pass because DocumentType matches with Metadata.');
    }    
    
    @isTest
    static void teststillborn2() {
        // Fetch the created case for reference
        Case stillborn2Case = [SELECT Id, IC_Type__c, Sub_Type__c, Subject, Sub_Type_Reason__c FROM Case WHERE Subject = 'Test Case - ICS-630 V2' LIMIT 1];
        
        IC_MinimumDocTypeChecker.FlowInputs inputs = new IC_MinimumDocTypeChecker.FlowInputs();
        inputs.caseId = stillborn2Case.Id;
        inputs.caseType = stillborn2Case.IC_Type__c;
        inputs.subType = stillborn2Case.Sub_Type__c;
        inputs.subTypeReason = stillborn2Case.Sub_Type_Reason__c;
        inputs.productType = 'Funeral';
        inputs.caseOrigin = 'Email';
        inputs.noIDNumberAvailable = false;
        
        Test.startTest();
        List<String> result = IC_MinimumDocTypeChecker.doesDocumentTypeMatch(new List<IC_MinimumDocTypeChecker.FlowInputs>{inputs});
        Test.stopTest();
        
        // Assert based on the expected output
        System.assert(result != null && !result.isEmpty(), 'Result should not be empty.');
        System.assertEquals('Pass', result[0], 'Expecting a Pass because DocumentType matches with Metadata.');
    }
}