/**
 * @description Utility class for handling Capitec Pay case-related operations.
 * Provides methods to validate case closure by ensuring all related disputes are resolved before closing a case.
 * @author Johan Langenhoven
 */
public with sharing class capitec_CaseCC {

    /**
     * @description Developer Name of the Record Type used for Capitec Pay cases.
     * This constant is used for reference in queries and validations.
     */
    public static final String RT_CAPITEC_PAY = 'CapitecPay';

    /**
     * @description Record Type ID for Capitec Pay cases, retrieved dynamically at runtime.
     * The value is obtained using Salesforce schema describe methods to enhance flexibility and avoid hardcoding.
     */
    public static final String RT_CAPITEC_PAY_ID =
            Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get(RT_CAPITEC_PAY).getRecordTypeId();

    /**
     * @description Validates case closure to ensure all associated disputes are resolved
     * before allowing the case status to be changed to "Closed".
     *
     * @param oldCaseMap A map of case records before the update operation.
     * @param newCaseMap A map of case records after the update operation.
     * 
     * @throws SObjectException if any disputes related to the case are not resolved before closure.
     */
    public static void validateCaseClosure(Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap) {

        Set<Id> caseIds = new Set<Id>();
        List<Case> cases = new List<Case>();
        Map<Id, List<Dispute>> disputeMap = new Map<Id, List<Dispute>>();

        // Identify Capitec Pay cases and collect their IDs
        for (Case newCase : newCaseMap.values()) {
            if (newCase.RecordTypeId == RT_CAPITEC_PAY_ID) {
                cases.add(newCase);
                caseIds.add(newCase.Id);
            }
        }

        // Exit if no relevant cases are found
        if (!cases.isEmpty()) {
            // Query associated disputes for the identified cases
            List<Dispute> disputes = [
                    SELECT Id, Status, CaseId, RecordTypeId
                    FROM Dispute
                    WHERE CaseId IN :caseIds
            ];

            // Organize disputes by case ID
            for (Dispute dispute : disputes) {
                if (!disputeMap.containsKey(dispute.CaseId)) {
                    disputeMap.put(dispute.CaseId, new List<Dispute>());
                }
                disputeMap.get(dispute.CaseId).add(dispute);
            }

            // Validate each case's closure status
            for (Case disputeCase : cases) {
                Case oldDisputeCase = oldCaseMap.get(disputeCase.Id);
                Case newDisputeCase = newCaseMap.get(disputeCase.Id);

                // Check if the case status is being changed to "Closed"
                if (oldDisputeCase.Status != 'Closed' && newDisputeCase.Status == 'Closed') {

                    // Ensure all related disputes are resolved before allowing case closure
                    if (disputeMap.get(newDisputeCase.Id) != null) {
                        for (Dispute dispute : disputeMap.get(newDisputeCase.Id)) {
                            if (dispute.Status != 'Resolved') {
                                newDisputeCase.addError('Status', 'Case cannot be closed until all disputes are resolved.');
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
}