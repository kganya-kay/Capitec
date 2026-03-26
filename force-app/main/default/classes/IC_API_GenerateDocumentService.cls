/*******************************************************************
* @Class Name        :  IC_API_GenerateDocumentService
* @Test Class        :  IC_API_GenerateDocumentService_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 29-July-2023, Jira Tickets: ICS-1368 
* @Version           :  1.0
*
*******************************************************************/

public class IC_API_GenerateDocumentService {
    
    public class TemplateValue {
        public String name;
        public String value;
        
        public TemplateValue(String name, String value) {
            this.name = name;
            this.value = value;
        }
    }

    public class Client{
        public String cifNumber;
        public String idNumber;

        public Client(String cifNumber, String idNumber){
            this.cifNumber = cifNumber;
            this.idNumber = idNumber;
        }
    }
    
    public class TemplateRequest {
        public Integer templateId;
        public Integer templateDataId;
        public List<TemplateValue> templateValues;
        public Client client;
        public String documentName;
        public String documentType;
        
        public TemplateRequest(Integer templateId, Integer templateDataId, List<TemplateValue> templateValues, String documentName, Client client, String documentType) {
            this.templateId = templateId;
            this.templateDataId = templateDataId;
            this.templateValues = templateValues;
            this.documentName = documentName;
            this.client = client;
            this.documentType = documentType;
        }
    }
    
    public class ResponseWrapper {
        public String id;
        //public String documentContent;
    }
    
    @InvocableMethod(label='Generate Funeral Plan Claims Note' description='Send an HTTP request with template data for funeral plan claims note')
    public static List<String> generateFuneralPlanClaimsNote(List<Id> caseIds) {
        List<String> results = new List<String>();
        Id caseId = caseIds[0];
        try {
            Case caseRecord = [
                SELECT Id, CaseNumber, IC_Claims_Note_Ext_Doc_ID__c, IC_Send_Funeral_Plan_Claims_Note__c,
                Account.Salutation, Account.FirstName, Account.LastName, Account.MiddleName,
                Account.Name, Account.Identity_Number__c, Account.PersonEmail, Account.Phone, Account.CIF_Number__c,
                Account.Initials__c, IC_Claimant_Initials__c, Title__c, Surname__c, First_Name__c, IC_Claimant_Middle_Name__c,
                ID_Number__c, Email_Address__c, Mobile_Number__c
                FROM Case 
                WHERE Id = :caseId LIMIT 1];
            
            // Construct the template values
            List<TemplateValue> values = new List<TemplateValue>();
            
            values.add(new TemplateValue('caseNumber', caseRecord.CaseNumber));//ICS-1566
            values.add(new TemplateValue('generatedOn', String.valueOf(DateTime.now())));//ICS-1566

            if(String.isBlank(caseRecord.ID_Number__c)){//Claimant ID Number is white space, empty (''), or null
                values.add(new TemplateValue('title', caseRecord.Account.Salutation));
                values.add(new TemplateValue('surname', caseRecord.Account.LastName));
                values.add(new TemplateValue('firstName', caseRecord.Account.FirstName));
                values.add(new TemplateValue('fullName', caseRecord.Account.Name));
                values.add(new TemplateValue('middleName', caseRecord.Account.MiddleName));
                values.add(new TemplateValue('idType', '1'));
                values.add(new TemplateValue('idNumber', caseRecord.Account.Identity_Number__c));
                values.add(new TemplateValue('clientEmail', caseRecord.Account.PersonEmail));
                values.add(new TemplateValue('cellphone', caseRecord.Account.Phone));
                values.add(new TemplateValue('initials', caseRecord.Account.Initials__c));
            }
            
            else{//claimant
                String fullname = caseRecord.First_Name__c + 
                  (String.isBlank(caseRecord.IC_Claimant_Middle_Name__c) ? '' : ' ' + caseRecord.IC_Claimant_Middle_Name__c) + 
                  ' ' + caseRecord.Surname__c;
                values.add(new TemplateValue('title', caseRecord.Title__c));
                values.add(new TemplateValue('surname', caseRecord.Surname__c));
                values.add(new TemplateValue('firstName', caseRecord.First_Name__c));
                values.add(new TemplateValue('fullName', fullname));
                values.add(new TemplateValue('middleName', caseRecord.IC_Claimant_Middle_Name__c));
                values.add(new TemplateValue('idType', '1'));
                values.add(new TemplateValue('idNumber', caseRecord.ID_Number__c));
                values.add(new TemplateValue('clientEmail', caseRecord.Email_Address__c));
                values.add(new TemplateValue('cellphone', caseRecord.Mobile_Number__c));
                values.add(new TemplateValue('initials', caseRecord.IC_Claimant_Initials__c));
            }

			System.debug('RIDWAN values: ' + values);

            // Construct the request body
            Client clientWrapper = new Client(caseRecord.Account.CIF_Number__c, caseRecord.Account.Identity_Number__c);
            TemplateRequest requestBody = new TemplateRequest(3003, 3003, values, 'Claim Note.pdf', clientWrapper, 'FuneralClaimsNote');
            String jsonBody = JSON.serialize(requestBody);
            System.debug('jsonBody: ' + jsonBody);
            
            // Create the HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:NC_CapiInsure/insure/document/v1/generate-and-store');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            
            // Send the HTTP request
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Status code: ' + res.getStatusCode());
            System.debug('Response body: ' + res.getBody());
            
            // Handle the response
            if (res.getStatusCode() == 200) {
                ResponseWrapper response = (ResponseWrapper) JSON.deserialize(res.getBody(), ResponseWrapper.class);
                caseRecord.IC_Claims_Note_Ext_Doc_ID__c = response.id;
                caseRecord.IC_Send_Funeral_Plan_Claims_Note__c = true;
                update caseRecord;
                results.add('Pass');
            } else {
                results.add('Request failed: ' + res.getStatusCode() + ' ' + res.getStatus());
            }
        } catch (Exception e) {
            results.add('Error occurred for Case ' + caseId + ': ' + e.getMessage());
        }
        
        
        return results;
    }
}