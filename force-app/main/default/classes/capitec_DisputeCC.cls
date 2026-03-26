/**
 * @description Utility class for handling Capitec Pay dispute-related operations.
 * Provides methods to validate dispute resolution and manage related records.
 * @author Johan Langenhoven
 */
public with sharing class capitec_DisputeCC {

    /**
     * @description Developer Name of the Record Type used for Capitec Pay disputes.
     * This constant is used to reference the Capitec Pay dispute type in queries and validations.
     */
    public static final String RT_CAPITEC_PAY = 'CapitecPay';

    /**
     * @description Record Type ID for Capitec Pay disputes, retrieved dynamically at runtime.
     * This value is determined using the Salesforce schema describe methods to ensure flexibility.
     */
    public static final String RT_CAPITEC_PAY_ID =
            Dispute.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get(RT_CAPITEC_PAY).getRecordTypeId();

    /**
     * @description Validates dispute resolution to ensure all associated dispute items are settled
     * before allowing the dispute status to be changed to "Resolved".
     *
     * @param oldDisputeMap A map of dispute records before the update operation.
     * @param newDisputeMap A map of dispute records after the update operation.
     *
     * @throws SObjectException if any dispute items are not settled before resolution.
     */
    public static void validateDisputeResolution(Map<Id, Dispute> oldDisputeMap, Map<Id, Dispute> newDisputeMap) {

        Set<Id> disputeIds = new Set<Id>();
        List<Dispute> disputes = new List<Dispute>();
        Map<Id, List<DisputeItem>> disputeItemMap = new Map<Id, List<DisputeItem>>();

        // Collect IDs of Capitec Pay disputes to process
        for (Dispute dispute : newDisputeMap.values()) {
            if (dispute.RecordTypeId == RT_CAPITEC_PAY_ID) {
                disputes.add(dispute);
                disputeIds.add(dispute.Id);
            }
        }

        // Proceed only if relevant disputes are identified
        if (!disputes.isEmpty()) {
            // Retrieve associated dispute items for identified disputes
            List<DisputeItem> disputeItems = [
                    SELECT Id, Status, DisputeId, RecordTypeId
                    FROM DisputeItem
                    WHERE DisputeId IN :disputeIds
            ];

            // Organize dispute items by dispute ID
            for (DisputeItem disputeItem : disputeItems) {
                if (!disputeItemMap.containsKey(disputeItem.DisputeId)) {
                    disputeItemMap.put(disputeItem.DisputeId, new List<DisputeItem>());
                }
                disputeItemMap.get(disputeItem.DisputeId).add(disputeItem);
            }

            // Validate resolution for each dispute
            for (Dispute dispute : disputes) {
                Dispute oldDispute = oldDisputeMap.get(dispute.Id);
                Dispute newDispute = newDisputeMap.get(dispute.Id);

                // Ensure that the status change to "Resolved" is allowed only if all items are settled
                if (oldDispute.Status != 'Resolved' && newDispute.Status == 'Resolved') {
                    if (disputeItemMap.get(newDispute.Id) != null) {
                        for (DisputeItem disputeItem : disputeItemMap.get(newDispute.Id)) {
                            if (disputeItem.Status != 'Settled') {
                                newDispute.addError('Status', 'Dispute cannot be resolved until all dispute items are settled.');
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
}