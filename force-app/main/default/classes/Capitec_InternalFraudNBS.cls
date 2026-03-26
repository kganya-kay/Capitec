/**
 * This class handles the internal fraud NBS updates.
 * It includes methods to update internal fraud cases.
 *
 * <a href='https://capitecbank.atlassian.net/browse/FFSF-876'>FFSF-876</a>
 *
 * @author Caleb Govender
 * @date 08/10/2024
 */
public with sharing class Capitec_InternalFraudNBS {

    @TestVisible private static final String API_ISSUE_MSG = 'API Issue,Request Error Code: ';

    public static final String INTERNAL_FRAUD_CASE_APPROVAL_UPDATE = '/fraudp/nbs-proxy/v1/bypass';

    /**
    * Inner class representing the input for internal fraud approval.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-876'>FFSF-876</a>
    *
    * @author Caleb Govender
    * @date 08/10/2024
    */
    public class InternalFraudApprovalInput {
        @InvocableVariable(Label='CIF' Required=true)
        public String cif;
        @InvocableVariable(Label='Outcome' Required=true)
        public String outcome;
    }

    /**
    * Updates the internal fraud NBS based on the provided input.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-876'>FFSF-876</a>
    *
    * @author Caleb Govender
    * @date 08/10/2024
    *
    * @param input The list of internal fraud approval inputs.
    */
    @InvocableMethod(Label='Internal Fraud NBS' Category='Fraud' Callout=true)
    public static void InternalFraudNBSUpdate(List<InternalFraudApprovalInput> input) {

        System.debug('BODY:::: ' + createBody(input[0].cif, input[0].outcome));
        HttpResponse response = Capitec_CalloutHandler.makePUTCalloutWithBody(INTERNAL_FRAUD_CASE_APPROVAL_UPDATE, createBody(input[0].cif, input[0].outcome));

        if (response.getStatusCode() != 200) {
            throw new InternalFraudNBSUpdateException(API_ISSUE_MSG + response.getStatusCode());
        }
    }

    /**
    * Creates the request body for the internal fraud NBS update.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-876'>FFSF-876</a>
    *
    * @author Caleb Govender
    * @date 08/10/2024
    *
    * @param sCIF The CIF of the beneficiary.
    * @param sOutcome The outcome of the fraud case.
    * @return The constructed request body as a JSON string.
    */
    private static String createBody(String sCIF, String sOutcome) {
        RequestBodyWrapper requestBR = new RequestBodyWrapper();
        requestBR.cif = sCIF;
        requestBR.outcome = sOutcome;
        String sBody = JSON.serialize(requestBR);

        return sBody;
    }

    /**
    * Inner class representing the structure of the request body.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-876'>FFSF-876</a>
    *
    * @author Caleb Govender
    * @date 08/10/2024
    */
    public class RequestBodyWrapper {
        
		public String outcome {get; set;}
        public String cif {get; set;}
       
    }

    /**
    * Exception class for internal fraud NBS update errors.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-876'>FFSF-876</a>
    *
    * @author Caleb Govender
    * @date 08/10/2024
    */
    public class InternalFraudNBSUpdateException extends Exception {}

}