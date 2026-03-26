/**
    *This class is responsible for interacting with the STrack system to fetch incident data
    * based on the CIF number of a client. It includes methods for retrieving incidents and
    * handling OAuth token acquisition for secure communication with external services.

    * Tickets            : CECSF-143 & CECSF-144
    * @author            : Nonny Mahao
    * @LastModified      : 21.11.2024     
    **/
public with sharing class STrackController {
    @AuraEnabled(cacheable=true)

    /**
     * This method is for retrieving incidents from STrack based on the CIF number and filters out already linked incidents
     * This method is triggered when the Get Incidents button is pressed on Salesforce
     * @param cifNumber    : CIF number of the client
     * @param caseId       : Id of the case to filter out linked incidents.
     * @return list<STrack_Incident__c> : Returns a list of incidents excluding already linked ones.
     * @author : Nonny Mahao
     * @date : 26.07.2024
     */
    public static List<STrack_Incident__c> getIncidents(String cifNumber, Id caseId,  Date fromDate, Date toDate) {
        if (!Schema.sObjectType.STrack_Incident__c.isAccessible()) {
            throw new AuraHandledException('Insufficient access rights on objects');
        }

        List<STrack_Incident__c> linkedIncidents = [
            SELECT Incident_ID__c
            FROM STrack_Incident__c
            WHERE Related_case__c = :caseId
        ];

        Set<String> linkedIncidentIds = new Set<String>();
        for (STrack_Incident__c linkedIncident : linkedIncidents) {
            linkedIncidentIds.add(linkedIncident.Incident_ID__c);
        }

        String endpoint = '/incident-management-proxy/incident-management/incidents/v2/incident/client';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:NC_ClientDomain' + endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        String requestBody = cifNumber;

        req.setBody(requestBody);
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res;

        List<STrack_Incident__c> incidents = new List<STrack_Incident__c>();
        try {
            // Logging
            System.debug('Sending request to: ' + endpoint);
            System.debug('Request body: ' + requestBody);

            res = http.send(req);
            System.debug('HTTP Response status code: ' + res.getStatusCode());
            System.debug('HTTP Response body: ' + res.getBody());

            if (res.getStatusCode() == 200) {
                List<ExternalIncident> externalIncidents = (List<ExternalIncident>) JSON.deserialize(res.getBody(), List<ExternalIncident>.class);
                System.debug('Parsed external incidents: ' + externalIncidents);
                System.debug('Number of incidents parsed: ' + externalIncidents.size());

                for (ExternalIncident externalIncident : externalIncidents) {
                    if (linkedIncidentIds.contains(externalIncident.incidentNumber)) {
                        continue;
                    }
                    Date createdDate = convertToDateTime(externalIncident.createdDateTime).date();
                    if (createdDate >= fromDate && createdDate <= toDate) {

                    System.debug('Processing external incident: ' + externalIncident.incidentNumber);
                    STrack_Incident__c incident = new STrack_Incident__c();
                    incident.Incident_ID__c = externalIncident.incidentNumber;
                    incident.Summary__c = externalIncident.summary;
                    incident.Description__c = externalIncident.description;
                    incident.Type__c = externalIncident.incidentType;
                    incident.Category__c = externalIncident.category;
                    incident.Subcategory__c = externalIncident.subCategory;
                    incident.Issue__c = externalIncident.issue;
                    incident.Owner_Team__c = externalIncident.ownerTeam;
                    incident.Owner__c = externalIncident.owner;
                    incident.Status__c = externalIncident.status;
                    incident.Created_On__c = convertToDateTime(externalIncident.createdDateTime).date(); 
                    incident.Solution__c = externalIncident.resolution;
                    incident.recId__c = externalIncident.recId;
                    incident.voiceRefNo__c = externalIncident.voiceRefNo;
                    incident.callerPhone__c = externalIncident.callerPhone;
                    incident.orgUnitID__c = externalIncident.orgUnitID;
                    incident.vDN__c = externalIncident.vDN;
                    incident.Source__c = externalIncident.source;
                    incident.NetworkUsername__c = externalIncident.networkUsername;
                    incident.Impact__c = externalIncident.impact;
                    incident.Urgency__c = externalIncident.urgency;
                    incident.BranchID__c = externalIncident.branchID;
                    incident.CauseCode__c = externalIncident.causeCode;

                    incidents.add(incident);
                }
                }
            } else {
                System.debug('Failed to get data from external system. Status: ' + res.getStatusCode() + ', Body: ' + res.getBody());
                throw new AuraHandledException('Failed to retrieve incidents. Please check the external system or configuration.');
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
        System.debug('Returned Incidents: ' + incidents);
        return incidents;
    }



    /**
    * This method converts a date-time string in the format "dd/MM/yyyy HH:mm:ss" to a DateTime instance.
    * @param dateTimeString The date-time string to be converted, expected in the format "dd/MM/yyyy HH:mm:ss".
    * @return A DateTime instance representing the given date-time string.
    * @author : Nonny Mahao
    * @date : 26.07.2024
    */
    private static DateTime convertToDateTime(String dateTimeString) {
        String datePart = dateTimeString.substring(0, 10); // "15/07/2024"
        String timePart = dateTimeString.substring(11, 19); // "10:17:14"

        // Split the date part into day, month, and year
        String[] dateParts = datePart.split('/');
        Integer day = Integer.valueOf(dateParts[0]);
        Integer month = Integer.valueOf(dateParts[1]);
        Integer year = Integer.valueOf(dateParts[2]);

        // Construct the DateTime instance
        Date convertedDate = Date.newInstance(year, month, day);
        Time convertedTime = Time.newInstance(
            Integer.valueOf(timePart.substring(0, 2)),  // Hour
            Integer.valueOf(timePart.substring(3, 5)),  // Minute
            Integer.valueOf(timePart.substring(6, 8)),  // Second
            0  // Millisecond
        );

        return DateTime.newInstance(convertedDate, convertedTime);
    }

    public class ExternalIncident {
        public String incidentNumber;
        public String recId;
        public String voiceRefNo;
        public String callerPhone;
        public String orgUnitID;
        public String category;
        public String subCategory;
        public String issue;
        public String vDN;
        public String ownerTeam;
        public String owner;
        public String networkUsername;
        public String source;
        public String impact;
        public String urgency;
        public String branchID;
        public String summary;
        public String description;
        public String incidentType;
        public String resolution;
        public String causeCode;
        public String status;
        public String createdDateTime;
        public ClientDetails clientDetails;
        public NonClientDetails nonClientDetails;
    }

    public class ClientDetails {
        public String cif;
        public String fullName;
        public String southAfricanIDNumber;
        public String cellNumber;
        public String workNumber;
        public String email;
    }

    public class NonClientDetails {
        public String fullName;
        public String southAfricanIDNumber;
        public String cellPhone;
        public String workPhone;
        public String email;
    }
}