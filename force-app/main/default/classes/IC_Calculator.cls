/********************************\
    @ Func Area     : IC Calculator
    @ Author        : Gerhard de Klerk
    @ Date          : 13 Nov 2024
    @ Description   : Insurance Calculations for Funeral
    @ Related files :
    @ Test File     : IC_XTND_isPending_Batch_TEST
                    :
    CHANGE LOG - Please update on every change
===================================
    @ Version - Major   : 1
    @ Version - Minor   : 1
    @ Last Modified By  :
    @ Last Modified On  :
    @ Jira Ticket       :
    @ Modification Description :
	@ -
===================================
    @ Version - Major   :
    @ Version - Minor   :
    @ Last Modified By  :
    @ Last Modified On  :
    @ Jira Ticket       :
    @ Modification Description :
	@ -

===================================

**********************************
* CLASS NOTES:
**********************************
When making a change, please increment the Class Static Variables (VERSION_MAJOR,VERSION_MINOR and VERSION_LASTMODIFIEDDATE)
with the same information as on your changelog above
**********************************/
@SuppressWarnings('InconsistentSalesforceApiVersion')
public class IC_Calculator {

/* ================================================================================================================
 *  STATIC VARIABLES
 * ================================================================================================================
 */
    private static final Integer VERSION_MAJOR = 1;
    private static final Integer VERSION_MINOR = 0;
    private static final String VERSION_LASTMODIFIEDDATE = '13 Nov 2024';


    public static final Id POLICYPARTICIPANT_BENEFICIARY_RT = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByName().get('Beneficiaries').getRecordTypeId();
    public static final Id POLICYPARTICIPANT_LIVESASSURED_RT = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByName().get('Lives Assured').getRecordTypeId();

/* ================================================================================================================
 *  INSTANCE VARIABLES AND CONSTRUCTORS
 * ================================================================================================================
 */

    public IC_Calculator (){
        this.version = new Version();
        this.interview = new Interview();
        this.claimInformation = new ClaimInformation();
        this.recommendedPayoutAmounts = new RecommendedPayoutAmounts();
        this.calculatedCoverAmount = new CalculatedCoverAmount();
        this.beneficiaries = new Map<String,PolicyParticipantBeneficiary>();
        this.livesAssured = new Map<String,PolicyParticipant>();
        this.errors = new List<Error>();
    }

    private Version version {get;set;}
    public ClaimInformation claimInformation {get;set;}
    public RecommendedPayoutAmounts recommendedPayoutAmounts {get;set;}
    public List<Error> errors {get;set;}
    public Interview interview {get;set;}

    public CalculatedCoverAmount calculatedCoverAmount {get;set;}
    public Map<String,PolicyParticipantBeneficiary> beneficiaries {get;set;}
    private Map<String,PolicyParticipant> livesAssured {get;set;}

/* ================================================================================================================
 *  HELPER CLASSES
 * ================================================================================================================
 */

    private class calculatorException extends Exception{}

    //DENOTE THE APEX CLASS DETAILS
    private class Version{
        private Integer major {get;set;}
        private Integer minor {get;set;}
        private String lastModifiedDate {get;set;}
        public Version(){
            this.major = VERSION_MAJOR;
            this.minor = VERSION_MINOR;
            this.lastModifiedDate = VERSION_LASTMODIFIEDDATE;
        }
    }

    public class Error{
        public Boolean isError {get;set;}
        public String description {get;set;}
        public String stacktrace {get;set;}
        public String method {get;set;}
        public DateTime timestamp {get;set;}

        public Error(Exception e, String method){
            this.description = e.getMessage();
            this.stacktrace = e.getStackTraceString();
            this.method = method;
            this.isError = true;
            this.timestamp = System.now();
        }
    }
    public class Interview{
        public String runningUserUsername {get;set;}
        public String runningUserId {get;set;}
        public String userProfile {get;set;}
        public String userRole {get;set;}
        public Datetime timestamp {get;set;}

        public Interview(){
            String profileId = System.UserInfo.getProfileId();
            Profile profile = [SELECT Name FROM Profile WHERE Id = :profileId];
            this.runningUserUsername = System.UserInfo.getUserName();
            this.runningUserId = System.UserInfo.getUserId();
            this.userProfile = profile.Name;
            this.userRole = System.UserInfo.getUserRoleId();
            this.timestamp = System.now();
        }
    }

    public class ClaimInformation{
        public List<String> notes {get;set;}
        public String policyNumber {get;set;}
        public String caseNumber {get;set;}
        public String benefitType {get;set;}
        public String childCaseSubStatus {get;set;} //PendingOutOfForce etc.
        public Decimal arrearsTotal {get{
            return (arrearsTotal ==null) ? 0:arrearsTotal;
            }set;}
        public Decimal refundAmount {get{
            return (refundAmount ==null) ? 0:refundAmount;
            }set;}
        public String policyStatus {get;set;}
        public Boolean isMainLifeDeceased {get;set;}
        //public Decimal deceasedCalculatedCoverAmount {get;set;}
        //public Decimal deceasedCoverAmount {get;set;}
        public Decimal deceasedCalculatedCoverAmount {get{
            return (deceasedCalculatedCoverAmount ==null) ? 0:deceasedCalculatedCoverAmount;
            }set;}
        public Decimal deceasedCoverAmount {get{
            return (deceasedCoverAmount ==null) ? 0:deceasedCoverAmount;
            }set;}

        public ClaimInformation(){
            this.notes = new List<String>();
            this.policyNumber = null;
            this.caseNumber = null;
            this.benefitType = null;
            this.childCaseSubStatus = null;
            this.arrearsTotal = 0.0;
            this.refundAmount = 0.0;
            this.policyStatus = null;
            this.isMainLifeDeceased = null;
            this.deceasedCalculatedCoverAmount = 0.0;
            this.deceasedCoverAmount = 0.0;
        }

        public void addNote(String note)
        {
            this.notes.add(note);
        }
    }

    public class RecommendedPayoutAmounts{
        private Decimal totalBenefitAmount {get;set;}
        public Decimal finalRecommendedPayoutAmount {get;set;}
        private Decimal natural {get;set;}
        private Decimal accidental {get;set;}
        private Decimal naturalPortion {get;set;}
        private Decimal accidentalPortion_NaturalPortion_Paid {get;set;}
        private Decimal accidentalPortion_NaturalPortion_Declined {get;set;}

        public RecommendedPayoutAmounts(){
            this.totalBenefitAmount = 0.0;
            this.finalRecommendedPayoutAmount = 0;
            this.natural = 0;
            this.accidental = 0;
            this.naturalPortion = 0;
            this.accidentalPortion_NaturalPortion_Paid = 0;
            this.accidentalPortion_NaturalPortion_Declined = 0;
        }
    }

    public class CalculatedCoverAmount{
        public Decimal natural {get;set;}
        public Decimal accidental {get;set;}

        public CalculatedCoverAmount(){
            this.natural = 0.0;
            this.accidental = 0.0;
        }
    }


    public virtual class PolicyParticipant{
        public String policyParticipantName {get;set;}
        public String firstName {get;set;}
        public String surname {get;set;}
        public String identityNumber {get;set;}
        public String recommendedOutcome {get;set;}
        public String Id {get;set;}
        public Decimal benefitAmount {get;set;}
        public Boolean isMainLife {get;set;}
            

        public PolicyParticipant(){
            Id = null;
            benefitAmount = 0.0;
            isMainLife = false;
            policyParticipantName = null;
            firstName = null;
            surname = null;
            identityNumber = null;
            recommendedOutcome = null;
        }
    }

    public class PolicyParticipantBeneficiary extends PolicyParticipant{
        public Decimal percentagePortionOfPayout {get;set;}
        public Decimal normalizedPercentagePortionOfPayout {get;set;}
        public Decimal apportionedRecommendedPayoutAmount {get;set;}

        public PolicyParticipantBeneficiary(){
            Id = null;
            benefitAmount = 0.0;
            isMainLife = false;
            percentagePortionOfPayout = 0;
            normalizedPercentagePortionOfPayout = 0;
            apportionedRecommendedPayoutAmount = 0;
        }
    }

    public void addBeneficiary(IC_Policy_Participant__c participant){
        if(participant != null){
            PolicyParticipantBeneficiary beneficiary = new PolicyParticipantBeneficiary();
            beneficiary.Id = participant.Id;
            beneficiary.benefitAmount = participant.IC_BenefitAmount__c;
            beneficiary.isMainLife = (participant.IC_Relationship__c == 'Main Life' || participant.IC_Relationship__c == 'MainLife')? true:false;
            beneficiary.policyParticipantName = participant.Name;
            beneficiary.firstName = participant.IC_Name__c;
            beneficiary.surname = participant.IC_Surname__c;
            beneficiary.identityNumber = participant.IC_Identity_Number__c;
            beneficiary.recommendedOutcome = participant.IC_Recommended_Outcome__c;
            this.beneficiaries.put(participant.Id,beneficiary);
        }
    }

    public void addBeneficiary(String beneficiaryId, Double beneficiaryAmount, Boolean isMainLife){
        PolicyParticipantBeneficiary beneficiary = new PolicyParticipantBeneficiary();
        beneficiary.Id = beneficiaryId;
        beneficiary.benefitAmount = beneficiaryAmount;
        beneficiary.isMainLife = isMainLife;
        this.beneficiaries.put(beneficiaryId,beneficiary);
    }

    public void addLiveAssured(IC_Policy_Participant__c participant){
        if(participant != null){
            PolicyParticipant liveAssured = new PolicyParticipant();
            liveAssured.Id = participant.Id;
            liveAssured.benefitAmount = participant.IC_BenefitAmount__c;
            liveAssured.isMainLife = (participant.IC_Relationship__c == 'Main Life' || participant.IC_Relationship__c == 'MainLife')? true:false;
            liveAssured.policyParticipantName = participant.Name;
            liveAssured.firstName = participant.IC_Name__c;
            liveAssured.surname = participant.IC_Surname__c;
            liveAssured.identityNumber = participant.IC_Identity_Number__c;
            liveAssured.recommendedOutcome = participant.IC_Recommended_Outcome__c;
            this.livesAssured.put(participant.Id,liveAssured);
        }
    }

    public void addLiveAssured(String liveAssuredId, Double beneficiaryAmount, Boolean isMainLife){
        PolicyParticipant liveAssured = new PolicyParticipant();
        liveAssured.Id = liveAssuredId;
        liveAssured.benefitAmount = beneficiaryAmount;
        liveAssured.isMainLife = isMainLife;
        this.livesAssured.put(liveAssuredId,liveAssured);
    }



    private void calculateBPPOP(){
        try{

            for(PolicyParticipantBeneficiary beneficiary : this.beneficiaries.values()){
                if(beneficiary.benefitAmount != null){
                    this.recommendedPayoutAmounts.totalBenefitAmount += beneficiary.benefitAmount;
                }
            }

            if(this.claimInformation.isMainLifeDeceased){
                System.debug('^^^ calculateBPPOP - this.claimInformation.isMainLifeDeceased');
                for(PolicyParticipantBeneficiary beneficiary : beneficiaries.values()){
                    if(beneficiary.isMainLife == false){
                        if(this.claimInformation.deceasedCoverAmount == null || this.claimInformation.deceasedCoverAmount == 0){
                            throw new IllegalArgumentException('Calculation failure - Divide by zero / null - claimInformation.deceasedCoverAmount: ' + this.claimInformation.deceasedCoverAmount);
                        }
                        beneficiary.percentagePortionOfPayout = (beneficiary.benefitAmount / claimInformation.deceasedCoverAmount).setScale(2);
                    }
                }
            }else{
                System.debug('^^^ calculateBPPOP - this.claimInformation.isMainLifeDeceased');
                if(claimInformation.policyStatus == 'PendingOutOfForce'){ //Main life has also been deceased
                    for(PolicyParticipantBeneficiary beneficiary : beneficiaries.values()){
                        if(beneficiary.isMainLife == false) {
                            if(this.recommendedPayoutAmounts.totalBenefitAmount == null || this.recommendedPayoutAmounts.totalBenefitAmount == 0){
                                throw new IllegalArgumentException('Calculation failure - Divide by zero / null - recommendedPayoutAmounts.totalBenefitAmount: ' + this.recommendedPayoutAmounts.totalBenefitAmount);
                            }
                            beneficiary.percentagePortionOfPayout = (beneficiary.benefitAmount / this.recommendedPayoutAmounts.totalBenefitAmount).setScale(2);
                        }
                    }
                }else{
                    this.beneficiaries.values()[0].percentagePortionOfPayout = 1;
                }
            }
        }catch (Exception e){
            Error error = new Error(e,'calculateBPPOP');
            this.errors.add(error);
            System.debug(error);
        }
    }

    public void calculateRecommendedPayoutAmount(){
        try{
            //13Nov2024
            //IF THE POLICY IS PENDINGOUTOFFORCE, DO NOT INCLUDE THE REFUND
            if(claimInformation.policyStatus == 'PendingOutOfForce') { //Main life has also been deceased
                this.claimInformation.addNote('The current refund amount (' + this.claimInformation.refundAmount + ') has been set to 0 as the policy is PendingOutOfForce');
                this.claimInformation.refundAmount = 0;
            }

            //Safety Checks
            /*if(calculatedCoverAmount.natural == null){
                throw new IllegalArgumentException('The calculatedCoverAmount.natural is null');
            }*/


            recommendedPayoutAmounts.natural = calculatedCoverAmount.natural - claimInformation.arrearsTotal + claimInformation.refundAmount;
            recommendedPayoutAmounts.accidental = 2 * calculatedCoverAmount.accidental - claimInformation.arrearsTotal + claimInformation.refundAmount;
            recommendedPayoutAmounts.naturalPortion = calculatedCoverAmount.natural - claimInformation.arrearsTotal + claimInformation.refundAmount;
            recommendedPayoutAmounts.accidentalPortion_NaturalPortion_Paid = recommendedPayoutAmounts.accidental - recommendedPayoutAmounts.naturalPortion;
            recommendedPayoutAmounts.accidentalPortion_NaturalPortion_Declined = recommendedPayoutAmounts.accidental;

            switch on (claimInformation.benefitType) {
                //TODO: Check benefit type values
                when 'Natural' {
                    //Recommended payout amount = (Calculated Cover Amount - ArrearsTotal + RefundAmount) * BPPOP
                    recommendedPayoutAmounts.finalRecommendedPayoutAmount = recommendedPayoutAmounts.natural;
                }
                when 'Accidental' {
                    //Recommended payout amount = (2(Accidental Calculated Cover Amount) - ArrearsTotal + RefundAmount) * BPPOP
                    recommendedPayoutAmounts.finalRecommendedPayoutAmount = recommendedPayoutAmounts.accidental;
                }
                when 'Natural Portion' {
                    //Recommended payout amount = (Calculated Cover Amount - ArrearsTotal + RefundAmount) * BPPOP
                    recommendedPayoutAmounts.finalRecommendedPayoutAmount = recommendedPayoutAmounts.naturalPortion;
                }
                when 'Accidental Portion' {
                    if (claimInformation.childCaseSubStatus == 'Payment(s) Scheduled') { //TODO: check status values
                        //Recommended payout amount = (2(Accidental Calculated Cover Amount) - sibling.payoutAmount) * BPPOP
                        recommendedPayoutAmounts.finalRecommendedPayoutAmount = recommendedPayoutAmounts.accidentalPortion_NaturalPortion_Paid;
                    } else if (claimInformation.childCaseSubStatus == 'Declined') {
                        //Recommended payout amount = (2(Accidental Calculated Cover Amount) - ArrearsTotal + RefundAmount) * BPPOP
                        recommendedPayoutAmounts.finalRecommendedPayoutAmount = recommendedPayoutAmounts.accidentalPortion_NaturalPortion_Declined;
                    }
                }
                when else{
                    //throw new calculatorException()
                    throw new IllegalArgumentException('Unknown claimInformation.benefitType: ' + claimInformation.benefitType);
                }
            }
        }catch (Exception e){
            Error error = new Error(e,'calculateRecommendedPayoutAmount');
            this.errors.add(error);
            System.debug(error);
        }
    }

    public void calculateRecommendedPayoutAmountPerBPPOP(){
        calculateBPPOP();

        //GET ALL PERCENTAGE OF PAYOUTS AND NORMALIZE
        try{

            Double totalPercentageOfPayout = 0.0;
            for(PolicyParticipantBeneficiary beneficiary : beneficiaries.values()) {
                totalPercentageOfPayout += (beneficiary.percentagePortionOfPayout).setScale(2);
            }

            //IF THE BENEFICIARY PAYOUT PERCENTAGE IS GREATER THAN 100%, NORMALIZE, ELSE USE THE VALUES EVEN IF LESS THAN 100%
            for(PolicyParticipantBeneficiary beneficiary : beneficiaries.values()) {

                if(totalPercentageOfPayout > 1){
                    beneficiary.normalizedPercentagePortionOfPayout = (beneficiary.percentagePortionOfPayout / totalPercentageOfPayout).setScale(2);
                }else{
                    beneficiary.normalizedPercentagePortionOfPayout = (beneficiary.percentagePortionOfPayout).setScale(2);
                }

                beneficiary.apportionedRecommendedPayoutAmount = (recommendedPayoutAmounts.finalRecommendedPayoutAmount * beneficiary.normalizedPercentagePortionOfPayout).setScale(2);
            }
        }catch (Exception e){
            Error error = new Error(e,'calculateRecommendedPayoutAmountPerBPPOP');
            this.errors.add(error);
            System.debug(error);
        }
    }

/* ================================================================================================================
 *  STATIC METHODS
 * ================================================================================================================
 */

    public class CoverAmounts{
        public Decimal calculatedCoverAmount {get;set;}
        public Decimal calculatedCoverAmount_Accidental {get;set;}

        public CoverAmounts(){
            calculatedCoverAmount = 0;
            calculatedCoverAmount_Accidental = 0;
        }
    }
    public static CoverAmounts calculateCoverAmountFromSegments(Map<Id,IC_Calculator.CoverAmounts> map_Participant_CoverAmounts, IC_Segment__c segment){
        system.debug('------ segment: ' + segment);
        Boolean recommendToPay = false;
        Boolean recommendToPayAccidental = false;

        if(!map_Participant_CoverAmounts.containsKey(segment.IC_Policy_Participant__c)){
            map_Participant_CoverAmounts.put(segment.IC_Policy_Participant__c, new CoverAmounts());
        }
        CoverAmounts coverAmounts = map_Participant_CoverAmounts.get(segment.IC_Policy_Participant__c);

        if (segment.IC_In_Force_on_Event_Date__c && !segment.IC_In_Waiting_Period_on_Event_Date__c) {
            recommendToPay = true;

        } else if (segment.IC_In_Force_on_Event_Date__c) {
            recommendToPayAccidental = true;

        }

        if (segment.IC_Select_to_Pay__c) {
            system.debug('------ IC_Select_to_Pay__c: ' + segment);
            coverAmounts.calculatedCoverAmount = coverAmounts.calculatedCoverAmount + segment.IC_Cover_Amount__c;
            coverAmounts.calculatedCoverAmount_Accidental = coverAmounts.calculatedCoverAmount_Accidental + segment.IC_Cover_Amount__c;
        }else if (recommendToPay) {
            system.debug('------ recommendToPay: ' + segment);
            coverAmounts.calculatedCoverAmount = coverAmounts.calculatedCoverAmount + segment.IC_Cover_Amount__c;
            coverAmounts.calculatedCoverAmount_Accidental = coverAmounts.calculatedCoverAmount_Accidental + segment.IC_Cover_Amount__c;
        }else if (recommendToPayAccidental) {
            system.debug('------ recommendToPayAccidental: ' + segment);
            coverAmounts.calculatedCoverAmount_Accidental = coverAmounts.calculatedCoverAmount_Accidental + segment.IC_Cover_Amount__c;
        }
        map_Participant_CoverAmounts.put(segment.IC_Policy_Participant__c,coverAmounts);
        return coverAmounts;
    }

}