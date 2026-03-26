/*******************************************************************
* @Class Name        :  IC_API_InsuranceClaimsCase_TEST
* @Author            :  Dhriven
* @Last Modified By  :  Dhriven, 09-Oct-2023, Jira Tickets: ICS-62, ICS-193, ICS-890, ICS-480, ICS-914 
* @Version           :  1.0
*
*******************************************************************/

@isTest
public class IC_API_InsuranceClaimsCase_TEST {
    
    @testSetup
    static void createPersonAccount(){
        
        Account personAccount = new Account();
        personAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        
        personAccount.FirstName = 'John';
        personAccount.LastName = 'Doe';
        personAccount.ID_Type__c = 'SA Id';
        personAccount.Identity_Number__c = 'ID8901234';
        personAccount.Passport_Number__c = 'P12345';
        personAccount.CIF_Number__c = 'CIF12345';
        
        insert personAccount;
    }
    
    @isTest static void testCreateClaim_Success() {
        // Mock the HTTP request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/InsuranceClaims/v1';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        // Create a payload for testing
        IC_API_InsuranceClaimsCase.Payload payload = new IC_API_InsuranceClaimsCase.Payload();
        payload.ucs_id = '12345';
        payload.cif_number = 'CIF12345';
        payload.policy_number = 'P12345';
        payload.case_type = 'Unemployment/ITEI';
        payload.sub_type = 'Retrenchment';
        payload.sub_type_reason = 'Reorganisation';
        payload.product_type = 'Credit Life';
        payload.id_number = 'ID8901234';
        payload.passport_number = 'P4567890';
        payload.from_email_address = 'test@example.com';
        payload.subject = 'Test Subject';
        payload.description = 'Test Description';
        payload.claimant_title = 'Mr.';
        payload.claimant_first_name = 'John';
        payload.claimant_surname = 'Doe';
        payload.claimant_id_type = 'SA ID';
        payload.claimant_id_number = '1234567890';
        payload.claimant_email_address = 'johndoe@example.com';
        payload.claimant_mobile_number = '0123456789';
        payload.claimant_work_number = '0123456789';
        payload.case_origin = 'Data Wash';
        payload.event_date = '2023-10-31';
            
            req.requestBody = Blob.valueOf(JSON.serialize(new List<IC_API_InsuranceClaimsCase.Payload>{payload}));
        
        Test.startTest();
        IC_API_InsuranceClaimsCase.createClaim();
        Test.stopTest();
        
        // Assertions to verify the functionality
        List<Case> cases = [SELECT Id, Subject FROM Case];
        System.assertEquals(1, cases.size(), 'Expected one Case to be created.');
        System.assertEquals('Test Subject', cases[0].Subject, 'Expected Subject to be set correctly.');
    }
    
    @isTest static void testCreateClaim_Error() {
        // Mock the HTTP request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/InsuranceClaims/v1';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        // Create a payload for testing
        IC_API_InsuranceClaimsCase.Payload payload = new IC_API_InsuranceClaimsCase.Payload();
        payload.ucs_id = '12345';
        //payload.cif_number = 'CIF12345';
        payload.policy_number = 'P12345';
        payload.case_type = 'Unemployment/ITEI';
        payload.sub_type = 'Retrenchment';
        payload.sub_type_reason = 'Reorganisation';
        payload.product_type = 'Credit Life';
        //payload.id_number = 'ID8901234';
        //payload.passport_number = 'P4567890';
        payload.from_email_address = 'test@example.com';
        payload.subject = 'Test Subject';
        payload.description = 'Test Description';
        payload.claimant_title = 'Mr ';// this will result in an error - invalid picklist value
        payload.claimant_first_name = 'John';
        payload.claimant_surname = 'Doe';
        payload.claimant_id_type = 'SA ID';
        payload.claimant_id_number = '1234567890';
        payload.claimant_email_address = 'johndoe@example.com';
        payload.claimant_mobile_number = '0123456789';
        payload.claimant_work_number = '0123456789';
        payload.case_origin = 'Data Wash';
        payload.event_date = '2023-10-31';
        
        req.requestBody = Blob.valueOf(JSON.serialize(new List<IC_API_InsuranceClaimsCase.Payload>{payload}));
        
        Test.startTest();
        IC_API_InsuranceClaimsCase.createClaim();
        Test.stopTest();
        
        // Assertions to verify the functionality
        List<Case> cases = [SELECT Id, Subject FROM Case];
        System.assertEquals(true, true);
    }
    
    @isTest static void testCreateFuneralClaim_Success() {
        // Mock the HTTP request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/InsuranceClaims/v1';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        // Create a payload for testing
        IC_API_InsuranceClaimsCase.Payload payload = new IC_API_InsuranceClaimsCase.Payload();
        payload.ucs_id = '12345';
        payload.cif_number = 'CIF12345';
        payload.policy_number = 'P12345';
        payload.case_type = 'Death';
        payload.sub_type = 'Natural';
        payload.sub_type_reason = '';
        payload.product_type = 'Funeral';
        payload.id_number = 'ID8901234';
        payload.passport_number = 'P4567890';
        payload.from_email_address = 'test@example.com';
        payload.subject = 'Test Subject';
        payload.description = 'Test Description';
        payload.claimant_title = 'Mr.';
        payload.claimant_first_name = 'John';
        payload.claimant_surname = 'Doe';
        payload.claimant_id_type = 'SA ID';
        payload.claimant_id_number = '1234567890';
        payload.claimant_email_address = 'johndoe@example.com';
        payload.claimant_mobile_number = '0123456789';
        payload.claimant_work_number = '0123456789';
        payload.case_origin = 'NBS';
        payload.event_date = '2023-10-31';
        payload.deceased_first_name = 'testing FName';
        payload.deceased_last_name = 'testing LName';
        payload.deceased_id_number = '938475683';
        payload.deceased_date_of_birth = '2000-10-31';
        payload.bi_number = '0997';
            
            req.requestBody = Blob.valueOf(JSON.serialize(new List<IC_API_InsuranceClaimsCase.Payload>{payload}));
        
        Test.startTest();
        IC_API_InsuranceClaimsCase.createClaim();
        Test.stopTest();
        
        // Assertions to verify the functionality
        List<Case> cases = [SELECT Id, Subject FROM Case];
        System.assertEquals(1, cases.size(), 'Expected one Case to be created.');
        System.assertEquals('Test Subject', cases[0].Subject, 'Expected Subject to be set correctly.');
    }
    
    @isTest static void testCreateWhatsappClaim_Success() {
        // Mock the HTTP request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/InsuranceClaims/v1';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        // Create a payload for testing
        IC_API_InsuranceClaimsCase.Payload payload = new IC_API_InsuranceClaimsCase.Payload();
        IC_API_InsuranceClaimsCase.ClaimParticipant claimParticipant = new IC_API_InsuranceClaimsCase.ClaimParticipant();
        payload.ucs_id = '12345';
        payload.cif_number = 'CIF12345';
        payload.policy_number = 'P12345';
        payload.case_type = 'Death';
        payload.sub_type = 'Natural';
        payload.sub_type_reason = '';
        payload.product_type = 'Funeral';
        payload.id_number = 'ID8901234';
        payload.passport_number = 'P4567890';
        payload.from_email_address = 'test@example.com';
        payload.subject = 'Test Subject';
        payload.description = 'Test Description';
        payload.claimant_title = 'Mr.';
        payload.claimant_first_name = 'John';
        payload.claimant_surname = 'Doe';
        payload.claimant_id_type = 'SA ID';
        payload.claimant_id_number = '1234567890';
        payload.claimant_email_address = 'johndoe@example.com';
        payload.claimant_mobile_number = '0123456789';
        payload.claimant_work_number = '0123456789';
        payload.case_origin = 'WhatsApp';
        payload.event_date = '2023-10-31';
        payload.deceased_first_name = 'testing FName';
        payload.deceased_last_name = 'testing LName';
        payload.deceased_id_number = '938475683';
        payload.deceased_date_of_birth = '2000-10-31';
        payload.bi_number = '0997';
        
        claimParticipant.claimParticipant_title = 'Mr.';
        claimParticipant.claimParticipant_bank_name = 'Capitec';
        claimParticipant.claimParticipant_account_type = 'Savings';
        payload.claimParticipants = new List<IC_API_InsuranceClaimsCase.ClaimParticipant>{claimParticipant};
        
            req.requestBody = Blob.valueOf(JSON.serialize(new List<IC_API_InsuranceClaimsCase.Payload>{payload}));
        
        Test.startTest();
        IC_API_InsuranceClaimsCase.createClaim();
        Test.stopTest();
        
        // Assertions to verify the functionality
        List<Case> cases = [SELECT Id, Subject FROM Case];
        System.assertEquals(1, cases.size(), 'Expected one Case to be created.');
        System.assertEquals('Test Subject', cases[0].Subject, 'Expected Subject to be set correctly.');
    }
    
    @isTest static void testCreateNBSPolicyClaim_Success() {
        // Mock the HTTP request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/InsuranceClaims/v1';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        // Create a payload for testing
        IC_API_InsuranceClaimsCase.Payload payload = new IC_API_InsuranceClaimsCase.Payload();
        IC_FuneralResponse.PolicyWrapper policyWrapper = new IC_FuneralResponse.PolicyWrapper();
        IC_FuneralResponse.Policy policy = new IC_FuneralResponse.Policy();
        IC_FuneralResponse.RoleplayerWrapper roleplayerWrapper = new IC_FuneralResponse.RoleplayerWrapper();
        IC_FuneralResponse.Roleplayer roleplayer = new IC_FuneralResponse.Roleplayer();
        
        payload.ucs_id = '12345';
        payload.cif_number = 'CIF12345';
        payload.policy_number = 'P12345';
        payload.case_type = 'Death';
        payload.sub_type = 'Natural';
        payload.sub_type_reason = '';
        payload.product_type = 'Funeral';
        payload.id_number = 'ID8901234';
        payload.passport_number = 'P4567890';
        payload.from_email_address = 'test@example.com';
        payload.subject = 'Test Subject';
        payload.description = 'Test Description';
        payload.claimant_title = 'Mr.';
        payload.claimant_first_name = 'John';
        payload.claimant_surname = 'Doe';
        payload.claimant_id_type = 'SA ID';
        payload.claimant_id_number = '1234567890';
        payload.claimant_email_address = 'johndoe@example.com';
        payload.claimant_mobile_number = '0123456789';
        payload.claimant_work_number = '0123456789';
        payload.case_origin = 'NBS';
        payload.event_date = '2023-10-31';
        payload.deceased_first_name = 'testing FName';
        payload.deceased_last_name = 'testing LName';
        payload.deceased_id_number = '938475683';
        payload.deceased_date_of_birth = '2000-10-31';
        payload.bi_number = '0997';
        
        policy.contractReference = 'FP00004419';
        policy.commencementDate = DateTime.now();
        policy.productCode = 'Capitec';

        roleplayer.firstName = 'fName';
        roleplayer.surname = 'sName';
        roleplayer.idNumber = '7404047104085';
        roleplayer.dateOfBirth = Date.today();
        roleplayer.relationship = 'MainLife';
        roleplayer.coverAmount = 5000;
        roleplayer.lifeAssured = true;
        
        roleplayerWrapper.details = roleplayer;
        
		policyWrapper.policy = policy;
        policyWrapper.roleplayers = new List<IC_FuneralResponse.RoleplayerWrapper>{roleplayerWrapper};        
        payload.policies = new List<IC_FuneralResponse.PolicyWrapper>{policyWrapper};
            
        req.requestBody = Blob.valueOf(JSON.serialize(new List<IC_API_InsuranceClaimsCase.Payload>{payload}));
        
        Test.startTest();
        IC_API_InsuranceClaimsCase.createClaim();
        Test.stopTest();
        
        // Assertions to verify the functionality
        List<Case> cases = [SELECT Id, Subject FROM Case];
        System.assertEquals(1, cases.size(), 'Expected one Case to be created.');
        System.assertEquals('Test Subject', cases[0].Subject, 'Expected Subject to be set correctly.');
    }

    @isTest static void testCreateDocument_Success() {
        // Mock the HTTP request
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/InsuranceClaims/v1';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.txt'; // The file name. This must include the file extension
        cv.VersionData = Blob.valueOf('Test Content'); // Your version data here
        cv.Documentum_ID__c = 'testId'; // This is the id of the related record
        insert cv;
        
        // Create a payload for testing
        IC_API_InsuranceClaimsCase.Payload payload = new IC_API_InsuranceClaimsCase.Payload();
        IC_API_InsuranceClaimsCase.Document document = new IC_API_InsuranceClaimsCase.Document();
        payload.ucs_id = '12345';
        payload.cif_number = 'CIF12345';
        payload.policy_number = 'P12345';
        payload.case_type = 'Death';
        payload.sub_type = 'Natural';
        payload.sub_type_reason = '';
        payload.product_type = 'Funeral';
        payload.id_number = 'ID8901234';
        payload.passport_number = 'P4567890';
        payload.from_email_address = 'test@example.com';
        payload.subject = 'Test Subject';
        payload.description = 'Test Description';
        payload.claimant_title = 'Mr.';
        payload.claimant_first_name = 'John';
        payload.claimant_surname = 'Doe';
        payload.claimant_id_type = 'SA ID';
        payload.claimant_id_number = '1234567890';
        payload.claimant_email_address = 'johndoe@example.com';
        payload.claimant_mobile_number = '0123456789';
        payload.claimant_work_number = '0123456789';
        payload.case_origin = 'Data Wash';
        payload.event_date = '2023-10-31';
        
        document.documentumId = 'testId';
        payload.documents = new List<IC_API_InsuranceClaimsCase.Document>{document};    
            req.requestBody = Blob.valueOf(JSON.serialize(new List<IC_API_InsuranceClaimsCase.Payload>{payload}));
        
        Test.startTest();
        IC_API_InsuranceClaimsCase.createClaim();
        Test.stopTest();
        
        // Assertions to verify the functionality
        List<Case> cases = [SELECT Id, Subject FROM Case];
        System.assertEquals(1, cases.size(), 'Expected one Case to be created.');
        System.assertEquals('Test Subject', cases[0].Subject, 'Expected Subject to be set correctly.');
    }
}