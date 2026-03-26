/**
* Class Name:       IC_FuneralResponse
* Test Class:       IC_API_ObligationServiceV3_TEST
* Author           	Ridwan Moosuddee
* Company          	BlueSky
* Ticket      		ICS-1073 - DEV Funeral: Get Obligations additional fields returned - Integration
**/
public class IC_FuneralResponse {
    public Funeral funeral;

    public class Funeral {
        public List<PolicyWrapper> policies;
    }

    public class PolicyWrapper {
        public Policy policy;
        public List<RoleplayerWrapper> roleplayers;
    }

    public class Policy {
        public ArrearDetails arrearDetails;
        public List<Benefit> benefits;
        public CancellationDetails cancellationDetails;
        public Boolean canReinstate;
        public List<Claim> claims;
        public DateTime commencementDate;
        public String contractReference;
        public DeductionDetails deductionDetails;
        public String displayStatus;
        public Boolean isOptedOutForEarlyCollection;
        public List<Mandate> mandates;
        public PaymentSchedule paymentSchedule;
        public Decimal policyMinumumPremium;
        public String policyRule;
        public String productCode;
        public String status;
        public String pasStatus; //ICS-1738 
        public Decimal totalPremium;
    }

    public class ArrearDetails {
        public Decimal outstandingAmount;
        public Integer monthsOutstanding;
        public List<Arrear> arrears;
    }

    public class Arrear {
        public Decimal amount;
        public DateTime dueDate;
        public String objectID;
        public Decimal totalArrearsAmount;
    }

    public class Benefit {
        public String type;
        public Boolean available;
        public DateTime availableDate;
    }

    public class CancellationDetails {
        public DateTime recordedCancellationDate;
        public DateTime effectiveCancellationDate;
        public String reason;
        public String displayReason;
    }

    public class Claim {
        public Roleplayer roleplayer;
        public String claimsReference;
        public Decimal claimSettlementAmount;
        public String taskReference;
        public DateTime claimIntimationDate;
        public DateTime claimReceivedOnDate;
        public DateTime claimIncidentDate;
        public String claimStatus;
        public String clientClaimStatus;
        public String claimType;
        public String subClaimType;
        public String causeOfIncident;
        public List<Document> documentsRequired;
        public List<Document> documentsReceived;
        public List<PaymentTransaction> paymentTransaction;
        public String incidentNumber;
        public String lastComment;
        public DateTime repudiationDate;
        public String repudiationReason;
    }

    public class Roleplayer {
        public Boolean beneficiary;
        public Decimal benefitPayout;
        public String cifNumber;
        public ContactDetails contactDetails;
        public Decimal coverAmount;
        public DateTime coverEndDate;
        public DateTime coverStartDate;
        public DateTime dateOfBirth;
        public String firstName;
        public String gender;
        public String idNumber;
        public String idType;
        public String ifrS17Grouping;
        public Boolean lifeAssured;
        public String middleName;
        public Decimal premium;
        public DateTime premiumStartDate;
        public String recordID;
        public String recordIDType;
        public String relationship;
        public Integer rowID;
        public String surname;
        public String title;
        public Boolean deceased_indicator;
        public Boolean waiting_flag;
    }

    public class ContactDetails {
        public String cellphone;
        public String email;
        public String homephone;
        public String workphone;
    }

    public class Document {
        public String documentCode;
        public String documentName;
        public String guid;
        public String docStatus;
        public Boolean isMandatory;
    }

    public class PaymentTransaction {
        public Decimal amount;
        public List<BankDetail> bankDetails;
        public Roleplayer beneficiary;
        public String paymentTransacdate;
        public String payStatus;
    }

    public class BankDetail {
        public String accountName;
        public String accountNumber;
        public String accountType;
        public String bank;
        public String branchCode;
    }

    public class DeductionDetails {
        public BankDetail bankDetails;
        public Integer collectionDay;
        public String collectionMethod;
        public DateTime effectiveFromDate;
        public DateTime effectiveToDate;
        public String frequency;
        public String mandateReferenceNumber;
    }

    public class Mandate {
        public String accountName;
        public String branchCode;
        public String accountNumber;
        public String bank;
        public String accountType;
        public String mandateType;
        public Decimal initialInstalmentAmount;
        public DateTime firstCollectionDate;
        public Integer numberOfDebitInstalments;
        public String statusReason;
        public String mandateStatus;
        public DateTime mandateInitiationDate;
        public Integer mandateID;
        public DateTime lastCollectionDate;
        public Decimal instalmentAmount;
        public String contractReference;
        public Integer collectionDay;
        public Integer cifNumber;
        public String idNumber;
        public String instalmentOccurrence;
        public String messageAuthenticationCode;
        public Boolean authRequired;
        public String mandateReferenceNumber;
        public String contactNumber;
        public String voiceRecordingNumber;
        public String mandateRequestTransactionIdentifier;
    }

    public class PaymentSchedule {
        public Decimal nextPaymentAmount;
        public DateTime nextPaymentDate;
        public Decimal previousArrearsPaymentAmount;
        public DateTime previousArrearsPaymentDate;
        public Decimal previousPaymentAmount;
        public DateTime previousPaymentDate;
    }

    public class RoleplayerWrapper {
        public List<RoleplayerBenefit> benefits;
        public Roleplayer details;
        public Boolean isMatchedToDeceased;
        public Integer matchScore;
    }

    public class RoleplayerBenefit {
        public String benefit;
        public Decimal coverAmount;
        public DateTime benefitStartDate;
        public DateTime benefitEndDate;
        public DateTime coverStartDate;
        public DateTime coverEffectiveDate;
        public DateTime waitingPeriodEndDate;
    }
}