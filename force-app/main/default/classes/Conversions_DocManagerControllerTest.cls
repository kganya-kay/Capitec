/**
 * @description       : Test class for Conversions_DocumentManagerController
 * @author            : Samiirah Aujub
 * @group             : 
 * @last modified on  : 03-09-2026
 * @last modified by  : Samiirah Aujub
**/
@IsTest
public with sharing class Conversions_DocManagerControllerTest {
    public static Id CONVERSIONS_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();

    @TestSetup
    static void setup() {

       Case testCase = new Case(Subject = 'Test Case',
                                 Status = 'In Progress',
                                 Origin = 'Branch',
                                 RecordTypeId = CONVERSIONS_RECORDID
                                );
        insert testCase;

        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('dummy'),
            FirstPublishLocationId = testCase.Id
        );
        insert cv;

    }

    @IsTest
    static void testGetRequestItems() {

        Case caseRecord = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
            List<IC_DocumentRequestList__c> lstResults = Conversions_DocumentManagerController.getRequestItems(caseRecord.Id);
            System.debug('## Retrieved items size:'+ lstResults.size());
        Test.stopTest();

        System.assertEquals(1, lstResults.size(), 'Should return 1 unclassified record');
    }

    @IsTest
    static void testCreateDocChecklistItem() {

        Case caseRecord = [SELECT Id FROM Case LIMIT 1];

        IC_DocumentRequestList__c req =[SELECT Id, CON_Content_Document_Id__c
                                        FROM IC_DocumentRequestList__c LIMIT 1];

        Test.startTest();
            Boolean result = Conversions_DocumentManagerController.createDocChecklistItem( caseRecord.Id,req.Id,req.CON_Content_Document_Id__c,'Bank Statement');
        Test.stopTest();

        System.assertEquals(true, result, 'Expected successful classification');

        DocumentChecklistItem dci = [SELECT Id, 
                                             ParentRecordId, 
                                             CON_Document_Type__c 
                                      FROM DocumentChecklistItem 
                                      LIMIT 1
                                    ];

        System.assertEquals(caseRecord.Id, dci.ParentRecordId);
        System.assertEquals('Bank Statement', dci.CON_Document_Type__c);

        IC_DocumentRequestList__c updatedReq = [SELECT Id, CON_Classified__c
                                                FROM IC_DocumentRequestList__c
                                                WHERE Id = :req.Id
                                                LIMIT 1];

        System.assertEquals(true, updatedReq.CON_Classified__c,'Request item must be marked as classified.');
    }

    @IsTest
    static void testCreateDocChecklistItemInvalid() {

        Test.startTest();
            Boolean result = Conversions_DocumentManagerController.createDocChecklistItem(null, null, null, null);
        Test.stopTest();

        System.assertEquals(false, result, 'Expected failure on invalid input');
    }

}