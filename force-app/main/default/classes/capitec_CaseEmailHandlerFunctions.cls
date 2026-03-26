/**
* This class provides utility functions for handling operations related to Cases and EmailMessages in Salesforce.
* It includes methods to extract case numbers from email subjects, retrieve Case Ids based on case numbers,
* and simulate the creation of a Case and an associated EmailMessage from an incoming email.
*
* @author Caleb Govender
* @date 23.04.2024
*
* @lastModified 21.01.2025
* @LastModifiedBy Dhriven Hamlall
*/
public with sharing class capitec_CaseEmailHandlerFunctions {
    
    private static final String DEFAULT_ORIGIN = 'Email';
    private static final String FRAUD_REC_TYPE_DEV_NAME = 'Fraud_Record_Type';
    private static final String FRAUD_QUEUE_DEV_NAME = 'Fraud_Email_Cases';
    private static final String FRAUD_SUBJECT_SQL = 'SELECT capitec_Phrase__c,FR_Routing_Queue__c FROM Email_Listener_Search_Library__c WHERE capitec_isActive__c = TRUE AND capitec_Phrase_Type__c =' + '\'Subject\'' + ' AND capitec_Email_Listener__c INCLUDES (' + '\'Fraud\'' + ')';
    private static final String FRAUD_FROM_ADDRESS_SQL = 'SELECT capitec_Phrase__c,FR_Routing_Queue__c, Case_Origin__c, External_Bank__c, Record_Type__c FROM Email_Listener_Search_Library__c WHERE capitec_isActive__c = TRUE AND capitec_Phrase_Type__c =' + '\'From Address\'' + ' AND capitec_Email_Listener__c INCLUDES (' + '\'Fraud\'' + ')';
    private static final String FRAUD_CC_ADDRESS_SQL = 'SELECT capitec_Phrase__c,FR_Routing_Queue__c FROM Email_Listener_Search_Library__c WHERE capitec_isActive__c = TRUE AND capitec_Phrase_Type__c =' + '\'CC Address\'' + ' AND capitec_Email_Listener__c INCLUDES (' + '\'Fraud\'' + ')';
    
    /**
* @author Dawid Kuczer
* @date 13.06.2024
*
* @description This method searches through a body of text looking for numbers resembling a Case Number.
* <a href='https://capitecbank.atlassian.net/browse/FFSF-525'>FFSF-525</a>
* <a href='https://capitecbank.atlassian.net/browse/ICS-891'>ICS-891</a>
*
* @param textToSearchThrough email message that the new case will be based on
* @param caseRecordTypeDevName the record type that the new case should have
* @param emailMessage the email message associated with the case
* @return The Id of the newly created Case.
*/
    public static String returnCaseIdPatternSearch(String textToSearchThrough, String caseRecordTypeDevName,EmailMessage emailMessage) {
        
        Pattern patternDigitsOnly;
        
        
        String caseNumberPattern = '(?<![1-9])(0*\\d{4,10})';
        patternDigitsOnly = Pattern.compile(caseNumberPattern);
        
        List<String> caseNumbersFound = new List<String>();
        matchPattern(patternDigitsOnly, textToSearchThrough, caseNumbersFound);
        
        
        Case foundCase;
        try{
            foundCase = pullCasesByCaseNumbers(caseNumbersFound, caseRecordTypeDevName);
        }
        catch (QueryException e){
            foundCase = null;
        }
        
        
        if(foundCase == null){
            return null;
        }
        return CaseStatusCheck(foundCase.Id, emailMessage);
    }
    
    
    /**
* @author Dawid Kuczer
* @author Caleb Govender
* @date 13.06.2024
*
* @descriptionThis method simulates the creation of a Case and an associated EmailMessage from an incoming email.
* The data from the EmailMessage is then passed to the Case.
* <a href='https://capitecbank.atlassian.net/browse/FFSF-525'>FFSF-525</a>
* <a href='https://capitecbank.atlassian.net/browse/FCO-92'>FCO-92</a>
* <a href='https://capitecbank.atlassian.net/browse/ICS-891'>ICS-891</a>
*
* @param emailMsg email message that the new case will be based on
* @param caseRecordTypeDevName the record type that the new case should have
* @param queueDevName the queue that the case should be assigned to
* @param sParentCase the possible parent case that could be used for creation of child cases
* @param sPriority the Priority of the Case that gets created
* @return The Id of the newly created Case.
*/
    public static Id CustomEmailToCase(EmailMessage emailMsg, String caseRecordTypeDevName, String queueDevName,String sParentCase,String sPriority) {
        Case newCase = new Case();
        
        newCase.Subject = emailMsg.Subject;
        newCase.Description = emailMsg.TextBody;
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(caseRecordTypeDevName).getRecordTypeId();
        newCase.Status = 'New';
        newCase.Origin = FromAddressCaseOriginCheck(emailMsg.FromAddress);
        newCase.External_Bank__c = FromAddressCaseExtBankCheck(emailMsg.FromAddress);
        newCase.Priority = sPriority;
        newCase.OwnerId = [SELECT Id FROM Group WHERE Type='Queue' AND DeveloperName=:queueDevName].Id;
        newCase.Capitec_Email_To_Case__c = true;
        newCase.SuppliedEmail = emailMsg.FromAddress; //FFSF-823 Added to store the email address of the sender
        
        if (sParentCase != '' || sParentCase.length() > 0) {
            newCase.ParentId = sParentCase;
        }
        
        insert newCase;
        return newCase.Id;
    }
    
    
    /**
* Checks the status of a case and creates a new child case if the status is 'Closed' or 'Not Fraud'.
*
* @param sCaseId The ID of the case to check.
* @param emailMsg The email message associated with the case.
* @return The ID of the new child case if created, otherwise null.
*
* <a href='https://capitecbank.atlassian.net/browse/FCO-112'>FCO-112</a>
* @lastModified 27.11.2024
*/
    public static Id CaseStatusCheck(String sCaseId, EmailMessage emailMsg) {
        Case myCase = new Case();
        myCase = [SELECT Id, Status,CaseNumber,OwnerId,Priority FROM Case WHERE Id =: sCaseId LIMIT 1];
        if (myCase.Status == 'Closed' || myCase.Status == 'Not Fraud') {
            return openClosedCaseAndSetPriorityHigh(sCaseId);
        }
        return myCase.Id;
    }
    
    /**
* Opens a closed case and sets the priority to 'High'.
*
* @param caseId The ID of the case to open and update.
* @return The ID of the updated case if successful, otherwise null.
*
* <a href='https://capitecbank.atlassian.net/browse/FCO-112'>FCO-112</a>
* @lastModified 14.01.2025
*/
    public static Id openClosedCaseAndSetPriorityHigh(Id caseId) {
        Case myCase = [SELECT Id, Status, Priority, OwnerId, Subject FROM Case WHERE Id = :caseId LIMIT 1];
        if (myCase.Status == 'Closed' || myCase.Status == 'Not Fraud') {
            myCase.Status = 'New';
            myCase.Priority = 'High';
            myCase.OwnerId = [SELECT Id FROM Group WHERE Type='Queue' AND DeveloperName=:FRAUD_QUEUE_DEV_NAME].Id;
            myCase.Subject = '[REOPENED] ' + myCase.Subject;
            update myCase;
            return myCase.Id;
        }
        return myCase.Id;
    }
    
    /**
* @author Dawid Kuczer
* @date 13.06.2024
* @description This method takes a compiled pattern and searches through a body of text trying to match the pattern
* <a href='https://capitecbank.atlassian.net/browse/ICS-891'>ICS-891</a>
*
* @param pattern compiled RegEx pattern
* @param textToSearchThrough body of the text that we want to search through for the phrase described by the RegEx pattern
* @param caseNumbersFound a list of string containing all of the numbers that match the Case Number format
*/
    private static void matchPattern (Pattern pattern, String textToSearchThrough, List<String> caseNumbersFound){
        Matcher matcher = pattern.matcher(textToSearchThrough);
        while(matcher.find()) {
            caseNumbersFound.add(matcher.group(1)); // Use group 1 for captured digits
        }
    }
    
    
    /**
* @author Dawid Kuczer
* @date 13.06.2024
* @description Retrieves a Case record based on a list of possible case numbers and a specified record type.
* <a href='https://capitecbank.atlassian.net/browse/ICS-891'>ICS-891</a>
*
* @param possibleCaseNumbers A list of possible case numbers to search for.
* @param caseRecordTypeDevName The developer name of the record type to filter the cases.
* @return The Case record if found, otherwise null.
*/
    private static Case pullCasesByCaseNumbers(List<String> possibleCaseNumbers, String caseRecordTypeDevName) {
        
        return [SELECT Id, CaseNumber FROM Case WHERE CaseNumber IN :possibleCaseNumbers AND RecordType.DeveloperName =: caseRecordTypeDevName LIMIT 1];
    }
    
    
    /**
* @author Caleb Govender
* @date 17.07.2024
* @description This function extracts the case number from the subject of an email.
*  <a href='https://capitecbank.atlassian.net/browse/FFSF-791'>FFSF-791</a>
*
* @param subject The subject line of the email.
* @return The case number if found, otherwise null.
*/
    public static String extractCaseNumberFromSubject(String subject) {
        String[] words = subject.split(' ');
        
        for (String word : words) {
            try {
                Integer.valueOf(word);
                return word;
            } catch (Exception e) {
                
            }
        }
        return null;
    }
    
    
    /**
* @author Caleb Govender
* @date 17.07.2024
* @description This function retrieves the Case Id based on the case number extracted from the subject of an email.
* <a href='https://capitecbank.atlassian.net/browse/FFSF-791'>FFSF-791</a>
*
* @param sCaseNumber The case number extracted from the email subject.
* @param emailMessage The email message associated with the case.
* @return The Case Id if found, otherwise null.
*/
    public static String LikeCaseIdSearch(String sCaseNumber, EmailMessage emailMessage) {
        try {
            Case myCase = new Case();
            String sFraudRecordTypeID = getFraudRecordTypeId();
            String sExtractedCaseNumber = extractCaseNumberFromSubject(sCaseNumber);
            
            if (sExtractedCaseNumber != null && sExtractedCaseNumber.length() < 8) {
                String sCaseNumberWithPadding = padNumberWithZeros(Integer.valueOf(sExtractedCaseNumber));
                myCase = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber =: sCaseNumberWithPadding AND RecordTypeId =: sFraudRecordTypeID LIMIT 1];
            }
            else{
                myCase = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber =: sExtractedCaseNumber AND RecordTypeId =: sFraudRecordTypeID LIMIT 1];
            }
            
            if (myCase != null) {
                return CaseStatusCheck(myCase.Id, emailMessage);
            } else {
                return null;
            }
        } catch (Exception e) {
            System.debug('Exception in LikeCaseIdSearch: ' + e.getMessage());
            return null;
        }
    }
    
    
    /**
* @author Caleb Govender
* @date 19.07.2024
* @description This function retrieves the Case Id based on the case number extracted from the subject of an email.
* <a href='https://capitecbank.atlassian.net/browse/FFSF-791'>FFSF-792</a>
* <a href='https://capitecbank.atlassian.net/browse/FFSF-793'>FFSF-793</a>
*
* @param subject The subject line of the email.
* @return The email address if found, otherwise null.
*/
    public static String extractEmailFromSubject(String subject) {
        Pattern emailPattern = Pattern.compile('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}');
        Matcher matcher = emailPattern.matcher(subject);
        if (matcher.find()) {
            return matcher.group();
        }
        return null;
    }
    
    
    /**
* @author Caleb Govender
* @description This method is used to link a Case to an Account and Contact based on the information extracted from the email subject.
* It extracts the Identity Number from the email subject and searches for a matching Account and Contact.
* If a matching Account or Contact is found, the Case is linked to that Account or Contact.
* <a href='https://capitecbank.atlassian.net/browse/FFSF-792'>FFSF-792</a>
* <a href='https://capitecbank.atlassian.net/browse/FFSF-793'>FFSF-793</a>
* <a href='https://capitecbank.atlassian.net/browse/FFSF-833'>FFSF-833</a>
* <a href='https://capitecbank.atlassian.net/browse/FFSF-834'>FFSF-834</a>
*
* @lastModified 08.08.2024
* @param sSubject The subject line of the email.
* @param sCaseId The Id of the Case to be linked to an Account or Contact.
* @return True if the Case was successfully linked to an Account or Contact, otherwise False.
*/
    public static Boolean CaseIdNumberAccountAndContactLinking(String sSubject, String sCaseId) {
        try {
            Case myCase = [SELECT Id, CaseNumber, AccountId, ContactId FROM Case WHERE Id =: sCaseId LIMIT 1];
            Account myAccount = new Account();
            String sIdNumber = capitec_CaseEmailHandlerFunctions.ExtractIDNumber(sSubject);
            String sPersonAccountRecordTypeID = getPersonAccountRecordTypeId();
            
            if (sIdNumber != null && sIdNumber.length() == 13) {
                myAccount = [SELECT Id, Identity_Number__c,PersonContactId FROM Account WHERE Identity_Number__c =: sIdNumber AND Identity_Number__c != NULL AND RecordTypeId =: sPersonAccountRecordTypeID LIMIT 1];
                if (myAccount != null && myCase.AccountId == null) {
                    myCase.AccountId = myAccount.Id;
                    myCase.ContactId = myAccount.PersonContactId;
                    
                    update myCase;
                    return true;
                }
            }
        } catch (Exception e) {
            System.debug('Exception in CaseIdNumberAccountLinking: ' + e.getMessage());
            return false;
        }
        return false;
    }
    
    
    /**
* @author Caleb Govender
* @description This method is used to link a Case to an Account and Contact based on the email address.
* It uses the From email address to search for a matching Account and Contact.
* If a matching Account or Contact is found, the Case is linked to that Account or Contact.
* <a href='https://capitecbank.atlassian.net/browse/FFSF-792'>FFSF-792</a>
* <a href='https://capitecbank.atlassian.net/browse/FFSF-793'>FFSF-793</a>
* <a href='https://capitecbank.atlassian.net/browse/FFSF-833'>FFSF-833</a>
* <a href='https://capitecbank.atlassian.net/browse/FFSF-834'>FFSF-834</a>
*
* @lastModified 08.08.2024
* @param sCaseId The Id of the Case to be linked to an Account or Contact.
* @param sFromAddress The From Address of the email.
*/
    public static void CaseEmailAccountAndContactLinking(String sCaseId, String sFromAddress) {
        try {
            Case myCase = [SELECT Id, CaseNumber, AccountId, ContactId FROM Case WHERE Id =: sCaseId LIMIT 1];
            String sPersonAccountRecordTypeID = getPersonAccountRecordTypeId();
            Account myAccount = [SELECT Id, PersonEmail,PersonContactId FROM Account WHERE PersonEmail =: sFromAddress AND PersonEmail != NULL AND RecordTypeId =: sPersonAccountRecordTypeID LIMIT 1];
            
            if (myAccount != null && myCase.AccountId == null) {
                myCase.AccountId = myAccount.Id;
                myCase.ContactId = myAccount.PersonContactId;
                
                update myCase;
            }
        } catch (Exception e) {
            System.debug('Exception in CaseEmailAccountLinking: ' + e.getMessage());
        }
    }
    
    /**
* @author Caleb Govender
* @description This method checks if the given email address is from the Capitec Bank domain.
* It verifies if the email address contains '@capitecbank.co.za'.
* <a href='https://capitecbank.atlassian.net/browse/FFSF-846'>FFSF-846</a>
*
* @param sFromAddress The email address to be checked.
* @return True if the email address is from the Capitec Bank domain, otherwise False.
*/
    public static Boolean FromAddressCheck(String sFromAddress) {
        try {
            Boolean sContainsCapitec = sFromAddress.contains('@capitecbank.co.za');
            if (sContainsCapitec == true) {
                return true;
            } else {
                return false;
            }
        } catch (Exception e) {
            System.debug('Exception in FromAddressCheck: ' + e.getMessage());
            return false;
        }
    }
    
    
    /**
* @author Caleb Govender
* @description  Checks the subject of an email to determine the appropriate queue for the case.
* <a href='https://capitecbank.atlassian.net/browse/FCO-81'>FCO-81</a>
*
* @param sSubject The subject line of the email.
* @return The API name of the queue.
*/
    public static String CaseQueueCheck(String sSubject) {
        String sReturnQueue = '';
        List<Email_Listener_Search_Library__c> sFraudSubjectTerms = new List<Email_Listener_Search_Library__c>();
        sFraudSubjectTerms = mapQueryToEmailListenerList(FRAUD_SUBJECT_SQL);
        String sSubjectFormatted = sSubject.toLowerCase();
        
        for (Email_Listener_Search_Library__c item : sFraudSubjectTerms) {
            String sPhraseFormatted = item.capitec_Phrase__c.toLowerCase();
            if (sSubjectFormatted.contains(sPhraseFormatted)) {
                sReturnQueue = ReturnQueueAPIName(item.FR_Routing_Queue__c);
                break;
            }
        }
        return sReturnQueue;
    }
    
    
    /**
* @author Caleb Govender
* @description This method checks the from address of an email to determine the appropriate queue for the case.
* <a href='https://capitecbank.atlassian.net/browse/FCO-81'>FCO-81</a>
*
* @param sFromAddress The from address of the email.
* @return The API name of the queue.
*/
    public static String FromAddressCaseQueueCheck(String sFromAddress){
        String sReturnQueue = FRAUD_QUEUE_DEV_NAME;
        List<Email_Listener_Search_Library__c> sFraudEmails = new List<Email_Listener_Search_Library__c>();
        sFraudEmails = mapQueryToEmailListenerList(FRAUD_FROM_ADDRESS_SQL);
        String sFromAddressFormatted = sFromAddress.toLowerCase();
        
        for (Email_Listener_Search_Library__c item : sFraudEmails) {
            String sPhraseFormatted = item.capitec_Phrase__c.toLowerCase();
            if (sFromAddressFormatted.contains(sPhraseFormatted)) {
                sReturnQueue = ReturnQueueAPIName(item.FR_Routing_Queue__c);
                break;
            }
        }
        return sReturnQueue;
    }
  
    /**
* @author Dhriven Hamlall
* @description This method checks the from address of an email to determine the appropriate record type for the case.
* <a href='https://capitecbank.atlassian.net/browse/FCO-81'>FCO-81</a>
*
* @param sFromAddress The from address of the email.
* @return The record type name.
*/    
    public static String getRecordTypeWithFromAddress(String sFromAddress) {
        String recordTypeDevName = FRAUD_REC_TYPE_DEV_NAME;
        
        List<Email_Listener_Search_Library__c> sFraudEmails = mapQueryToEmailListenerList(FRAUD_FROM_ADDRESS_SQL);
        String sFromAddressFormatted = sFromAddress.toLowerCase();
        
        for (Email_Listener_Search_Library__c item : sFraudEmails) {
            String sPhraseFormatted = item.capitec_Phrase__c.toLowerCase();
            if (sFromAddressFormatted.contains(sPhraseFormatted)) {
                if (!String.isBlank(item.Record_Type__c)) {
                    recordTypeDevName = item.Record_Type__c;
                }
                break;
            }
        }
        return recordTypeDevName;
    }
    
    
    /**
* @author Dhriven Hamlall
* @description This method checks the from address of an email to determine the appropriate origin for the case.
* <a href='https://capitecbank.atlassian.net/browse/FCO-97'>FCO-97</a>
*
* @param sFromAddress The from address of the email.
* @return A string indicating the Case Origin, based on configuration in the Email_Listener_Search_Library__c object or a default of 'Email'.
*/    
    public static String FromAddressCaseOriginCheck(String sFromAddress) {
        String sReturnOrigin = DEFAULT_ORIGIN;
        
        List<Email_Listener_Search_Library__c> sFraudEmails = mapQueryToEmailListenerList(FRAUD_FROM_ADDRESS_SQL);
        
        String sFromAddressFormatted = sFromAddress.toLowerCase();
        
        for (Email_Listener_Search_Library__c item : sFraudEmails) {
            String sPhraseFormatted = item.capitec_Phrase__c.toLowerCase();
            
            if (sFromAddressFormatted.contains(sPhraseFormatted)) {
                sReturnOrigin = String.isBlank(item.Case_Origin__c) ? sReturnOrigin : item.Case_Origin__c;
                break;
            }
        }
        return sReturnOrigin;
    }
    
    /**
* @author Dhriven Hamlall
* @description This method checks the from address of an email to determine the appropriate external bank for the case.
* <a href='https://capitecbank.atlassian.net/browse/FCO-85'>FCO-85</a>
*
* @param sFromAddress The from address of the email.
* @return A string indicating the Case Ext Bank, based on configuration in the Email_Listener_Search_Library__c object.
*/    
    public static String FromAddressCaseExtBankCheck(String sFromAddress) {
        String sReturnExtBank = '';
        
        List<Email_Listener_Search_Library__c> sFraudEmails = mapQueryToEmailListenerList(FRAUD_FROM_ADDRESS_SQL);
        
        String sFromAddressFormatted = sFromAddress.toLowerCase();
        
        for (Email_Listener_Search_Library__c item : sFraudEmails) {
            String sPhraseFormatted = item.capitec_Phrase__c.toLowerCase();
            
            if (sFromAddressFormatted.contains(sPhraseFormatted)) {
                sReturnExtBank = String.isBlank(item.External_Bank__c) ? sReturnExtBank : item.External_Bank__c;
                break;
            }
        }
        return sReturnExtBank;
    }
    
    
    
    /**
* Checks the CC addresses of an email to determine if they match any known fraud addresses.
* <a href='https://capitecbank.atlassian.net/browse/FCO-92'>FCO-92</a>
*
* @param lCCAddress A list of CC addresses from the email.
* @return A string containing the checked CC addresses.
*/
    public static String CCAddressCheck(List<String> lCCAddress) {
        String sCCCheckedAddress = '';
        List<Email_Listener_Search_Library__c> sCCEmails = new List<Email_Listener_Search_Library__c>();
        sCCEmails = mapQueryToEmailListenerList(FRAUD_CC_ADDRESS_SQL);
        for (String ccAddress : lCCAddress) {
            for (Email_Listener_Search_Library__c item : sCCEmails) {
                String sPhraseFormatted = item.capitec_Phrase__c.toLowerCase();
                if (!ccAddress.toLowerCase().contains(sPhraseFormatted)) {
                    sCCCheckedAddress += ccAddress + '; ';
                }
            }
        }
        return sCCCheckedAddress;
    }
    
    
    /**
* @author Caleb Govender
* @description  Retrieves the API name of a queue based on its name.
* <a href='https://capitecbank.atlassian.net/browse/FCO-81'>FCO-81</a>
*
* @param sQueueName The name of the queue.
* @return The API name of the queue.
*/
    public static String ReturnQueueAPIName(String sQueueName) {
        Group sQueue = new Group();
        sQueue = [SELECT Id, DeveloperName FROM Group WHERE Type='Queue' AND Name =: sQueueName LIMIT 1];
        return sQueue.DeveloperName;
    }
    
    
    /**
* @author Caleb Govender
* @description Executes a SOQL query from a string and maps the response to a list of Email_Listener_Search_Library__c.
* <a href='https://capitecbank.atlassian.net/browse/FCO-81'>FCO-81</a>
*
* @param queryString The SOQL query string to execute.
* @return A list of Email_Listener_Search_Library__c containing the query results.
* @throws QueryException if the query is invalid or fails.
*/
    public static List<Email_Listener_Search_Library__c> mapQueryToEmailListenerList(String queryString) {
        try {
            List<Email_Listener_Search_Library__c> results = Database.query(queryString);
            return results;
        } catch (QueryException e) {
            System.debug('QueryException: ' + e.getMessage());
            throw e;
        }
    }
    
    
    /**
* @author Caleb Govender
* @date 29.07.2024
* @description  Extracts a 13-digit ID number from the given input string.
* <a href='https://capitecbank.atlassian.net/browse/FFSF-792'>FFSF-792</a>
* <a href='https://capitecbank.atlassian.net/browse/FFSF-793'>FFSF-793</a>
*
* @param input The input string from which to extract the 13-digit ID number.
* @return The extracted 13-digit ID number if found, otherwise null.
*/
    public static String ExtractIDNumber(String input) {
        
        Pattern pattern = Pattern.compile('\\b\\d{13}\\b');
        Matcher matcher = pattern.matcher(input);
        
        if (matcher.find()) {
            return matcher.group();
        }
        return null;
    }
    
    
    /**
* @author Caleb Govender
* @date 26.07.2024
*
* @description
* Pads a given number with zeros at the back to make it 8 digits long.
* @param iCaseNumber The number to be padded.
* @return The padded number as a string.
*/
    public static String padNumberWithZeros(Integer iCaseNumber) {
        String numberStr = String.valueOf(iCaseNumber);
        while (numberStr.length() < 8) {
            numberStr = '0' + numberStr ;
        }
        return numberStr;
    }
    
    /**
* @author Caleb Govender
* @date 25.11.2024
*
* @description
* Retrieves the Id of the Fraud Record Type for the Case object.
*
* @return The Id of the Fraud Record Type, or null if not found.
*/
    public static Id getFraudRecordTypeId() {
        try {
            RecordType fraudRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Fraud_Record_Type' AND SObjectType = 'Case' LIMIT 1];
            return fraudRecordType.Id;
        } catch (Exception e) {
            System.debug('Exception in getFraudRecordTypeId: ' + e.getMessage());
            return null;
        }
    }
    
    /**
* @author Caleb Govender
* @date 25.11.2024
*
* @description
* Retrieves the Id of the Person Account Record Type for the Account object.
*
* @return The Id of the Person Account Record Type, or null if not found.
*/
    public static Id getPersonAccountRecordTypeId() {
        try {
            RecordType personAccountRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' AND SObjectType = 'Account' LIMIT 1];
            return personAccountRecordType.Id;
        } catch (Exception e) {
            System.debug('Exception in getPersonAccountRecordTypeId: ' + e.getMessage());
            return null;
        }
    }
}