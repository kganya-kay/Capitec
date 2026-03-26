/********************************\
    @ Func Area     : IC Calculator - Funeral
    @ Author        : Gerhard de Klerk
    @ Date          : 19 Nov 2024
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

public with sharing class IC_Calculator_Funeral {

    public class FlowRequest{
        @InvocableVariable(Label='Records for Input' Description='Child Cases for input' Required=true)
        public List<Case> childCases;
    }
    public class FlowResponse{
        @InvocableVariable(Label='Calculator Results for Input' Description='IC Calculator Data structured outputs' Required=false)
        public List<IC_Calculator> calcResults;
    }

    @InvocableMethod(Label='Insurance Calculator - Funeral' Description='Calculate the insurance claim values for insurance claims' Category='Insurance')
    public static List<FlowResponse> calculate(List<FlowRequest> requests) {
        system.debug('!!!!! REQUESTS: ' + requests);

        List<FlowResponse> responses = new List<FlowResponse>();
        for (FlowRequest req : requests){
            FlowResponse response = new FlowResponse();
            response.calcResults = new List<IC_Calculator>();

            //FOR EACH REQUEST,
            Set<Id> beneficiaryIds = new Set<Id>();
            //Map<Id,IC_Policy_Participant__c> map_Id_beneficiaries = new Map<Id,IC_Policy_Participant__c>();
            Set<Id> parentCaseIds = new Set<Id>();
            //Map<Id,Case> map_BeneficiaryID_ChildCase = new Map<Id,Case>();
            Map<Id,Case> map_BeneficiaryId_Case = new Map<Id,Case>();

            Set<Id> childCaseIDs = new Set<Id>();
            for(Case childCase : req.childCases){
                beneficiaryIds.add(childCase.IC_Beneficiary__c);
                parentCaseIds.add(childCase.ParentId);
                //map_Id_beneficiaries.put(ipp.Id,ipp);
                map_BeneficiaryId_Case.put(childCase.IC_Beneficiary__c,childCase);
            }


            //RETRIEVE PARENT CASES
            List<Case> retrievedCases = [
                    SELECT
                            Id,
                            Product_Type__c,
                            IC_Type__c,
                            Sub_Type__c,
                            Sub_Type_Reason__c,
                            IC_Beneficiary__c, //lives on the child case
                            IC_BenefitType__c, //lives on the child case
                            Sub_Status__c,
                            IC_UnnaturalDeathType__c,
                            ParentId
                    FROM
                            Case
                    WHERE
                            Id IN :parentCaseIds
                            OR
                            ParentId IN :parentCaseIds
            ];

            Map<Id,Case> map_parentCasesRetrieved = new Map<Id,Case>();
            //Map<Id,Case> map_childCasesRetrieved = new Map<Id,Case>();
            Map<Id,Case> map_BeneficiaryId_childCasesRetrieved = new Map<Id,Case>();
            for(Case c : retrievedCases){
                if(c.ParentId == null){
                    map_parentCasesRetrieved.put(c.Id,c);
                }else{
                    map_BeneficiaryId_childCasesRetrieved.put(c.IC_Beneficiary__c,c);
                }
            }
            SYSTEM.DEBUG('-=-=-=-=-=-=-=-=-= map_parentCasesRetrieved: ' + map_parentCasesRetrieved);


            SYSTEM.DEBUG('-=-=-=-=-=-=-=-=-= map_BeneficiaryId_childCasesRetrieved: ' + map_BeneficiaryId_childCasesRetrieved);



            SYSTEM.DEBUG('-=-=-=-=-=-=-=-=-= beneficiaryIds: ' + beneficiaryIds);
            SYSTEM.DEBUG('-=-=-=-=-=-=-=-=-= parentCaseIds: ' + parentCaseIds);
            //SYSTEM.DEBUG('-=-=-=-=-=-=-=-=-= map_BeneficiaryID_ChildCase: ' + map_BeneficiaryID_ChildCase);


            //GET THE All POLICY PARTICIPANTS RELATED TO EACH OF THE CHILD CASES
            List<IC_Policy_Participant__c> policyParticipants = [
                    SELECT
                            Id,
                            Name,
                            IC_Name__c,
                            IC_Surname__c,
                            IC_Identity_Number__c,
                            IC_Recommended_Outcome__c,
                            IC_Case__c,
                            IC_Case__r.CaseNumber,
                            IC_BenefitAmount__c,
                            IC_Relationship__c,
                            RecordTypeId,
                            IC_Record_Type_DeveloperName__c,
                            IC_Calculated_Cover_Amount__c,
                            IC_Accidental_Calculated_Cover_Amount__c,
                            IC_Policy_Number__c,
                            IC_Policy_Number__r.Name,
                            IC_Policy_Number__r.IC_ArrearsAmount__c,
                            IC_Policy_Number__r.IC_Refund_Amount__c,
                            IC_Policy_Number__r.IC_Status__c,
                            IC_Policy_Number__r.IC_DeceasedMainLife__c,
                            IC_Policy_Number__r.IC_DeceasedCovermount__c,
                            IC_Policy_Number__r.IC_Deceased_Calculated_AccidentCoverAmnt__c,
                            IC_Policy_Number__r.IC_DeceasedCalculatedCoverAmount__c
                    FROM
                            IC_Policy_Participant__c
                    WHERE
                            IC_Case__c IN :parentCaseIds
            ];

            //PARSE THE LIST TO DETERMINE THE LIVES ASSURED AND THE BENEFICIARIES
            Map<Id,IC_Policy_Participant__c> map_LivesAssured = new Map<Id,IC_Policy_Participant__c>();
            Map<Id,IC_Policy_Participant__c> map_Beneficiaries = new Map<Id,IC_Policy_Participant__c>();

            for(IC_Policy_Participant__c policyParticipant : policyParticipants){
                if(policyParticipant.RecordTypeId == IC_Calculator.POLICYPARTICIPANT_LIVESASSURED_RT){
                    map_LivesAssured.put(policyParticipant.Id,policyParticipant);

                }else if(policyParticipant.RecordTypeId == IC_Calculator.POLICYPARTICIPANT_BENEFICIARY_RT){
                    map_Beneficiaries.put(policyParticipant.Id,policyParticipant);
                }
            }

            //GET POLICY

            //CREATE A CALCULATOR INSTANCE FOR EACH BENEFICIARY
            for(IC_Policy_Participant__c beneficiary : map_Beneficiaries.values()) {

                system.debug('&&&&& beneficiary: ' + beneficiary);
                if(beneficiaryIds.contains(beneficiary.Id)){

                    //GET PARENT CASE
                    Case parentCase = map_parentCasesRetrieved.get(beneficiary.IC_Case__c);
                    system.debug('**** PARENT CASE: ' + parentCase);
                    String benefitType = null;
                    //DERIVE BENEFIT TYPE
                    if(//NATURAL
                            parentCase.Product_Type__c == 'Funeral' &&
                                    parentCase.IC_Type__c == 'Death' &&
                                    parentCase.Sub_Type__c == 'Natural' &&
                                    (
                                            parentCase.Sub_Type_Reason__c == 'Main life' ||
                                                    parentCase.Sub_Type_Reason__c == 'Other life'
                                    )
                    ){
                        benefitType = 'Natural';
                    }else if(//ACCIDENTAL
                            parentCase.Product_Type__c == 'Funeral' &&
                                    parentCase.IC_Type__c == 'Death' &&
                                    parentCase.IC_UnnaturalDeathType__c == 'Accidental' &&
                                    (
                                            parentCase.Sub_Type__c == 'Unnatural' ||
                                                    parentCase.Sub_Type__c == 'Under investigation'
                                    ) &&
                                    (
                                            parentCase.Sub_Type_Reason__c == 'Main life' ||
                                                    parentCase.Sub_Type_Reason__c == 'Other life'
                                    )
                    ){
                        benefitType = 'Accidental';
                    }else if(//Further Investigation - Natural Portion
                            parentCase.Product_Type__c == 'Funeral' &&
                                    parentCase.IC_Type__c == 'Death' &&
                                    parentCase.IC_UnnaturalDeathType__c == 'Further Investigation required' &&
                                    (
                                            parentCase.Sub_Type__c == 'Unnatural' ||
                                                    parentCase.Sub_Type__c == 'Under investigation'
                                    ) &&
                                    (
                                            parentCase.Sub_Type_Reason__c == 'Main life' ||
                                                    parentCase.Sub_Type_Reason__c == 'Other life'
                                    )
                    ){
                        benefitType = 'Natural Portion';
                    }


                    IC_Calculator calc = new IC_Calculator();

                    calc.claimInformation.caseNumber = beneficiary.IC_Case__r.CaseNumber;
                    calc.claimInformation.policyNumber = beneficiary.IC_Policy_Number__r.Name;
                    calc.claimInformation.arrearsTotal = beneficiary.IC_Policy_Number__r.IC_ArrearsAmount__c; //0;
                    calc.claimInformation.refundAmount = beneficiary.IC_Policy_Number__r.IC_Refund_Amount__c; //0;
                    calc.claimInformation.policyStatus = beneficiary.IC_Policy_Number__r.IC_Status__c; //'Active';
                    calc.claimInformation.isMainLifeDeceased = (beneficiary.IC_Policy_Number__r.IC_DeceasedMainLife__c > 0) ? true : false; //false;
                    calc.claimInformation.benefitType = benefitType;//'Natural';
                    calc.claimInformation.childCaseSubStatus = map_BeneficiaryId_childCasesRetrieved.get(beneficiary.Id)?.Sub_Status__c;
                    calc.claimInformation.deceasedCoverAmount = beneficiary.IC_Policy_Number__r.IC_DeceasedCovermount__c; //100000; //the cover amount on the Lives assured that is deceased //TODO: check if this is correct


                    calc.calculatedCoverAmount.natural = beneficiary.IC_Policy_Number__r.IC_DeceasedCalculatedCoverAmount__c;//100000; //Calculated with LOGIC FROM SEGMENTS
                    calc.calculatedCoverAmount.accidental = beneficiary.IC_Policy_Number__r.IC_Deceased_Calculated_AccidentCoverAmnt__c; //Calculated with LOGIC

                    /*        calc.addBeneficiary(map_Beneficiaries.values());

                calc.addLiveAssured(map_LivesAssured.values());*/

                    for (IC_Policy_Participant__c bene : map_Beneficiaries.values()) {
                        //ONLY USE BENEFICIARIES AND LIVES ASSURED RELATED TO THE POLICY
                        if(bene.IC_Policy_Number__c == beneficiary.IC_Policy_Number__c){
                            calc.addBeneficiary(bene);
                        }
                    }
                    for (IC_Policy_Participant__c la : map_LivesAssured.values()) {
                        if(la.IC_Policy_Number__c == beneficiary.IC_Policy_Number__c){
                            calc.addLiveAssured(la);
                        }
                    }

                    System.debug('### ------------------------------ CALC-BEFORE -------------------------------------');
                    System.debug('### CALC: ' + calc);
                    System.debug('### CALC: ' + JSON.serializePretty(calc));

                    //CALCULATE
                    calc.calculateRecommendedPayoutAmount();
                    calc.calculateRecommendedPayoutAmountPerBPPOP();
                    System.debug('### ------------------------------ CALC - AFTER -------------------------------------');
                    System.debug('### CALC: ' + calc);
                    System.debug('### CALC: ' + JSON.serializePretty(calc));
                    //calculatorResults.add(calc);
                    response.calcResults.add(calc);

                    beneficiary.IC_Calculated_Payout_Amount__c = calc.beneficiaries.get(beneficiary.Id).apportionedRecommendedPayoutAmount;
                    beneficiary.IC_Policy_Calculations__c = JSON.serializePretty(calc);
                    //UPDATE BENEFICIARY RECORD

                    //SET THE VALUE ON THE CHILD CASE
                    Case childcase = map_BeneficiaryId_Case.get(beneficiary.Id);
                    childcase.IC_Payout_Amount__c = beneficiary.IC_Calculated_Payout_Amount__c;
                    childcase.IC_Recommended_Payout_Amount__c = beneficiary.IC_Calculated_Payout_Amount__c;




                }
                //ADD RESULTS FOR RESPONSE
            }
            update map_Beneficiaries.values();
            update map_BeneficiaryId_Case.values();
            responses.add(response);
        }
        system.debug('!!!!! responses: ' + responses);

        system.debug('!!!!! requests.size(): ' + requests.size());
        system.debug('!!!!! responses.size(): ' + responses.size());


        return responses;
    }

}