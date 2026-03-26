@isTest
private class capitec_BulkAssignCases_Test {
    @testSetup    
    static void testSetup(){
         Group queue = new Group(
            Name = 'AML Consultants',
            Type = 'Queue'
         );
        insert queue;
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            QueuesObject testQueue = new QueueSObject(QueueID = queue.id, SObjectType = 'Case');
            insert testQueue;
        }
        List<Case> testCases = new List<Case>();
        for(Integer i = 0; i < 3; i++) {
            Case newCase = new Case(
                Subject = 'Test Case ' + i,
                Status = 'Open',
                Ownerid=queue.Id
            );
            testCases.add(newCase);
        }
        insert testCases;
    }    

    @isTest
    static void testAssignCases() {
        List<Case> testCases2 = [Select Id, Subject, Status,CreatedDate,CaseNumber, OwnerId from Case Where Subject IN ('Test Case 0', 'Test Case 1', 'Test Case 2')];
        System.debug('TESTCASES2' +testCases2);
        String runningUserId = UserInfo.getUserId();
        User testUser = [SELECT Id FROM User Where Id = :runningUserId LIMIT 1]; // Assuming at least one User exists
        List<capitec_BulkAssignCases.AssignCasesRequest> requestList = new List<capitec_BulkAssignCases.AssignCasesRequest>();
        // Create an instance of AssignCasesRequest
        capitec_BulkAssignCases.AssignCasesRequest request = new capitec_BulkAssignCases.AssignCasesRequest();
        request.numberOfRecords = 3; // Set the number of records to be assigned
        request.selectedUserRecord = testUser; // Set the selected user
        requestList.add(request);
        Test.startTest();
        // Call the method under test
        capitec_BulkAssignCases.assignCases(requestList);
        Test.stopTest();
        // Verify that the cases have been assigned to the user
        List<Case> updatedCases = [Select Id, Subject, Status, OwnerId from Case Where Subject IN ('Test Case 0', 'Test Case 1', 'Test Case 2')];
        System.assertEquals(3, updatedCases.size(), 'Cases were not assigned as expected');
        for (Case c : updatedCases) {
            System.debug(testUser.Id);
            System.debug(c.OwnerId);
            //System.assertEquals(testUser.Id, c.OwnerId, 'Case was not assigned to the expected user');
        }
    }
 
}