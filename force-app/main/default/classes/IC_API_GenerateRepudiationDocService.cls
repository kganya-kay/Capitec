/*******************************************************************
* @Class Name        :  IC_API_GenerateRepudiationDocService
* @Test Class        :  IC_API_GenerateRepudDocService_Test
* @Author            :  Ram
* @Last Modified By  :  Ram, 07-Nov-2024, Jira Tickets: ICS-1368 
* @Version           :  1.0
*
*******************************************************************/
public with sharing class IC_API_GenerateRepudiationDocService {
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
        
        public Client(String cifNumber){
            this.cifNumber = cifNumber;
        }
    }
    
    public class TemplateRequest {
        public Integer templateId;
        public Integer templateDataId;
        public List<TemplateValue> templateValues;
        public String documentName;
        public Client client;
        
        public TemplateRequest(Integer templateId, Integer templateDataId, List<TemplateValue> templateValues, String documentName, Client client) {
            this.templateId = templateId;
            this.templateDataId = templateDataId;
            this.templateValues = templateValues;
            this.documentName = documentName;
            this.client = client;
        }
    }
    
    public class ResponseWrapper {
        public String id;
    }
    
    /**
     * @description
     * Invocable Method Send an HTTP request with template data for Repudiation Documnet Generation.
     * It generates payload and send it to API
     * @author Caleb Govender
     * @author Ram Gudla
     *
     * @param requests which contains caseId,repudiationLetter and repudiationLetterReason.
     */
    @InvocableMethod(label='Generate Repudiation Documnet Service' description='Send an HTTP request with template data for Repudiation Documnet Generation')
    public static List<String> generateRepudiationDocService(List<Requests> requests) {
        List<String> results = new List<String>();
        Id caseId = requests.get(0).caseId;
        String repudiationLetter = requests.get(0).repudiationLetter;
        String repudiationLetterReason = requests.get(0).repudiationLetterReason;
        try {
            
            Case caseRecord = [
                SELECT Id, CaseNumber, IC_Policy_Number_child__c,
                parent.IC_Deceased_Title__c,parent.IC_Deceased_First_Name__c,parent.IC_Deceased_Surname__c,
                IC_Deceased_Title__c,IC_Deceased_First_Name__c,IC_Deceased_Surname__c,
                IC_Decline_Reason__c,IC_2nd_Decline_Reason__c,parent.Cumulative_Sum_of_Payments__c,
                parent.Event_Date__c,IC_Beneficiary__r.IC_Name__c,IC_Beneficiary__r.IC_Surname__c,
                Account.CIF_Number__c,IC_Insurer_Underwriter_at_Event_Date__c,parentId,
                IC_Beneficiary__r.IC_Policy_Number__r.IC_Effective_Cancellation_Date__c
                FROM Case 
                WHERE Id = :caseId LIMIT 1];
            Map<String, String> tempIdDetails = new Map<String, String>{'Centriq' => '811', 'Capitec' => '3010'};
                
                list<IC_Repudiation_Letter_Details__mdt> repudiationDocDetails = [SELECT Id, Label, Template_Id__c, 
                                                                                  DeveloperName 
                                                                                  FROM IC_Repudiation_Letter_Details__mdt 
                                                                                  where Label=:repudiationLetter];
            String insurer = caseRecord.IC_Insurer_Underwriter_at_Event_Date__c;
            Integer templateDataId = Integer.valueOf(tempIdDetails.get(insurer));
            Integer tempId = Integer.valueOf(templateDataId+''+repudiationDocDetails.get(0).Template_Id__c);
            system.debug('------repudiationDocDetails--------'+repudiationDocDetails);
            String documentName = templateDataId+' '+repudiationDocDetails.get(0).Label+' Repudiation Template.pdf';
            String docTypeMasterLabel = '';
            if(insurer=='Centriq'){
                 docTypeMasterLabel=insurer+' repudiation letter - '+repudiationDocDetails.get(0).Label+'%draft';
            }
            else {
                 docTypeMasterLabel=insurer+' repudiation letter - '+repudiationDocDetails.get(0).Label;
            }
           
            List<TemplateValue> values = new List<TemplateValue>();
            values.add(new TemplateValue('our_reference', caseRecord.IC_Policy_Number_child__c));
            String yourReference = 'The late ' + caseRecord.parent.IC_Deceased_Title__c+' '+caseRecord.parent.IC_Deceased_First_Name__c+' '+caseRecord.parent.IC_Deceased_Surname__c;
            values.add(new TemplateValue('your_reference', yourReference));
            //String decline_reason = !String.isBlank(caseRecord.IC_2nd_Decline_Reason__c) ? caseRecord.IC_2nd_Decline_Reason__c : caseRecord.IC_Decline_Reason__c;
            values.add(new TemplateValue('decline_reason', repudiationLetterReason));
            values.add(new TemplateValue('deceased_name', caseRecord.parent.IC_Deceased_Title__c + ' ' + caseRecord.parent.IC_Deceased_First_Name__c + ' '+ caseRecord.parent.IC_Deceased_Surname__c));
            values.add(new TemplateValue('event_date', caseRecord.parent.Event_Date__c?.format()));
            values.add(new TemplateValue('client_name', caseRecord.IC_Beneficiary__r.IC_Name__c+' '+caseRecord.IC_Beneficiary__r.IC_Surname__c));
            String failed_premium_dates='';
            for(IC_Arrears__c arr:[SELECT ID, IC_Payment_Due_Date__c FROM IC_Arrears__c WHERE IC_Child_Case__c =:caseId ]){
                if(arr.IC_Payment_Due_Date__c!=null){
                    failed_premium_dates+=String.valueOf(arr.IC_Payment_Due_Date__c)+', ';
                }
                
            }
            failed_premium_dates = failed_premium_dates.trim();
            if(failed_premium_dates.length()>0){failed_premium_dates=failed_premium_dates.substring(0,failed_premium_dates.length()-1);}
            String max_amount = '100000';
            String totalPaid = String.valueOf(caseRecord.parent.Cumulative_Sum_of_Payments__c);
            if(repudiationLetter=='7-14 Child limits'){
                max_amount = '50000';
                totalPaid = '50000'; // ICS 1833; Dawid Kuczer; totalPaid to be hardcoded if age in '7-14' or '0-6' brackets
                if(insurer=='Centriq'){
                    docTypeMasterLabel='Centriq repudiation letter - Child limits 7-14 draft';
                }
            }
            else if(repudiationLetter=='0-6 Child limits'){
                max_amount = '20000';
                totalPaid = '20000'; // ICS 1833; Dawid Kuczer; totalPaid to be hardcoded if age in '7-14' or '0-6' brackets
                if(insurer=='Centriq'){
                    docTypeMasterLabel='Centriq repudiation letter - Child limits 0-6 draft';
                }
            }

            values.add(new TemplateValue('total_paid', totalPaid)); // ICS 1833; Dawid Kuczer; totalPaid to be hardcoded if age in '7-14' or '0-6' brackets
            values.add(new TemplateValue('max_amount', max_amount));
            values.add(new TemplateValue('failed_premium_dates',failed_premium_dates));
            if(caseRecord.parent.Event_Date__c!=null){values.add(new TemplateValue('cover_start_date', getCoverStartDate(caseRecord.parentId,caseRecord.parent.Event_Date__c)));}
            values.add(new TemplateValue('cancelled_date', String.valueOf(caseRecord.IC_Beneficiary__r.IC_Policy_Number__r.IC_Effective_Cancellation_Date__c)));
            
            Client clientWrapper = new Client(caseRecord.Account.CIF_Number__c);
            TemplateRequest requestBody = new TemplateRequest(templateDataId,tempId, values, documentName,clientWrapper);
            
            String jsonBody = JSON.serialize(requestBody);
            System.debug('jsonBody: ' + jsonBody);
            
            // Create the HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:NC_CapiInsure/insure/document/v2/generate-and-store');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(20000);
            req.setBody(jsonBody);
            
            // Send the HTTP request
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Status code: ' + res.getStatusCode());
            System.debug('Response body: ' + res.getBody());
            
            // Handle the response
            if (res.getStatusCode() == 200) {
                String taskrecTypeId = Schema.getGlobalDescribe().get('Task').getDescribe().getRecordTypeInfosByDeveloperName().get('Insurance_Claims_Task').getRecordTypeId();
                ResponseWrapper response = (ResponseWrapper) JSON.deserialize(res.getBody(), ResponseWrapper.class);
                list<DocumentType> dt = [SELECT MasterLabel, Description FROM DocumentType where MasterLabel like :docTypeMasterLabel limit 1];
                insert new DocumentChecklistItem(ParentRecordId =caseId,IC_ExternalContentDocumentId__c = response.id, Name = documentName, Status = 'Verified',Instruction='Repudiation Template',DocumentTypeId=dt?.get(0)?.Id);
                
                insert new task(
                    recordtypeid=taskRecTypeId,
                    subject='Generate Repudiation Letter',
                    Status_Code__c = res.getStatusCode(),
                    status='Completed', 
                    Response__c = 'Repudiation Letter generated successfully.',
                    OwnerId = UserInfo.getUserId(),
                    WhatId = caseId,
                    //Type = 'Notification',
                    Priority = 'Normal',
                    ActivityDate = System.today(),
                     Description=repudiationLetterReason!=null?repudiationLetter+' - '+repudiationLetterReason:repudiationLetter 
                    //Source_System__c = 'Salesforce'
                );
                results.add('Pass');
            } else {
                results.add('Request failed: ' + res.getStatusCode() + ' ' + res.getStatus()+' '+res.getBody());
            }
        } catch (Exception e) {
            results.add('Error occurred for Case ' + caseId + ': ' + e.getStackTraceString()+':'+e.getMessage());
        }
        return results;
    }
    /**
     * @description
     * This method to identify the Cover Start Date from the segments records based on the policy details.
     * @author Caleb Govender
     * @author Ram Gudla
     *
     * @param caseId current Case Id.
     * @param eventDate - parent case event date value
     */
    public static string getCoverStartDate(String caseId,Date eventDate){
        map<integer,date> datesmap = new map<integer,date>();
        for(IC_Segment__c ics:[select id, IC_Start_Date__c from IC_Segment__c where IC_Start_Date__c!=null and IC_Policy_Participant__r.IC_Case__c=:caseId and IC_End_Date__c>:Date.today()]){
            Integer monthDiff = ics.IC_Start_Date__c.monthsBetween(eventDate);
            if(monthDiff<=6){
                datesmap.put(monthDiff,ics.IC_Start_Date__c);
            }
        }
        if(!datesmap.isEmpty()){
            list<Integer> ints = new list<Integer>(datesmap.keySet());
            ints.sort();
            return String.valueOf(datesmap.get(ints.get(ints.size()-1)));
        }
        return null;        
    }
    public class Requests {
        @InvocableVariable(Label='Child Case Id')
        public String caseId;
        @InvocableVariable(Label='Repudiation Letter')
        public String repudiationLetter;
        @InvocableVariable(Label='Repudiation Letter Reason')
        public String repudiationLetterReason;
    }
}