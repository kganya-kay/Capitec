/**
 * The capitec_AddRelatedIncidents class is designed to facilitate the 
 * addition of related incidents to a specific case within the Salesforce 
 * environment. It provides methods to validate user permissions, fetch 
 * case details, create new incident records based on input data, and 
 * insert these records into the database.
 * Tickets            : CECSF-350
 * @author            : Nonny Mahao
 * @LastModified      : 25.11.2024 
 */

public with sharing class capitec_AddRelatedIncidents {
    /**
     * This method is the main entry point for adding related incidents to a case.
     * It validates user permissions, fetches the case details, processes the list 
     * of incidents, and inserts them into the database.
     *
     * @param lstIncidents - List of incidents to be added.
     * @param caseId - The ID of the case to which the incidents are related.
     * @author : Nonny Mahao
     * @date : 16.10.2024
     */
    @AuraEnabled
    public static void addRelatedIncidents(List<STrack_Incident__c> lstIncidents, Id caseId) {
        validatePermissions();
        Case caseDetails = fetchCaseDetails(caseId);
        List<STrack_Incident__c> listOfSTrackIncidents = createIncidents(lstIncidents, caseDetails);
        insertIncidents(listOfSTrackIncidents);
        System.debug('Related Incidents added successfully.');
    }
    
    /**
     * This method validates whether the current user has the necessary 
     * permissions to access, update, and insert Case and Incident records.
     * @author : Nonny Mahao
     * @date : 16.10.2024
     */
    private static void validatePermissions() {
        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('You do not have permission to access Case records.');
        }
        if (!Schema.sObjectType.STrack_Incident__c.isAccessible() || 
            !Schema.sObjectType.STrack_Incident__c.isUpdateable() ||
            !Schema.sObjectType.STrack_Incident__c.isCreateable()) {
            throw new AuraHandledException('You do not have permission to access, update, or insert STrack Incident records.');
        }
    }

    /**
     * This method fetches the details of a case from the database using the provided case ID.
     *
     * @param caseId - The ID of the case to fetch.
     * @return Case - The case details fetched from the database.
     * @author : Nonny Mahao
     * @date : 25.11.2024
     */
    private static Case fetchCaseDetails(Id caseId) {
        List<Case> caseDetailsList = [SELECT Id, CaseNumber FROM Case WHERE Id = :caseId LIMIT 1];
        if (caseDetailsList.isEmpty()) {
            throw new AuraHandledException('No case found with the provided ID.');
        }
        return caseDetailsList[0];
    }

    /**
     * This method processes the list of incidents, checks if they are already related to the case,
     * and creates a new list of incidents to insert.
     *
     * @param lstIncidents - List of incidents to process.
     * @param caseDetails - The case to which the incidents are related.
     * @return List<STrack_Incident__c> - A list of new incidents to insert.
     * @author : Nonny Mahao
     * @date : 16.10.2024
     */
    private static List<STrack_Incident__c> createIncidents(List<STrack_Incident__c> lstIncidents, Case caseDetails) {
        List<STrack_Incident__c> listOfSTrackIncidents = new List<STrack_Incident__c>();
        System.debug('Received Incidents: ' + lstIncidents);
        System.debug('Case Details: ' + caseDetails);
        Set<String> existingIncidentNumbers = new Set<String>();
        for (STrack_Incident__c existingIncidentNumber : [
            SELECT Incident_ID__c
            FROM STrack_Incident__c
            WHERE Related_Case__c = :caseDetails.Id
        ]) {
            existingIncidentNumbers.add(existingIncidentNumber.Incident_ID__c);
        }

        for (STrack_Incident__c s : lstIncidents) {
            if (!existingIncidentNumbers.contains(s.Incident_ID__c)) {
                STrack_Incident__c newIncident = new STrack_Incident__c();
                newIncident.Name = s.Incident_ID__c;
                newIncident.Incident_ID__c = s.Incident_ID__c;
                newIncident.Related_Case__c = caseDetails.Id;
                newIncident.Category__c = s.Category__c;
                newIncident.Subcategory__c = s.Subcategory__c;
                newIncident.Issue__c = s.Issue__c;
                newIncident.Type__c = s.Type__c;
                newIncident.Summary__c = s.Summary__c;
                newIncident.Status__c = s.Status__c;
                newIncident.recId__c = s.recId__c;
                newIncident.VoiceRefNo__c = s.VoiceRefNo__c;
                newIncident.CallerPhone__c = s.CallerPhone__c;
                newIncident.OrgUnitID__c = s.OrgUnitID__c;
                newIncident.vDN__c = s.vDN__c;
                newIncident.Source__c = s.Source__c;
                newIncident.NetworkUsername__c = s.NetworkUsername__c;
                newIncident.Impact__c = s.Impact__c;
                newIncident.Urgency__c = s.Urgency__c;
                newIncident.BranchID__c = s.BranchID__c;
                newIncident.CauseCode__c = s.CauseCode__c;
                newIncident.Description__c = s.Description__c;
                newIncident.Solution__c = s.Solution__c;
                newIncident.Owner_Team__c = s.Owner_Team__c;
                newIncident.Owner__c = s.Owner__c;
                newIncident.Created_On__c = s.Created_On__c;

                listOfSTrackIncidents.add(newIncident);
            }
        }
        return listOfSTrackIncidents;
    }

    /**
     * This method inserts the list of incidents into the database.
     * It performs a bulk insert operation and handles any errors that occur.
     *
     * @param listOfSTrackIncidents - List of incidents to insert.
     * @author : Nonny Mahao
     * @date : 16.10.2024
     */
    private static void insertIncidents(List<STrack_Incident__c> listOfSTrackIncidents) {
        System.debug(listOfSTrackIncidents);
       // insert listOfSTrackIncidents;
       List<String> errorMessages = new List<String>();
        if (!listOfSTrackIncidents.isEmpty()) {
            Database.SaveResult[] saveResults = Database.insert(listOfSTrackIncidents, false);
            for (Database.SaveResult sr : saveResults) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('Error inserting record: ' + err.getMessage());
                        errorMessages.add(err.getMessage());
                    }
                }
            }
        }
        if (listOfSTrackIncidents.isEmpty()) {
            throw new AuraHandledException('Failed to insert incident(s)');
        }
    }
}