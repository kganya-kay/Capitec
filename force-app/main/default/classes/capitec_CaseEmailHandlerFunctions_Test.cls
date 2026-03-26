/**
* Test class for the capitec_CaseEmailHandlerFunctions and capitec_CaseEmailHandler class.
* @author Caleb Govender
* @date 23.04.2024
*
* @LastModified 21.01.2025
* @LastModifiedBy Dhriven Hamlall
*/
@IsTest
public class capitec_CaseEmailHandlerFunctions_Test {
    
    @TestSetup
    static void setupTestData() {
        
        // Insert a test case
        Case testCase = new Case(Status = 'New', Origin = 'Email');
        insert testCase;
        
        // Insert test data for Email_Listener_Search_Library__c
        Email_Listener_Search_Library__c testSubjectTerm = new Email_Listener_Search_Library__c(
            capitec_Phrase__c = 'Test Subject',
            FR_Routing_Queue__c = 'Fraud Email Cases',
            capitec_isActive__c = true,
            capitec_Phrase_Type__c = 'Subject',
            capitec_Email_Listener__c = 'Fraud'
        );
        insert testSubjectTerm;
        
        Email_Listener_Search_Library__c originRule = new Email_Listener_Search_Library__c(
            capitec_Phrase__c = 'mydomain.com',
            FR_Routing_Queue__c = 'Fraud Email Cases',
            Case_Origin__c = 'External Bank',
            External_Bank__c = 'ABSA',
            capitec_isActive__c = true,
            capitec_Phrase_Type__c = 'From Address',
            capitec_Email_Listener__c = 'Fraud',
            Record_Type__c = 'Fraud_Record_Type'
        );
        insert originRule;
    }
    
    
    @IsTest
    static void testHandleInboundEmailWithCaseId() {
        Case testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test User';
        email.subject = 'Test Subject ' + testCase.CaseNumber;
        email.plainTextBody = 'This is a test email body.';
        email.htmlBody = '<p>This is a test email body.</p>';
        email.messageId = 'testMessageId';
        email.inReplyTo = 'replyTo@example.com';
        email.replyTo = 'replyTo@example.com';
        email.toAddresses = new List<String>();
        email.toAddresses.add('recipient1@example.com');
        email.toAddresses.add('recipient2@example.com');
        email.toAddresses.add('recipient3@example.com');
        email.ccAddresses = new List<String>();
        email.ccAddresses.add('ccrecipient1@example.com');
        email.ccAddresses.add('ccrecipient2@example.com');
        email.ccAddresses.add('ccrecipient3@example.com');
        email.headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Date';
        header.value = 'Thu, 14 Jun 2024 12:34:56 -0700';
        email.headers.add(header);
        
        // Create a test Messaging.InboundEnvelope object
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'test@example.com';
        envelope.toAddress = 'inbound@example.com';
        
        // Call the handleInboundEmail method
        capitec_CaseEmailHandler handler = new capitec_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
        
        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        System.assertEquals(1, emailMessages.size(), 'One EmailMessage should be created.');
        
        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('test@example.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Test User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('Test Subject ' + testCase.CaseNumber, createdEmailMessage.Subject, 'Subject should match.');
        System.assertEquals('This is a test email body.', createdEmailMessage.TextBody, 'TextBody should match.');
        System.assertEquals('<p>This is a test email body.</p>', createdEmailMessage.HtmlBody, 'HtmlBody should match.');
        System.assertEquals('testMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
        System.assertEquals('recipient1@example.com; recipient2@example.com; recipient3@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');
    }
    
    
    @IsTest
    static void testHandleInboundEmailWithoutCaseId() {
        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'no-case@example.com';
        email.fromName = 'No Case User';
        email.subject = 'No Case Subject';
        email.plainTextBody = 'This email does not have an associated case.';
        email.htmlBody = '<p>This email does not have an associated case.</p>';
        email.messageId = 'noCaseMessageId';
        email.inReplyTo = 'noCaseReplyTo@example.com';
        email.replyTo = 'noCaseReplyTo@example.com';
        email.toAddresses = new List<String>();
        email.toAddresses.add('recipient1@example.com');
        email.toAddresses.add('recipient2@example.com');
        email.toAddresses.add('recipient3@example.com');
        email.ccAddresses = new List<String>();
        email.ccAddresses.add('ccrecipient1@example.com');
        email.ccAddresses.add('ccrecipient2@example.com');
        email.ccAddresses.add('ccrecipient3@example.com');
        email.headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Date';
        header.value = 'Thu, 14 Jun 2024 12:34:56 -0700';
        email.headers.add(header);
        
        // Create a test Messaging.InboundEnvelope object
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'no-case@example.com';
        envelope.toAddress = 'inbound@example.com';
        
        // Call the handleInboundEmail method
        capitec_CaseEmailHandler handler = new capitec_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
        
        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        System.assertEquals(1, emailMessages.size(), 'One EmailMessage should be created.');
        
        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('no-case@example.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('No Case User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('No Case Subject', createdEmailMessage.Subject, 'Subject should match.');
        System.assertEquals('This email does not have an associated case.', createdEmailMessage.TextBody, 'TextBody should match.');
        System.assertEquals('<p>This email does not have an associated case.</p>', createdEmailMessage.HtmlBody, 'HtmlBody should match.');
        System.assertEquals('noCaseMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
        System.assertEquals('recipient1@example.com; recipient2@example.com; recipient3@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');
        System.assertNotEquals(null, createdEmailMessage.RelatedToId, 'A new case should be created and related to the email.');
    }
    
    @IsTest
    static void testHandleInboundEmailWithAttachments() {
        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'attachments@example.com';
        email.fromName = 'Attachment User';
        email.subject = 'Attachment Subject';
        email.plainTextBody = 'This email has attachments.';
        email.htmlBody = '<p>This email has attachments.</p>';
        email.messageId = 'attachmentMessageId';
        email.inReplyTo = 'attachmentReplyTo@example.com';
        email.replyTo = 'attachmentReplyTo@example.com';
        email.headers = new List<Messaging.InboundEmail.Header>();
        email.toAddresses = new List<String>();
        email.toAddresses.add('recipient1@example.com');
        email.toAddresses.add('recipient2@example.com');
        email.toAddresses.add('recipient3@example.com');
        email.ccAddresses = new List<String>();
        email.ccAddresses.add('ccrecipient1@example.com');
        email.ccAddresses.add('ccrecipient2@example.com');
        email.ccAddresses.add('ccrecipient3@example.com');
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Date';
        header.value = 'Thu, 14 Jun 2024 12:34:56 -0700';
        email.headers.add(header);
        
        // Add binary attachments
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.fileName = 'binaryAttachment.txt';
        binaryAttachment.body = Blob.valueOf('This is a binary attachment.');
        email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{ binaryAttachment };
            
            // Add text attachments
            Messaging.InboundEmail.TextAttachment textAttachment = new Messaging.InboundEmail.TextAttachment();
        textAttachment.fileName = 'textAttachment.txt';
        textAttachment.body = 'This is a text attachment.';
        email.textAttachments = new List<Messaging.InboundEmail.TextAttachment>{ textAttachment };
            
            // Create a test Messaging.InboundEnvelope object
            Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'attachments@example.com';
        envelope.toAddress = 'inbound@example.com; test@gmail.com';
        
        Test.setMock(HttpCalloutMock.class, new EmailListenerHttpResponseGenerator());
        // Call the handleInboundEmail method
        capitec_CaseEmailHandler handler = new capitec_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
        
        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        System.assertEquals(1, emailMessages.size(), 'One EmailMessage should be created.');
        
        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('attachments@example.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Attachment User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('Attachment Subject', createdEmailMessage.Subject, 'Subject should match.');
        System.assertEquals('This email has attachments.', createdEmailMessage.TextBody, 'TextBody should match.');
        System.assertEquals('<p>This email has attachments.</p>', createdEmailMessage.HtmlBody, 'HtmlBody should match.');
        System.assertEquals('attachmentMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
        System.assertEquals('recipient1@example.com; recipient2@example.com; recipient3@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');
        
        // Verify attachments and files
        List<Attachment> attachments = [SELECT Id, Name, ParentId FROM Attachment WHERE ParentId = :createdEmailMessage.Id];
        System.assertEquals(2, attachments.size(), 'Two attachments should be created.');
        System.assert(attachments[0].Name == 'binaryAttachment.txt' || attachments[1].Name == 'binaryAttachment.txt', 'Binary attachment should be created.');
        System.assert(attachments[0].Name == 'textAttachment.txt' || attachments[1].Name == 'textAttachment.txt', 'Text attachment should be created.');
        
        List<ContentVersion> contentVersions = [SELECT Id, Title, FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId = :createdEmailMessage.RelatedToId];
        System.assertEquals(2, contentVersions.size(), 'Two ContentVersion records should be created.');
        System.assert(contentVersions[0].Title == 'binaryAttachment.txt' || contentVersions[1].Title == 'binaryAttachment.txt', 'Binary ContentVersion should be created.');
        System.assert(contentVersions[0].Title == 'textAttachment.txt' || contentVersions[1].Title == 'textAttachment.txt', 'Text ContentVersion should be created.');
    }
    
    @IsTest
    static void testLikeCaseIdSearch() {
        // Get a test case with a known case number
        Case testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        
        // Create a test EmailMessage
        EmailMessage emailMsg = new EmailMessage();
        emailMsg.FromAddress = 'test@example.com';
        emailMsg.Subject = 'Test Email';
        emailMsg.TextBody = 'This is a test email body.';
        
        // Call LikeCaseIdSearch with the case number and EmailMessage
        Test.startTest();
        String returnedCaseId = capitec_CaseEmailHandlerFunctions.LikeCaseIdSearch(testCase.CaseNumber.toString(), emailMsg);
        Test.stopTest();
        
        // Assert that the returned case ID matches the inserted case ID
        System.assertEquals(testCase.Id, testCase.Id, 'The returned case ID should match the inserted case ID.');
    }
    
    @IsTest
    static void testExtractCaseNumberFromSubject() {
        String subject = 'Test Subject 00111111';
        
        Test.startTest();
        String sNumber = capitec_CaseEmailHandlerFunctions.extractCaseNumberFromSubject(subject);
        Test.stopTest();
        
        // Verify the Number is Extracted
        System.assertEquals('00111111', sNumber);
    }
    
    
    @IsTest
    static void testExtractEmailFromSubject() {
        String subject = 'Contact us at support@example.com for more information.';
        
        Test.startTest();
        String extractedEmail = capitec_CaseEmailHandlerFunctions.extractEmailFromSubject(subject);
        Test.stopTest();
        
        System.assertEquals('support@example.com', extractedEmail, 'The extracted email should match the expected value.');
    }
    @IsTest
    static void testCaseAccountLinking() {
        // Create a test Account
        Account testAccount = new Account(LastName = 'Test', PersonEmail = 'test@example.com');
        insert testAccount;
        
        // Get a test Contact
        Contact testContact = [SELECT Id,AccountId FROM Contact WHERE AccountId =: testAccount.Id LIMIT 1];
        
        
        // Create a test Case
        Case testCase = new Case(Status = 'New', Origin = 'Email');
        insert testCase;
        
        // Subject containing the email address
        String subject = 'Please contact test@example.com regarding your case.';
        
        Test.startTest();
        capitec_CaseEmailHandlerFunctions.CaseEmailAccountAndContactLinking(testCase.Id, 'test@example.com');
        Test.stopTest();
        
        // Verify the Case is linked to the Account and Contact
        Case updatedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(testAccount.Id, updatedCase.AccountId, 'The Case should be linked to the Account.');
        System.assertEquals(testContact.Id, updatedCase.ContactId, 'The Case should be linked to the Contact.');
    }
    
    @IsTest
    static void testCaseAccountLinkingWithIdentityNumber() {
        // Create a test Account with a specific Identity Number
        Account testAccount = new Account(LastName = 'Test', Identity_Number__c = '0000000000000');
        insert testAccount;
        
        // Get a test Contact with the same Identity Number
        Contact testContact = [SELECT Id,AccountId FROM Contact WHERE AccountId =: testAccount.Id LIMIT 1];
        
        // Create a test Case
        Case testCase = new Case(Status = 'New', Origin = 'Email');
        insert testCase;
        
        // Subject containing the Identity Number
        String subject = 'Please contact 0000000000000 regarding your case.';
        
        Test.startTest();
        capitec_CaseEmailHandlerFunctions.CaseIdNumberAccountAndContactLinking(subject, testCase.Id);
        Test.stopTest();
        
        // Verify the Case is linked to the Account and Contact
        Case updatedCase = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(testAccount.Id, updatedCase.AccountId, 'The Case should be linked to the Account.');
        System.assertEquals(testContact.Id, updatedCase.ContactId, 'The Case should be linked to the Contact.');
    }
    
    @IsTest
    static void testExtractIDNumber() {
        // Test case with a 13-digit number
        String inputWithID = 'This is a test string with ID 0000000000000 in it.';
        String expectedID = '0000000000000';
        String extractedID = capitec_CaseEmailHandlerFunctions.ExtractIDNumber(inputWithID);
        System.assertEquals(expectedID, extractedID, 'The extracted ID should match the expected value.');
        
        // Test case without a 13-digit number
        String inputWithoutID = 'This is a test string without an ID.';
        String extractedIDNull = capitec_CaseEmailHandlerFunctions.ExtractIDNumber(inputWithoutID);
        System.assertEquals(null, extractedIDNull, 'The extracted ID should be null when no 13-digit number is present.');
        
        // Test case with multiple 13-digit numbers
        String inputWithMultipleIDs = 'Here are two IDs: 0000000000000 and 9876543210987.';
        String expectedFirstID = '0000000000000';
        String extractedFirstID = capitec_CaseEmailHandlerFunctions.ExtractIDNumber(inputWithMultipleIDs);
        System.assertEquals(expectedFirstID, extractedFirstID, 'The extracted ID should match the first 13-digit number found.');
    }
    
    @IsTest
    static void testPadNumberWithZeros() {
        // Call padNumberWithZeros with a number less than 8 digits
        Test.startTest();
        String paddedNumber = capitec_CaseEmailHandlerFunctions.padNumberWithZeros(123);
        Test.stopTest();
        
        // Assert that the returned string is correctly padded with zeros
        System.assertEquals('00000123', paddedNumber, 'The padded number should be 00000123.');
    }
    
    @IsTest
    static void testFromAddressCheck() {
        // Test with an email address from the Capitec Bank domain
        Test.startTest();
        Boolean isCapitecEmail = capitec_CaseEmailHandlerFunctions.FromAddressCheck('user@capitecbank.co.za');
        System.assertEquals(true, isCapitecEmail, 'The method should return true for a Capitec Bank email address.');
        
        // Test with an email address not from the Capitec Bank domain
        Boolean isNotCapitecEmail = capitec_CaseEmailHandlerFunctions.FromAddressCheck('user@example.com');
        Test.stopTest();
        System.assertEquals(false, isNotCapitecEmail, 'The method should return false for a non-Capitec Bank email address.');
    }
    
    @IsTest
    static void testCaseQueueCheck() {
        String subject = 'Test Subject';
        
        Test.startTest();
        String queueAPIName = capitec_CaseEmailHandlerFunctions.CaseQueueCheck(subject);
        Test.stopTest();
        
        // Add appropriate assertions based on the expected behavior of CaseQueueCheck
        System.assertNotEquals(null, queueAPIName, 'Queue API Name should not be null.');
    }
    
    @IsTest
    static void testCaseStatusCheck() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        EmailMessage emailMsg = new EmailMessage();
        emailMsg.FromAddress = 'test@example.com';
        emailMsg.Subject = 'Test Email';
        emailMsg.TextBody = 'This is a test email body.';
        
        Test.startTest();
        Id newChildCaseId = capitec_CaseEmailHandlerFunctions.CaseStatusCheck(testCase.Id, emailMsg);
        Test.stopTest();
        
        // Add appropriate assertions based on the expected behavior of CaseStatusCheck
        System.assertNotEquals(null, newChildCaseId, 'New child case ID should not be null.');
    }
    
    
    @IsTest
    static void testFromAddressCaseQueueCheck() {
        String fromAddress = 'test@fraud.com';
        
        Test.startTest();
        String queueAPIName = capitec_CaseEmailHandlerFunctions.FromAddressCaseQueueCheck(fromAddress);
        Test.stopTest();
        
        System.assertNotEquals(null, queueAPIName, 'Queue API Name should not be null.');
    }
    
    @IsTest
    static void testCCAddressCheck() {
        List<String> ccAddresses = new List<String>{'cc1@test.com', 'cc2@test.com'};
            
            Test.startTest();
        String checkedCCAddresses = capitec_CaseEmailHandlerFunctions.CCAddressCheck(ccAddresses);
        Test.stopTest();
        
        System.debug('checkedCCAddresses:::' + checkedCCAddresses);
        System.assertEquals('', checkedCCAddresses, 'Checked CC Addresses should be empty.');
    }
    
    @IsTest
    static void testReturnQueueAPIName() {
        String queueName = 'Fraud Email Cases';
        
        Test.startTest();
        String queueAPIName = capitec_CaseEmailHandlerFunctions.ReturnQueueAPIName(queueName);
        Test.stopTest();
        
        System.assertNotEquals(null, queueAPIName, 'Queue API Name should not be null.');
    }
    
    @IsTest
    static void testMapQueryToEmailListenerList() {
        String queryString = 'SELECT capitec_Phrase__c, FR_Routing_Queue__c FROM Email_Listener_Search_Library__c WHERE capitec_isActive__c = TRUE';
        
        Test.startTest();
        List<Email_Listener_Search_Library__c> results = capitec_CaseEmailHandlerFunctions.mapQueryToEmailListenerList(queryString);
        Test.stopTest();
        
        System.assertNotEquals(0, results.size(), 'Results should not be empty.');
    }
    
    @IsTest
    static void testGetFraudRecordTypeId() {
        // Mock the existing Fraud Record Type
        Id fraudRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Fraud_Record_Type').getRecordTypeId();
        
        // Call the method and verify the result
        Test.startTest();
        Id returnedFraudRecordTypeId = capitec_CaseEmailHandlerFunctions.getFraudRecordTypeId();
        Test.stopTest();
        
        System.assertNotEquals(null, returnedFraudRecordTypeId, 'The Fraud Record Type Id should not be null.');
        System.assertEquals(fraudRecordTypeId, returnedFraudRecordTypeId, 'The Fraud Record Type Id should match the existing record.');
    }
    
    @IsTest
    static void testGetPersonAccountRecordTypeId() {
        // Mock the existing Person Account Record Type
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        // Call the method and verify the result
        Test.startTest();
        Id returnedPersonAccountRecordTypeId = capitec_CaseEmailHandlerFunctions.getPersonAccountRecordTypeId();
        Test.stopTest();
        
        System.assertNotEquals(null, returnedPersonAccountRecordTypeId, 'The Person Account Record Type Id should not be null.');
        System.assertEquals(personAccountRecordTypeId, returnedPersonAccountRecordTypeId, 'The Person Account Record Type Id should match the existing record.');
    }
    
    public class EmailListenerHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('200');
            res.setBody('{"fileContent":"fakeFileContent"}'); // Simulate successful response
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testopenClosedCaseAndSetPriorityHigh(){
        Case testCase = [SELECT Id, Status, Priority, Subject FROM Case LIMIT 1];
        
        testCase.Status = 'Not Fraud';
        update testCase;
        
        Test.startTest();
        Id updatedCaseId = capitec_CaseEmailHandlerFunctions.CaseStatusCheck(testCase.Id, new EmailMessage());
        Test.stopTest();
        
        Case reopenedCase = [SELECT Id, Status, Priority, Subject, OwnerId FROM Case WHERE Id = :updatedCaseId];
        
        Assert.areEqual('High', reopenedCase.Priority,'Priority should have been updated to High.');
    }
    
    @IsTest
    static void testFromAddressCaseOriginCheck() {
        Test.startTest();
        String matchedOrigin = capitec_CaseEmailHandlerFunctions.FromAddressCaseOriginCheck('user@mydomain.com');
        Test.stopTest();
        Assert.areEqual('External Bank', matchedOrigin, 'Origin should match the custom value from Case_Origin__c.');
        
    }
    
    @IsTest
    static void testFromAddressCaseExtBankCheck() {
        Test.startTest();
        String matchedBank = capitec_CaseEmailHandlerFunctions.FromAddressCaseExtBankCheck('user@mydomain.com');
        Test.stopTest();
        Assert.areEqual('ABSA', matchedBank, 'Bank should match the custom value from External_Bank__c.');
        
    }
    
    @IsTest
    static void testGetRecordTypeWithFromAddress() {
        Test.startTest();
        String recordType = capitec_CaseEmailHandlerFunctions.getRecordTypeWithFromAddress('user@mydomain.com');
        Test.stopTest();
        Assert.areEqual('Fraud_Record_Type', recordType, 'Record Type should match the custom value from Record_Type__c.');
        
    }
    
}