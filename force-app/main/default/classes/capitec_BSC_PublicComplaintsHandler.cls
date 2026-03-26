public class capitec_BSC_PublicComplaintsHandler {
    
    @InvocableMethod
    public static void createPublicComplaintsFromFlow(List<Case> lstCase){
        List<PublicComplaint> lstPublicComplaint = new List<PublicComplaint>();
        
        for(Case c: lstCase){
            PublicComplaint pc = new PublicComplaint();
            pc.AccountId = c.AccountId;
            pc.ComplaintCaseId = c.Id;
            pc.ComplaintType = c.Type;
            pc.Description = c.Description;
            pc.Subject = c.Subject;
            pc.Email = c.Email_Address__c;
            pc.IncidentDate = System.Today();
            pc.Priority = c.Priority;
            pc.Related_Financial_Account__c = c.AccountId;
            pc.Status = c.Status;
            lstPublicComplaint.add(pc);
        }
        
        Database.insert(lstPublicComplaint);
    }
}