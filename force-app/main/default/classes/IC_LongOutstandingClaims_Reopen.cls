/********************************\
    @ Func Area     : IC Long Outstanding Claims (LOC)
    @ Author        : Gerhard de Klerk
    @ Date          : 11 Feb 2025
    @ Description   : LOC Logic for REOPENING
    @ Related files :
    @ Test File     : IC_LongOutstandingClaims_Reopen_TEST
                    :
===================================
    @ Last Modified By  : Gerhard de Klerk
    @ Last Modified On  : 25 Feb 2025
    @ Modification Description : Do Not Throw exception for an open case if it a logging operation only
	@ -
	@ -
===================================
**********************************/
global with sharing class IC_LongOutstandingClaims_Reopen {

/* ================================================================================================================
 *  STATIC VARIABLES
 * ================================================================================================================
 */
    // RECORD TYPES
    public static final Id RT_CLAIMSUPPORT_LOC = Schema.SObjectType.IC_ClaimSupport__c.getRecordTypeInfosByName().get('LOC').getRecordTypeId();
    public static final Id RT_POLICYPARTICIPANT_LIVESASSURED = Schema.SObjectType.IC_Policy_Participant__c.getRecordTypeInfosByName().get('Lives Assured').getRecordTypeId();
    public static final Id RT_CASE_INSURANCE_CLAIMS = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims').getRecordTypeId(); //Parent Case
    public static final Id RT_CASE_INSURANCE_CLAIMS_ASSESSMENT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Insurance Claims Assessment').getRecordTypeId(); //Child Case


/* ================================================================================================================
 *  CUSTOM EXCEPTION CLASSES
 * ================================================================================================================
 */
    //global class ProcessingException    extends Exception {}


/* ================================================================================================================
 *  MAIN METHOD
 * ================================================================================================================
 */
    public static void reopenClaim(Id caseId, String reopenEvent, Boolean logReopenOnly){

        String configDevName = null;
        //RETRIEVE THE CASE
        Case c = getCase(caseId);

        //CHECK CASE RECORD TYPE
        if( c.RecordTypeId == RT_CASE_INSURANCE_CLAIMS){
            //CHECK PARENT CASE STATUS
            switch on c.Status{
                when 'Closed','Finalised'{
                    //do something
                }
                when else{
                    //case not closed - nothing to do
                    if(logReopenOnly == false){
                        throw new IC_InsuranceClaimsService.ProcessingException('Case not closed');
                    }
                    //return;
                }
            }

            switch on c.Product_Type__c{
                //DEFINE CONFIG NAMES FOR CUSTOM METADATA RETRIEVAL
                when 'Funeral'{
                    configDevName = 'Funeral_Reopen';
                }
            }
        }else{
            //EXIT THE METHOD IF THE RECORD TYPE IS NOT APPLICABLE
            return;
        }

        //GET INSURANCE CLAIM OPERATIONS METADATA
        IC_Insurance_Claim_Operation__mdt insuranceClaimOperation = getInsuranceClaimOperation(configDevName);

        //EVALUATE INSURANCE CLAIM OPERATIONS METADATA RECORD
        if(insuranceClaimOperation != null){
            if(insuranceClaimOperation.Active__c){
                IC_ClaimSupport__c csr = generateClaimSupportRecord(caseId,reopenEvent);

                Id ownerId = null;
                if (insuranceClaimOperation.Reopen_Owner_is_Queue__c){
                    ownerId = getOwner_Queue(insuranceClaimOperation.Reopen_Owner__c);
                }else{
                    ownerId = getOwner_User(insuranceClaimOperation.Reopen_Owner__c);
                }

                if (ownerId == null){
                    throw new IC_InsuranceClaimsService.ProcessingException('Unable to Update Case Owner - Owner ( ' + insuranceClaimOperation.Reopen_Owner__c + ' ) not found ');
                }

                //SET CASE VALUES
                c.OwnerId = ownerId;
                c.Status = insuranceClaimOperation.Reopen_Status__c;
                if (insuranceClaimOperation.Reopen_Sub_Status__c != null){
                    c.Sub_Status__c = insuranceClaimOperation.Reopen_Sub_Status__c;
                }

                //UPDATE Case
                if(logReopenOnly == false){
                    try {
                        update c;
                    }catch(Exception e){
                        throw new IC_InsuranceClaimsService.ProcessingException('Unable to Update Case - ' + e.getMessage());
                    }
                }

                try{
                    insert csr;
                }catch(Exception e){
                    throw new IC_InsuranceClaimsService.ProcessingException('Unable to insert Claim Support Record: ' + e.getMessage());
                }
            }
        }
    }

/* ================================================================================================================
 *  HELPER METHODS
 * ================================================================================================================
 */



    private static Case getCase(Id caseId){
        try{
            List<String> fields = new List<String>(Case.SObjectType.getDescribe().fields.getMap().keySet());
            String soql = ''
                    + ' SELECT ' + String.join(fields, ',')
                    + ' FROM  Case'
                    + ' WHERE Id = :caseId'
                    + ' LIMIT 1';
            return Database.query(soql);
        }catch(Exception e){
            throw new IC_InsuranceClaimsService.ProcessingException('Case not found - Please check Id');
        }
    }

    private static Id getOwner_Queue(String owner){
        try{
            Group grp = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName =: owner LIMIT 1];
            return grp.Id;
        }catch(Exception e){
            throw new IC_InsuranceClaimsService.ProcessingException('Owner ( ' + owner + ' ) not found');
        }
    }
    private static Id getOwner_User(String owner){
        try{
            User usr = [SELECT Id FROM User WHERE Username =: owner LIMIT 1];
            return usr.Id;
        }catch(Exception e){
            throw new IC_InsuranceClaimsService.ProcessingException('Owner ( ' + owner + ' ) not found');
        }
    }

    private static IC_Insurance_Claim_Operation__mdt getInsuranceClaimOperation(String configName){
        IC_Insurance_Claim_Operation__mdt insuranceClaimOperation = IC_Insurance_Claim_Operation__mdt.getInstance(configName);
        if(Test.isRunningTest()){
            IC_Insurance_Claim_Operation__mdt insuranceClaimOperationTemp = new IC_Insurance_Claim_Operation__mdt ();
            switch on configName{
                when 'Funeral_Reopen'{
                    insuranceClaimOperationTemp.Active__c = true;
                    insuranceClaimOperationTemp.Closure_Notice_Days__c = 121;
                    insuranceClaimOperationTemp.First_Notice_Days__c = 90;
                    insuranceClaimOperationTemp.Product__c = 'Funeral';
                    insuranceClaimOperationTemp.Reopen_Owner__c = 'IC_Funeral_Claims';
                    insuranceClaimOperationTemp.Reopen_Owner_is_Queue__c = true;
                    insuranceClaimOperationTemp.Reopen_Status__c = 'Administration';
                    insuranceClaimOperationTemp.Reopen_Sub_Status__c = 'Update Received';
                }
            }
            return insuranceClaimOperationTemp;
        }
        return insuranceClaimOperation;
    }

    public static IC_ClaimSupport__c generateClaimSupportRecord(Id caseId, String reopenEvent){
        IC_ClaimSupport__c csr = new IC_ClaimSupport__c();
        csr.IC_ParentCase__c = caseId;
        csr.RecordTypeId = RT_CLAIMSUPPORT_LOC;
        csr.IC_LOC_ClaimReopenDate__c = System.Datetime.now();
        csr.IC_Status__c = 'Active';
        csr.IC_LOC_Claim_Reopen_Event__c = reopenEvent;
        return csr;
    }


}