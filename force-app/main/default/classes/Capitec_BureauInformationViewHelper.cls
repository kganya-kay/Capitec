/**
 * Created by dawid on 18.04.2023.
 */

public with sharing class Capitec_BureauInformationViewHelper {

    private static final String BODY_PREFIX = '{ "sourceKey": 717, "searchCriteriaParams": {';
    private static final String BODY_SUFFIX = '"purpose": 12, "clientConsent": "Y", "valueAddServices": { "wantBureauScore": "Y", "wantDeeds": "Y", "wantDirectors": "Y", "wantSAFPS": "Y", "wantPinPoints": "N" } }}';
    private static final String URL = '/client/bureau-proxy/v1/nonfootprint/nonfootprintcall/';
    private static final String ERROR_MESSAGE = '"We\'re sorry, but we encountered an error while trying to process your request. Our team has been notified and is working to resolve the issue as quickly as possible. Please try again later, or feel free to contact our support team for further assistance. Thank you for your patience and understanding."';


    @AuraEnabled
    public static BureauResponseWrapper getBureauInfo(String recordId){

        Account currentAcc;
        Id tempId = recordId;
        BureauResponseWrapper bureauWrapper;

        if(tempId.getSObjectType().getDescribe().getName() == 'Account'){
            currentAcc = [SELECT Id, Identity_Number__c, ID_Type__c, LastName, FirstName, Gender__c, Birthdate__c FROM Account WHERE Id =: recordId LIMIT 1];
        }
        else if(tempId.getSObjectType().getDescribe().getName() == 'Case'){
            Case thisCase = [SELECT Id,Account.Identity_Number__c, Account.ID_Type__c, Account.LastName, Account.FirstName, Account.Gender__c, Account.Birthdate__c FROM Case WHERE Id = :recordId LIMIT 1];
            currentAcc = thisCase.Account;
        }




        String requestBody = '';
        requestBody += '"identityNumber": "' + currentAcc.Identity_Number__c + '", ';
        requestBody += '"identityType": "' + (currentAcc.Identity_Number__c.length() == 13? 'SID' : 'PASSPORT') + '", ';
        requestBody += '"surname": "' + currentAcc.LastName + '", ';
        requestBody += '"forename": "' + currentAcc.FirstName + '", ';
        requestBody += '"gender": "' + currentAcc.Gender__c + '", ';
        requestBody += '"dateOfBirth": "' + String.valueOf(currentAcc.Birthdate__c) + '",';

        String fullBody = (BODY_PREFIX + requestBody + BODY_SUFFIX);


        System.debug(fullBody);

//        Object temp = Capitec_CalloutHandler.makeLongPOSTCalloutWithBody(URL, fullBody);
//        System.debug(temp);

        HttpResponse httpResponse = (HttpResponse)Capitec_CalloutHandler.makePOSTCalloutWithBody(URL, fullBody);





        System.debug(httpResponse);
        System.debug(httpResponse.getBody());
        System.debug(httpResponse.getStatus());

        if(httpResponse.getStatusCode() != 200){
            bureauWrapper = new BureauResponseWrapper();
            bureauWrapper.statusCode = httpResponse.getStatusCode();
            bureauWrapper.responseMessage = httpResponse.getBody();
            return(bureauWrapper);
        }
        try{
            bureauWrapper = (BureauResponseWrapper)JSON.deserialize(httpResponse.getBody(), BureauResponseWrapper.class);
            bureauWrapper.statusCode = httpResponse.getStatusCode();
        }
        catch (JSONException e){
            System.debug(e.getMessage());
            bureauWrapper = new BureauResponseWrapper();
            bureauWrapper.statusCode = 999;
            bureauWrapper.responseMessage = ERROR_MESSAGE;
            bureauWrapper.responseMessage += ' \n';
            bureauWrapper.responseMessage += e.getMessage();
            bureauWrapper.responseMessage = httpResponse.getBody();
        }




        System.debug(bureauWrapper);
        
        return bureauWrapper;

    }

    public static String stringify(BureauResponseWrapper bureauResponseWrapper){
        return JSON.serialize(bureauResponseWrapper);
    }

    public static BureauResponseWrapper pareJSON(String jsonString){
        return (BureauResponseWrapper)System.JSON.deserialize(jsonString, BureauResponseWrapper.class);
    }

        public class BureauResponseWrapper{
            @AuraEnabled public bureauResultModel bureauResultModel ;
            @AuraEnabled public String correlationID ;
            @AuraEnabled public Integer statusCode ;
            @AuraEnabled public String responseMessage ;

        }


        public class bureauResultModel {
            @AuraEnabled public bureauResponse bureauResponse;
        }
        public class bureauResponse {
            @AuraEnabled public String responseStatus;	
            @AuraEnabled public String errorCode;	
            @AuraEnabled public String errorDescription;	
            @AuraEnabled public transactionStats transactionStats;
            @AuraEnabled public returnData returnData;
        }
        public class transactionStats {
            @AuraEnabled public String receivedTime;	
            @AuraEnabled public String responseTime;	
            @AuraEnabled public String systemUUID;	
        }
        public class returnData {
            @AuraEnabled public String enquiryID;	
            @AuraEnabled public String enquiryDateTime;	
            @AuraEnabled public returnDataBreakdown returnDataBreakdown;
            @AuraEnabled public inputSearchCriteria inputSearchCriteria;
            @AuraEnabled public bureauMatch bureauMatch;
            @AuraEnabled public accounts[] accounts;
            @AuraEnabled public addresses[] addresses;
            @AuraEnabled public adverses[] adverses;
            @AuraEnabled public bureauScores[] bureauScores;
            @AuraEnabled public dcEnquiries[] dcEnquiries;
            @AuraEnabled public debtRestructurings[] debtRestructurings;
            @AuraEnabled public deeds[] deeds;
            @AuraEnabled public directors[] directors;
            @AuraEnabled public employers[] employers;
            @AuraEnabled public enquiries[] enquiries;
            @AuraEnabled public fraud[] fraud;
            @AuraEnabled public judgements[] judgements;
            @AuraEnabled public notices[] notices;
            @AuraEnabled public publicDefaults[] publicDefaults;
            @AuraEnabled public telephones[] telephones;
            @AuraEnabled public traces[] traces;
            @AuraEnabled public warnings[] warnings;
            @AuraEnabled public dispute dispute;
            @AuraEnabled public pinPoints pinPoints;
        }
        public class returnDataBreakdown {
            @AuraEnabled public dataSetCounts dataSetCounts;
        }
        public class dataSetCounts {
            @AuraEnabled public String warnings;	
            @AuraEnabled public boolean warningsSpecified;
            @AuraEnabled public String dispute;	
            @AuraEnabled public boolean disputeSpecified;
            @AuraEnabled public String fraud;	
            @AuraEnabled public boolean fraudSpecified;
            @AuraEnabled public String enquiries;	
            @AuraEnabled public boolean enquiriesSpecified;
            @AuraEnabled public String dcEnquiries;	
            @AuraEnabled public boolean dcEnquiriesSpecified;
            @AuraEnabled public String addresses;	
            @AuraEnabled public boolean addressesSpecified;
            @AuraEnabled public String telephones;	
            @AuraEnabled public boolean telephonesSpecified;
            @AuraEnabled public String employment;	
            @AuraEnabled public boolean employmentSpecified;
            @AuraEnabled public String judgements;	
            @AuraEnabled public boolean judgementsSpecified;
            @AuraEnabled public String notices;	
            @AuraEnabled public boolean noticesSpecified;
            @AuraEnabled public String traces;	
            @AuraEnabled public boolean tracesSpecified;
            @AuraEnabled public String debtRestructurings;	
            @AuraEnabled public boolean debtRestructuringsSpecified;
            @AuraEnabled public String publicDefaults;	
            @AuraEnabled public boolean publicDefaultsSpecified;
            @AuraEnabled public String accounts;	
            @AuraEnabled public boolean accountsSpecified;
            @AuraEnabled public String adverses;	
            @AuraEnabled public boolean adversesSpecified;
            @AuraEnabled public String deeds;	
            @AuraEnabled public boolean deedsSpecified;
            @AuraEnabled public String directors;	
            @AuraEnabled public boolean directorsSpecified;
            @AuraEnabled public String bureauScores;	
            @AuraEnabled public boolean bureauScoresSpecified;
            @AuraEnabled public String pinPoints;	
            @AuraEnabled public boolean pinPointsSpecified;
        }
        public class inputSearchCriteria {
            @AuraEnabled public String identityNumber;	
            @AuraEnabled public String identityType;	
            @AuraEnabled public String firstName;	
            @AuraEnabled public String surname;	
            @AuraEnabled public String countryCode;	
            @AuraEnabled public String countryName;	
            @AuraEnabled public String dob;	
            @AuraEnabled public String gender;	
            @AuraEnabled public String enquiryPurpose;	
            @AuraEnabled public String clientReference;	
        }
        public class bureauMatch {
            @AuraEnabled public String identityNumber;	
            @AuraEnabled public String countryCode;	
            @AuraEnabled public String countryName;	
            @AuraEnabled public String firstName;	
            @AuraEnabled public String surname;	
            @AuraEnabled public String statusCode;	
            @AuraEnabled public String statusCodeDesc;	
            @AuraEnabled public String deceasedDate;	
            @AuraEnabled public boolean deceasedDateSpecified;
        }
        public class accounts {
            @AuraEnabled public String subscriberCode;	
            @AuraEnabled public String subscriberName;	
            @AuraEnabled public String branchCode;	
            @AuraEnabled public String accountNo;	
            @AuraEnabled public String subAccountNo;	
            @AuraEnabled public String ownershipTypeCode;	
            @AuraEnabled public String ownershipTypeCodeDesc;	
            @AuraEnabled public String reasonCode;	
            @AuraEnabled public String reasonCodeDesc;	
            @AuraEnabled public String paymentTypeCode;	
            @AuraEnabled public String paymentTypeCodeDesc;	
            @AuraEnabled public String accountTypeCode;	
            @AuraEnabled public String accountTypeCodeDesc;	
            @AuraEnabled public String industryCode;	
            @AuraEnabled public String industryCodeDesc;	
            @AuraEnabled public String openDate;	
            @AuraEnabled public String deferredPaymentDate;	
            @AuraEnabled public boolean deferredPaymentDateSpecified;
            @AuraEnabled public String lastPaymentDate;	
            @AuraEnabled public boolean lastPaymentDateSpecified;
            @AuraEnabled public String openBal;	
            @AuraEnabled public String openBalInd;	
            @AuraEnabled public String openBalIndDesc;	
            @AuraEnabled public String currentBal;	
            @AuraEnabled public boolean currentBalSpecified;
            @AuraEnabled public String currentBalInd;	
            @AuraEnabled public String currentBalIndDesc;	
            @AuraEnabled public String overdueAmount;	
            @AuraEnabled public boolean overdueAmountSpecified;
            @AuraEnabled public String overdueAmountInd;	
            @AuraEnabled public String overdueAmountIndDesc;	
            @AuraEnabled public String instalmentAmount;	
            @AuraEnabled public boolean instalmentAmountSpecified;
            @AuraEnabled public String arrearsPeriod;	
            @AuraEnabled public boolean arrearsPeriodSpecified;
            @AuraEnabled public String repaymentFreq;	
            @AuraEnabled public boolean repaymentFreqSpecified;
            @AuraEnabled public String repaymentFreqDesc;	
            @AuraEnabled public String terms;	
            @AuraEnabled public boolean termsSpecified;
            @AuraEnabled public String statusCode;	
            @AuraEnabled public String statusCodeDesc;	
            @AuraEnabled public String statusDate;	
            @AuraEnabled public boolean statusDateSpecified;
            @AuraEnabled public String thirdPartyName;	
            @AuraEnabled public String thirdPartySold;	
            @AuraEnabled public boolean thirdPartySoldSpecified;
            @AuraEnabled public String thirdPartySoldDesc;	
            @AuraEnabled public String jointLoanParticipants;	
            @AuraEnabled public boolean jointLoanParticipantsSpecified;
            @AuraEnabled public String paymentHistory;	
            @AuraEnabled public String paymentHistoryStatus;	
            @AuraEnabled public String monthEndDate;	
            @AuraEnabled public String paymentHistoryOpenBal;	
            @AuraEnabled public String paymentHistoryCurrBal;	
            @AuraEnabled public String paymentHistoryOverBal;	
            @AuraEnabled public String paymentHistoryInstBal;	
            @AuraEnabled public String paymentHistoryMonthEndDate;	
            @AuraEnabled public String paymentHistoryStatusDate;	
            @AuraEnabled public String paymentHistoryLastPmtDate;	
        }
        public class addresses {
            @AuraEnabled public String addressTypeCode;	
            @AuraEnabled public String addressTypeCodeDesc;	
            @AuraEnabled public String line1;	
            @AuraEnabled public String line2;	
            @AuraEnabled public String line3;	
            @AuraEnabled public String line4;	
            @AuraEnabled public String postalCode;	
            @AuraEnabled public String dateFirstCreated;	
            @AuraEnabled public String dateLastUpdated;	
        }
        public class adverses {
            @AuraEnabled public String subscriberCode;	
            @AuraEnabled public String subscriberName;	
            @AuraEnabled public String branchCode;	
            @AuraEnabled public String accountNo;	
            @AuraEnabled public String subAccountNo;	
            @AuraEnabled public String ownershipTypeCode;	
            @AuraEnabled public String ownershipTypeCodeDesc;	
            @AuraEnabled public String reasonCode;	
            @AuraEnabled public String reasonCodeDesc;	
            @AuraEnabled public String paymentTypeCode;	
            @AuraEnabled public String paymentTypeCodeDesc;	
            @AuraEnabled public String accountTypeCode;	
            @AuraEnabled public String accountTypeCodeDesc;	
            @AuraEnabled public String industryCode;	
            @AuraEnabled public String industryCodeDesc;	
            @AuraEnabled public String openDate;	
            @AuraEnabled public String deferredPaymentDate;	
            @AuraEnabled public boolean deferredPaymentDateSpecified;
            @AuraEnabled public String lastPaymentDate;	
            @AuraEnabled public boolean lastPaymentDateSpecified;
            @AuraEnabled public String openBal;	
            @AuraEnabled public String openBalInd;	
            @AuraEnabled public String openBalIndDesc;	
            @AuraEnabled public String currentBal;	
            @AuraEnabled public boolean currentBalSpecifiedCommonly;
            @AuraEnabled public String currentBalInd;	
            @AuraEnabled public String currentBalIndDesc;	
            @AuraEnabled public String overdueAmount;	
            @AuraEnabled public boolean overdueAmountSpecifiedCommonly;
            @AuraEnabled public String overdueAmountInd;	
            @AuraEnabled public String overdueAmountIndDesc;	
            @AuraEnabled public String instalmentAmount;	
            @AuraEnabled public boolean instalmentAmountSpecifiedCommonly;
            @AuraEnabled public String arrearsPeriod;	
            @AuraEnabled public boolean arrearsPeriodSpecifiedCommonly;
            @AuraEnabled public String repaymentFreq;	
            @AuraEnabled public boolean repaymentFreqSpecifiedCommonly;
            @AuraEnabled public String repaymentFreqDesc;	
            @AuraEnabled public String terms;	
            @AuraEnabled public boolean termsSpecifiedCommonly;
            @AuraEnabled public String statusCode;	
            @AuraEnabled public String statusCodeDesc;	
            @AuraEnabled public String statusDate;	
            @AuraEnabled public boolean statusDateSpecifiedCommonly;
            @AuraEnabled public String thirdPartyName;	
            @AuraEnabled public String thirdPartySold;	
            @AuraEnabled public boolean thirdPartySoldSpecifiedCommonly;
            @AuraEnabled public String thirdPartySoldDesc;	
            @AuraEnabled public String jointLoanParticipants;	
            @AuraEnabled public boolean jointLoanParticipantsSpecifiedCommonly;
            @AuraEnabled public String paymentHistory;	
            @AuraEnabled public String paymentHistoryStatus;	
            @AuraEnabled public String monthEndDate;	
            @AuraEnabled public String adverseCode;	
            @AuraEnabled public String adverseCodeDesc;	
            @AuraEnabled public String adverseDate;	
            @AuraEnabled public boolean adverseDateSpecified;
            @AuraEnabled public String adverseOverdueAmount;	
            @AuraEnabled public boolean adverseOverdueAmountSpecified;
            @AuraEnabled public String paymentHistoryOpenBal;	
            @AuraEnabled public String paymentHistoryCurrBal;	
            @AuraEnabled public String paymentHistoryOverBal;	
            @AuraEnabled public String paymentHistoryInstBal;	
            @AuraEnabled public String paymentHistoryMonthEndDate;	
            @AuraEnabled public String paymentHistoryStatusDate;	
            @AuraEnabled public String paymentHistoryLastPmtDate;	
        }
        public class bureauScores {
            @AuraEnabled public String riskType;	
            @AuraEnabled public String score;	
            @AuraEnabled public boolean scoreSpecified;
            @AuraEnabled public String declineReason1;	
            @AuraEnabled public String declineReason2;	
            @AuraEnabled public String declineReason3;	
            @AuraEnabled public String declineReason4;	
            @AuraEnabled public String declineReason5;	
            @AuraEnabled public String thinFileIndicator;	
            @AuraEnabled public String version;
            @AuraEnabled public boolean versionSpecified;
        }
        public class dcEnquiries {
            @AuraEnabled public String source;	
            @AuraEnabled public String enquiryDate;	
            @AuraEnabled public String dcName;	
            @AuraEnabled public String dcRegistrationNumber;	
            @AuraEnabled public String enquiryReasonOrType;	
            @AuraEnabled public String contact;	
        }
        public class debtRestructurings {
            @AuraEnabled public String regNo;	
            @AuraEnabled public String contactPerson;	
            @AuraEnabled public String telephone;	
            @AuraEnabled public String applicationDate;	
            @AuraEnabled public String statusCode;	
            @AuraEnabled public String statusCodeDesc;	
            @AuraEnabled public String statusDate;	
        }
        public class deeds {
            @AuraEnabled public String propertyId;
            @AuraEnabled public String erfNo;	
            @AuraEnabled public String propertyTypeCode;	
            @AuraEnabled public String propertyTypeCodeDesc;	
            @AuraEnabled public String township;	
            @AuraEnabled public String portion;	
            @AuraEnabled public String unit;	
            @AuraEnabled public boolean unitSpecified;
            @AuraEnabled public String sectSchemeName;	
            @AuraEnabled public propertyDetails[] propertyDetails;
            @AuraEnabled public bonds[] bonds;
        }
        public class propertyDetails {
            @AuraEnabled public String titleDeedNo;	
            @AuraEnabled public String registrationDate;	
            @AuraEnabled public String purchaseDate;	
            @AuraEnabled public boolean purchaseDateSpecified;
            @AuraEnabled public String purchasePrice;	
            @AuraEnabled public boolean purchasePriceSpecified;
            @AuraEnabled public String titleShare;
            @AuraEnabled public boolean titleShareSpecified;
        }
        public class bonds {
            @AuraEnabled public String bondNumber;	
            @AuraEnabled public String institution;	
            @AuraEnabled public String bondAmount;	
            @AuraEnabled public boolean bondAmountSpecified;
            @AuraEnabled public String bondRegistrationDateDay;	
            @AuraEnabled public String noProp;	
            @AuraEnabled public boolean noPropSpecified;
        }
        public class directors {
            @AuraEnabled public String entTypeCode;	
            @AuraEnabled public boolean entTypeCodeSpecified;
            @AuraEnabled public String entTypeCodeDesc;	
            @AuraEnabled public String companyRegNumber;	
            @AuraEnabled public String companyName;	
            @AuraEnabled public String registrationDate;	
            @AuraEnabled public boolean registrationDateSpecified;
            @AuraEnabled public String bussStartDate;	
            @AuraEnabled public boolean bussStartDateSpecified;
            @AuraEnabled public String statusCode;	
            @AuraEnabled public String statusCodeDesc;	
            @AuraEnabled public String statusDate;	
            @AuraEnabled public boolean statusDateSpecified;
            @AuraEnabled public String sicCode;	
            @AuraEnabled public boolean sicCodeSpecified;
            @AuraEnabled public String sicCodeDesc;	
            @AuraEnabled public String appDate;	
            @AuraEnabled public boolean appDateSpecified;
            @AuraEnabled public String memberTypeCode;	
            @AuraEnabled public boolean memberTypeCodeSpecified;
            @AuraEnabled public String memberTypeCodeDesc;	
            @AuraEnabled public String memberContribution;	
            @AuraEnabled public boolean memberContributionSpecified;
            @AuraEnabled public String memberContributionType;	
            @AuraEnabled public String resignationDate;	
            @AuraEnabled public boolean resignationDateSpecified;
            @AuraEnabled public String memberStatusCode;	
            @AuraEnabled public String memberStatusCodeDesc;	
            @AuraEnabled public String memberStatusDate;	
            @AuraEnabled public boolean memberStatusDateSpecified;
            @AuraEnabled public String memberSize;	
            @AuraEnabled public boolean memberSizeSpecified;
            @AuraEnabled public String taxNumber;	
        }
        public class employers {
            @AuraEnabled public String employerName;	
            @AuraEnabled public String employmentDate;	
            @AuraEnabled public String occupation;	
            @AuraEnabled public String dateFirstCreated;	
            @AuraEnabled public String dateLastUpdated;	
        }
        public class enquiries {
            @AuraEnabled public String enquiryDate;	
            @AuraEnabled public String branchName;	
            @AuraEnabled public String contactPerson;	
            @AuraEnabled public String telephoneNumber;	
            @AuraEnabled public String categoryId;	
            @AuraEnabled public String categoryIdDesc;	
        }
        public class fraud {
            @AuraEnabled public String titleCode;	
            @AuraEnabled public boolean titleCodeSpecified;
            @AuraEnabled public String title;	
            @AuraEnabled public String subjectId;	
            @AuraEnabled public String passport;	
            @AuraEnabled public String surname;	
            @AuraEnabled public String firstName;	
            @AuraEnabled public String dateOfBirth;	
            @AuraEnabled public boolean dateOfBirthSpecified;
            @AuraEnabled public String gender;	
            @AuraEnabled public String email;	
            @AuraEnabled public IncidentDetails[] IncidentDetails;
            @AuraEnabled public AddressDetails[] AddressDetails;
            @AuraEnabled public TelDetails[] TelDetails;
            @AuraEnabled public AliasDetails[] AliasDetails;
            @AuraEnabled public OtherIdDetails[] OtherIdDetails;
            @AuraEnabled public EmployerDetails[] EmployerDetails;
            @AuraEnabled public BankDetails[] BankDetails;
            @AuraEnabled public CaseDetails[] CaseDetails;
        }
        public class IncidentDetails {
            @AuraEnabled public String victim;	
            @AuraEnabled public String membersRef;	
            @AuraEnabled public String categoryCode;	
            @AuraEnabled public String categoryCodeDesc;	
            @AuraEnabled public String subcatCode;	
            @AuraEnabled public boolean subcatCodeSpecified;
            @AuraEnabled public String subcatCodeDesc;	
            @AuraEnabled public String incidentComDate;	
            @AuraEnabled public String subroleCode;	
            @AuraEnabled public boolean subroleCodeSpecified;
            @AuraEnabled public String subroleCodeDesc;	
            @AuraEnabled public String city;	
            @AuraEnabled public String detail;	
            @AuraEnabled public String forensic;	
        }
        public class AddressDetails {
            @AuraEnabled public String addTypeDesc;	
            @AuraEnabled public String street;	
            @AuraEnabled public String address;	
            @AuraEnabled public String city;	
            @AuraEnabled public String postalCode;	
            @AuraEnabled public String dateFirstCreated;	
            @AuraEnabled public boolean dateFirstCreatedSpecified;
            @AuraEnabled public String dateLastUpdated;	
            @AuraEnabled public boolean dateLastUpdatedSpecified;
        }
        public class TelDetails {
            @AuraEnabled public String telTypeCode;	
            @AuraEnabled public String telTypeCodeDesc;	
            @AuraEnabled public String telNumber;	
            @AuraEnabled public String city;	
            @AuraEnabled public String country;	
        }
        public class AliasDetails {
            @AuraEnabled public String surname;	
            @AuraEnabled public String firstname;	
        }
        public class OtherIdDetails {
            @AuraEnabled public String identityNumber;	
            @AuraEnabled public String idTypeDesc;	
            @AuraEnabled public String issueDate;	
            @AuraEnabled public boolean issueDateSpecified;
            @AuraEnabled public String country;	
        }
        public class EmployerDetails {
            @AuraEnabled public String employerName;	
            @AuraEnabled public String telephone;	
            @AuraEnabled public String companyName;	
            @AuraEnabled public String companyNo;	
            @AuraEnabled public String occupation;	
            @AuraEnabled public String dateFirstCreated;	
            @AuraEnabled public boolean dateFirstCreatedSpecified;
            @AuraEnabled public String dateLastUpdated;	
            @AuraEnabled public boolean dateLastUpdatedSpecified;
        }
        public class BankDetails {
            @AuraEnabled public String accountNo;	
            @AuraEnabled public String accountType;	
            @AuraEnabled public String bank;	
            @AuraEnabled public String dateFirstCreated;	
            @AuraEnabled public boolean dateFirstCreatedSpecified;
            @AuraEnabled public String dateLastUpdated;	
            @AuraEnabled public boolean dateLastUpdatedSpecified;
        }
        public class CaseDetails {
            @AuraEnabled public String caseNo;	
            @AuraEnabled public String reportDate;	
            @AuraEnabled public boolean reportDateSpecified;
            @AuraEnabled public String officer;	
            @AuraEnabled public String createdBy;	
            @AuraEnabled public String station;	
            @AuraEnabled public String typeCode;	
            @AuraEnabled public boolean typeCodeSpecified;
            @AuraEnabled public String typeCodeDesc;	
            @AuraEnabled public String statusCode;	
            @AuraEnabled public boolean statusCodeSpecified;
            @AuraEnabled public String statusCodeDesc;	
            @AuraEnabled public String reasonCode;	
            @AuraEnabled public boolean reasonCodeSpecified;
            @AuraEnabled public String reasonCodeDesc;	
            @AuraEnabled public String reasonExtension;	
            @AuraEnabled public String contactNo;	
            @AuraEnabled public String email;	
            @AuraEnabled public String fax;	
            @AuraEnabled public String details;	
        }
        public class judgements {
            @AuraEnabled public String dateIssued;	
            @AuraEnabled public String caseNo;	
            @AuraEnabled public String courtTypeCode;	
            @AuraEnabled public boolean courtTypeCodeSpecified;
            @AuraEnabled public String courtTypeCodeDesc;	
            @AuraEnabled public String courtName;	
            @AuraEnabled public String courtProvinceCode;	
            @AuraEnabled public boolean courtProvinceCodeSpecified;
            @AuraEnabled public String courtProvince;	
            @AuraEnabled public String attorney;	
            @AuraEnabled public String judgementTypeCode;	
            @AuraEnabled public boolean judgementTypeCodeSpecified;
            @AuraEnabled public String judgementTypeCodeDesc;	
            @AuraEnabled public String amount;	
            @AuraEnabled public String reasonCode;	
            @AuraEnabled public String reasonCodeDesc;	
            @AuraEnabled public String plaintiff;	
        }
        public class notices {
            @AuraEnabled public String dateIssued;	
            @AuraEnabled public String caseNo;	
            @AuraEnabled public String courtTypeCode;	
            @AuraEnabled public boolean courtTypeCodeSpecified;
            @AuraEnabled public String courtTypeCodeDesc;	
            @AuraEnabled public String courtName;	
            @AuraEnabled public String courtProvinceCode;	
            @AuraEnabled public boolean courtProvinceCodeSpecified;
            @AuraEnabled public String courtProvince;	
            @AuraEnabled public String attorney;	
            @AuraEnabled public String noticeTypeCode;	
            @AuraEnabled public boolean noticeTypeCodeSpecified;
            @AuraEnabled public String noticeTypeCodeDesc;	
            @AuraEnabled public String amount;	
            @AuraEnabled public String reasonCode;	
            @AuraEnabled public String reasonCodeDesc;	
            @AuraEnabled public String plaintiff;	
        }
        public class publicDefaults {
            @AuraEnabled public String branchCode;	
            @AuraEnabled public String branchName;	
            @AuraEnabled public String accountRefNumber;	
            @AuraEnabled public String defaultAmount;	
            @AuraEnabled public String defaultDate;	
            @AuraEnabled public String legalActionCode;	
            @AuraEnabled public String legalActionCodeDesc;	
        }
        public class telephones {
            @AuraEnabled public String telephoneTypeCode;	
            @AuraEnabled public String telephoneTypeDesc;	
            @AuraEnabled public String telephoneNumber;	
            @AuraEnabled public String dateFirstCreated;	
            @AuraEnabled public String dateLastUpdated;	
        }
        public class traces {
            @AuraEnabled public String subscriberName;	
            @AuraEnabled public String contactPerson;	
            @AuraEnabled public String telephone;	
            @AuraEnabled public String traceDate;	
            @AuraEnabled public String refNo;	
        }
        public class warnings {
            @AuraEnabled public String reasonCode;	
            @AuraEnabled public String reasonCodeDesc;	
        }
        public class dispute {
            @AuraEnabled public String identityNumber;	
            @AuraEnabled public String countryCode;	
            @AuraEnabled public String countryName;	
        }
        public class pinPoints {
            @AuraEnabled public numericPinpoints[] numericPinpoints;
            @AuraEnabled public alphaNumericPinpoints[] alphaNumericPinpoints;
        }
        public class numericPinpoints {
            @AuraEnabled public String name;	
            @AuraEnabled public String value;	
        }
        public class alphaNumericPinpoints {
            @AuraEnabled public String name;	
            @AuraEnabled public String value;	
        }

}