/**
 * @description Trigger handler for Capitec Dispute management.
 * This class ensures proper validation of dispute resolutions before updating records.
 * It leverages the TriggerHandler base class to provide structured event handling.
 * @author Johan Langenhoven
 */
public with sharing class capitec_DisputeTRH extends TriggerHandler {

    /**
     * @description A map storing the old version of Dispute records before the update operation.
     * This map is populated from the Trigger.oldMap context variable.
     */
    private final Map<Id, Dispute> oldDisputeMap;

    /**
     * @description A map storing the new version of Dispute records after the update operation.
     * This map is populated from the Trigger.newMap context variable.
     */
    private final Map<Id, Dispute> newDisputeMap;

    /**
     * @description Constructor that initializes the old and new dispute record maps.
     * It extracts the values from the trigger context variables to allow for validation logic.
     */
    public capitec_DisputeTRH() {
        oldDisputeMap = (Map<Id, Dispute>) Trigger.oldMap;
        newDisputeMap = (Map<Id, Dispute>) Trigger.newMap;
    }

    /**
     * @description Handles the before update trigger event.
     */
    public override void beforeUpdate() {
        capitec_DisputeCC.validateDisputeResolution(oldDisputeMap, newDisputeMap);
    }
}