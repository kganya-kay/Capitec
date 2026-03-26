/**
* Class Name:       IC_API_OIPA_Services
* Test Class:       IC_API_OIPA_Services_TEST
* Author            Dawid Kuczer
* Company           BlueSky
* Created on        25.07.2024
**/

public without sharing class IC_API_OIPA_Services {

    static final List<IC_OIPA_API__mdt> apiSettings = IC_OIPA_API__mdt.getAll().values();

    /**
    * @description Create child case for the OIPA Callout
    * @author Samiirah.A@bsky.co.za [Added header only] | 12-03-2024 
    * @param triggeringCases 
    **/
    public static void handleChildCaseCreationOIPACallout(List<Case> triggeringCases) {

        List<Case> casesToProcess = new List<Case>();
        Set<String> parentCaseIds = new Set<String>();
        Set<String> benefitIds = new Set<String>();

        for (Case eachLoopCase : triggeringCases) {
            if (eachLoopCase.Product_Type__c == 'Funeral' && eachLoopCase.RecordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId()) {
                parentCaseIds.add(eachLoopCase.ParentId);
                benefitIds.add(eachLoopCase.IC_Beneficiary__c);
                casesToProcess.add(eachLoopCase);
            }
        }

        //ICS- 1831 :Samiirah Aujub - Query updated to query more fields from parent case
        Map<String, Case> caseParents = new Map<String, Case>([SELECT Id, CreatedDate, CaseNumber,Event_Date__c, IC_Lodge_Date__c, CIF_Number__c, Product_Type__c, IC_Type__c, Sub_Type__c, Last_Working_Date__c, Client_ID_Number__c FROM Case WHERE Id IN :parentCaseIds]); //ICS-1651 - IC_Lodge_Date__c added in query
        Map<String, IC_Policy_Participant__c> caseBenefits = new Map<String, IC_Policy_Participant__c>([SELECT Id, IC_BenefitAmount__c, IC_Cover_Amount__c, IC_roleguids__c, IC_Policy_Number__c, IC_Policy_Number__r.IC_Decesead_roleguids__c FROM IC_Policy_Participant__c WHERE Id IN :benefitIds]);

        //ICS-1651 - START
        List<IC_Policy__c> policies = [SELECT Id, Name, IC_Effective_Cancellation_Date__c, IC_Decesead_roleguids__c, Parent_Case__c FROM IC_Policy__c WHERE Parent_Case__c IN :parentCaseIds];
        Map<String, String> caseDeceasedRoleguids = new Map<String, String>();

        for (IC_Policy__c policy : policies) {
            caseDeceasedRoleguids.put(policy.Parent_Case__c, policy.IC_Decesead_roleguids__c);
        }
        //ICS-1651 - END

        System.debug('caseDeceasedRoleguids: ' + caseDeceasedRoleguids);

        for (Case eachCase : casesToProcess) {

            RequestWrapper requestWrapper = new RequestWrapper();

            requestWrapper.policyNumber = eachCase.IC_Policy_Number_child__c;
            requestWrapper.approvedAmount = null; //ICS-1651
            requestWrapper.benefitType = eachCase.IC_BenefitType__c;
            requestWrapper.childCaseNumber = eachCase.CaseNumber;
            requestWrapper.claimDate = caseParents.get(eachCase.ParentId).IC_Lodge_Date__c.date();  //ICS-1651
            requestWrapper.declineReason = null; //ICS-1651
            requestWrapper.eventDate = eachCase.IC_Event_Date_from_Parent__c; //ICS-1651
            requestWrapper.parentCaseNumber = caseParents.get(eachCase.ParentId).CaseNumber;
            requestWrapper.status = eachCase.Status;
            requestWrapper.subStatus = eachCase.Sub_Status__c;
            requestWrapper.subType = eachCase.Sub_Type__c;
            requestWrapper.type = eachCase.IC_Type__c;

            GuidsWrapper guidsWrapper = new GuidsWrapper(); //ICS-1651 


            IC_Policy_Participant__c beneficiary = caseBenefits.get(eachCase.IC_Beneficiary__c);
            guidsWrapper.beneficiary = beneficiary?.IC_roleguids__c; //ICS-1651
            guidsWrapper.deceased = beneficiary?.IC_Policy_Number__r.IC_Decesead_roleguids__c; //ICS-1651

            requestWrapper.roleGuids = guidsWrapper; //ICS-1651

            try {
                System.enqueueJob(new makeOIPACalloutClaimCreated(JSON.serialize(requestWrapper), eachCase, caseParents.get(eachCase.ParentId),  beneficiary));
            } catch (Exception e) {
                System.debug('OIPA callout exception');
                System.debug(e.getTypeName());
                System.debug(e.getCause());
                System.debug(e.getMessage());
            }
        }
    }

    @TestVisible
    public class makeOIPACalloutClaimCreated implements Queueable, Database.AllowsCallouts {
        private final String requestWrapperJSON;
        private IC_Policy_Participant__c beneficiaryToProcess;
        private Case caseToProcess;
        private Case parentCaseToProcess;

        /**
        * @description Method to initialise makeOIPACalloutClaimCreated
        * @author Samiirah.A@bsky.co.za [Added header only] | 12-03-2024 
        * @param jsonWrapper 
        * @param childCase 
        * @param beneficiary 
        **/
        makeOIPACalloutClaimCreated(String jsonWrapper, Case childCase, Case parentCase, IC_Policy_Participant__c beneficiary) {
            requestWrapperJSON = jsonWrapper;
            caseToProcess = childCase;
            parentCaseToProcess = parentCase; //Added by Samiirah Aujub : ICS - 1831
            beneficiaryToProcess = beneficiary;
        }

        /**
        * @description Queue 'Execution' method
        * @author Samiirah.A@bsky.co.za[Added header only] | 12-03-2024 
        * @param context 
        **/
        public void execute(QueueableContext context) {
            Integer timeoutValue = 120000;
            List<String> results = new List<String>();
            String randomUuidStr = String.valueOf(UUID.randomUUID());

//            try {
                // Callout logic
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(apiSettings[0].Endpoint__c);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('x-request-id', randomUuidStr);
                req.setHeader('x-requester-uid', 'SALESFORCE_00000_12_0000_00');
                req.setBody(requestWrapperJSON);
                req.setTimeout(timeoutValue);

                System.debug(req.getBody());
                HttpResponse res = http.send(req);
//                res.setBody(samplePayload);
                System.debug(res.getStatusCode());
                System.debug('##res.getBody() - ' + res.getBody());


//            if (beneficiary.IC_Cover_Amount__c != null && beneficiary.IC_Cover_Amount__c != 0 && beneficiary.IC_BenefitAmount__c != null) {
//                benefitProportion = (beneficiary.IC_BenefitAmount__c / beneficiary.IC_Cover_Amount__c);
//            }

                if (res.getStatusCode() == 200) {
                    if (String.isNotBlank(res.getBody())) {

                        //23 Sept 2024 - Cant set the value on the Case record as it is in the After Insert Context - EXCEPTION_THROWN|[103]|System.FinalException: Record is read-only
                        //Create a new variable and set the value

                        List<IC_Arrears__c> arrearsToInsert = new List<IC_Arrears__c>();
                        OipaCreateResponseWrapper oipaResWrapper = (OipaCreateResponseWrapper) JSON.deserialize(res.getBody(), OipaCreateResponseWrapper.class);
                                                
                        system.debug('### oipaResWrapper: ' + oipaResWrapper);
                        system.debug('### beneficiaryToProcess: ' + beneficiaryToProcess);
                        
                        Case caseToUpdate = new Case();
                        caseToUpdate.Id = caseToProcess.Id;

                        Decimal totalPaymentDueAmount = 0;
                        Decimal totalReceivedAmount = 0;                        
                        
                        List<IC_Arrears__c> existingArrears = [SELECT Id FROM IC_Arrears__c WHERE IC_Policy__c = :beneficiaryToProcess.IC_Policy_Number__c];

                        if(oipaResWrapper?.arrears != null){
                            for(Arrear arr : oipaResWrapper?.arrears?.arrear){
                            IC_Arrears__c arrearRecord = new IC_Arrears__c();
                            arrearRecord.IC_arrears_Id__c = arr.arrearsId;
                            arrearRecord.IC_Payment_Status__c = arr.paymentStatus;
                            arrearRecord.IC_Payment_Received_Amount__c = arr.paymentReceivedAmount;
                            arrearRecord.IC_Payment_Due_Amount__c = arr.paymentDueAmount;
                            arrearRecord.IC_Payment_Due_Date__c = (arr.paymentDueDate != null) ? Date.valueOf(arr.paymentDueDate) : null;
                            arrearRecord.IC_Payment_Received_Date__c = (arr.paymentReceivedDate != null) ? Date.valueOf(arr.paymentReceivedDate) : null;
                            arrearRecord.IC_Policy__c = beneficiaryToProcess.IC_Policy_Number__c; //ICS-1712
                            arrearRecord.IC_Child_Case__c = caseToProcess.Id;

                            totalPaymentDueAmount += arr.paymentDueAmount;
                            totalReceivedAmount += arr.paymentReceivedAmount;

                            arrearsToInsert.add(arrearRecord);
                        	}
                        }
                        


                        System.debug('OIPA arrearsToInsert : ' + arrearsToInsert);
                        
                        // START ICS-1712
                        Boolean recalc = false;

                        if (!arrearsToInsert.isEmpty() && existingArrears.isEmpty()) {

                            insert arrearsToInsert;
                            recalc = true;
                        }

                        //ICS-1831 - START - Samiirah Aujub : Arrears for lapsed policies
                        //Check lapsed policies also
                        System.debug('##1831 parentCaseToProcess:' + parentCaseToProcess);
                        System.debug('##1831 caseToProcess:' + caseToProcess);
                        
                        if(arrearsToInsert.isEmpty() && parentCaseToProcess != null ){
                            IC_Policy__c policy = [SELECT Id, Name, IC_Effective_Cancellation_Date__c 
                                                    FROM IC_Policy__c 
                                                    WHERE Name = :caseToProcess.IC_Policy_Number_child__c 
                                                    AND Parent_Case__c = :caseToProcess.ParentId 
                                                    LIMIT 1];
                          
                             System.debug('##1831 policy:' + policy);

                            if(policy.IC_Effective_Cancellation_Date__c < Date.valueOf('2024-11-01T16:00:00')) {
                                System.debug('##1831 Making Obligation call:');
                                List <IC_Arrears__c> lstArrearsFromObligation = IC_API_Arrears.getArrearsFromObligationService(caseToProcess, parentCaseToProcess);
                                
                                if(lstArrearsFromObligation != null && !lstArrearsFromObligation.isEmpty()){
                                    insert lstArrearsFromObligation;
                                    recalc = true;
                                }
                            }
                        }
                        //ICS - 1831 - END
                        
                        if (oipaResWrapper.refundAmount != null && oipaResWrapper.refundAmount > 0) {
                            IC_Policy__c policy = new IC_Policy__c(
                                Id = beneficiaryToProcess.IC_Policy_Number__c,
                                IC_Refund_Amount__c = oipaResWrapper.refundAmount
                            );
                            
                            update policy;
                            recalc = true;
                        }

                        try{
                            if (recalc) {
                                //List<FormulaRecalcResult> caseRecalcResults = Formula.recalculateFormulas(new List<Case> {caseToUpdate});
                                //caseToUpdate.IC_Payout_Amount__c = (Decimal) caseRecalcResults[0].getSObject().get('IC_RecommendedPayoutAmount__c');

                                List<FormulaRecalcResult> beneficiaryRecalcResults = Formula.recalculateFormulas(new List<IC_Policy_Participant__c> {beneficiaryToProcess});

                                Decimal naturalPayoutAmount = (Decimal) beneficiaryRecalcResults[0].getSObject().get('IC_PayoutAmount__c');
                                Decimal accidentalPayoutAmount = (Decimal) beneficiaryRecalcResults[0].getSObject().get('IC_AccidentalBenefitAmount__c');
                                system.debug('naturalPayoutAmount: ' + naturalPayoutAmount);
                                system.debug('accidentalPayoutAmount: ' + accidentalPayoutAmount);

                                Decimal payoutAmount = 0;
                                String benefitType = caseToProcess.IC_BenefitType__c;

                                if (benefitType == 'Natural' || benefitType == 'Natural Portion') {
                                    payoutAmount = naturalPayoutAmount;
                                } else if (benefitType == 'Accidental') {
                                    payoutAmount = naturalPayoutAmount + accidentalPayoutAmount;
                                } else if (benefitType == 'Accidental Portion' && caseToProcess.IC_SiblingCase__c != null) {

                                    Case siblingCase = [SELECT Id, Status, Sub_Status__c FROM Case WHERE Id = :caseToProcess.IC_SiblingCase__c LIMIT 1];

                                    if (siblingCase.Status == 'Finalised' && siblingCase.Sub_Status__c == 'Payment(s) Scheduled') {
                                        payoutAmount = accidentalPayoutAmount;
                                    } else {
                                        payoutAmount = naturalPayoutAmount + accidentalPayoutAmount;
                                    }
                                }

                                if (payoutAmount > 0) {
                                    caseToUpdate.IC_Recommended_Payout_Amount__c = payoutAmount;
                                    caseToUpdate.IC_Payout_Amount__c = payoutAmount;
                                }
                            }
                        //TODO: unpack why the formulas are resulting in null reference - but for the interim at least update the case with the claim Number
                        }catch(Exception e){
                            System.Debug('An error has occurred ');
                        }finally{
                            caseToUpdate.IC_Claim_Number__c = oipaResWrapper.claimNumber;
                            system.debug('###oipaResWrapper.claimNumber: ' + oipaResWrapper.claimNumber);
                            system.debug('###caseToUpdate.IC_Claim_Number__c: ' + caseToUpdate.IC_Claim_Number__c);
                            update caseToUpdate;
                        }
                        
                        system.debug('Case updated: ' + caseToUpdate);

                        

                        // END ICS-1712
                        
                        //TODO the below is wrong, needs to be corrected with ACs from ICS-1712

//                        Decimal benefitAmount = beneficiaryToProcess.IC_BenefitAmount__c;
//                        Decimal coverAmount = beneficiaryToProcess.IC_Cover_Amount__c;
//                        Decimal refundAmount = oipaResWrapper.refundAmount;
//
//                        if( benefitAmount != null &benefitAmount != 0 & coverAmount != null & coverAmount != 0){
//                            Decimal benefitProportion = benefitAmount / coverAmount;
//                            Decimal calculatedAmountToBePaid = ((benefitAmount - totalPaymentDueAmount + refundAmount) * benefitProportion);
//                            caseToUpdate.IC_Recommended_Payout_Amount__c = calculatedAmountToBePaid;
//                        }
//
//                        caseToUpdate.IC_Refund_Amount__c = refundAmount;
//                        caseToUpdate.IC_Claim_Number__c = oipaResWrapper.claimNumber;

//                        update caseToUpdate;

                    } else {
                        // Handle empty response body
                        results.add('Error: We could not complete this request, please take a screen shot of this error and log a call with the Claims IT team. The response body from the callout is empty.');
                        System.debug('Response Body: ' + res.getBody());
                        System.debug('Status: ' + res.getStatus());
                    }
                }
//            } catch (Exception e) {
//                System.debug('An unhandled error has occured while performing OIPA callout');
//                System.debug(e.getMessage());
//                System.debug(e.getStackTraceString());
//            }
        }
    }

    public class RequestWrapper {

        @InvocableVariable public String policyNumber;
        @InvocableVariable public String approvedAmount;
        @InvocableVariable public String benefitType;
        @InvocableVariable public String childCaseNumber;
        @InvocableVariable public Date claimDate;
        @InvocableVariable public String declineReason;
        @InvocableVariable public Date eventDate;
        @InvocableVariable public String parentCaseNumber;
        @InvocableVariable public String reason;
        @InvocableVariable public String uri;
        @InvocableVariable public String status;
        @InvocableVariable public String subStatus;
        @InvocableVariable public String subType;
        @InvocableVariable public String type;
        @InvocableVariable public String transactionId;
        @InvocableVariable public GuidsWrapper roleGuids;
    }

    public class GuidsWrapper {
        @InvocableVariable public String beneficiary;
        @InvocableVariable public String deceased;
    }

    public class OipaCreateResponseWrapper {
        public String claimNumber; // "DEAA4F16C55441309C1C"
        public String newPolicyPremium; // "182.75" //ICS-1831 - Updated by Samiirah Aujub
        public Decimal refundAmount; // 0
        public Arrears arrears;
    }
    public class Arrears {
        public List<Arrear> arrear;
    }

    public class Arrear {
        public String arrearsId;
        public Decimal paymentDueAmount; // "882.75"
        public String paymentDueDate; // "2024-06-16 00:00:00.0"
        public Decimal paymentReceivedAmount; // "882.75"
        public String paymentReceivedDate; // "2024-07-15 00:00:00.0"
        public String paymentStatus; // "null"
    }

    static public String samplePayload = '{\n' +
            '    "claimNumber": "7C45B9DD79A64006BF71",\n' +
            '    "newPolicyPremium": "-167.25",\n' +
            '    "refundAmount": 500,\n' +
            '    "arrears": {\n' +
            '        "arrear": [\n' +
            '            {\n' +
            '                "arrearsId": null,\n' +
            '                "paymentDueAmount": "882.75",\n' +
            '                "paymentDueDate": "2024-06-16 00:00:00.0",\n' +
            '                "paymentReceivedAmount": "882.75",\n' +
            '                "paymentReceivedDate": "2024-07-15 00:00:00.0",\n' +
            '                "paymentStatus": "null"\n' +
            '            },\n' +
            '            {\n' +
            '                "arrearsId": null,\n' +
            '                "paymentDueAmount": "882.75",\n' +
            '                "paymentDueDate": "2024-06-16 00:00:00.0",\n' +
            '                "paymentReceivedAmount": "882.75",\n' +
            '                "paymentReceivedDate": "2024-07-15 00:00:00.0",\n' +
            '                "paymentStatus": "null"\n' +
            '            },\n' +
            '            {\n' +
            '                "arrearsId": null,\n' +
            '                "paymentDueAmount": "882.75",\n' +
            '                "paymentDueDate": "2024-06-16 00:00:00.0",\n' +
            '                "paymentReceivedAmount": "882.75",\n' +
            '                "paymentReceivedDate": "2024-07-15 00:00:00.0",\n' +
            '                "paymentStatus": "null"\n' +
            '            }\n' +
            '        ]\n' +
            '    }\n' +
            '}';
}