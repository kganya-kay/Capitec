/*
  @description       : CEDT-2932 - Scheduler class for closing Client Care Cases.
  @author            : Kevin Nundran
  @last modified on  : 04-11-2024
  @last modified by  : Cornelia Smit
					 : CEDT- - Close Civil cases with Not Fraud status
*/
public class capitec_CCCaseCloseScheduler implements Schedulable {
    
    // Variable to store the Case ID
    public String caseId;
    public String closingStatus;

    /*
      @description       : Constructor to accept the Case ID.
      @param             : caseId - The ID of the case to be closed.
      @created on        : 20-09-2024
    */
    public capitec_CCCaseCloseScheduler(String caseId, String closingStatus) {
        this.caseId = caseId;
        this.closingStatus = closingStatus;
    }

    /*
      @description       : Implements the execute method for the Schedulable interface.
                           This method is called when the scheduled job is executed.
      @param             : sc - The context of the scheduled job.
      @created on        : 20-09-2024
    */
    public void execute(SchedulableContext sc) {
        // Call the method to update the Case status
        updateCaseStatus(caseId);
    }

    /*
      @description       : Updates the status of the Case to Closed.
      @param             : caseId - The ID of the case to be updated.
      @created on        : 20-09-2024
    */
    private void updateCaseStatus(String caseId) {
        try {
            // Query the Case record by ID
            Case caseRecord = [SELECT Id, Status FROM Case WHERE Id = :caseId LIMIT 1];
            if (caseRecord != null) {
                // Update the Case status to Closed
                caseRecord.Status = closingStatus;
                update caseRecord;
            }
        } catch (Exception e) {
            // Handle any exceptions
            System.debug('Error updating Case status: ' + e.getMessage());
        }
    }
}