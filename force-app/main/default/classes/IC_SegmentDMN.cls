/**
 * Created by dawid on 09.07.2024.
 * @description <a href="https://capitecbank.atlassian.net/browse/ICS-1160">ICS-1160</a>
 */

public with sharing class IC_SegmentDMN {

    /**
     * <a href="https://capitecbank.atlassian.net/browse/ICS-1160">ICS-1160</a>
     *
     * @param icSegments List of segments that need to be recalculated
     * @param isInsert context from Trigger execution
     *
     * @author Dawid Kuczer
     *
     * @Created date 09.07.2024     
	 *
     * @Updated date 27.10.2024 by Ridwan Moosuddee (ICS-1750)
     */
	 
	public static void recalculateSegments(List<IC_Segment__c> icSegments, Boolean isInsert) {
        
        Map<String, List<IC_Segment__c>> affectedBeneficiaries = new Map<String, List<IC_Segment__c>>();
        Set<String> beneficiaryIds = new Set<String>();
        
        for (IC_Segment__c currentSegment : icSegments) {
            beneficiaryIds.add(currentSegment.IC_Policy_Participant__c);
        }
		
		System.debug('RIDWAN - beneficiaryIds: ' + beneficiaryIds);
    
        if (!beneficiaryIds.isEmpty()) {
			
            // Query all segments linked to each unique policy participant in the list
            List<IC_Segment__c> allRelatedSegments = [SELECT Id,
                    IC_Select_to_Pay__c,
                    IC_Cover_Amount__c,
                    IC_Policy_Participant__c,
                    IC_Policy_Participant__r.IC_Case__c,
                    IC_Policy_Participant__r.IC_Case__r.IC_Total_Assured_Amount_on_Policy__c,
                    IC_Policy_Participant__r.IC_Case__r.RecordTypeId,
                    IC_Policy_Participant__r.IC_Case__r.ParentId,
                    IC_In_Waiting_Period_on_Event_Date__c,
                    IC_In_Force_on_Event_Date__c
            FROM IC_Segment__c
                                                       WHERE IC_Policy_Participant__c IN :beneficiaryIds];
													   
			System.debug('RIDWAN - allRelatedSegments: ' + allRelatedSegments);										   
            
            Map<String, List<IC_Segment__c>> allSegmentsByParticipant = new Map<String, List<IC_Segment__c>>();
            
            // Group queried segments by policy participant
            for (IC_Segment__c segment : allRelatedSegments) {
				
                if (!allSegmentsByParticipant.containsKey(segment.IC_Policy_Participant__c)) {
                    allSegmentsByParticipant.put(segment.IC_Policy_Participant__c, new List<IC_Segment__c>());
                }
                
                allSegmentsByParticipant.get(segment.IC_Policy_Participant__c).add(segment);
            }
			
			System.debug('RIDWAN - allSegmentsByParticipant: ' + allSegmentsByParticipant);										  
			            
            List<IC_Policy_Participant__c> participants = [SELECT Id, IC_Calculated_Cover_Amount__c 
                                                           FROM IC_Policy_Participant__c 
                                                           WHERE Id IN :beneficiaryIds];

            // IC Calculator - 04 Nov 2024
            Map<Id,IC_Calculator.CoverAmounts> map_Participant_coverAmounts = new Map<Id,IC_Calculator.CoverAmounts>();
            for (IC_Policy_Participant__c currentParticipant : participants) {
				
				System.debug('RIDWAN - allSegmentsByParticipant: ' + currentParticipant);
				
                Decimal coveredAmount = 0;
                Decimal accidentalCoveredAmount = 0;
                
                // Get all segments associated with this participant and apply the condition checks
                List<IC_Segment__c> participantSegments = allSegmentsByParticipant.get(currentParticipant.Id);
				
                if (participantSegments != null) {
					
                    for (IC_Segment__c currentSegment : participantSegments) {
						
						System.debug('RIDWAN - currentSegment: ' + currentSegment);
						
                        if (currentSegment.IC_Select_to_Pay__c) {
							
							System.debug('RIDWAN - currentSegment: ' + currentSegment.IC_Select_to_Pay__c);
							
                            coveredAmount += currentSegment.IC_Cover_Amount__c;
							
							System.debug('RIDWAN - coveredAmount: ' + coveredAmount);
                            /*// IC Calculator - 04 Nov 2024
                            IC_Calculator.CoverAmounts calculatedCoverAmounts = IC_Calculator.calculateCoverAmountFromSegments(map_Participant_coverAmounts,currentSegment);
                            system.debug('CoverAmounts: ' + calculatedCoverAmounts);
                            accidentalCoveredAmount += calculatedCoverAmounts.calculatedCoverAmount_Accidental;*/
                        }
                        // IC Calculator - 04 Nov 2024
                        IC_Calculator.CoverAmounts calculatedCoverAmounts = IC_Calculator.calculateCoverAmountFromSegments(map_Participant_coverAmounts,currentSegment);
                        system.debug('CoverAmounts: ' + calculatedCoverAmounts);
                        accidentalCoveredAmount += calculatedCoverAmounts.calculatedCoverAmount_Accidental;
                    }
                }
                
                currentParticipant.IC_Calculated_Cover_Amount__c = coveredAmount;
                currentParticipant.IC_Accidental_Calculated_Cover_Amount__c = map_Participant_coverAmounts.get(currentParticipant.Id).calculatedCoverAmount_Accidental;//accidentalCoveredAmount;
            }
            system.debug('+++++ map_Participant_coverAmounts : ' + JSON.serializePretty(map_Participant_coverAmounts));
            upsert participants;
        }
    }


    /*public static void policyCalculation(List<IC_Segment__c> icSegments){
        System.Debug('&&&&&&&&&&&&&&&&&&&&& IC_SegmentDMN.policyCalculation');
        System.Debug('&&&&&&&&&&&&&&&&&&&&& IC_SegmentDMN.policyCalculation - icSegments: ' + icSegments);
        //11 Nov 2024 - IC_Calculator - Gerhard de Klerk
        //BUILD A LIST OF THE POLICY PARTICIPANTS FROM THE SEGMENTS
        set<Id> policyParticipantIds = new set<Id>();
        //set<Id> parentCaseIds = new set<Id>();
        for (IC_Segment__c segment : icSegments){
            policyParticipantIds.add(segment.IC_Policy_Participant__c);
        }

        //GET THE PARENT CASES
        Map<Id,IC_Policy_Participant__c> map_Id_PolicyParticipants = new Map<Id,IC_Policy_Participant__c>([
                SELECT
                        Id,
                        Name,
                        IC_Case__c
                FROM IC_Policy_Participant__c
                WHERE
                        Id IN :policyParticipantIds
        ]);

        Map<Id,Map<String,List<IC_Policy_Participant__c>>> map_ParentCaseId_MapPolicyParticipants = new Map<Id,Map<String,List<IC_Policy_Participant__c>>>();

        for(IC_Policy_Participant__c policyParticipant : map_Id_PolicyParticipants.values()){
            //parentCaseIds.add(policyParticipant.IC_Case__c); //Parent Case ID
            map_ParentCaseId.put(policyParticipant.IC_Case__c,null);
        }
        System.Debug('&&&&&&&&&&&&&&&&&&&&& IC_SegmentDMN.policyCalculation - parentCaseIds: ' + parentCaseIds);


        //GET THE LIVES ASSURED FROM THE POLICY PARTICIPANTS
        Id POLICYPARTICIPANT_LIVESASSURED_RT = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByName().get('Lives Assured').getRecordTypeId();
        Map<Id,IC_Policy_Participant__c> map_Id_PolicyParticipant_LivesAssured = new Map<Id,IC_Policy_Participant__c>([
                SELECT
                        Id,
                        Name,
                        IC_Case__c,
                        IC_Case__r.IC_BenefitType__c,
                        IC_Case__r.Sub_Status__c,
                        IC_Policy_Number__c,
                        IC_Policy_Number__r.IC_ArrearsAmount__c,
                        IC_Policy_Number__r.IC_Refund_Amount__c,
                        IC_Policy_Number__r.IC_Status__c,
                        IC_Policy_Number__r.IC_DeceasedMainLife__c,
                        IC_Policy_Number__r.IC_DeceasedCovermount__c,
                        IC_Policy_Number__r.IC_Deceased_Calculated_AccidentCoverAmnt__c,
                        IC_BenefitAmount__c,
                        IC_Relationship__c,
                        RecordTypeId,
                        IC_Record_Type_DeveloperName__c,
                        IC_Calculated_Cover_Amount__c,
                        IC_Accidental_Calculated_Cover_Amount__c
                FROM IC_Policy_Participant__c
                WHERE
                        IC_Case__c IN :map_ParentCaseId_MapPolicyParticipants.keySet()
                        AND
                        RecordTypeId = :POLICYPARTICIPANT_LIVESASSURED_RT
        ]);

        //GET BENEFICIARIES - GET THE PARENT CASE FROM THE LIVES ASSURED, THEN GET ALL THE CHILD CASES AND THEIR BENEFICIARY


        //GET THE BENEFICIARIES FROM THE POLICY PARTICIPANTS
        Id POLICYPARTICIPANT_BENEFICIARY_RT = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByName().get('Beneficiaries').getRecordTypeId();
        Map<Id,IC_Policy_Participant__c> map_Id_PolicyParticipant_Beneficiaries = new Map<Id,IC_Policy_Participant__c>([
                SELECT
                        Id,
                        Name,
                        IC_Case__c,
                        IC_Case__r.IC_BenefitType__c,
                        IC_Case__r.Sub_Status__c,
                        IC_Policy_Number__c,
                        IC_Policy_Number__r.IC_ArrearsAmount__c,
                        IC_Policy_Number__r.IC_Refund_Amount__c,
                        IC_Policy_Number__r.IC_Status__c,
                        IC_Policy_Number__r.IC_DeceasedMainLife__c,
                        IC_Policy_Number__r.IC_DeceasedCovermount__c,
                        IC_Policy_Number__r.IC_Deceased_Calculated_AccidentCoverAmnt__c,
                        IC_BenefitAmount__c,
                        IC_Relationship__c,
                        RecordTypeId,
                        IC_Record_Type_DeveloperName__c,
                        IC_Calculated_Cover_Amount__c,
                        IC_Accidental_Calculated_Cover_Amount__c
                FROM IC_Policy_Participant__c
                WHERE
                        IC_Case__c IN :map_ParentCaseId_MapPolicyParticipants.values()
                AND
                    RecordTypeId = :POLICYPARTICIPANT_BENEFICIARY_RT
        ]);


        //TODO
        //GET ALL LIVES ASSURED RELATED TO THIS PARENT CASE
        //BUILD LIVES ASSURED LIST
        //BUILD BENEFICIARY LIST



        //FOR EACH BENEFICIARY, RUN THE CALCULATOR AND SAVE RESULT
        List<Id> caseIDs = new List<Id>();
        List<Id> policyID = new List<Id>();
        for (IC_Policy_Participant__c beneficiary: map_Id_PolicyParticipant_Beneficiaries.values()){
            caseIDs.add(beneficiary.IC_Case__c);
            IC_Calculator calc = new IC_Calculator();

            calc.claimInformation.arrearsTotal = beneficiary.IC_Policy_Number__r.IC_ArrearsAmount__c; //0;
            calc.claimInformation.refundAmount = beneficiary.IC_Policy_Number__r.IC_Refund_Amount__c; //0;
            calc.claimInformation.policyStatus = beneficiary.IC_Policy_Number__r.IC_Status__c; //'Active';
            calc.claimInformation.isMainLifeDeceased = (beneficiary.IC_Policy_Number__r.IC_DeceasedMainLife__c >0) ? false: true; //false;
            calc.claimInformation.benefitType = beneficiary.IC_Case__r.IC_BenefitType__c;//'Natural';  //TODO: This must come from the Child Case and not the Parent
            calc.claimInformation.childCaseSubStatus = beneficiary.IC_Case__r.Sub_Status__c; //null; //Payments Scheduled  //TODO: This must come from the Child Case and not the Parent
            calc.claimInformation.deceasedCoverAmount = beneficiary.IC_Policy_Number__r.IC_DeceasedCovermount__c; //100000; //the cover amount on the Lives assured that is deceased //TODO: check if this is correct


            calc.calculatedCoverAmount.natural = beneficiary.IC_Policy_Number__r.IC_DeceasedCovermount__c;//100000; //Calculated with LOGIC FROM SEGMENTS
            calc.calculatedCoverAmount.accidental = beneficiary.IC_Policy_Number__r.IC_Deceased_Calculated_AccidentCoverAmnt__c; //Calculated with LOGIC

            calc.addBeneficiary(beneficiary);
            for (IC_Policy_Participant__c liveAssured : map_Id_PolicyParticipant_LivesAssured.values()){
                calc.addLiveAssured(liveAssured);
            }

            //CALL CALCULATOR
            calc.calculateRecommendedPayoutAmount();
            calc.calculateRecommendedPayoutAmountPerBPPOP();
            //SAVE CALCULATOR RESULT
            system.debug('THIS IS MY SANITY CHECK');
            System.debug('### ------------------------------ IC_SegmentDMN.policyCalculation - CALC -------------------------------------');
            System.debug('### CALC: ' + JSON.serializePretty(calc));
        }




        System.debug('**** map_Id_PolicyParticipant_LivesAssured: ' + map_Id_PolicyParticipant_LivesAssured);
        System.debug('**** map_Id_PolicyParticipant_Beneficiaries: ' + map_Id_PolicyParticipant_Beneficiaries);
    }
*/

    public static void recommendedOutcome(List<IC_Segment__c> icSegments){
        Set<String> policyParticipantIds = new Set<String>();
        for (IC_Segment__c segment : icSegments) {
            if (segment.IC_Policy_Participant__c != null) {
                policyParticipantIds.add(segment.IC_Policy_Participant__c);
            }
        }

        List<IC_Policy_Participant__c> participants = [
                SELECT Id, Name, IC_Recommended_Outcome__c, IC_Recommended_Reason__c,
                                        (SELECT Id, IC_In_Force_on_Event_Date__c, IC_In_Waiting_Period_on_Event_Date__c,
                                                IC_Recommendation_to_Pay__c, IC_Select_to_Pay__c FROM Segments__r)
                FROM IC_Policy_Participant__c
                WHERE Id IN :policyParticipantIds
        ];

        for (IC_Policy_Participant__c participant : participants) {

            if (participant.Segments__r == null) continue;

            for(IC_Segment__c segment : participant.Segments__r){
                String reasons = calculateRecommendations(participant);
                if (reasons != '') {
                    participant.IC_Recommended_Reason__c = reasons;
                    participant.IC_Recommended_Outcome__c = 'Decline';
                } else {
                    participant.IC_Recommended_Reason__c = reasons;
                    participant.IC_Recommended_Outcome__c = 'Approve';
                }
            }
        }

        update participants;
    }

    public static String calculateRecommendations(IC_Policy_Participant__c participant) {
        String reason = '';
        Boolean inWaiting = false;
        Boolean notInForce = false;
        Boolean excludeCover = false;
        Boolean selectToPay = false;

        for (IC_Segment__c segment : participant.Segments__r) {
            
            if (segment.IC_Select_to_Pay__c && segment.IC_In_Waiting_Period_on_Event_Date__c) {
                inWaiting = true;
            }
            if (segment.IC_Select_to_Pay__c && !segment.IC_In_Force_on_Event_Date__c) {
                notInForce = true;
            }
            if (!segment.IC_Select_to_Pay__c && segment.IC_Recommendation_to_Pay__c) {
                excludeCover = true;
            }
        }

        if (inWaiting || notInForce || excludeCover) {
            if (inWaiting) {
                reason += System.Label.IC_Recommended_Outcome_In_Waiting;
            }
            if (notInForce) {
                reason += '\n' + System.Label.IC_Recommended_Outcome_Not_In_Force;
            }
            if (excludeCover) {
                reason += '\n' + System.Label.IC_Recommended_Outcome_Excluded;
            }
        }
        return reason;
    }
    
    /**
     * <a href="https://capitecbank.atlassian.net/browse/ICS-1750">ICS-1750</a>
     *
     * @param deceasedDeath The date of death of the insured person
     * @param icSegment the segments that has to be evaluated
     * @param isInsert context from Trigger execution
     *
     * @return evaluated Segment record
     *
     * @author Ridwan Moosuddee
     *
     * @date 28.10.2024
     */
    public static void pushRecommendToPaySegment(List<IC_Segment__c> icSegments, Boolean isInsert){
		
		for(IC_Segment__c currentSegment : icSegments){
		
			Boolean inForce = (currentSegment.IC_Deceased_Date_of_Death__c >= currentSegment.IC_Start_Date__c && currentSegment.IC_Deceased_Date_of_Death__c <= currentSegment.IC_End_Date__c) ? true : false;
			Boolean inWaiting = (currentSegment.IC_Deceased_Date_of_Death__c < currentSegment.IC_Cover_Effective_Date__c) ? true : false;

			currentSegment.IC_In_Force_on_Event_Date__c = inForce;
			currentSegment.IC_In_Waiting_Period_on_Event_Date__c = inWaiting;

			if(isInsert){
				if(inForce && !inWaiting){
					currentSegment.IC_Recommendation_to_Pay__c = true;
					currentSegment.IC_Select_to_Pay__c = true;
				}
				else{
					currentSegment.IC_Recommendation_to_Pay__c = false;
					currentSegment.IC_Select_to_Pay__c = false;
				}
			}
			else{
				if(inForce && !inWaiting){
					currentSegment.IC_Recommendation_to_Pay__c = true;
				}
				else{
					currentSegment.IC_Recommendation_to_Pay__c = false;
				}
			}
		}
    }

    /** Commented for ICS-1750
     * <a href="https://capitecbank.atlassian.net/browse/ICS-1160">ICS-1160</a>
     *
     * @param deceasedDeath The date of death of the insured person
     * @param icSegment the segments that has to be evaluated
     * @param isInsert context from Trigger execution
     *
     * @return evaluated Segment record
     *
     * @author Dawid Kuczer
     *
     * @date 09.07.2024
     
    public static IC_Segment__c recommendToPaySegment(Date deceasedDeath, IC_Segment__c icSegment, Boolean isInsert){
        Boolean inForce = (deceasedDeath >= icSegment.IC_Start_Date__c && deceasedDeath <= icSegment.IC_End_Date__c) ? true : false;
        Boolean inWaiting = (deceasedDeath < icSegment.IC_Cover_Effective_Date__c) ? true : false;

        icSegment.IC_In_Force_on_Event_Date__c = inForce;
        icSegment.IC_In_Waiting_Period_on_Event_Date__c = inWaiting;

        if(isInsert){
            if(inForce && !inWaiting){
                icSegment.IC_Recommendation_to_Pay__c = true;
                icSegment.IC_Select_to_Pay__c = true;
            }
            else{
                icSegment.IC_Recommendation_to_Pay__c = false;
                icSegment.IC_Select_to_Pay__c = false;
            }
        }
        else{
            if(inForce && !inWaiting){
                icSegment.IC_Recommendation_to_Pay__c = true;
            }
            else{
                icSegment.IC_Recommendation_to_Pay__c = false;
            }
        }
        return icSegment;
    }
	*/

    /**
     * <a href="https://capitecbank.atlassian.net/browse/ICS-892">ICS-1160</a>
     *
     * @param lstSegments The list of segments being created or updated 
     *
     * @return void
     *
     * @author Samiirah Aujub
     *
     * @date 24.09.2024
     */
    public static void calculateAssuredAmount(Map<Id, IC_Segment__c> oldSegmentMap, List<IC_Segment__c> lstSegments){
        Set<Id> setParticipantsId = new Set<Id>();
        Set<Id> setParentId = new Set<Id>();
        Map<Id,Case> mapCaseIdToNewAmount = new Map<Id,Case>();
        Map<Id,Decimal> mapCaseIdToExistingAmount = new Map<Id,Decimal>();
        Id childCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Insurance_Claims_Assessment').getRecordTypeId();

        for(IC_Segment__c segment : lstSegments){
            if(oldSegmentMap == null && segment.IC_Cover_Amount__c != null){
                setParticipantsId.add(segment.IC_Policy_Participant__c);
            }
            else if (oldSegmentMap != null && 
                     (oldSegmentMap.get(segment.Id).IC_Cover_Amount__c != segment.IC_Cover_Amount__c ||
                      oldSegmentMap.get(segment.Id).IC_Select_to_Pay__c != segment.IC_Select_to_Pay__c )
                    ){
                setParticipantsId.add(segment.IC_Policy_Participant__c);
            }

            mapCaseIdToExistingAmount.put(segment.IC_Policy_Participant__r.IC_Case__c, segment.IC_Policy_Participant__r.IC_Case__r.IC_Total_Assured_Amount_on_Policy__c);
        }
        
        System.debug('##setParticipantsId:' + setParticipantsId);
        System.debug('##mapCaseIdToExistingAmount:' + mapCaseIdToExistingAmount);

        // IC Calculator - 04 Nov 2024
        Map<Id,IC_Calculator.CoverAmounts> map_Participant_coverAmounts = new Map<Id,IC_Calculator.CoverAmounts>();

        if(!setParticipantsId.isEmpty() && setParticipantsId != null){
            //Get All segments for the participants
            for(IC_Segment__c segment : [ SELECT Id,
                                                IC_Select_to_Pay__c, 
                                                IC_Cover_Amount__c, 
                                                IC_Policy_Participant__c, 
                                                IC_Policy_Participant__r.IC_Case__c,
                                                IC_Policy_Participant__r.IC_Case__r.IC_Total_Assured_Amount_on_Policy__c,
                                                IC_Policy_Participant__r.IC_Case__r.RecordTypeId, 
                                                IC_Policy_Participant__r.IC_Case__r.ParentId,
                                                IC_In_Waiting_Period_on_Event_Date__c,
                                                IC_In_Force_on_Event_Date__c
                                        FROM IC_Segment__c
                                        WHERE IC_Policy_Participant__c IN: setParticipantsId
                                        ])
            {
                Id caseId = segment.IC_Policy_Participant__r.IC_Case__c;
                Decimal amount = (segment.IC_Cover_Amount__c == null) ? 0.0 : segment.IC_Cover_Amount__c;  

                if(caseId != null && mapCaseIdToNewAmount.containsKey(caseId)){
                    Case caseRecord = mapCaseIdToNewAmount.get(caseId);
                    if(segment.IC_Select_to_Pay__c){
                        caseRecord.IC_Total_Assured_Amount_on_Policy__c += amount;
                     }
                    mapCaseIdToNewAmount.put(caseId, caseRecord);
                }
                else if(caseId != null && !mapCaseIdToNewAmount.containsKey(caseId)){
                    Case caseRecord = new Case(Id = caseId,
                                               RecordTypeId = segment.IC_Policy_Participant__r.IC_Case__r.RecordTypeId,
                                               ParentId = segment.IC_Policy_Participant__r.IC_Case__r.ParentId);

                    if(segment.IC_Select_to_Pay__c){
                        caseRecord.IC_Total_Assured_Amount_on_Policy__c = amount;
                    }
                    else{
                        caseRecord.IC_Total_Assured_Amount_on_Policy__c = 0.0;
                    }
                         
                    mapCaseIdToNewAmount.put(caseId, caseRecord);
                }

                /*// IC Calculator - 04 Nov 2024
                IC_Calculator.calculateCoverAmountFromSegments(map_Participant_coverAmounts,segment);*/

            }
            system.debug('### map_Participant_coverAmounts: ' + map_Participant_coverAmounts);
             System.debug('##mapCaseIdToNewAmount:' + mapCaseIdToNewAmount);
          
            List<Case> lstCasesToUpdate = new List<Case>();
            Map<Id,Case> mapParentIdParentCase = new Map<Id,Case>();
            Map<Id,Set<Id>> mapParentIdChildCases = new Map<Id, Set<Id>>();

            for(Case caseRecord : mapCaseIdToNewAmount.values()){
                if(mapCaseIdToExistingAmount.get(caseRecord.Id) != caseRecord.IC_Total_Assured_Amount_on_Policy__c) {
                    lstCasesToUpdate.add(caseRecord);
                    
                    // propagate IC_Total_Assured_Amount_on_Policy__c from the child case to the parent.
                    //init parent map with current child assured amount
                    if(caseRecord.ParentId != null && mapParentIdParentCase.containsKey(caseRecord.ParentId)){
                        Case parentCase = mapParentIdParentCase.get(caseRecord.ParentId);
                        parentCase.IC_Total_Assured_Amount_on_Policy__c += caseRecord.IC_Total_Assured_Amount_on_Policy__c;

                        mapParentIdParentCase.put(caseRecord.ParentId, parentCase);
                    }
                    else if(caseRecord.ParentId != null && !mapParentIdParentCase.containsKey(caseRecord.ParentId)){
                        mapParentIdParentCase.put(caseRecord.ParentId, 
                                            new Case(Id = caseRecord.ParentId, IC_Total_Assured_Amount_on_Policy__c = caseRecord.IC_Total_Assured_Amount_on_Policy__c )
                                           );
                    }

                    if(caseRecord.ParentId != null && mapParentIdChildCases.containsKey(caseRecord.ParentId)){
                        Set<Id> setIds = mapParentIdChildCases.get(caseRecord.ParentId);
                        setIds.add(caseRecord.Id);

                        mapParentIdChildCases.put(caseRecord.ParentId, setIds);
                    }
                    else if(caseRecord.ParentId != null && !mapParentIdChildCases.containsKey(caseRecord.ParentId)){
                        mapParentIdChildCases.put(caseRecord.ParentId, new Set<Id>{caseRecord.Id});
                    }
                }
            }
            
            System.debug('##mapParentIdChildCases:' + mapParentIdChildCases);
            
            if(!mapParentIdParentCase.isEmpty()){
               List<Case> lstParentCases = getParentCaseToUpdate(mapParentIdParentCase, mapParentIdChildCases);
                 System.debug('##lstParentCases:' + lstParentCases);
               if(!lstParentCases.isEmpty() && lstParentCases != null){
                lstCasesToUpdate.addAll(lstParentCases);
               }
            }

            if(lstCasesToUpdate != null && !lstCasesToUpdate.isEmpty()){
                system.debug('##calculateAssuredAmount updating cases :' + lstCasesToUpdate);
                update lstCasesToUpdate;
            }

            }


        /*// IC Calculator - 04 Nov 2024
        if(map_Participant_coverAmounts.size()>0){
            List<IC_Policy_Participant__c> policyParticipantsToUpdate = new List<IC_Policy_Participant__c>();
            for(Id participantId: map_Participant_coverAmounts.keySet()){
                IC_Calculator.CoverAmounts coverAmounts = map_Participant_coverAmounts.get(participantId);
                IC_Policy_Participant__c policyParticipant = new IC_Policy_Participant__c();
                policyParticipant.Id = participantId;
                policyParticipant.IC_Accidental_Calculated_Cover_Amount__c = coverAmounts.calculatedCoverAmount_Accidental;
                //policyParticipant.IC_Calculated_Cover_Amount__c = coverAmounts.calculatedCoverAmount;//map_Participant_coverAmounts.get(participantId).calculatedCoverAmount;
                policyParticipantsToUpdate.add(policyParticipant);
            }

            if(policyParticipantsToUpdate.size()>0){
                update policyParticipantsToUpdate;
                system.debug('### calculateAssuredAmount.policyParticipantsToUpdate: ' + policyParticipantsToUpdate);
            }
        }*/


    }

    public static List<Case> getParentCaseToUpdate(Map<Id,Case> mapParentIdParentCase, Map<Id,Set<Id>> mapParentIdChildCases){
        for(Case childCase : [SELECT Id, ParentId, IC_Total_Assured_Amount_on_Policy__c
                              FROM Case
                              WHERE ParentId IN: mapParentIdParentCase.keySet()]){

            //makes sure of not taking the child case being updated
            if(!mapParentIdChildCases.get(childCase.ParentId).contains(childCase.Id)){
                Case parentCase = mapParentIdParentCase.get(childCase.parentId);
                parentCase.IC_Total_Assured_Amount_on_Policy__c += childCase.IC_Total_Assured_Amount_on_Policy__c;

                mapParentIdParentCase.put(childCase.ParentId, parentCase);
            }
        }

        return mapParentIdParentCase.values();
    }

}