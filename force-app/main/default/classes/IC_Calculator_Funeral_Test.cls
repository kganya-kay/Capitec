/********************************\
    @ Func Area     : IC Calculator
    @ Author        : Gerhard de Klerk
    @ Date          : 13 Nov 2024
    @ Description   : Invocable Wrapper to call the IC_Calculator from a flow
    @ Related files :
    @ Test File     : IC_Calculator_Funeral_TEST
                    :
===================================
    CHANGE LOG - Please update on every change
===================================
    @ Version - Major   :
    @ Version - Minor   :
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

**********************************/
@IsTest
public with sharing class IC_Calculator_Funeral_Test {

    private static final Id insuranceClaimsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId();
    private static final Id insuranceClaimsAssessmentRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId();
    //private static final Id POLICYPARTICIPANT_BENEFICIARY_RT = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByName().get('Beneficiaries').getRecordTypeId();
    //private static final Id POLICYPARTICIPANT_LIVESASSURED_RT = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByName().get('Lives Assured').getRecordTypeId();

    private static Decimal DEFAULTVALUE_REFUND = 20;
    private static Decimal DEFAULTVALUE_ARREARS = 10;

    /*@TestSetup
    private static void setup(){

        //CREATE PARENT CASE
        Case parentCase = new Case(
                Subject = 'Test Parent Case',
                Status = 'New',
                Sub_Status__c = 'Unclassified',
                //IC_Type__c = 'Unemployment/ITEI',
                //Sub_Type__c = 'Retrenchment',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Funeral',
                IC_Insurer_Underwriter_at_Event_Date__c = 'Centriq'
               // AccountId = a.Id
        );
        insert parentCase;

        //CREATE CHILD CASE
        Case childCase = new Case(
                Subject = 'Test Child Case',
                Status = '2nd Assessment',
                Sub_Status__c = 'Preliminary Declined',
                //IC_Type__c = 'Unemployment/ITEI',
                //Sub_Type__c = 'Retrenchment',
                //Sub_Type_Reason__c = 'New Technology',
                RecordTypeId = insuranceClaimsAssessmentRTId,
                Product_Type__c = 'Credit Life',
                IC_Insurer_Underwriter_at_Event_Date__c = 'Centriq',
                IC_1st_decline_process_completed__c = false,
                ParentId = parentCase.Id,
                IC_BenefitType__c = 'Natural'
                //AccountId = a.Id
        );
        insert childCase;




    }*/

    /*
     * ===============================================================================================================
     *  CREATION METHODS
     * ===============================================================================================================
     */
    private static Case createParentCase() {
        Case parentCase = new Case(
                Subject = 'Test Parent Case',
                Sub_Status__c = 'Unclassified',
                //IC_Type__c = 'Unemployment/ITEI',
                //Sub_Type__c = 'Retrenchment',
                RecordTypeId = insuranceClaimsRTId,
                Product_Type__c = 'Funeral',
                IC_Type__c = 'Death',
                Sub_Type__c = 'Natural',
                Sub_Type_Reason__c = 'Other Life',
                //IC_BenefitType__c = null,
                IC_UnnaturalDeathType__c = 'Accidental',
                IC_Insurer_Underwriter_at_Event_Date__c = 'Centriq',
                Status = 'Assessment'
                // AccountId = a.Id
        );
        return parentCase;
    }

    private static Case createParentCaseAccidental() {
        Case parentCase = createParentCase();
        parentCase.Sub_Type__c = 'Unnatural';
        return parentCase;
    }

    private static Case createChildCase(Id parentCaseId, String subject, String subStatus, String benefitType){
        Case childCase = new Case(
                Subject = subject,
                Status = '2nd Assessment',
                Sub_Status__c = subStatus,
                //IC_Type__c = 'Unemployment/ITEI',
                //Sub_Type__c = 'Retrenchment',
                //Sub_Type_Reason__c = 'New Technology',
                RecordTypeId = insuranceClaimsAssessmentRTId,
                Product_Type__c = 'Credit Life',
                IC_Insurer_Underwriter_at_Event_Date__c = 'Centriq',
                IC_1st_decline_process_completed__c = false,
                ParentId = parentCaseId,
                IC_BenefitType__c = benefitType
                //AccountId = a.Id
        );
        return childCase;
    }

    private static IC_Policy__c createPolicy(String policyName, Id parentCaseId, Decimal refundAmount, String status){
        //CREATE POLICY
        IC_Policy__c policy = new IC_Policy__c();
        policy.Parent_Case__c = parentCaseId;
        policy.Name = policyName;
        //policy.IC_ArrearsAmount__c //Rollup
        policy.IC_Refund_Amount__c = refundAmount;
        policy.IC_Status__c = status;
        //IC_Policy__c.IC_DeceasedMainLife__c - rollup field from policy participants
        return policy;
    }

    private static IC_Arrears__c createArrears(Id policyId, Id childCaseId, Decimal paymentDueAmount){
        IC_Arrears__c arrears = new IC_Arrears__c();
        arrears.IC_Policy__c = policyId;
        arrears.IC_Payment_Due_Amount__c = paymentDueAmount;
        arrears.IC_Child_Case__c = childCaseId;
        return arrears;
    }

    private static IC_Policy_Participant__c createLiveAssured(Person person, Id policyNumberId, Id parentCaseId, Decimal coverAmount){
        IC_Policy_Participant__c liveAssured  = new IC_Policy_Participant__c();
        liveAssured.IC_Name__c = person.personName;
        liveAssured.IC_Policy_Number__c = policyNumberId;
        liveAssured.IC_Case__c = parentCaseId;
        //policyParticipant.IC_BenefitAmount__c = 1000;
        liveAssured.IC_Cover_Amount__c = coverAmount;
        //Calculated cover amount is calculated
        liveAssured.IC_Relationship__c = person.relationship;
        liveAssured.IC_Deceased_Indicator__c = person.isDeceased;
        liveAssured.RecordTypeId = IC_Calculator.POLICYPARTICIPANT_LIVESASSURED_RT;
        liveAssured.IC_Name__c = person.personName;
        liveAssured.IC_Surname__c = 'surname';
        liveAssured.IC_Identity_Number__c = 'IdentityNumberHere';
        liveAssured.IC_Recommended_Outcome__c = 'RecommendedOutcome';
        //insert policyParticipant_livesAssured_A;
        return liveAssured;
    }

    private static IC_Policy_Participant__c createBeneficiary(Person person, Id policyNumberId, Id parentCaseId, Decimal benefitAmount){
        IC_Policy_Participant__c beneficiary  = new IC_Policy_Participant__c();
        beneficiary.IC_Name__c = person.personName;
        beneficiary.IC_Policy_Number__c = policyNumberId;
        beneficiary.IC_Case__c = parentCaseId;
        beneficiary.IC_BenefitAmount__c = benefitAmount;
        beneficiary.IC_Relationship__c = person.relationship;
        beneficiary.IC_Deceased_Indicator__c = false;
        beneficiary.RecordTypeId = IC_Calculator.POLICYPARTICIPANT_BENEFICIARY_RT;
        beneficiary.IC_Name__c = person.personName;
        beneficiary.IC_Surname__c = 'surname';
        beneficiary.IC_Identity_Number__c = 'IdentityNumberHere';
        beneficiary.IC_Recommended_Outcome__c = 'RecommendedOutcome';
        //insert policyParticipant_livesAssured_A;
        return beneficiary;
    }

    private static IC_Segment__c createSegment(Id liveAssuredId, Date startDate, Date endDate, Date coverEffectiveDate, Date dateOfDeath, String relationship, Decimal coverAmount){
        IC_Segment__c segment = new IC_Segment__c();
        segment.IC_Policy_Participant__c = liveAssuredId;
        segment.IC_Start_Date__c = startDate;
        segment.IC_End_Date__c = endDate;
        segment.IC_Cover_Effective_Date__c = coverEffectiveDate;
        segment.IC_Deceased_Date_of_Death__c = dateOfDeath;

        segment.IC_Segment_Type__c = relationship;
        segment.IC_Cover_Amount__c = coverAmount;
        //*segment.IC_Recommendation_to_Pay__c = true; //TRIGGER CALCULATED
        //segment.IC_Select_to_Pay__c = true;  //TRIGGER CALCULATED
        //segment.IC_In_Waiting_Period_on_Event_Date__c = false; //set by pushRecommendToPaySegment
        //segment.IC_In_Force_on_Event_Date__c = true; //set by pushRecommendToPaySegment
        //insert segment;
        return segment;
    }

    /*
     * ===============================================================================================================
     *  CLASSES
     * ===============================================================================================================
     */
    private class Person{
        public String personName {get;set;}
        public String relationship {get;set;}
        public Boolean isDeceased {get;set;}

        public Person(String personName, String relationship, Boolean deceased){
            this.personName = personName;
            this.relationship = relationship;
            this.isDeceased = deceased;
        }
    }

    /*
     * ===============================================================================================================
     *  RETRIEVAL METHODS
     * ===============================================================================================================
     */
    private static IC_Policy__c getPolicy(){
        IC_Policy__c policy = [
                SELECT
                        Id,
                        Name,
                        IC_ArrearsAmount__c,
                        IC_Refund_Amount__c,
                        IC_Status__c,
                        IC_ActualCoverAmount__c,
                        IC_DeceasedCovermount__c,
                        IC_DeceasedCalculatedCoverAmount__c,
                        IC_Deceased_Calculated_AccidentCoverAmnt__c,
                        IC_DeceasedMainLife__c
                FROM IC_Policy__c];

        System.debug('### ------------------------------ POLICY - RETRIEVED -------------------------------------');
        System.debug(JSON.serializePretty(policy));
        return policy;
    }
    private static List<IC_Policy__c> getPolicies(){
        List<IC_Policy__c> policies = [
                SELECT
                        Id,
                        Name,
                        IC_ArrearsAmount__c,
                        IC_Refund_Amount__c,
                        IC_Status__c,
                        IC_ActualCoverAmount__c,
                        IC_DeceasedCovermount__c,
                        IC_DeceasedCalculatedCoverAmount__c,
                        IC_Deceased_Calculated_AccidentCoverAmnt__c,
                        IC_DeceasedMainLife__c
                FROM IC_Policy__c];

        System.debug('### ------------------------------ POLICY - RETRIEVED -------------------------------------');
        System.debug(JSON.serializePretty(policies));
        return policies;
    }

    private static List<IC_Policy_Participant__c> getPolicyParticipants(){
        List<IC_Policy_Participant__c> policyParticipants = [
                SELECT
                        Id,
                        Name,
                        IC_BenefitAmount__c,
                        IC_Relationship__c,
                        RecordTypeId,
                        IC_Record_Type_DeveloperName__c,
                        IC_Calculated_Cover_Amount__c,
                        IC_Accidental_Calculated_Cover_Amount__c,
                        IC_Policy_Number__c,
                        IC_Policy_Number__r.Name,
                        IC_Case__c,
                        IC_Policy_Calculations__c,
                        IC_Deceased_Indicator__c,
                        IC_Calculated_Payout_Amount__c
                FROM IC_Policy_Participant__c];

        System.debug('### ------------------------------ POLICY PARTICIPANTS - RETRIEVED -------------------------------------');
        System.debug(JSON.serializePretty(policyParticipants));
        return policyParticipants;
    }


    private static Case getChildCase(){
        Case childCase = [
                SELECT
                        Id,
                        CaseNumber,
                        Subject,
                        Status,
                        Sub_Status__c,
                        Product_Type__c,
                        IC_Insurer_Underwriter_at_Event_Date__c,
                        IC_1st_decline_process_completed__c,
                        ParentId,
                        IC_BenefitType__c,
                        IC_Cover_Amount_Rollup__c
                FROM
                        Case
                WHERE
                        RecordTypeId = :insuranceClaimsAssessmentRTId
                LIMIT 1
        ];

        System.debug('### ------------------------------ CHILD CASE - RETRIEVED -------------------------------------');
        System.debug(JSON.serializePretty(childCase));
        return childCase;
    }

    private static List<IC_Segment__c> getSegments(){
        List<IC_Segment__c> segments = [
                SELECT
                        Id,
                        IC_Recommendation_to_Pay__c,
                        IC_Select_to_Pay__c,
                        IC_Policy_Participant__c,
                        IC_Policy_Participant__r.Name,
                        IC_Cover_Amount__c,
                        IC_Deceased_Date_of_Death__c,
                        IC_Cover_Effective_Date__c,
                        IC_Start_Date__c,
                        IC_End_Date__c,
                        IC_Actual_Cover__c
                FROM
                        IC_Segment__c
        ];

        System.debug('### ------------------------------ SEGMENTS - RETRIEVED -------------------------------------');
        System.debug(JSON.serializePretty(segments));
        return segments;
    }



    /*
     * ===============================================================================================================
     *  TEST METHODS - FLOW REQUEST
     * ===============================================================================================================
     */



    /**
     * @description Calculator test with actual values - Policy In-force
     * Death type: NATURAL
     * Death: Live Assured (non-main life)
     * - Segment = Not In waiting period
     * - Multiple Beneficiaries but only pay main life
     */
    @IsTest
    private static void test_ActualRecords_FlowRequest(){
        //TEST PARAMETERS (tp)
        Decimal tp_Arrears = 31;
        Decimal tp_Refund = 331;

        Test.startTest();
        Case parentCase_create = createParentCase();
        insert parentCase_create;

        Case childCase_create = createChildCase(parentCase_create.Id, 'Test Child Case', 'Preliminary Declined', 'Natural');
        insert childCase_create;
        Test.stopTest();

        System.debug('### PARENT CASE: ' + JSON.serializePretty(parentCase_create));
        System.debug('### CHILD CASE: ' + JSON.serializePretty(childCase_create));



        //Id parentCaseId = childCase_create.ParentId;

        String policyName = 'insurancePolicy1';
        //Id parentCaseId = childCase.Id;
        Decimal refundAmount = tp_Refund;
        String status = 'Active';
        IC_Policy__c policy_create = createPolicy(policyName, parentCase_create.Id, refundAmount, status);
        insert policy_create;

        //Create Arrears against policy
        IC_Arrears__c arrears = createArrears(policy_create.Id, childCase_create.Id, tp_Arrears);
        insert arrears;


        Person person_A = new Person('Person A','Main Life',false);
        Person person_B = new Person('Person B','Spouse',true);
        Person person_C = new Person('Person C','Child',false);
        //Lives Assured
        List<IC_Policy_Participant__c> policyParticipantsToCreate = new List<IC_Policy_Participant__c>();
        IC_Policy_Participant__c liveAssured_A = createLiveAssured(person_A, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_A);

        IC_Policy_Participant__c liveAssured_B = createLiveAssured(person_B, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_B);

        IC_Policy_Participant__c liveAssured_C = createLiveAssured(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_C);


        //Beneficiaries
        IC_Policy_Participant__c beneficiary_A = createBeneficiary(person_A, policy_create.Id, parentCase_create.Id, null);
        policyParticipantsToCreate.add(beneficiary_A);
        IC_Policy_Participant__c beneficiary_C = createBeneficiary(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(beneficiary_C);
        insert policyParticipantsToCreate;


        List<IC_Segment__c> segments = new List<IC_Segment__c>();
        Date startDate = Date.today().addDays(-5);
        Date endDate = Date.today().addDays(+10);
        Date coverEffectiveDate = Date.today();
        Date dateOfDeath = Date.today().addDays(1);
        IC_Segment__c segment_A = createSegment(liveAssured_A.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'MainLife', 100000);
        IC_Segment__c segment_B = createSegment(liveAssured_B.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000); //TODO: Check relationship aka segment_type
        IC_Segment__c segment_C = createSegment(liveAssured_C.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000);

        segments.add(segment_A);
        segments.add(segment_B);
        segments.add(segment_C);
        insert segments;

        //SET THE BENEFICIARY ON THE CHILD CASE
        childCase_create.IC_Beneficiary__c = beneficiary_A.Id;
        update childCase_create;


        //RETRIEVE RECORDS FOR CALCULATOR
        //  - Use the Child Case to get the parent ifo as well
        //Get Child Case
        Case childCase = getChildCase();

        IC_Policy__c policy = getPolicy();


        List<IC_Calculator_Funeral.FlowRequest> requests = new List<IC_Calculator_Funeral.FlowRequest>();
        IC_Calculator_Funeral.FlowRequest request = new IC_Calculator_Funeral.FlowRequest();
        request.childCases = new List<Case>{childCase_create};
        requests.add(request);

        List<IC_Calculator_Funeral.FlowResponse> responses = IC_Calculator_Funeral.calculate(requests);

        System.debug('### ------------------------------ responses -------------------------------------');
        System.debug('### responses: ' + JSON.serializePretty(responses));

        List<IC_Policy_Participant__c> policyParticipants = getPolicyParticipants();


        System.assertEquals(0,responses[0].calcResults[0].errors.size(),'An Error has been encountered: ' + responses[0].calcResults[0].errors);
        System.assertEquals(1,responses[0].calcResults[0].beneficiaries.values()[0].percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(100300,responses[0].calcResults[0].beneficiaries.values()[0].apportionedRecommendedPayoutAmount,'Unexpected apportionedRecommendedPayoutAmount');
    }

    /**
     * @description Calculator test with actual values - Policy In-force
     * Death type: NATURAL
     * Death: Live Assured (non-main life)
     * - Segment = Not In waiting period
     * - Multiple Beneficiaries but only pay main life
     * - Extra segment selected to pay (Segment Cover = R20k)
     *//*
    @IsTest
    private static void test_ActualRecords_FlowRequest_AdditionalSegmentSelectedToPay(){
        //TEST PARAMETERS (tp)
        Decimal tp_Arrears = 31;
        Decimal tp_Refund = 331;

        Test.startTest();
        Case parentCase_create = createParentCase();
        insert parentCase_create;

        Case childCase_create = createChildCase(parentCase_create.Id, 'Test Child Case', 'Preliminary Declined', 'Natural');
        insert childCase_create;
        Test.stopTest();

        System.debug('### PARENT CASE: ' + JSON.serializePretty(parentCase_create));
        System.debug('### CHILD CASE: ' + JSON.serializePretty(childCase_create));



        //Id parentCaseId = childCase_create.ParentId;

        String policyName = 'insurancePolicy1';
        //Id parentCaseId = childCase.Id;
        Decimal refundAmount = tp_Refund;
        String status = 'Active';
        IC_Policy__c policy_create = createPolicy(policyName, parentCase_create.Id, refundAmount, status);
        insert policy_create;

        //Create Arrears against policy
        IC_Arrears__c arrears = createArrears(policy_create.Id, childCase_create.Id, tp_Arrears);
        insert arrears;


        Person person_A = new Person('Person A','Main Life',false);
        Person person_B = new Person('Person B','Spouse',true);
        Person person_C = new Person('Person C','Child',false);
        //Lives Assured
        List<IC_Policy_Participant__c> policyParticipantsToCreate = new List<IC_Policy_Participant__c>();
        IC_Policy_Participant__c liveAssured_A = createLiveAssured(person_A, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_A);

        IC_Policy_Participant__c liveAssured_B = createLiveAssured(person_B, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_B);

        IC_Policy_Participant__c liveAssured_C = createLiveAssured(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_C);


        //Beneficiaries
        IC_Policy_Participant__c beneficiary_A = createBeneficiary(person_A, policy_create.Id, parentCase_create.Id, null);
        policyParticipantsToCreate.add(beneficiary_A);
        IC_Policy_Participant__c beneficiary_C = createBeneficiary(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(beneficiary_C);
        insert policyParticipantsToCreate;


        List<IC_Segment__c> segments = new List<IC_Segment__c>();
        Date startDate = Date.today().addDays(-5);
        Date endDate = Date.today().addDays(+10);
        Date coverEffectiveDate = Date.today();
        Date dateOfDeath = Date.today().addDays(1);
        IC_Segment__c segment_A = createSegment(liveAssured_A.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'MainLife', 100000);
        IC_Segment__c segment_B = createSegment(liveAssured_B.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000); //TODO: Check relationship aka segment_type
        IC_Segment__c segment_B_2 = createSegment(liveAssured_B.Id, startDate.addDays(-100), endDate.addDays(-100), coverEffectiveDate.addDays(-100), dateOfDeath, 'Other', 20000);
        IC_Segment__c segment_C = createSegment(liveAssured_C.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000);

        segments.add(segment_A);
        segments.add(segment_B_2);
        segments.add(segment_B);
        segments.add(segment_C);
        insert segments;

        //SET THE BENEFICIARY ON THE CHILD CASE
        childCase_create.IC_Beneficiary__c = beneficiary_A.Id;
        update childCase_create;


        //RETRIEVE RECORDS FOR CALCULATOR
        //  - Use the Child Case to get the parent ifo as well
        //Get Child Case
        Case childCase = getChildCase();

        IC_Policy__c policy = getPolicy();

        //SELECT TO PAY EXTRA SEGMENT
        segment_B_2.IC_Select_to_Pay__c = true;
        update segment_B_2;

        List<IC_Segment__c> segmentsRetrieved = getSegments();

        List<IC_Calculator_Funeral.FlowRequest> requests = new List<IC_Calculator_Funeral.FlowRequest>();
        IC_Calculator_Funeral.FlowRequest request = new IC_Calculator_Funeral.FlowRequest();
        request.childCases = new List<Case>{childCase_create};
        requests.add(request);

        List<IC_Calculator_Funeral.FlowResponse> responses = IC_Calculator_Funeral.calculate(requests);

        System.debug('### ------------------------------ responses -------------------------------------');
        System.debug('### responses: ' + JSON.serializePretty(responses));

        List<IC_Policy_Participant__c> policyParticipants = getPolicyParticipants();


        System.assertEquals(0,responses[0].calcResults[0].errors.size(),'An Error has been encountered: ' + responses[0].calcResults[0].errors);
        System.assertEquals(1,responses[0].calcResults[0].beneficiaries.values()[0].percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(120300,responses[0].calcResults[0].beneficiaries.values()[0].apportionedRecommendedPayoutAmount,'Unexpected apportionedRecommendedPayoutAmount');
    }*/

    /**
     * @description Calculator test with actual values - Policy In-force
     * Death type: ACCIDENTAL
     * Death: Live Assured (non-main life)
     * - Segment = Not In waiting period
     * - Multiple Beneficiaries but only pay main life
     */
    @IsTest
    private static void test_ActualRecords_FlowRequest_Accidental(){
        //TEST PARAMETERS (tp)
        Decimal tp_Arrears = 31;
        Decimal tp_Refund = 331;

        Test.startTest();
        Case parentCase_create = createParentCaseAccidental();
        insert parentCase_create;

        Case childCase_create = createChildCase(parentCase_create.Id, 'Test Child Case', 'Preliminary Declined', 'Accidental');
        insert childCase_create;
        Test.stopTest();

        System.debug('### PARENT CASE: ' + JSON.serializePretty(parentCase_create));
        System.debug('### CHILD CASE: ' + JSON.serializePretty(childCase_create));



        //Id parentCaseId = childCase_create.ParentId;

        String policyName = 'insurancePolicy1';
        //Id parentCaseId = childCase.Id;
        Decimal refundAmount = tp_Refund;
        String status = 'Active';
        IC_Policy__c policy_create = createPolicy(policyName, parentCase_create.Id, refundAmount, status);
        insert policy_create;

        //Create Arrears against policy
        IC_Arrears__c arrears = createArrears(policy_create.Id, childCase_create.Id, tp_Arrears);
        insert arrears;


        Person person_A = new Person('Person A','Main Life',false);
        Person person_B = new Person('Person B','Spouse',true);
        Person person_C = new Person('Person C','Child',false);
        //Lives Assured
        List<IC_Policy_Participant__c> policyParticipantsToCreate = new List<IC_Policy_Participant__c>();
        IC_Policy_Participant__c liveAssured_A = createLiveAssured(person_A, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_A);

        IC_Policy_Participant__c liveAssured_B = createLiveAssured(person_B, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_B);

        IC_Policy_Participant__c liveAssured_C = createLiveAssured(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_C);


        //Beneficiaries
        IC_Policy_Participant__c beneficiary_A = createBeneficiary(person_A, policy_create.Id, parentCase_create.Id, null);
        policyParticipantsToCreate.add(beneficiary_A);
        IC_Policy_Participant__c beneficiary_C = createBeneficiary(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(beneficiary_C);
        insert policyParticipantsToCreate;


        List<IC_Segment__c> segments = new List<IC_Segment__c>();
        Date startDate = Date.today().addDays(-5);
        Date endDate = Date.today().addDays(+10);
        Date coverEffectiveDate = Date.today();
        Date dateOfDeath = Date.today().addDays(1);
        IC_Segment__c segment_A = createSegment(liveAssured_A.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'MainLife', 100000);
        IC_Segment__c segment_B = createSegment(liveAssured_B.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000); //TODO: Check relationship aka segment_type
        IC_Segment__c segment_C = createSegment(liveAssured_C.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000);

        segments.add(segment_A);
        segments.add(segment_B);
        segments.add(segment_C);
        insert segments;

        //SET THE BENEFICIARY ON THE CHILD CASE
        childCase_create.IC_Beneficiary__c = beneficiary_A.Id;
        update childCase_create;


        //RETRIEVE RECORDS FOR CALCULATOR
        //  - Use the Child Case to get the parent ifo as well
        //Get Child Case
        Case childCase = getChildCase();

        IC_Policy__c policy = getPolicy();


        List<IC_Calculator_Funeral.FlowRequest> requests = new List<IC_Calculator_Funeral.FlowRequest>();
        IC_Calculator_Funeral.FlowRequest request = new IC_Calculator_Funeral.FlowRequest();
        request.childCases = new List<Case>{childCase_create};
        requests.add(request);

        List<IC_Calculator_Funeral.FlowResponse> responses = IC_Calculator_Funeral.calculate(requests);

        System.debug('### ------------------------------ responses -------------------------------------');
        System.debug('### responses: ' + JSON.serializePretty(responses));

        List<IC_Policy_Participant__c> policyParticipants = getPolicyParticipants();


        System.assertEquals(0,responses[0].calcResults[0].errors.size(),'An Error has been encountered: ' + responses[0].calcResults[0].errors);
        System.assertEquals(1,responses[0].calcResults[0].beneficiaries.values()[0].percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(200300,responses[0].calcResults[0].beneficiaries.values()[0].apportionedRecommendedPayoutAmount,'Unexpected apportionedRecommendedPayoutAmount');
    }

    /**
     * @description Calculator test with actual values - Policy In-force
     * Death type: ACCIDENTAL
     * Death: Live Assured (non-main life)
     * - Segment = Not In waiting period
     * - Extra Segment with value R20k selected to pay
     * - Multiple Beneficiaries but only pay main life
     */
    /*@IsTest
    private static void test_ActualRecords_FlowRequest_Accidental_ExtraSegment(){
        //TEST PARAMETERS (tp)
        Decimal tp_Arrears = 31;
        Decimal tp_Refund = 331;

        Test.startTest();
        Case parentCase_create = createParentCaseAccidental();
        insert parentCase_create;

        Case childCase_create = createChildCase(parentCase_create.Id, 'Test Child Case', 'Preliminary Declined', 'Accidental');
        insert childCase_create;


        System.debug('### PARENT CASE: ' + JSON.serializePretty(parentCase_create));
        System.debug('### CHILD CASE: ' + JSON.serializePretty(childCase_create));



        //Id parentCaseId = childCase_create.ParentId;

        String policyName = 'insurancePolicy1';
        //Id parentCaseId = childCase.Id;
        Decimal refundAmount = tp_Refund;
        String status = 'Active';
        IC_Policy__c policy_create = createPolicy(policyName, parentCase_create.Id, refundAmount, status);
        insert policy_create;

        //Create Arrears against policy
        IC_Arrears__c arrears = createArrears(policy_create.Id, childCase_create.Id, tp_Arrears);
        insert arrears;


        Person person_A = new Person('Person A','Main Life',false);
        Person person_B = new Person('Person B','Spouse',true);
        Person person_C = new Person('Person C','Child',false);
        //Lives Assured
        List<IC_Policy_Participant__c> policyParticipantsToCreate = new List<IC_Policy_Participant__c>();
        IC_Policy_Participant__c liveAssured_A = createLiveAssured(person_A, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_A);

        IC_Policy_Participant__c liveAssured_B = createLiveAssured(person_B, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_B);

        IC_Policy_Participant__c liveAssured_C = createLiveAssured(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_C);


        //Beneficiaries
        IC_Policy_Participant__c beneficiary_A = createBeneficiary(person_A, policy_create.Id, parentCase_create.Id, null);
        policyParticipantsToCreate.add(beneficiary_A);
        IC_Policy_Participant__c beneficiary_C = createBeneficiary(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(beneficiary_C);
        insert policyParticipantsToCreate;


        List<IC_Segment__c> segments = new List<IC_Segment__c>();
        Date startDate = Date.today().addDays(-5);
        Date endDate = Date.today().addDays(+10);
        Date coverEffectiveDate = Date.today();
        Date dateOfDeath = Date.today().addDays(1);
        IC_Segment__c segment_A = createSegment(liveAssured_A.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'MainLife', 100000);
        IC_Segment__c segment_B = createSegment(liveAssured_B.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000); //TODO: Check relationship aka segment_type
        IC_Segment__c segment_B_2 = createSegment(liveAssured_B.Id, startDate.addDays(-100), endDate.addDays(-100), coverEffectiveDate.addDays(-100), dateOfDeath, 'Other', 20000);
        IC_Segment__c segment_C = createSegment(liveAssured_C.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000);

        segments.add(segment_A);
        segments.add(segment_B);
        segments.add(segment_B_2);
        segments.add(segment_C);
        insert segments;

        //SET THE BENEFICIARY ON THE CHILD CASE
        childCase_create.IC_Beneficiary__c = beneficiary_A.Id;
        update childCase_create;


        //RETRIEVE RECORDS FOR CALCULATOR
        //  - Use the Child Case to get the parent ifo as well
        //Get Child Case
        //Case childCase = getChildCase();

        //IC_Policy__c policy = getPolicy();

        //SELECT TO PAY EXTRA SEGMENT
        segment_B_2.IC_Select_to_Pay__c = true;
        update segment_B_2;

        //List<IC_Segment__c> segmentsRetrieved = getSegments();

        Test.stopTest();
        List<IC_Calculator_Funeral.FlowRequest> requests = new List<IC_Calculator_Funeral.FlowRequest>();
        IC_Calculator_Funeral.FlowRequest request = new IC_Calculator_Funeral.FlowRequest();
        request.childCases = new List<Case>{childCase_create};
        requests.add(request);

        List<IC_Calculator_Funeral.FlowResponse> responses = IC_Calculator_Funeral.calculate(requests);

        System.debug('### ------------------------------ responses -------------------------------------');
        System.debug('### responses: ' + JSON.serializePretty(responses));

        //List<IC_Policy_Participant__c> policyParticipants = getPolicyParticipants();


        System.assertEquals(0,responses[0].calcResults[0].errors.size(),'An Error has been encountered: ' + responses[0].calcResults[0].errors);
        System.assertEquals(1,responses[0].calcResults[0].beneficiaries.values()[0].percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(240300,responses[0].calcResults[0].beneficiaries.values()[0].apportionedRecommendedPayoutAmount,'Unexpected apportionedRecommendedPayoutAmount');
    }
*/


    /**
     * @description Calculator test with actual values - Policy In-force
     * Death type: NATURAL
     * Death: Live Assured (non-main life)
     * - Segment = Not In waiting period
     * - Multiple Beneficiaries but only pay main life
     */
    @IsTest
    private static void test_ActualRecords_FlowRequest_MultiplePolicies(){
        //TEST PARAMETERS (tp)
        Decimal tp_Arrears = 31;
        Decimal tp_Refund = 331;

        Test.startTest();
        Case parentCase_create = createParentCase();
        insert parentCase_create;

        Case childCase_create = createChildCase(parentCase_create.Id, 'Test Child Case', 'Preliminary Declined', 'Natural');
        insert childCase_create;
        Test.stopTest();

        System.debug('### PARENT CASE: ' + JSON.serializePretty(parentCase_create));
        System.debug('### CHILD CASE: ' + JSON.serializePretty(childCase_create));



        //Id parentCaseId = childCase_create.ParentId;

        String policyName = 'insurancePolicy1';
        //Id parentCaseId = childCase.Id;
        Decimal refundAmount = tp_Refund;
        String status = 'Active';
        IC_Policy__c policy_create = createPolicy(policyName, parentCase_create.Id, refundAmount, status);
        insert policy_create;

        //POLICY 2
        String policyName2 = 'insurancePolicy2';
        //Id parentCaseId = childCase.Id;
        Decimal refundAmount2 = 0;
        String status2 = 'Active';
        IC_Policy__c policy_create2 = createPolicy(policyName2, parentCase_create.Id, refundAmount2, status2);
        insert policy_create2;

        //Create Arrears against policy
        IC_Arrears__c arrears = createArrears(policy_create.Id, childCase_create.Id, tp_Arrears);
        insert arrears;


        Person person_A = new Person('Person A','Main Life',false);
        Person person_B = new Person('Person B','Spouse',true);
        Person person_C = new Person('Person C','Child',false);
        //Lives Assured
        List<IC_Policy_Participant__c> policyParticipantsToCreate = new List<IC_Policy_Participant__c>();
        IC_Policy_Participant__c liveAssured_A = createLiveAssured(person_A, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_A);

        IC_Policy_Participant__c liveAssured_B = createLiveAssured(person_B, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_B);

        IC_Policy_Participant__c liveAssured_C = createLiveAssured(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_C);

        //POLICY 2:
        //Lives Assured
        IC_Policy_Participant__c liveAssured_A_pol2= createLiveAssured(person_A, policy_create2.Id, parentCase_create.Id, 20000);
        policyParticipantsToCreate.add(liveAssured_A_pol2);

        IC_Policy_Participant__c liveAssured_B_pol2 = createLiveAssured(person_B, policy_create2.Id, parentCase_create.Id, 20000);
        policyParticipantsToCreate.add(liveAssured_B_pol2);

        IC_Policy_Participant__c liveAssured_C_pol2 = createLiveAssured(person_C, policy_create2.Id, parentCase_create.Id, 20000);
        policyParticipantsToCreate.add(liveAssured_C_pol2);


        //Beneficiaries
        IC_Policy_Participant__c beneficiary_A = createBeneficiary(person_A, policy_create.Id, parentCase_create.Id, null);
        policyParticipantsToCreate.add(beneficiary_A);
        IC_Policy_Participant__c beneficiary_C = createBeneficiary(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(beneficiary_C);

        //POLICY 2 BENEFICIARIES
        IC_Policy_Participant__c beneficiary_A_pol2 = createBeneficiary(person_A, policy_create2.Id, parentCase_create.Id, null);
        policyParticipantsToCreate.add(beneficiary_A_pol2);
        IC_Policy_Participant__c beneficiary_C_pol2 = createBeneficiary(person_C, policy_create2.Id, parentCase_create.Id, 20000);
        policyParticipantsToCreate.add(beneficiary_C_pol2);

        insert policyParticipantsToCreate;


        List<IC_Segment__c> segments = new List<IC_Segment__c>();
        Date startDate = Date.today().addDays(-5);
        Date endDate = Date.today().addDays(+10);
        Date coverEffectiveDate = Date.today();
        Date dateOfDeath = Date.today().addDays(1);
        IC_Segment__c segment_A = createSegment(liveAssured_A.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'MainLife', 100000);
        IC_Segment__c segment_B = createSegment(liveAssured_B.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000); //TODO: Check relationship aka segment_type
        IC_Segment__c segment_C = createSegment(liveAssured_C.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000);

        //Policy2
        IC_Segment__c segment_A_pol2 = createSegment(liveAssured_A_pol2.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'MainLife', 100000);
        IC_Segment__c segment_B_pol2 = createSegment(liveAssured_B_pol2.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000); //TODO: Check relationship aka segment_type
        IC_Segment__c segment_C_pol2 = createSegment(liveAssured_C_pol2.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000);

        segments.add(segment_A);
        segments.add(segment_B);
        segments.add(segment_C);
        segments.add(segment_A_pol2);
        segments.add(segment_B_pol2);
        segments.add(segment_C_pol2);
        insert segments;

        //SET THE BENEFICIARY ON THE CHILD CASE
        childCase_create.IC_Beneficiary__c = beneficiary_A.Id;
        update childCase_create;


        //RETRIEVE RECORDS FOR CALCULATOR
        //  - Use the Child Case to get the parent ifo as well
        //Get Child Case
        Case childCase = getChildCase();

        //IC_Policy__c policy = getPolicy();
        List<IC_Policy__c> policies = getPolicies();


        List<IC_Calculator_Funeral.FlowRequest> requests = new List<IC_Calculator_Funeral.FlowRequest>();
        IC_Calculator_Funeral.FlowRequest request = new IC_Calculator_Funeral.FlowRequest();
        request.childCases = new List<Case>{childCase_create};
        //request.beneficiaries = new List<IC_Policy_Participant__c>{beneficiary_A};
        //request.beneficiaries = new List<IC_Policy_Participant__c>{beneficiary_C};
        requests.add(request);

        List<IC_Calculator_Funeral.FlowResponse> responses = IC_Calculator_Funeral.calculate(requests);

        System.debug('### ------------------------------ responses -------------------------------------');
        System.debug('### responses: ' + JSON.serializePretty(responses));

        List<IC_Policy_Participant__c> policyParticipants = getPolicyParticipants();


        System.assertEquals(0,responses[0].calcResults[0].errors.size(),'An Error has been encountered: ' + responses[0].calcResults[0].errors);
        System.assertEquals(1,responses[0].calcResults[0].beneficiaries.values()[0].percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(100300,responses[0].calcResults[0].beneficiaries.values()[0].apportionedRecommendedPayoutAmount,'Unexpected apportionedRecommendedPayoutAmount');
    }

    /**
     * @description Calculator test with actual values - Policy In-force
     * Death type: NATURAL
     * Death: Live Assured (non-main life)
     * - Segment = Not In waiting period
     * - Multiple Beneficiaries but only pay main life
     */
    @IsTest
    private static void test_ActualRecords_FlowRequest_MultiplePoliciesAddedToRequest(){
        //TEST PARAMETERS (tp)
        Decimal tp_Arrears = 31;
        Decimal tp_Refund = 331;

        Test.startTest();
        Case parentCase_create = createParentCase();
        insert parentCase_create;

        List<Case> childCasesToCreate = new List<Case>();
        Case childCase_create = createChildCase(parentCase_create.Id, 'Test Child Case', 'Preliminary Declined', 'Natural');
        childCasesToCreate.add(childCase_create);
        Case childCase_create2 = createChildCase(parentCase_create.Id, 'Test Child Case2', 'Preliminary Declined', 'Natural');
        childCasesToCreate.add(childCase_create2);
        insert childCasesToCreate;
        Test.stopTest();

        System.debug('### PARENT CASE: ' + JSON.serializePretty(parentCase_create));
        System.debug('### CHILD CASE: ' + JSON.serializePretty(childCase_create));
        System.debug('### CHILD CASE2: ' + JSON.serializePretty(childCase_create2));



        //Id parentCaseId = childCase_create.ParentId;

        String policyName = 'insurancePolicy1';
        //Id parentCaseId = childCase.Id;
        Decimal refundAmount = tp_Refund;
        String status = 'Active';
        IC_Policy__c policy_create = createPolicy(policyName, parentCase_create.Id, refundAmount, status);
        insert policy_create;

        //POLICY 2
        String policyName2 = 'insurancePolicy2';
        //Id parentCaseId = childCase.Id;
        Decimal refundAmount2 = 0;
        String status2 = 'Active';
        IC_Policy__c policy_create2 = createPolicy(policyName2, parentCase_create.Id, refundAmount2, status2);
        insert policy_create2;

        //Create Arrears against policy
        IC_Arrears__c arrears = createArrears(policy_create.Id, childCase_create.Id, tp_Arrears);
        insert arrears;


        Person person_A = new Person('Person A','Main Life',false);
        Person person_B = new Person('Person B','Spouse',true);
        Person person_C = new Person('Person C','Child',false);
        //Lives Assured
        List<IC_Policy_Participant__c> policyParticipantsToCreate = new List<IC_Policy_Participant__c>();
        IC_Policy_Participant__c liveAssured_A = createLiveAssured(person_A, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_A);

        IC_Policy_Participant__c liveAssured_B = createLiveAssured(person_B, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_B);

        IC_Policy_Participant__c liveAssured_C = createLiveAssured(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(liveAssured_C);

        //POLICY 2:
        //Lives Assured
        IC_Policy_Participant__c liveAssured_A_pol2= createLiveAssured(person_A, policy_create2.Id, parentCase_create.Id, 20000);
        policyParticipantsToCreate.add(liveAssured_A_pol2);

        IC_Policy_Participant__c liveAssured_B_pol2 = createLiveAssured(person_B, policy_create2.Id, parentCase_create.Id, 20000);
        policyParticipantsToCreate.add(liveAssured_B_pol2);

        IC_Policy_Participant__c liveAssured_C_pol2 = createLiveAssured(person_C, policy_create2.Id, parentCase_create.Id, 20000);
        policyParticipantsToCreate.add(liveAssured_C_pol2);


        //Beneficiaries
        IC_Policy_Participant__c beneficiary_A = createBeneficiary(person_A, policy_create.Id, parentCase_create.Id, null);
        policyParticipantsToCreate.add(beneficiary_A);
        IC_Policy_Participant__c beneficiary_C = createBeneficiary(person_C, policy_create.Id, parentCase_create.Id, 100000);
        policyParticipantsToCreate.add(beneficiary_C);

        //POLICY 2 BENEFICIARIES
        IC_Policy_Participant__c beneficiary_A_pol2 = createBeneficiary(person_A, policy_create2.Id, parentCase_create.Id, null);
        policyParticipantsToCreate.add(beneficiary_A_pol2);
        IC_Policy_Participant__c beneficiary_C_pol2 = createBeneficiary(person_C, policy_create2.Id, parentCase_create.Id, 20000);
        policyParticipantsToCreate.add(beneficiary_C_pol2);

        insert policyParticipantsToCreate;


        List<IC_Segment__c> segments = new List<IC_Segment__c>();
        Date startDate = Date.today().addDays(-5);
        Date endDate = Date.today().addDays(+10);
        Date coverEffectiveDate = Date.today();
        Date dateOfDeath = Date.today().addDays(1);
        IC_Segment__c segment_A = createSegment(liveAssured_A.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'MainLife', 100000);
        IC_Segment__c segment_B = createSegment(liveAssured_B.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000); //TODO: Check relationship aka segment_type
        IC_Segment__c segment_C = createSegment(liveAssured_C.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000);

        //Policy2
        IC_Segment__c segment_A_pol2 = createSegment(liveAssured_A_pol2.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'MainLife', 100000);
        IC_Segment__c segment_B_pol2 = createSegment(liveAssured_B_pol2.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000); //TODO: Check relationship aka segment_type
        IC_Segment__c segment_C_pol2 = createSegment(liveAssured_C_pol2.Id, startDate, endDate, coverEffectiveDate, dateOfDeath, 'Other', 100000);

        segments.add(segment_A);
        segments.add(segment_B);
        segments.add(segment_C);
        segments.add(segment_A_pol2);
        segments.add(segment_B_pol2);
        segments.add(segment_C_pol2);
        insert segments;

        //SET THE BENEFICIARY ON THE CHILD CASE
        childCase_create.IC_Beneficiary__c = beneficiary_A.Id;
        childCase_create2.IC_Beneficiary__c = beneficiary_A_pol2.Id;
        update childCase_create;


        //RETRIEVE RECORDS FOR CALCULATOR
        //  - Use the Child Case to get the parent ifo as well
        //Get Child Case
        Case childCase = getChildCase();

        //IC_Policy__c policy = getPolicy();
        List<IC_Policy__c> policies = getPolicies();

        SYSTEM.DEBUG('%^&^ beneficiary_A: ' + beneficiary_A);
        SYSTEM.DEBUG('%^&^ beneficiary_A_pol2: ' + beneficiary_A_pol2);

        List<IC_Calculator_Funeral.FlowRequest> requests = new List<IC_Calculator_Funeral.FlowRequest>();
        IC_Calculator_Funeral.FlowRequest request = new IC_Calculator_Funeral.FlowRequest();
        /*request.beneficiaries = new List<IC_Policy_Participant__c>();
        request.beneficiaries.add(beneficiary_A);
        //request.beneficiaries.add(beneficiary_C);
        request.beneficiaries.add(beneficiary_A_pol2);
        //request.beneficiaries.add(beneficiary_C_pol2);*/

        List<Case> childCases = New List<Case>();
        childCases.add(childCase_create);
        childCases.add(childCase_create2);
        request.childCases = childCases;

        requests.add(request);

        List<IC_Calculator_Funeral.FlowResponse> responses = IC_Calculator_Funeral.calculate(requests);

        System.debug('### ------------------------------ responses -------------------------------------');
        System.debug('### responses: ' + JSON.serializePretty(responses));

        List<IC_Policy_Participant__c> policyParticipants = getPolicyParticipants();


        System.assertEquals(0,responses[0].calcResults[0].errors.size(),'An Error has been encountered: ' + responses[0].calcResults[0].errors);
        System.assertEquals(1,responses[0].calcResults[0].beneficiaries.values()[0].percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(100300,responses[0].calcResults[0].beneficiaries.values()[0].apportionedRecommendedPayoutAmount,'Unexpected apportionedRecommendedPayoutAmount');
    }
}