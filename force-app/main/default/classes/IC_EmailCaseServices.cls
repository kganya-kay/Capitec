/**
 * This class provides utility functions for handling operations related to Cases and EmailMessages in Salesforce.
 * It includes methods to extract case numbers from email subjects, retrieve Case Ids based on case numbers,
 * and simulate the creation of a Case and an associated EmailMessage from an incoming email.
 *
 * Created by CalebGovender on 2024/04/23.
 */
public without sharing class IC_EmailCaseServices {

    private static final String INSURANCE_CLAIMS_REC_TYPE_DEV_NAME = 'Insurance_Claims';
    private static final String INSURANCE_CLAIMS_ASSESSMENT_REC_TYPE_DEV_NAME = 'Insurance_Claims_Assessment';

    /**
     * @author Dawid Kuczer
     * @date 20.08.2024
     *
     * @description This method searches through a body of text looking for numbers resembling a Case Number.
     * <a href='https://capitecbank.atlassian.net/browse/ICS-891'>ICS-891</a>
     *
     * @param textToSearchThrough email message that the new case will be based on
     * @param caseRecordTypeDevName the record type that the new case should have
     * @return The Id of the newly created Case.
    */

    public static String returnCaseIdPatternSearch(String textToSearchThrough){

        Pattern patternDigitsOnly;

        //ICS-1504 refined the pattern. Now it is even more refined, one could say - refinier. Dawid Kuczer
        //String caseNumberPattern = 'Incident#\\s*(?<![1-9])(0*\\d{4,12})';
        // 27 Sept 2024 - Removed the case sensitive Incident and made it more generic - Gerhard de Klerk
        // 01 Oct 2024 - Further reduce the strictness of the REGEX by removing the # check - Gerhard de Klerk
        String caseNumberPattern = '\\s*(?<![1-9])(0*\\d{4,12})';
        patternDigitsOnly = Pattern.compile(caseNumberPattern);

        List<String> caseNumbersFound = new List<String>();
        matchPattern(patternDigitsOnly, textToSearchThrough, caseNumbersFound);

        System.debug(caseNumbersFound);

        Case foundCase;
        try{
            //ICS-1504 modified the method below to take a single string instead of a list to make it more intuitive and easier for tracking. Dawid Kuczer
            for(String potentialCaseNumber : caseNumbersFound){
                foundCase = pullCasesByCaseNumbers(potentialCaseNumber);
                if(foundCase != null) break;
            }
        }
        catch (QueryException e){
            foundCase = null;
        }

        return foundCase == null ? null : foundCase.Id;
    }

    /**
         * @description Extract the Policy Number Starting with CF and Search existing policies
         * @param textToSearchThrough Generally the subject of the Email to extract the CF number from
         *
         * @return ID of the Case if it has been found
         */
    public static String returnCaseIdPatternSearchPolicyNumber(String textToSearchThrough){

        Pattern patternDigitsOnly;
        String policyNumberPattern = 'CF(\\d{8})';
        patternDigitsOnly = Pattern.compile(policyNumberPattern);

        List<String> caseNumbersFound = new List<String>();
        matchPattern(patternDigitsOnly, textToSearchThrough, caseNumbersFound);

        System.debug(caseNumbersFound);

        Case foundCase;
        try{
            for(String potentialCaseNumber : caseNumbersFound){
                foundCase = pullCasesByPolicyNumber('CF' + potentialCaseNumber);
                if(foundCase != null) break;
            }

        }
        catch (QueryException e){
            foundCase = null;
        }

        return foundCase == null ? null : foundCase.Id;
    }

    /**
     * @description Extract the ID Number and search for Cases associated with it
     * @param textToSearchThrough Generally the subject of the Email to extract the ID number from
     *
     * @return ID of the Case if it has been found
     */
    public static String returnCaseIdPatternSearchIDNumber(String textToSearchThrough){

        Pattern patternDigitsOnly;
        String caseNumberPattern = '\\s*(\\d{13})';
        patternDigitsOnly = Pattern.compile(caseNumberPattern);

        List<String> caseNumbersFound = new List<String>();
        matchPattern(patternDigitsOnly, textToSearchThrough, caseNumbersFound);

        System.debug(caseNumbersFound);

        Case foundCase;
        try{
            for(String potentialCaseNumber : caseNumbersFound){
                foundCase = pullCasesByIDNumber(potentialCaseNumber);
                if(foundCase != null) break;
            }
        }
        catch (QueryException e){
            foundCase = null;
        }

        return foundCase == null ? null : foundCase.Id;
    }

    /**
     * @author Dawid Kuczer
     * @date 13.06.2024
     *
     * @descriptionThis method handles the creation of a Case and an associated EmailMessage from an incoming email.
     * The data from the EmailMessage is then passed to the Case.
     * <a href='https://capitecbank.atlassian.net/browse/ICS-891'>ICS-891</a>
     *
     * @param emailMsg email message that the new case will be based on
     * @param caseRecordTypeDevName the record type that the new case should have
     * @param queueDevName the queue that the case should be assigned to
     * @return The Id of the newly created Case.
    */
    public static Id customEmailToCase(EmailMessage emailMsg, String caseRecordTypeDevName, String queueDevName) {
        Case newCase = new Case();

        newCase.Subject = emailMsg.Subject;
        newCase.Description = emailMsg.TextBody;
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(caseRecordTypeDevName).getRecordTypeId();
        newCase.Status = 'New';
        //ICS-1602 change origin to Email - because you know, it's EMAIL to case
        newCase.Origin = 'Email';
        newCase.Priority = 'Medium';
        newCase.SuppliedEmail = emailMsg.FromAddress;
        newCase.Email_Address__c = emailMsg.FromAddress;
        newCase.OwnerId = [SELECT Id FROM Group WHERE Type='Queue' AND DeveloperName=:queueDevName].Id;

        insert newCase;

        return newCase.Id;
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
        //ICS-1504 moved the 0 padding to pullCasesByCaseNumbers() because it's only necessary for Case Number and not STrack. Dawid Kuczer
        Matcher matcher = pattern.matcher(textToSearchThrough);
        while(matcher.find()) {
            caseNumbersFound.add(matcher.group(1)); // Use group 1 for the captured digits
        }
    }

    private static Case pullCasesByCaseNumbers(String numberFromEmail){
        List<String> icRecordTypesNames = new List<String>();
        icRecordTypesNames.add(INSURANCE_CLAIMS_ASSESSMENT_REC_TYPE_DEV_NAME);
        icRecordTypesNames.add(INSURANCE_CLAIMS_REC_TYPE_DEV_NAME);

        //ICS-1504 Modified to also search through Case Subject in case the number coming from the email points to STrack Number that's going to be stored there. Dawid Kuczer
        //06.09.2024 - '0' padding for STrack number
        //I know you're reading this comment Caleb, love ya
        Case foundCase = null;

        String possibleCaseNumber = numberFromEmail.leftPad(8,'0');
        String possibleSTrackNumber = ('%' + possibleCaseNumber.leftPad(8,'0') + '%');

        System.debug('Pattern found: ' + numberFromEmail);
        //Additional debugs for production debugging purpose

        try{
            foundCase = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber = :possibleCaseNumber AND RecordType.DeveloperName IN :icRecordTypesNames LIMIT 1];
            System.debug('Insurance Case Email Handler: Case found by Case Number' + possibleCaseNumber);
            return foundCase;
        }
        catch (QueryException noRowsCaseNumber){
            System.debug('Insurance Case Email Handler: No existing case found by Case Number:' + possibleCaseNumber);
            
            try{
                foundCase = [SELECT Id, CaseNumber FROM Case WHERE Subject LIKE :possibleSTrackNumber AND RecordType.DeveloperName IN :icRecordTypesNames LIMIT 1];
                System.debug('Insurance Case Email Handler: Case found by STrack Number' + possibleSTrackNumber);
                return foundCase;
            }
            catch (QueryException noRowsCaseSubjectSTrack){
                System.debug('Insurance Case Email Handler: No existing case found by STrack Number:' + possibleSTrackNumber);
                return null;
            }
        }
    }

    /**
     * @author Gerhard de Klerk
     * @date 01 Oct 2024
     * @description Use the ID Number to locate a Claims Case by searching from the Account Perspective.
     * Look for the:
     * - Oldest Open Case OR
     * - Newest Closed Case
     * But limit results to Funeral Insurance Claims
     *
     *
     * @param idNumberFromEmail ID Number (13 Digits)
     *
     * @return Case record with only the ID set
     */
    private static Case pullCasesByIDNumber(String idNumberFromEmail){
        List<String> icRecordTypesNames = new List<String>();
        icRecordTypesNames.add(INSURANCE_CLAIMS_ASSESSMENT_REC_TYPE_DEV_NAME);
        icRecordTypesNames.add(INSURANCE_CLAIMS_REC_TYPE_DEV_NAME);

        Case foundCase = null;

        System.debug('Possible IdNumber found: ' + idNumberFromEmail);
        //Additional debugs for production debugging purpose

        try{
            foundCase = [
                    SELECT Id, CreatedDate, Status, IsClosed, Product_Type__c, CaseNumber, Account.Identity_Number__c
                    FROM Case
                    WHERE IsClosed = FALSE AND Product_Type__c = 'Funeral' AND RecordType.DeveloperName IN ('Insurance_Claims') AND Account.Identity_Number__c = :idNumberFromEmail
                    ORDER BY CreatedDate ASC LIMIT 1
            ];
            System.debug('Insurance Case Email Handler: Case found by ID Number - Oldest Open Case: ' + idNumberFromEmail);
            return foundCase;
        }
        catch (QueryException noRowsCaseNumber){
            System.debug('Insurance Case Email Handler: No existing case found by ID Number - Oldest Open Case:' + idNumberFromEmail);

            try{
                foundCase = [
                        SELECT Id, CreatedDate, Status, IsClosed, Product_Type__c, CaseNumber, Account.Identity_Number__c
                        FROM Case
                        WHERE IsClosed = TRUE AND Product_Type__c = 'Funeral' AND RecordType.DeveloperName IN ('Insurance_Claims') AND Account.Identity_Number__c = :idNumberFromEmail
                        ORDER BY CreatedDate DESC LIMIT 1
                ];
                System.debug('Insurance Case Email Handler: Case found by ID Number - Latest Closed Case: ' + idNumberFromEmail);
                return foundCase;
            }
            catch (QueryException noRowsCaseSubjectSTrack){
                System.debug('Insurance Case Email Handler: No existing case found by ID Number - Latest Closed Case: ' + idNumberFromEmail);
                return null;
            }
        }
    }

    /**
     * @author Gerhard de Klerk
     * @date 01 Oct 2024
     * @description Use the Policy Number to locate a Claims Case by searching from the IC Policy Perspective.
     * Look for the:
     * - Oldest Open Case OR
     * - Newest Closed Case
     * But limit results to Funeral Insurance Claims
     *
     *
     * @param policyNumberFromEmail Policy Number Starting with CF
     *
     * @return Case record with only the ID set
     */
    private static Case pullCasesByPolicyNumber(String policyNumberFromEmail){
        List<String> icRecordTypesNames = new List<String>();
        icRecordTypesNames.add(INSURANCE_CLAIMS_ASSESSMENT_REC_TYPE_DEV_NAME);
        icRecordTypesNames.add(INSURANCE_CLAIMS_REC_TYPE_DEV_NAME);

        Case foundCase = new Case();
        IC_Policy__c foundICPolicy = null;

        System.debug('Possible Policy Number found: ' + policyNumberFromEmail);
        //Additional debugs for production debugging purpose

        try{
            foundICPolicy = [
                    SELECT Id, Name, Parent_Case__c, Parent_Case__r.Status, Parent_Case__r.IsClosed, Parent_Case__r.Product_Type__c, Parent_Case__r.CaseNumber
                    FROM IC_Policy__c
                    WHERE Parent_Case__r.IsClosed = FALSE AND Parent_Case__r.Product_Type__c = 'Funeral' AND Parent_Case__r.RecordType.DeveloperName IN ('Insurance_Claims') AND Name = :policyNumberFromEmail
                    ORDER BY Parent_Case__r.CreatedDate ASC LIMIT 1
            ];
            foundCase.Id = foundICPolicy.Parent_Case__c;
            System.debug('Insurance Case Email Handler: Case found by Policy Number - Oldest Open Case: ' + policyNumberFromEmail);
            return foundCase;
        }
        catch (QueryException noRowsCaseNumber){
            System.debug('Insurance Case Email Handler: No existing case found by Policy Number - Oldest Open Case:' + policyNumberFromEmail);

            try{
                foundICPolicy = [
                        SELECT Id, Name, Parent_Case__c, Parent_Case__r.Status, Parent_Case__r.IsClosed, Parent_Case__r.Product_Type__c, Parent_Case__r.CaseNumber
                        FROM IC_Policy__c
                        WHERE Parent_Case__r.IsClosed = TRUE AND Parent_Case__r.Product_Type__c = 'Funeral' AND Parent_Case__r.RecordType.DeveloperName IN ('Insurance_Claims') AND Name = :policyNumberFromEmail
                        ORDER BY Parent_Case__r.CreatedDate DESC LIMIT 1
                ];
                foundCase.Id = foundICPolicy.Parent_Case__c;
                System.debug('Insurance Case Email Handler: Case found by Policy Number - Latest Closed Case: ' + policyNumberFromEmail);
                return foundCase;
            }
            catch (QueryException noRowsCaseSubjectSTrack){
                System.debug('Insurance Case Email Handler: No existing case found by Policy Number - Latest Closed Case: ' + policyNumberFromEmail);
                return null;
            }
        }
    }
}