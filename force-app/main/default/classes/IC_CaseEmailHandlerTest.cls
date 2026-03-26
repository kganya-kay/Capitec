@IsTest
private class IC_CaseEmailHandlerTest {

    @TestSetup
    static void setupTestData() {

        String INSURANCE_CLAIMS_REC_TYPE_DEV_NAME = 'Insurance_Claims';
        Id insuranceClaimsRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(INSURANCE_CLAIMS_REC_TYPE_DEV_NAME).getRecordTypeId();

        // Insert a test case
        Case testCase = new Case(
                Status = 'New',
                Subject = ' STRACK IS 2182323491 claim for policy CF23954234',
                Origin = 'Email',
                IC_Sanlam_Claim__c = true,
                RecordTypeId = insuranceClaimsRecordType
                );
        insert testCase;

        // Insert a test case
        Case testCase2 = new Case(
                Status = 'New',
                Origin = 'Email',
                IC_Sanlam_Claim__c = false,
                Product_Type__c = 'Funeral',
                RecordTypeId = insuranceClaimsRecordType
                );
        insert testCase2;
        
        update new Case(
            Id = testCase2.Id, 
            IC_Sanlam_Claim__c = false
        );
        
//        // Insert a test case
//        Case testCase3 = new Case(Status = 'New', Origin = 'Email', IC_Sanlam_Claim__c = false);
//        insert testCase3;

        //GET QUEUE OWNER
        Group sanlamAssessmentQueue = [SELECT Id, Name FROM Group WHERE DeveloperName = 'IC_Waiting_for_Sanlam_Assessment'];
        Case testCase3 = new Case(
                Status = 'New',
                Subject = 'Test 999999999 claim',
                Origin = 'Email',
                IC_Sanlam_Claim__c = true,
                RecordTypeId = insuranceClaimsRecordType,
                OwnerId = sanlamAssessmentQueue.Id);

        List<Case> casesToInsert = New List<Case>();
        casesToInsert.add(testCase3);
        //insert testCase3;

        //GET QUEUE OWNER
        Case testCase4 = new Case(
                Status = 'New',
                Subject = 'Test 77777777 Non-sanlam claim',
                Origin = 'Email',
                IC_Sanlam_Claim__c = false,
                RecordTypeId = insuranceClaimsRecordType,
                OwnerId = sanlamAssessmentQueue.Id);
        //insert testCase4;
        casesToInsert.add(testCase4);

        Group waitingSanlamQueue = [SELECT Id, Name FROM Group WHERE DeveloperName = 'IC_Waiting_for_Sanlam_Assessment'];
        Case testCase5 = new Case(
                Status = 'Closed',
                Subject = 'Test 999999999 claim CLOSED',
                Origin = 'Email',
                Product_Type__c = 'Funeral',
                IC_Sanlam_Claim__c = true,
                RecordTypeId = insuranceClaimsRecordType,
                OwnerId = waitingSanlamQueue.Id);
        casesToInsert.add(testCase5);

        insert casesToInsert;
        system.debug('#### testCase5: ' + testCase5);
    }



    //Addded by Ridwan - ICS-1602
    @IsTest
    static void handleEscalationAssessmentResponse() {
        Case testCase = [SELECT Id, OwnerId, Status, Sub_Status__c, Product_Type__c FROM Case where IC_Sanlam_Claim__c = false LIMIT 1];

        IC_EmailMessageDomain.handleEscalationAssessmentResponse(testCase);

        Case updatedCase = [SELECT Id, OwnerId, Status, Sub_Status__c, Product_Type__c  FROM Case WHERE Id = :testCase.Id];
        Group funeralClaimsQueue = [SELECT Id FROM Group WHERE DeveloperName = 'IC_Funeral_Claims'];

        //System.assertEquals(updatedCase.OwnerId, funeralClaimsQueue.Id, 'The case owner should be the Funeral Claims queue.');
        //System.assertEquals(updatedCase.Status, 'Administration', 'The status should be updated to Administration.');
        //System.assertEquals(updatedCase.Sub_Status__c, 'Admin Queued', 'The sub-status should be updated to Admin Queued.');
        //System.assertEquals(updatedCase.Sub_Status__c, 'Update Received', 'The sub-status should be updated to Update Received.');
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
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        //System.assertEquals(2, emailMessages.size(), 'One EmailMessage should be created.');

        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('test@example.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Test User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('Test Subject ' + testCase.CaseNumber, createdEmailMessage.Subject, 'Subject should match.');
        System.assertEquals('This is a test email body.', createdEmailMessage.TextBody, 'TextBody should match.');
        System.assertEquals('<p>This is a test email body.</p>', createdEmailMessage.HtmlBody, 'HtmlBody should match.');
        System.assertEquals('testMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
//        System.assertEquals('replyTo@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');
    }

    @IsTest
    static void testHandleInboundEmailWithSTrackNumber() {
        Case testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test User';
        email.subject = 'Test Subject Incident# 2182323491 blablablabal';
        email.plainTextBody = 'This is a test email body.';
        email.htmlBody = '<p>This is a test email body.</p>';
        email.messageId = 'testMessageId';
        email.inReplyTo = 'replyTo@example.com';
        email.replyTo = 'replyTo@example.com';
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
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        //System.assertEquals(2, emailMessages.size(), 'One EmailMessage should be created.');

        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('test@example.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Test User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('This is a test email body.', createdEmailMessage.TextBody, 'TextBody should match.');
        System.assertEquals('<p>This is a test email body.</p>', createdEmailMessage.HtmlBody, 'HtmlBody should match.');
        System.assertEquals('testMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
//        System.assertEquals('replyTo@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');
    }

    /**
     * @description Evaluate the IC_CaseEmailHandler and IC_EmailCaseServices to link to an existing
     * Claim using the policy number
     */

    @IsTest
    static void testHandleInboundEmailWithPolicyNumber() {
        String PolicyName = 'CF12345678';

        Case testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];

        //Create Insurance Policy
        IC_Policy__c icPolicy = new IC_Policy__c();
        icPolicy.Parent_Case__c = testCase.Id;
        icPolicy.Name = PolicyName;
        insert icPolicy;

        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test User';
        email.subject = icPolicy.Name;
        email.plainTextBody = 'This is a test email body.';
        email.htmlBody = '<p>This is a test email body.</p>';
        email.messageId = 'testMessageId';
        email.inReplyTo = 'replyTo@example.com';
        email.replyTo = 'replyTo@example.com';
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
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        //System.assertEquals(2, emailMessages.size(), 'One EmailMessage should be created.');

        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('test@example.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Test User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('This is a test email body.', createdEmailMessage.TextBody, 'TextBody should match.');
        System.assertEquals('<p>This is a test email body.</p>', createdEmailMessage.HtmlBody, 'HtmlBody should match.');
        System.assertEquals('testMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
//        System.assertEquals('replyTo@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');
    }

    /**
     * @description Evaluate the IC_CaseEmailHandler and IC_EmailCaseServices to link to an existing
     * Claim using the ID Number
     */

    @IsTest
    static void testHandleInboundEmailWithIDNumber() {
        Case testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        Account personAccount = New Account();
        personAccount.LastName = 'Doe';
        personAccount.Identity_Number__c = '1234567890123';
        insert personAccount;
        testCase.AccountId = personAccount.Id;


        update testCase;


        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test User';
        email.subject = personAccount.Identity_Number__c;
        email.plainTextBody = 'This is a test email body.';
        email.htmlBody = '<p>This is a test email body.</p>';
        email.messageId = 'testMessageId';
        email.inReplyTo = 'replyTo@example.com';
        email.replyTo = 'replyTo@example.com';
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
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        //System.assertEquals(2, emailMessages.size(), 'One EmailMessage should be created.');

        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('test@example.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Test User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('This is a test email body.', createdEmailMessage.TextBody, 'TextBody should match.');
        System.assertEquals('<p>This is a test email body.</p>', createdEmailMessage.HtmlBody, 'HtmlBody should match.');
        System.assertEquals('testMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
//        System.assertEquals('replyTo@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');
    }

    @IsTest
    static void testHandleInboundEmailSanlamAcknowledgment() {
        Case testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@bsky.com';
        email.fromName = 'Test User';
        email.subject = 'Test Subject ' + testCase.CaseNumber;
        email.plainTextBody = 'Good day\n' +
                '\n' +
                'We acknowledge receipt of the claim documents submitted.\n' +
                'Please be advised that claim is currently being assessed.\n' +
                'We will advise shortly.\n' +
                '\n' +
                'Regards\n' +
                '\n' +
                'Claims Department';
        email.htmlBody = '<p>Good day\n' +
                '\n' +
                'We acknowledge receipt of the claim documents submitted.\n' +
                'Please be advised that claim is currently being assessed.\n' +
                'We will advise shortly.\n' +
                '\n' +
                'Regards\n' +
                '\n' +
                'Claims Department</p>';
        email.messageId = 'testMessageId';
        email.inReplyTo = 'replyTo@example.com';
        email.replyTo = 'replyTo@example.com';
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
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        //System.assertEquals(2, emailMessages.size(), 'One EmailMessage should be created.');

        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('test@bsky.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Test User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('Test Subject ' + testCase.CaseNumber, createdEmailMessage.Subject, 'Subject should match.');
        System.assertEquals('testMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
//        System.assertEquals('replyTo@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');
    }

    @IsTest
    static void testHandleInboundEmailSanlamNoAcknowledgment() {
        Case testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@bsky.com';
        email.fromName = 'Test User';
        email.subject = 'Test Subject ' + testCase.CaseNumber;
        email.plainTextBody = 'Regular Body';
        email.htmlBody = '<p>Regular Body</p>';
        email.messageId = 'testMessageId';
        email.inReplyTo = 'replyTo@example.com';
        email.replyTo = 'replyTo@example.com';
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
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        //System.assertEquals(2, emailMessages.size(), 'One EmailMessage should be created.');

        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('test@bsky.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Test User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('Test Subject ' + testCase.CaseNumber, createdEmailMessage.Subject, 'Subject should match.');
        System.assertEquals('testMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
//        System.assertEquals('replyTo@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
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
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        //System.assertEquals(2, emailMessages.size(), 'One EmailMessage should be created.');

        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('no-case@example.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('No Case User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('No Case Subject', createdEmailMessage.Subject, 'Subject should match.');
        System.assertEquals('This email does not have an associated case.', createdEmailMessage.TextBody, 'TextBody should match.');
        System.assertEquals('<p>This email does not have an associated case.</p>', createdEmailMessage.HtmlBody, 'HtmlBody should match.');
        System.assertEquals('noCaseMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
//        System.assertEquals('noCaseReplyTo@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
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
        envelope.toAddress = 'inbound@example.com';

        // Call the handleInboundEmail method
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        //System.assertEquals(2, emailMessages.size(), 'One EmailMessage should be created.');

        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('attachments@example.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Attachment User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('Attachment Subject', createdEmailMessage.Subject, 'Subject should match.');
        System.assertEquals('This email has attachments.', createdEmailMessage.TextBody, 'TextBody should match.');
        System.assertEquals('<p>This email has attachments.</p>', createdEmailMessage.HtmlBody, 'HtmlBody should match.');
        System.assertEquals('attachmentMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
//        System.assertEquals('attachmentReplyTo@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');

        // Verify attachments and files
        List<Attachment> attachments = [SELECT Id, Name, ParentId FROM Attachment WHERE ParentId = :createdEmailMessage.Id];
        //System.assertEquals(2, attachments.size(), 'Two attachments should be created.');
        System.assert(attachments[0].Name == 'binaryAttachment.txt' || attachments[1].Name == 'binaryAttachment.txt', 'Binary attachment should be created.');
        System.assert(attachments[0].Name == 'textAttachment.txt' || attachments[1].Name == 'textAttachment.txt', 'Text attachment should be created.');

        List<ContentVersion> contentVersions = [SELECT Id, Title, FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId = :createdEmailMessage.RelatedToId];
        //System.assertEquals(2, contentVersions.size(), 'Two ContentVersion records should be created.');
        System.assert(contentVersions[0].Title == 'binaryAttachment.txt' || contentVersions[1].Title == 'binaryAttachment.txt', 'Binary ContentVersion should be created.');
        System.assert(contentVersions[0].Title == 'textAttachment.txt' || contentVersions[1].Title == 'textAttachment.txt', 'Text ContentVersion should be created.');
    }

    @IsTest
    static void testHandleInboundEmailSanlamNeedsDocs() {
        Case testCase = [SELECT Id, CaseNumber,Subject, IC_Sanlam_Claim__c FROM Case WHERE Subject = 'Test 999999999 claim' LIMIT 1];
        system.debug('###testCase: ' + testcase);
        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@bsky.com';
        email.fromName = 'Test User';
        email.subject = 'Test Subject 999999999';
        email.plainTextBody = 'Good day\n' +
                '\n' +
                'Please note that in order to finalise the assessment of this funeral claim we require the following outstanding documents.\n' +
                'Regards\n' +
                '\n' +
                'Claims Department';
        email.htmlBody = '<p>Good day\n' +
                '\n' +
                'Please note that in order to finalise the assessment of this funeral claim we require the following outstanding documents.\n' +
                'Regards\n' +
                '\n' +
                'Claims Department</p>';
        email.messageId = 'testMessageId';
        email.inReplyTo = 'replyTo@example.com';
        email.replyTo = 'replyTo@example.com';
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
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        //System.assertEquals(2, emailMessages.size(), 'One EmailMessage should be created.');

        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('test@bsky.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Test User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('Test Subject 999999999', createdEmailMessage.Subject, 'Subject should match.');
        System.assertEquals('testMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
//        System.assertEquals('replyTo@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');
    }
    /*
     *
     */
    @IsTest
    static void testHandleInboundEmailisSanlamAwaitingCentriqRepudiationApproval() {
        Case testCase = [SELECT Id, CaseNumber FROM Case WHERE IC_Sanlam_Claim__c = true LIMIT 1];
        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@bsky.com';
        email.fromName = 'Test User';
        email.subject = 'Test Subject ' + testCase.CaseNumber;
        email.plainTextBody = 'Good day\n' +
                '\n' +
                'Please note that the claim has been sent to Centriq for repudiation approval.\n' +
                '\n' +
                'Regards\n' +
                '\n' +
                'Claims Department';
        email.htmlBody = '<p>Good day\n' +
                '\n' +
                'Please note that the claim has been sent to Centriq for repudiation approval.\n' +
                '\n' +
                'Regards\n' +
                '\n' +
                'Claims Department</p>';
        email.messageId = 'testMessageId';
        email.inReplyTo = 'replyTo@example.com';
        email.replyTo = 'replyTo@example.com';
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
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        system.debug('emailMessages: ' + emailMessages);
        System.assertEquals(1, emailMessages.size(), 'One EmailMessage should be created.');

        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('test@bsky.com', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Test User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('Test Subject ' + testCase.CaseNumber, createdEmailMessage.Subject, 'Subject should match.');
        System.assertEquals('testMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
//        System.assertEquals('replyTo@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');

    }

    @IsTest
    static void testHandleInboundEmailSanlamFMS() {
        Case testCase = [SELECT Id, CaseNumber,Subject, IC_Sanlam_Claim__c, OwnerId FROM Case WHERE Subject = 'Test 999999999 claim' LIMIT 1];
        system.debug('###testCase: ' + testcase);
        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@fmscenta.co.za';
        email.fromName = 'Test User';
        email.subject = 'Test Subject 999999999';
        email.plainTextBody = 'Good day\n' +
                '\n' +
                'Something from FMS.\n' +
                'Regards\n' +
                '\n' +
                'Claims Department';
        email.htmlBody = '<p>Good day\n' +
                '\n' +
                'Something from FMS.\n' +
                'Regards\n' +
                '\n' +
                'Claims Department</p>';
        email.messageId = 'testMessageId';
        email.inReplyTo = 'replyTo@example.com';
        email.replyTo = 'replyTo@example.com';
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
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the results
        List<EmailMessage> emailMessages = [SELECT Id, FromAddress, FromName, Subject, TextBody, HtmlBody, MessageIdentifier, ToAddress, Incoming, RelatedToId FROM EmailMessage];
        //System.assertEquals(2, emailMessages.size(), 'One EmailMessage should be created.');

        EmailMessage createdEmailMessage = emailMessages[0];
        System.assertEquals('test@fmscenta.co.za', createdEmailMessage.FromAddress, 'FromAddress should match.');
        System.assertEquals('Test User', createdEmailMessage.FromName, 'FromName should match.');
        System.assertEquals('Test Subject 999999999', createdEmailMessage.Subject, 'Subject should match.');
        System.assertEquals('testMessageId', createdEmailMessage.MessageIdentifier, 'MessageIdentifier should match.');
//        System.assertEquals('replyTo@example.com', createdEmailMessage.ToAddress, 'ToAddress should match.');
        System.assertEquals(true, createdEmailMessage.Incoming, 'Incoming should be true.');

        Case testCase_after = [SELECT Id, CaseNumber,Subject, IC_Sanlam_Claim__c, OwnerId FROM Case WHERE Subject = 'Test 999999999 claim' LIMIT 1];
        System.assertEquals(testCase.OwnerId, testCase_after.OwnerId, 'Unexpected Case Owner');
    }

    /**
     * @description Evaluate the LongOutstandingClaim (LOC) reopen logic
     * When the case status has changed from closed for an applicable Claim type (based on Custom metadata),
     * a corresponding Claim Support record should be created.
     *
     * This method evaluates the new logic without the preceding email creation process.
     *
     * ICS-2006
     */
    @IsTest
    static void testHandleInboundEmailLOCReopenLogic() {
        Case testCase = [SELECT Id, CaseNumber,Subject, IC_Sanlam_Claim__c, Status, OwnerId, Owner.Name FROM Case WHERE Subject = 'Test 999999999 claim CLOSED' LIMIT 1];
        system.debug(testCase);
        // Create a test Messaging.InboundEmail object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@bsky.com';
        email.fromName = 'Test User';
        email.subject = 'Test Subject ' + testCase.CaseNumber;
        email.plainTextBody = 'Good day\n' +
                '\n' +
                'LOC.\n' +
                '\n' +
                'Regards\n' +
                '\n' +
                'Claims Department';
        email.htmlBody = '<p>Good day\n' +
                '\n' +
                'LOC.\n' +
                '\n' +
                'Regards\n' +
                '\n' +
                'Claims Department</p>';
        email.messageId = 'testMessageId';
        email.inReplyTo = 'replyTo@example.com';
        email.replyTo = 'replyTo@example.com';
        email.headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Date';
        header.value = 'Thu, 14 Jun 2024 12:34:56 -0700';
        email.headers.add(header);

        // Create a test Messaging.InboundEnvelope object
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'test@example.com';
        envelope.toAddress = 'inbound@example.com';


        EmailMessage emailMessage = new EmailMessage();

        emailMessage.FromAddress = email.fromAddress;
        emailMessage.FromName = email.fromName;
        emailMessage.Subject = email.subject;
        emailMessage.TextBody = email.plainTextBody;
        emailMessage.HtmlBody = email.htmlBody;
        emailMessage.MessageIdentifier = email.messageId;
        emailMessage.ToAddress = (email.toAddresses == null? '' : String.join(email.toAddresses, ','));
        emailMessage.CcAddress = (email.ccAddresses == null? '' : String.join(email.ccAddresses, ','));
        emailMessage.Incoming = true;
        // Call the handleInboundEmail method
        IC_CaseEmailHandler handler = new IC_CaseEmailHandler();
        Test.startTest();
        IC_CaseEmailHandler.handleResponses(emailMessage, testCase.Id, true);
        Test.stopTest();

        // Verify the results
        Case testCase_after = [SELECT Id, CaseNumber,Subject, IC_Sanlam_Claim__c, OwnerId, Status FROM Case WHERE Subject = 'Test 999999999 claim' LIMIT 1];
        //LOG REOPEN ONLY DOESNT CHANGE THE OWNER AND THE updateCaseSanlamFuneralClaimsQueue METHOD KEEPS THE OWNER THE SAME
        System.assertEquals(testCase.OwnerId, testCase_after.OwnerId, 'Unexpected Case Owner');
        //System.assertEquals('Administration',testCase_after.Status,'Unexpected Case Status');


        List<IC_ClaimSupport__c> claimSupports = [SELECT Id, Name, IC_ParentCase__c FROM IC_ClaimSupport__c];
        system.debug('$$$CLAIMSUPPORT: ' + claimSupports);
        system.assertEquals(1, claimSupports.size(), 'Unexpected number of ClaimSupport records');

    }
}