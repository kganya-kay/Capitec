@RestResource(urlMapping='/CaseLookup/*')
global with sharing class CaseLookupService {

    // Define a method to handle the GET request
    @HttpGet
    global static List<CaseDetails> getCasesByCIF() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        // Get the CIF_Number from the URL parameter
        String cifNumber = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);

        // Query cases associated with the provided CIF_Number
        List<Case> cases = [SELECT Id, Status, CaseNumber, CreatedDate, RecordTypeId
                            FROM Case 
                            WHERE Account.CIF_Number__c = :cifNumber];

        // Map each Case record to the CaseDetails custom class
        List<CaseDetails> caseDetailsList = new List<CaseDetails>();
        for (Case c : cases) {
            caseDetailsList.add(new CaseDetails(c.Id, c.Status, c.CaseNumber, c.CreatedDate, c.RecordTypeId));
        }
        
        return caseDetailsList;
    }

    // Define a custom data structure to hold Case details
    global class CaseDetails {
        public Id Id;
        public String Status;
        public String CaseNumber;
        public Datetime CreatedDate;
        public String RecordTypeId;
        
        public CaseDetails(Id Id, String Status, String CaseNumber, Datetime CreatedDate, String RecordTypeId) {
            this.Id = Id;
            this.Status = Status;
            this.CaseNumber = CaseNumber;
            this.CreatedDate = CreatedDate;
            this.RecordTypeId = RecordTypeId;
        }
    }
}