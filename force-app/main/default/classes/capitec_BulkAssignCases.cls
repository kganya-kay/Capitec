public class capitec_BulkAssignCases {
    @InvocableMethod
    public static void assignCases(List<AssignCasesRequest> requestList) {
        List<Case> casesToAssign = new List<Case>();
        
        for (AssignCasesRequest request : requestList) {
            Integer numberOfRecords = request.numberOfRecords;
            User selectedUser = request.selectedUserRecord;
            
            // Query for Case records ordered by CreatedDate in ascending order
            List<Case> queriedCases = [SELECT Id, Subject, CreatedDate, CaseNumber 
                                       FROM Case 
                                       Where Status = 'Open' AND Owner.Type = 'Queue' AND Owner.Name = 'AML Consultants'
                                       ORDER BY CaseNumber ASC 
                                       LIMIT :numberOfRecords];
            
            // Assign the retrieved cases to the selected user
            for (Case c : queriedCases) {
                c.OwnerId = selectedUser.Id;
                casesToAssign.add(c);
            }
        }
        
        // Update the cases to assign them to the selected user
        if (!casesToAssign.isEmpty()) {
            update casesToAssign;
        }
    }
    
    public class AssignCasesRequest {
        @InvocableVariable(required=true)
        public Integer numberOfRecords;
        
        @InvocableVariable(required=true)
        public User selectedUserRecord;
    }
}