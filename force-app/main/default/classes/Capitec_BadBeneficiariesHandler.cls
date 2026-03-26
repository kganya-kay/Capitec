/**
 * This class provides methods to handle the Capitec Bad Beneficiaries data.
 * It includes methods to update the status of a bad beneficiary.
 *
 * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
 *
 * @author Caleb Govender
 * @date 2024/09/17
 */
public with sharing class Capitec_BadBeneficiariesHandler {

    private static final String DEFAULT_IDENTIFIER_TYPE = 'ACCOUNT_NUMBER';
    private static final String DEFAULT_INSTITUTION = 'ACCOUNT_NUMBER';

    /**
    * Constructs a JSON string to update the status of a bad beneficiary.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
    *
    * @author Caleb Govender
    * @date 2024/09/17
    *
    * @param sIdentifier The identifier of the beneficiary.
    * @param sBenStatus The new status of the beneficiary.
    * @param sInstitution The institution of the beneficiary.
    * @return The constructed JSON string.
    */
    public static String UpdateBeneficiaryStatusJSON (String sIdentifier, String sBenStatus,String sInstitution) {

        UpdateBeneficiary beneficiary = new UpdateBeneficiary();
        beneficiary.identifier = sIdentifier;
        beneficiary.identifierType = DEFAULT_IDENTIFIER_TYPE;
        beneficiary.institution = sInstitution;
        beneficiary.fraudStatus = sBenStatus;
        beneficiary.defaultBranchCode = null;

        String jsonString = JSON.serialize(beneficiary);
        return jsonString;
    }

    /**
    * Inner class representing the structure of an update beneficiary request.
    *
    * <a href='https://capitecbank.atlassian.net/browse/FFSF-860'>FFSF-860</a>
    *
    * @author Caleb Govender
    * @date 2024/09/17
    */
    public class UpdateBeneficiary {
        public String identifier;
        public String identifierType;
        public String institution;
        public String fraudStatus;
        public String defaultBranchCode;
    }
}