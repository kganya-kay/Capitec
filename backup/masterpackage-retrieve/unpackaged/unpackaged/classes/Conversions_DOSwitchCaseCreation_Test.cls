/**
 * @description       : 
 * @author            : Rajesh Yandrathi
 * @group             : Cebtral Conversions
 * @last modified on  : 03-10-2026
 * @last modified by  : Samiirah Aujub
**/
@IsTest
public class Conversions_DOSwitchCaseCreation_Test {

    public static Id CONVERSIONS_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();

    //Added by Samiirah Aujub
    @testSetup
    static void setupTestData() {
        Case testCase = new Case(Subject = 'Test Case',
                                 Status = 'In Progress',
                                 Origin = 'Branch',
                                 Claim_Number__c = '12345679',
                                 RecordTypeId = CONVERSIONS_RECORDID
                                );
        insert testCase;

        Conversion__c conversion = new Conversion__c(Case__c = testCase.Id,
                                                     Old_Account_Number__c = '111222333'
                                                     );
        insert conversion;
    }

    @IsTest
    static void testCreateCase_WithDebitOrdersAndDocuments() {

        Id caseRecordTypeId;
        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();

        if (rtMap.containsKey('Conversions')) {
            caseRecordTypeId = rtMap.get('Conversions').getRecordTypeId();
        } else {
            caseRecordTypeId =
                Schema.SObjectType.Case.getRecordTypeInfos()[0].getRecordTypeId();
        }

        Group queue;
        List<Group> queues = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'Central_Conversions'
            AND Type = 'Queue'
            LIMIT 1
        ];

        if (queues.isEmpty()) {
            queue = new Group(
                Name = 'Central Conversions',
                DeveloperName = 'Central_Conversions',
                Type = 'Queue'
            );
            insert queue;
        } else {
            queue = queues[0];
        }

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/createDebitOrderSwitchCase/v1';

        req.requestBody = Blob.valueOf(
            JSON.serialize(new Map<String, Object>{
                'cdCIF' => '55557777',
                'idNumber' => '8965743902345',
                'consultantCP' => 'CP12345',
                'complexity' => 'Complex',
                'preferredTime' => '10:00:00',
                'preferredLanguage' => 'English',
                'preferredContactMethod' => 'SMS',
                'comments' => 'Client needs all debit orders switched by month end',
                'oldAccount' => '62498924234',
                'oldBank' => 'HSBC',
                'oldBranchCode' => '587000',
                'origin' => 'Digital',
                'typeValue' => 'Debit Order Switch',
                'subject' => 'Debit Order Switch Request',
                'statusValue' => 'New',
                'priorityValue' => 'Medium',
                'switchRequestId' => '12345678',
                'recordTypeId' => caseRecordTypeId,
                'ownerId' => queue.Id,
                'debitOrders' => new List<Object>{
                    new Map<String, Object>{
                        'fromAccount' => '123456789',
                        'toCapitecAccount' => '85756847474646',
                        'amount' => 980.00,
                        'debitOrderDate' => '2025-06-15',
                        'name' => 'FNB-Rent',
                        'externalInitiatorId' => 'DOI-1001',
                        'externalInitiatorName' => 'FNB Payments',
                        'inclusions' => 'Rent, Insurance, Gym',
                        'category' => 'FD Debit Order Switch',
                        'submissionDate' => '2025-10-15'
                    }
                },
                'documents' => new List<Object>{
                    new Map<String, Object>{
                        'name' => 'ID Document',
                        'documentLink' => 'https://example.com/id.pdf',
                        'documentumId' => 'DOC-001',
                        'documentType' => 'Bank Statement'
                    }
                }
            })
        );

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        Conversions_DebitOrderSwitchCaseCreation.ResponseWrapper response =
            Conversions_DebitOrderSwitchCaseCreation.createCase();
        Test.stopTest();

        System.assertEquals(true, response.success);
        System.assertNotEquals(null, response.caseId);

        Case cs = [
            SELECT Id, CaseNumber
            FROM Case
            WHERE Id = :response.caseId
        ];

        System.assertNotEquals(null, cs.CaseNumber);

        Conversion__c conv = [
            SELECT Id, Preferred_Language__c, Preferred_Contact_Method__c
            FROM Conversion__c
            WHERE Case__c = :cs.Id
            LIMIT 1
        ];

        System.assertEquals('English', conv.Preferred_Language__c);

        List<Debit_Order__c> dos = [
            SELECT Id
            FROM Debit_Order__c
            WHERE Case__c = :cs.Id
        ];

        System.assertEquals(1, dos.size());

        List<DocumentChecklistItem> docs = [
            SELECT Id
            FROM DocumentChecklistItem
            WHERE ParentRecordId = :cs.Id
        ];

        System.assertEquals(1, docs.size());
    }


    /**
    * @description Test method for getDuplicateCase
    * @author Samiirah Aujub | 02-04-2026 
    **/
    @IsTest
    static void testGetDuplicateCase() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/createDebitOrderSwitchCase/v1';

        req.requestBody = Blob.valueOf( JSON.serialize(new Map<String, Object>{
                                        'cdCIF' => '55557777',
                                        'idNumber' => '8965743902345',
                                        'consultantCP' => 'CP12345',
                                        'complexity' => 'Complex',
                                        'preferredTime' => '10:00:00',
                                        'preferredLanguage' => 'English',
                                        'preferredContactMethod' => 'SMS',
                                        'comments' => 'Client needs all debit orders switched by month end',
                                        'oldAccount' => '62498924234',
                                        'oldBank' => 'HSBC',
                                        'oldBranchCode' => '587000',
                                        'origin' => 'Digital',
                                        'typeValue' => 'Debit Order Switch',
                                        'subject' => 'Debit Order Switch Request',
                                        'statusValue' => 'New',
                                        'priorityValue' => 'Medium',
                                        'switchRequestId' => '12345679',
                                        'recordTypeId' => CONVERSIONS_RECORDID,
                                        'ownerId' => null,
                                        'debitOrders' => new List<Object>{
                                            new Map<String, Object>{
                                                'fromAccount' => '123456789',
                                                'toCapitecAccount' => '85756847474646',
                                                'amount' => 980.00,
                                                'debitOrderDate' => '2025-06-15',
                                                'name' => 'FNB-Rent',
                                                'externalInitiatorId' => 'DOI-1001',
                                                'externalInitiatorName' => 'FNB Payments',
                                                'inclusions' => 'Rent, Insurance, Gym',
                                                'category' => 'FD Debit Order Switch',
                                                'submissionDate' => '2025-10-15'
                                            }
                                        },
                                        'documents' => new List<Object>{
                                            new Map<String, Object>{
                                                'name' => 'ID Document',
                                                'documentLink' => 'https://example.com/id.pdf',
                                                'documentumId' => 'DOC-001',
                                                'documentType' => 'Bank Statement'
                                            }
                                        }
                                    })
                                );

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        Conversions_DebitOrderSwitchCaseCreation.ResponseWrapper response = Conversions_DebitOrderSwitchCaseCreation.createCase();
        Test.stopTest();

        System.assertEquals(false, response.success);
    }
}