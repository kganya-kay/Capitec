@isTest
private class capitec_AddRelatedIncidentsTest {

    @testSetup
    static void setupTestData() {
        // Create a test case record (the one we'll relate incidents to later)
        Case testCase = new Case(
            AccountId = null
        );
        insert testCase;

        // Create a second unrelated case to associate the incidents initially
        Case unrelatedCase = new Case(
            AccountId = null
        );
        insert unrelatedCase;

        // Create some test incident records with the unrelated case
        List<STrack_Incident__c> incidents = new List<STrack_Incident__c>();
        for (Integer i = 0; i < 3; i++) {
            STrack_Incident__c incident = new STrack_Incident__c(
                Incident_ID__c = 'INC' + i,
                Category__c = 'Category ' + i,
                Subcategory__c = 'Subcategory ' + i,
                Issue__c = 'Issue ' + i,
                Type__c = 'Incident',
                Summary__c = 'Test Summary ' + i,
                Status__c = 'Open',
                Related_Case__c = unrelatedCase.Id,
                recId__c = 'recId_' + i,
                voiceRefNo__c = 'VoiceRef_' + i,
                callerPhone__c = 'CallerPhone_' + i,
                orgUnitID__c = 'OrgUnit_' + i,
                vDN__c = 'VDN_' + i,
                Source__c = 'Source_' + i,
                NetworkUsername__c = 'NetworkUser_' + i,
                Impact__c = 'Impact_' + i,
                Urgency__c = 'Urgency_' + i,
                BranchID__c = 'BranchID_' + i,
                CauseCode__c = 'CauseCode_' + i,
                Description__c = 'Description_' + i,
                Solution__c = 'Solution_' + i,
                Owner_Team__c = 'Owner Team_' + i,
                Owner__c = 'Owner_' +i,
                Created_On__c = Datetime.now().addDays(i)
            );
            incidents.add(incident);
        }
        insert incidents;
    }

    @isTest
    static void testAddRelatedIncidents() {
        // Retrieve the test case created in testSetup
        Case testCase = [SELECT Id, CaseNumber, Client_Account_Number__c FROM Case LIMIT 1];

        // Retrieve the test incidents and ensure to query the Related_Case__c field
        List<STrack_Incident__c> testIncidents = [
        SELECT Id, Incident_ID__c, Category__c, Subcategory__c, Issue__c, Type__c, Summary__c, Status__c, Related_Case__c, 
            recId__c, voiceRefNo__c, callerPhone__c, orgUnitID__c, vDN__c, Source__c, NetworkUsername__c, 
            Impact__c, Urgency__c, BranchID__c, CauseCode__c, Description__c, Solution__c, Owner_Team__c, 
            Owner__c, Created_On__c
        FROM STrack_Incident__c 
        WHERE Related_Case__c != :testCase.Id 
        LIMIT 2
        ];

        // Call the method to be tested, only passing the case ID
        Test.startTest();
        capitec_AddRelatedIncidents.addRelatedIncidents(testIncidents, testCase.Id);
        Test.stopTest();

        // Assert that the related incidents were added with the correct Related_Case__c
        List<STrack_Incident__c> relatedIncidents = [SELECT Id, Related_Case__c FROM STrack_Incident__c WHERE Related_Case__c = :testCase.Id];
        System.assertEquals(2, relatedIncidents.size(), 'Two incidents should be related to the case');
    }
}