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
public with sharing class IC_Calculator_TEST {



    /*
     * ===============================================================================================================
     *  TEST METHODS
     * ===============================================================================================================
     */

    /**
     * @description Calculator Baseline:
     * - Other Life Deceased
     * - Natural death
     *
     * Expected Outcome:
     * - 1 beneficiary payout with full cover amount
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 0;
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = false;
        calc.claimInformation.benefitType = 'Natural';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = 100000; //Calculated with LOGIC FROM SEGMENTS
        calc.calculatedCoverAmount.accidental = 100000; //Calculated with LOGIC


        String person_A = 'Person A (Main Life)';
        String person_B = 'Person B (deceased)';

        calc.addBeneficiary(person_A, 100000, true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 100000,false); //Cover Amount on Lives Assured


        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(1,calc.beneficiaries.get(person_A).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(100000,calc.beneficiaries.get(person_A).apportionedRecommendedPayoutAmount,'Unexpected apportionedRecommendedPayoutAmount');
    }

    /**
     * @description Calculator Baseline with Refund:
     * - Other Life Deceased
     * - Natural death
     *
     * Expected Outcome:
     * - 1 beneficiary payout with full cover amount + the refund
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_WithRefund(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 331;
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = false;
        calc.claimInformation.benefitType = 'Natural';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = 100000; //Calculated with LOGIC FROM SEGMENTS
        calc.calculatedCoverAmount.accidental = 100000; //Calculated with LOGIC


        String person_A = 'Person A (Main Life)';
        String person_B = 'Person B (deceased)';

        calc.addBeneficiary(person_A, 100000, true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 100000,false); //Cover Amount on Lives Assured


        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(1,calc.beneficiaries.get(person_A).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(100331,calc.beneficiaries.get(person_A).apportionedRecommendedPayoutAmount,'Unexpected apportionedRecommendedPayoutAmount');

    }

    /**
     * @description Calculator Baseline - With Arrears:
     * - Other Life Deceased
     * - Natural death
     *
     * Expected Outcome:
     * - 1 beneficiary payout with full cover amount - the arrears
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_WithArrears(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 31;
        calc.claimInformation.refundAmount = 0;
        //calc.claimInformation.deceasedCalculatedCoverAmount = 1000; // IC_Policy__c.IC_DeceasedCalculatedCoverAmount__c
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = false;
        calc.claimInformation.benefitType = 'Natural';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = 100000; //Calculated with LOGIC
        calc.calculatedCoverAmount.accidental = 100000; //Calculated with LOGIC

        String person_A = 'Person A (Main Life)';
        String person_B = 'Person B (deceased)';

        calc.addBeneficiary(person_A, 100000, true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 100000,false); //Cover Amount on Lives Assured


        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(1,calc.beneficiaries.get(person_A).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(
                calc.calculatedCoverAmount.natural - calc.claimInformation.arrearsTotal,
                calc.beneficiaries.get(person_A).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');
    }

    /**
     * @description Calculator Baseline - With Arrears and refund:
     * - Other Life Deceased
     * - Natural death
     *
     * Expected Outcome:
     * - 1 beneficiary payout with full cover amount + the refund - arrears
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_WithArrearsAndRefund(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 31;
        calc.claimInformation.refundAmount = 331;
        //calc.claimInformation.deceasedCalculatedCoverAmount = 1000; // IC_Policy__c.IC_DeceasedCalculatedCoverAmount__c
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = false;
        calc.claimInformation.benefitType = 'Natural';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = 100000; //Calculated with LOGIC
        calc.calculatedCoverAmount.accidental = 100000; //Calculated with LOGIC

        String person_A = 'Person A (Main Life)';
        String person_B = 'Person B (deceased)';

        calc.addBeneficiary(person_A, 100000, true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 100000,false); //Cover Amount on Lives Assured


        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(1,calc.beneficiaries.get(person_A).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(
                calc.calculatedCoverAmount.natural - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount,
                calc.beneficiaries.get(person_A).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');
    }

    /**
     * @description Calculator Baseline - With Arrears and refund = PendingOutOfForce:
     * - Other Life Deceased
     * - Natural death
     *
     * Expected Outcome:
     * - 1 beneficiary payout with full cover amount + the refund - arrears
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_WithArrearsAndRefund_PendingOutOfForce(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 331;
        //calc.claimInformation.deceasedCalculatedCoverAmount = 1000; // IC_Policy__c.IC_DeceasedCalculatedCoverAmount__c
        calc.claimInformation.policyStatus = 'PendingOutOfForce';
        calc.claimInformation.isMainLifeDeceased = false;
        calc.claimInformation.benefitType = 'Natural';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = 100000; //Calculated with LOGIC
        calc.calculatedCoverAmount.accidental = 100000; //Calculated with LOGIC

        String person_A = 'Person A (Main Life)';
        String person_B = 'Person B (Beneficiary)';
        String person_C = 'Person C (deceased)';

        calc.addBeneficiary(person_B, 100000, false); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 100000,false); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_C, 100000,false); //Cover Amount on Lives Assured


        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(1,calc.beneficiaries.get(person_B).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(
                calc.calculatedCoverAmount.natural - calc.claimInformation.arrearsTotal,
                calc.beneficiaries.get(person_B).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');
    }

    /**
     * @description Calculator Baseline - With Arrears and refund:
     * - Main Life Deceased
     * - Natural death
     *
     * Expected Outcome:
     * - 1 beneficiary payout with full cover amount + the refund - arrears
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_MainLifeDeceased(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 331;
        //calc.claimInformation.deceasedCalculatedCoverAmount = 1000; // IC_Policy__c.IC_DeceasedCalculatedCoverAmount__c
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = true;
        calc.claimInformation.benefitType = 'Natural';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = 100000; //Calculated with LOGIC
        calc.calculatedCoverAmount.accidental = 100000; //Calculated with LOGIC


        String person_A = 'Person A (Main Life - deceased)';
        String person_B = 'Person B (Beneficiary)';

        calc.addBeneficiary(person_B, 100000, false); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 100000,false); //Cover Amount on Lives Assured


        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(1,calc.beneficiaries.get(person_B).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(
                calc.calculatedCoverAmount.natural - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount,
                calc.beneficiaries.get(person_B).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');

    }

    /**
     * @description Calculator Baseline - With Arrears and refund:
     * - Main Life Deceased
     * - Natural death
     * - Beneficiary benefit amount less than the policy value (segment calculated values)
     *
     * Expected Outcome:
     * - 1 beneficiary payout with full BENEFIT amount + the refund - arrears
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_MainLifeDeceased_beneficiaryBenefitLessThanPolicy(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 331;
        //calc.claimInformation.deceasedCalculatedCoverAmount = 1000; // IC_Policy__c.IC_DeceasedCalculatedCoverAmount__c
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = true;
        calc.claimInformation.benefitType = 'Natural';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = 100000; //Calculated with LOGIC
        calc.calculatedCoverAmount.accidental = 100000; //Calculated with LOGIC


        String person_A = 'Person A (Main Life - deceased)';
        String person_B = 'Person B (Beneficiary)';

        calc.addBeneficiary(person_B, 50000, false); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 100000,false); //Cover Amount on Lives Assured


        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(0.5,calc.beneficiaries.get(person_B).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(
                (calc.calculatedCoverAmount.natural - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount)/2,
                calc.beneficiaries.get(person_B).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');

    }

    /**
     * @description Calculator Baseline - With Arrears and refund:
     * - Main Life Deceased - 2 beneficiaries
     * - Natural death
     *
     * Expected Outcome:
     * - 2 beneficiary payouts
     * - Apportioned 60:40
     * - Apportionment includes the arrears and refunds
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_MainLifeDeceased_2Beneficiaries(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 331;
        //calc.claimInformation.deceasedCalculatedCoverAmount = 1000; // IC_Policy__c.IC_DeceasedCalculatedCoverAmount__c
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = true;
        calc.claimInformation.benefitType = 'Natural';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = 100000; //Calculated with LOGIC
        calc.calculatedCoverAmount.accidental = 100000; //Calculated with LOGIC


        String person_A = 'Person A (Main Life - deceased)';
        String person_B = 'Person B (Beneficiary)';
        String person_C = 'Person C (Beneficiary)';

        calc.addBeneficiary(person_B, 60000,false); //Cover Amount on Lives Assured
        calc.addBeneficiary(person_C, 40000,false); //Cover Amount on Lives Assured

        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 60000,false); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_C, 40000,false); //Cover Amount on Lives Assured



        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(0.6,calc.beneficiaries.get(person_B).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(0.4,calc.beneficiaries.get(person_C).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');

        System.assertEquals(0.6,calc.beneficiaries.get(person_B).normalizedPercentagePortionOfPayout,'Unexpected normalizedPercentagePortionOfPayout');
        System.assertEquals(0.4,calc.beneficiaries.get(person_C).normalizedPercentagePortionOfPayout,'Unexpected normalizedPercentagePortionOfPayout');

        System.assertEquals(
                (calc.calculatedCoverAmount.natural  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount) * 0.6,
                calc.beneficiaries.get(person_B).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');
        System.assertEquals(
                (calc.calculatedCoverAmount.natural  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount) * 0.4,
                calc.beneficiaries.get(person_C).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');

        //CHECK THAT ALL THE PORTIONS ADD UP:
        Decimal totalValue = 0.0;
        for (IC_Calculator.PolicyParticipantBeneficiary beneficiary : calc.beneficiaries.values()){
            totalValue += beneficiary.apportionedRecommendedPayoutAmount;
        }
        System.assertEquals(
                calc.calculatedCoverAmount.natural  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount,
                totalValue,
                'Unexpected Total Value of All beneficiaries added together');

    }


    /**
     * @description Calculator Baseline - With Arrears and refund - Benefit Total Exceeded:
     * - Main Life Deceased - 2 beneficiaries
     * - Natural death
     *
     * Expected Outcome:
     * - 2 beneficiary payouts
     * - Apportioned 60:40
     * - Apportionment includes the arrears and refunds BUT ADJUSTED TO NOT EXCEED TOTAL COVER AS PER SEGMENTS
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_MainLifeDeceased_2Beneficiaries_BenefitAmountsExceeded(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 331;
        //calc.claimInformation.deceasedCalculatedCoverAmount = 1000; // IC_Policy__c.IC_DeceasedCalculatedCoverAmount__c
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = true;
        calc.claimInformation.benefitType = 'Natural';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = 100000; //Calculated with LOGIC
        calc.calculatedCoverAmount.accidental = 100000; //Calculated with LOGIC


        String person_A = 'Person A (Main Life - deceased)';
        String person_B = 'Person B (Beneficiary)';
        String person_C = 'Person C (Beneficiary)';

        calc.addBeneficiary(person_B, 80000,false); //Cover Amount on Lives Assured
        calc.addBeneficiary(person_C, 40000,false); //Cover Amount on Lives Assured

        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 80000,false); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_C, 40000,false); //Cover Amount on Lives Assured



        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(0.8,calc.beneficiaries.get(person_B).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(0.4,calc.beneficiaries.get(person_C).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');

        System.assertEquals(0.67,calc.beneficiaries.get(person_B).normalizedPercentagePortionOfPayout,'Unexpected normalizedPercentagePortionOfPayout');
        System.assertEquals(0.33,calc.beneficiaries.get(person_C).normalizedPercentagePortionOfPayout,'Unexpected normalizedPercentagePortionOfPayout');

        System.assertEquals(
                (calc.calculatedCoverAmount.natural  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount) * 0.67,
                calc.beneficiaries.get(person_B).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');
        System.assertEquals(
                (calc.calculatedCoverAmount.natural  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount) * 0.33,
                calc.beneficiaries.get(person_C).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');

        //CHECK THAT ALL THE PORTIONS ADD UP:
        Decimal totalValue = 0.0;
        for (IC_Calculator.PolicyParticipantBeneficiary beneficiary : calc.beneficiaries.values()){
            totalValue += beneficiary.apportionedRecommendedPayoutAmount;
        }
        System.assertEquals(
                calc.calculatedCoverAmount.natural  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount,
                totalValue,
                'Unexpected Total Value of All beneficiaries added together');

    }

    /**
     * @description Calculator Baseline - With Arrears and refund - Benefit Total BELOW Segment Total:
     * - Main Life Deceased - 2 beneficiaries
     * - Natural death
     *
     * Expected Outcome:
     * - 2 beneficiary payouts
     * - Apportioned 30:20 (SHOULDNT COUNT UP TO 100%)
     * - Apportionment includes the arrears and refunds BUT ADJUSTED TO NOT EXCEED TOTAL COVER AS PER SEGMENTS
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_MainLifeDeceased_2Beneficiaries_BenefitAmountsBelow(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 331;
        //calc.claimInformation.deceasedCalculatedCoverAmount = 1000; // IC_Policy__c.IC_DeceasedCalculatedCoverAmount__c
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = true;
        calc.claimInformation.benefitType = 'Natural';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = 100000; //Calculated with LOGIC
        calc.calculatedCoverAmount.accidental = 100000; //Calculated with LOGIC


        String person_A = 'Person A (Main Life - deceased)';
        String person_B = 'Person B (Beneficiary)';
        String person_C = 'Person C (Beneficiary)';


        calc.addBeneficiary(person_B, 30000,false); //Cover Amount on Lives Assured
        calc.addBeneficiary(person_C, 20000,false); //Cover Amount on Lives Assured

        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 30000,false); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_C, 20000,false); //Cover Amount on Lives Assured



        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(0.3,calc.beneficiaries.get(person_B).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(0.2,calc.beneficiaries.get(person_C).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');

        System.assertEquals(0.3,calc.beneficiaries.get(person_B).normalizedPercentagePortionOfPayout,'Unexpected normalizedPercentagePortionOfPayout');
        System.assertEquals(0.2,calc.beneficiaries.get(person_C).normalizedPercentagePortionOfPayout,'Unexpected normalizedPercentagePortionOfPayout');

        System.assertEquals(
                (calc.calculatedCoverAmount.natural  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount) * 0.3,
                calc.beneficiaries.get(person_B).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');
        System.assertEquals(
                (calc.calculatedCoverAmount.natural  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount) * 0.2,
                calc.beneficiaries.get(person_C).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');

        //CHECK THAT ALL THE PORTIONS ADD UP:
        Decimal totalValue = 0.0;
        for (IC_Calculator.PolicyParticipantBeneficiary beneficiary : calc.beneficiaries.values()){
            totalValue += beneficiary.apportionedRecommendedPayoutAmount;
        }
        System.assertEquals(
                (calc.calculatedCoverAmount.natural - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount)/2,
                totalValue,
                'Unexpected Total Value of All beneficiaries added together');

    }

    //================================================================================================================
    // ACCIDENTAL
    //================================================================================================================

    /**
     * @description Calculator Baseline - With Arrears and refund - Benefit Total Exceeded:
     * - Main Life Deceased - 1 beneficiary
     * - ACCIDENTAL death
     *
     * Expected Outcome:
     * - 1 beneficiary payout
     * - Apportioned 100
     * - Apportionment includes the arrears and refunds BUT ADJUSTED TO NOT EXCEED TOTAL COVER AS PER SEGMENTS
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_MainLifeDeceased_1Beneficiary_Accidental(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 331;
        //calc.claimInformation.deceasedCalculatedCoverAmount = 1000; // IC_Policy__c.IC_DeceasedCalculatedCoverAmount__c
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = true;
        calc.claimInformation.benefitType = 'Accidental';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        //THE CALC VALUES BELOW WILL BE CALCULATED FROM THE SEGMENTS BASED ON THE RELEVANT DATES (i.e. Waiting periods etc)
        calc.calculatedCoverAmount.natural = 100000;
        calc.calculatedCoverAmount.accidental = 100000;


        String person_A = 'Person A (Main Life - deceased)';
        String person_B = 'Person B (Beneficiary)';

        calc.addBeneficiary(person_B, 100000,false); //Cover Amount on Lives Assured

        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 100000,false); //Cover Amount on Lives Assured




        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(1,calc.beneficiaries.get(person_B).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');

        System.assertEquals(1,calc.beneficiaries.get(person_B).normalizedPercentagePortionOfPayout,'Unexpected normalizedPercentagePortionOfPayout');

        System.assertEquals(
                (calc.calculatedCoverAmount.accidental * 2  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount) * 1,
                calc.beneficiaries.get(person_B).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');
        System.assertEquals(
                200331.00,
                calc.beneficiaries.get(person_B).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');


        //CHECK THAT ALL THE PORTIONS ADD UP:
        Decimal totalValue = 0.0;
        for (IC_Calculator.PolicyParticipantBeneficiary beneficiary : calc.beneficiaries.values()){
            totalValue += beneficiary.apportionedRecommendedPayoutAmount;
        }
        System.assertEquals(
                calc.calculatedCoverAmount.accidental * 2  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount,
                totalValue,
                'Unexpected Total Value of All beneficiaries added together');

    }


    /**
     * @description Calculator Baseline - With Arrears and refund - Benefit Total Exceeded:
     * - Main Life Deceased - 2 beneficiaries
     * - ACCIDENTAL death
     *
     * Expected Outcome:
     * - 2 beneficiary payouts
     * - Apportioned 60:40
     * - Apportionment includes the arrears and refunds BUT ADJUSTED TO NOT EXCEED TOTAL COVER AS PER SEGMENTS
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_MainLifeDeceased_2Beneficiaries_BenefitAmountsExceeded_Accidental(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 331;
        //calc.claimInformation.deceasedCalculatedCoverAmount = 1000; // IC_Policy__c.IC_DeceasedCalculatedCoverAmount__c
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = true;
        calc.claimInformation.benefitType = 'Accidental';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        //THE CALC VALUES BELOW WILL BE CALCULATED FROM THE SEGMENTS BASED ON THE RELEVANT DATES (i.e. Waiting periods etc)
        calc.calculatedCoverAmount.natural = 100000;
        calc.calculatedCoverAmount.accidental = 100000;


        String person_A = 'Person A (Main Life - deceased)';
        String person_B = 'Person B (Beneficiary)';
        String person_C = 'Person C (Beneficiary)';

        calc.addBeneficiary(person_B, 80000,false); //Cover Amount on Lives Assured
        calc.addBeneficiary(person_C, 40000,false); //Cover Amount on Lives Assured

        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 80000,false); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_C, 40000,false); //Cover Amount on Lives Assured



        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(0.8,calc.beneficiaries.get(person_B).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');
        System.assertEquals(0.4,calc.beneficiaries.get(person_C).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');

        System.assertEquals(0.67,calc.beneficiaries.get(person_B).normalizedPercentagePortionOfPayout,'Unexpected normalizedPercentagePortionOfPayout');
        System.assertEquals(0.33,calc.beneficiaries.get(person_C).normalizedPercentagePortionOfPayout,'Unexpected normalizedPercentagePortionOfPayout');

        System.assertEquals(
                (calc.calculatedCoverAmount.accidental * 2  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount) * 0.67,
                calc.beneficiaries.get(person_B).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');
        System.assertEquals(
                (calc.calculatedCoverAmount.accidental * 2  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount) * 0.33,
                calc.beneficiaries.get(person_C).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');

        //CHECK THAT ALL THE PORTIONS ADD UP:
        Decimal totalValue = 0.0;
        for (IC_Calculator.PolicyParticipantBeneficiary beneficiary : calc.beneficiaries.values()){
            totalValue += beneficiary.apportionedRecommendedPayoutAmount;
        }
        System.assertEquals(
                calc.calculatedCoverAmount.accidental * 2  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount,
                totalValue,
                'Unexpected Total Value of All beneficiaries added together');

    }

    /**
     * @description Calculator Baseline - With Arrears and refund - Benefit Total Exceeded:
     * - Other Life Deceased - 2 beneficiaries
     * - ACCIDENTAL death
     *
     * Expected Outcome:
     * - 1 beneficiary payouts - Main Life
     * - Apportioned 1
     * - Apportionment includes the arrears and refunds BUT ADJUSTED TO NOT EXCEED TOTAL COVER AS PER SEGMENTS
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_OtherLifeDeceased_1Beneficiaries_BenefitAmountsExceeded_Accidental(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 331;
        //calc.claimInformation.deceasedCalculatedCoverAmount = 1000; // IC_Policy__c.IC_DeceasedCalculatedCoverAmount__c
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = false;
        calc.claimInformation.benefitType = 'Accidental';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        //THE CALC VALUES BELOW WILL BE CALCULATED FROM THE SEGMENTS BASED ON THE RELEVANT DATES (i.e. Waiting periods etc)
        calc.calculatedCoverAmount.natural = 100000;
        calc.calculatedCoverAmount.accidental = 100000;


        String person_A = 'Person A (Main Life)';
        String person_B = 'Person B (Beneficiary - deceased)';
        String person_C = 'Person C (Beneficiary)';

        calc.addBeneficiary(person_A, 120000,true); //Cover Amount on Lives Assured

        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 80000,false); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_C, 40000,false); //Cover Amount on Lives Assured



        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(1,calc.beneficiaries.get(person_A).percentagePortionOfPayout,'Unexpected percentagePortionOfPayout');

        System.assertEquals(1,calc.beneficiaries.get(person_A).normalizedPercentagePortionOfPayout,'Unexpected normalizedPercentagePortionOfPayout');

        System.assertEquals(
                (calc.calculatedCoverAmount.accidental * 2  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount) * 1,
                calc.beneficiaries.get(person_A).apportionedRecommendedPayoutAmount,
                'Unexpected apportionedRecommendedPayoutAmount');


        //CHECK THAT ALL THE PORTIONS ADD UP:
        Decimal totalValue = 0.0;
        for (IC_Calculator.PolicyParticipantBeneficiary beneficiary : calc.beneficiaries.values()){
            totalValue += beneficiary.apportionedRecommendedPayoutAmount;
        }
        System.assertEquals(
                calc.calculatedCoverAmount.accidental * 2  - calc.claimInformation.arrearsTotal + calc.claimInformation.refundAmount,
                totalValue,
                'Unexpected Total Value of All beneficiaries added together');

    }

/*
 * ===============================================================================================================
 *  TEST METHODS - ERRORS
 * ===============================================================================================================
 */

    /**
     * @description Calculator Baseline - ERROR Test
     * Expected Outcome:
     * - 1 Error on BenefitType
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_Error_BenefitType(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 0;
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = false;
        calc.claimInformation.benefitType = 'This Should fail';
        calc.claimInformation.childCaseSubStatus = null; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = 100000; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = 100000; //Calculated with LOGIC FROM SEGMENTS
        calc.calculatedCoverAmount.accidental = 100000; //Calculated with LOGIC


        String person_A = 'Person A (Main Life)';
        String person_B = 'Person B (deceased)';

        calc.addBeneficiary(person_A, 100000, true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_A, 100000,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, 100000,false); //Cover Amount on Lives Assured


        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(1, calc.errors.size(),'Unexpected number of errors');
        System.assertEquals('Unknown claimInformation.benefitType: This Should fail', calc.errors[0].description,'Unexpected number of errors');

    }

    /**
     * @description Calculator Baseline - ERROR Test
     * Expected Outcome:
     * - 1 Error on TotalBenefitAmount
     */
    @IsTest
    private static void test1_Baseline_ValuesOnly_Error_totalBenefitAmount(){
        IC_Calculator calc = new IC_Calculator();

        calc.claimInformation.arrearsTotal = 0;
        calc.claimInformation.refundAmount = 0;
        calc.claimInformation.policyStatus = 'Active';
        calc.claimInformation.isMainLifeDeceased = true;
        calc.claimInformation.benefitType = 'Natural';
        calc.claimInformation.childCaseSubStatus = 'PendingOutOfForce'; //Payments Scheduled
        calc.claimInformation.deceasedCoverAmount = null; //the cover amount on the Lives assured that is deceased


        calc.calculatedCoverAmount.natural = null; //Calculated with LOGIC FROM SEGMENTS
        calc.calculatedCoverAmount.accidental = null; //Calculated with LOGIC


        String person_A = 'Person A (Main Life - deceased)';
        String person_B = 'Person B (Beneficiary)';

        calc.addBeneficiary(person_B, 100000, true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_A, null,true); //Cover Amount on Lives Assured
        calc.addLiveAssured(person_B, null,false); //Cover Amount on Lives Assured


        calc.calculateRecommendedPayoutAmount();
        calc.calculateRecommendedPayoutAmountPerBPPOP();
        System.debug(JSON.serializePretty(calc));

        System.assertEquals(1, calc.errors.size(),'Unexpected number of errors');

    }


}