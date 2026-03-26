@isTest
private class STrackControllerTest {
    
    @isTest
    static void testGetIncidents() {
        // Create a mock HTTP response for the incidents request
        HttpResponse incidentsResponse = new HttpResponse();
        incidentsResponse.setHeader('Content-Type', 'application/json');
        incidentsResponse.setBody('[' +
            '{"recId": "1", "incidentNumber": "1", "summary": "Incident 1", "description": "Description 1", "incidentType": "Type 1", "category": "Category 1", "subCategory": "SubCategory 1", "issue": "Issue 1", "ownerTeam": "Team 1", "owner": "Owner 1", "status": "Status 1", "createdDateTime": "15/07/2024 10:17:14", "resolution": "Resolution 1", "voiceRefNo": "VoiceRef1", "callerPhone": "CallerPhone1", "orgUnitID": "OrgUnit1", "vDN": "VDN1", "source": "Source1", "networkUsername": "NetworkUser1", "impact": "Impact1", "urgency": "Urgency1", "branchID": "Branch1", "causeCode": "CauseCode1"},' +
            '{"recId": "2", "incidentNumber": "2", "summary": "Incident 2", "description": "Description 2", "incidentType": "Type 2", "category": "Category 2", "subCategory": "SubCategory 2", "issue": "Issue 2", "ownerTeam": "Team 2", "owner": "Owner 2", "status": "Status 2", "createdDateTime": "15/07/2024 10:17:14", "resolution": "Resolution 2", "voiceRefNo": "VoiceRef2", "callerPhone": "CallerPhone2", "orgUnitID": "OrgUnit2", "vDN": "VDN2", "source": "Source2", "networkUsername": "NetworkUser2", "impact": "Impact2", "urgency": "Urgency2", "branchID": "Branch2", "causeCode": "CauseCode2"}' +
        ']');
        incidentsResponse.setStatusCode(200);
        
        // Mock the HttpCallout to return incidents response
        Test.setMock(HttpCalloutMock.class, new STrackControllerMockHttpResponseGenerator(incidentsResponse));
        
        // Create a mock Case record
        Case mockCase = new Case(
            Subject = 'Test Case',
            Status = 'New'
        );
        insert mockCase;

        // Define date range for testing
        Date fromDate = Date.newInstance(2024, 7, 15);
        Date toDate = Date.newInstance(2024, 7, 15);

        // Test the getIncidents method with CIF number and mock case ID
        Test.startTest();
        List<STrack_Incident__c> incidents = STrackController.getIncidents('testCifNumber', mockCase.Id, fromDate, toDate);
        Test.stopTest();
        
        // Debugging statement to print returned incidents
        System.debug('Returned Incidents: ' + incidents);
        
        // Assert the results
        System.assertEquals(2, incidents.size(), 'Expected 2 incidents to be returned');
        System.assertEquals('1', incidents[0].Incident_ID__c, 'First incident ID should be 1');
        System.assertEquals('Incident 1', incidents[0].Summary__c, 'First incident summary should be "Incident 1"');
        System.assertEquals('2', incidents[1].Incident_ID__c, 'Second incident ID should be 2');
        System.assertEquals('Incident 2', incidents[1].Summary__c, 'Second incident summary should be "Incident 2"');
    }
    
    private class STrackControllerMockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse incidentsResponse;
        
        public STrackControllerMockHttpResponseGenerator(HttpResponse incidentsResponse) {
            this.incidentsResponse = incidentsResponse;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            System.debug('Mocking HTTP request to: ' + req.getEndpoint());
            System.debug('Mocking HTTP request body: ' + req.getBody());

            if (req.getEndpoint().contains('incident-management-proxy')) {
                System.debug('Returning incidentsResponse');
                return incidentsResponse;
            } else {
                HttpResponse response = new HttpResponse();
                response.setStatusCode(400);
                return response;
            }
        }
    }
}