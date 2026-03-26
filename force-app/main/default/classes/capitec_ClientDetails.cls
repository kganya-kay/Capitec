/**
 * Created by Sebastian on 13.04.2023.
 * Updated by Barend on 07.12.2023.
 */

 public with sharing class capitec_ClientDetails {

    public static final List<String> MAIN_INCOME_SOURCE = new List<String>{'01','02','03','04','06','07','09','10','11','12','13'};
    public static final List<String> INDUSTRY = new List<String>{'01','02','03','04','05','06','07','08','09','10','11','13','14'};
    public static final List<String> EXPECTED_NET_INCOME = new List<String>{'014','015','016','017','018','019','020','021'};
    public static final List<String> OCCUPATION = new List<String>{'00','01','02','03','04'};
    public static final List<String> FREQUENCY_OF_INCOME = new List<String>{'M','A','B','Q','F','W'};
    public static final List<String> EMPLOYMENT_TYPE = new List<String>{'00','01','02','03','04','05','06','07','08','09','10','11','14','15','16','17','18'};
    public static final List<String> GENDER = new List<String>{'M','F'};
    public static final List<String> COUNTRIES = new List<String>{'AF','AX','AL','DZ','AD','AO','AI','AQ','AG','AR','AM','AW','AU','AT','AZ','BS','BH','BD','BB','BY','BE','BZ','BJ','BM','BT','BO','BQ','BA','BW','BV','BR','IO','BN','BG','BF','BI','KH','CM','CA','CV','KY','CF','TD','CL','CN','CX','CC','CO','KM','CG','CD','CK','CR','CI','HR','CU','CW','CY','CZ','DK','DJ','DM','DO','EC','EG','SV','GQ','ER','EE','ET','FK','FO','FJ','FI','FR','GF','PF','TF','GA','GM','GE','DE','GH','GI','GR','GL','GD','GP','GT','GG','GN','GW','GY','HT','HM','VA','HN','HU','IS','IN','ID','IR','IQ','IE','IM','IL','IT','JM','JP','JE','JO','KZ','KE','KI','KP','KR','KW','KG','LA','LV','LB','LS','LR','LY','LI','LT','LU','MO','MK','MG','MW','MY','MV','ML','MT','MQ','MR','MU','YT','MX','MD','MC','MN','ME','MS','MA','MZ','MM','NA','NR','NP','NL','NC','NZ','NI','NE','NG','NU','NF','NO','OM','PK','PS','PA','PG','PY','PE','PH','PN','PL','PT','QA','RE','RO','RU','RW','BL','SH','KN','LC','MF','PM','VC','WS','SM','ST','SA','SN','RS','SC','SL','SG','SX','SK','SI','SB','SO','ZA','GS','SS','ES','LK','SD','SR','SJ','SZ','SE','CH','SY','TW','TJ','TZ','TH','TL','TG','TK','TO','TT','TN','TR','TM','TC','TV','UG','UA','AE','UK','US','UY','UZ','VU','VE','VN','VG','WF','EH','YE','ZM','ZW'};

    @InvocableMethod(label='Update Client Details' category='Account' callout=true)
    public static void updateClientDetails(List<Id> id) {
        Account acc;

        try {
            acc = [SELECT CIF_Number__c FROM Account WHERE Id =: id[0] LIMIT 1];
        } catch (Exception ex) {
            throw new ClientDetailsException(ex.getMessage());
        }

        capitec_ClientDetailsWrapper wrapper = capitec_ClientDetailsWrapper.parse(makeAPICallout(acc.CIF_Number__c).getBody());

        mapAccountFields(acc, wrapper);

        try {
            update acc;
        } catch (Exception ex) {
            throw new ClientDetailsException(ex.getMessage());
        }

    }

    private static HttpResponse makeAPICallout(String cifNumber) {

        String url = 'client/client-proxy/client/v1/details';
        Http httpProtocol = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:NC_ClientDomain/' + url + '?cifNumber=' + cifNumber);
        request.setMethod('GET');
        HttpResponse response = httpProtocol.send(request);

        if (response.getStatusCode() != 200) {
            throw new ClientDetailsException('Can not reach endpoint: ' + request.getEndpoint());
        }

        return response;
    }

    private static void mapAccountFields(Account acc, capitec_ClientDetailsWrapper wrapper) {

        if (wrapper.title != null) {
            switch on wrapper.title {
                when 'MS' {
                    acc.Salutation = 'Ms.';
                }
                when 'MRS' {
                    acc.Salutation = 'Mrs.';
                }
                when 'MR' {
                    acc.Salutation = 'Mr.';
                }
                when 'DR' {
                    acc.Salutation = 'Dr.';
                }
                when 'PROF' {
                    acc.Salutation = 'Prof.';
                }
            }
        }
        if (wrapper.firstName != null) {
            acc.FirstName = wrapper.firstName;
        }
        if (wrapper.middleName != null) {
            acc.MiddleName = wrapper.middleName;
        }
        if (wrapper.lastName != null) {
            acc.LastName = wrapper.lastName;
        }
        if (wrapper.idNumber != null) {
            acc.Identity_Number__c = wrapper.idNumber;
        }
        if (wrapper.birthDate != null) {
            acc.Birthdate__c = Date.valueOf(wrapper.birthDate);
        }

        if (!COUNTRIES.contains(wrapper.countryOfBirth)) {
           acc.Country_Of_Birth__c = '--None--';
        }else{
            acc.Country_Of_Birth__c = wrapper.countryOfBirth;
        }

        if (!COUNTRIES.contains(wrapper.countryOfResidence)) {
           acc.Country_Of_Residence__c = '--None--';
        }else{
            acc.Country_Of_Residence__c = wrapper.countryOfResidence;
        }

        if (!COUNTRIES.contains(wrapper.nationalityCode)) {
           acc.Primary_Citizenship__c = '--None--';
        }else{
            acc.Primary_Citizenship__c = wrapper.nationalityCode;
         }

        if (wrapper.workPermitNumber != null) {
            acc.Permit_Number__c = wrapper.workPermitNumber;
        }
        if (wrapper.residentialAddress != null) {
            if (wrapper.residentialAddress.postalCode != null) {
                acc.BillingPostalCode = wrapper.residentialAddress.postalCode;
            }
            if (wrapper.residentialAddress.city != null) {
                acc.BillingCity = wrapper.residentialAddress.city;
            }
            if (wrapper.residentialAddress.address1 != null) {
                acc.BillingStreet = wrapper.residentialAddress.address1;
            }
        }
        if (wrapper.mobileNumber != null) {
            acc.Phone = wrapper.mobileNumber;
        }
        if (wrapper.residentialPhoneNumber != null) {
            acc.PersonHomePhone = wrapper.residentialPhoneNumber;
        }
        if (wrapper.businessPhoneNumber != null) {
            acc.Work_Contact_Number__c = wrapper.businessPhoneNumber;
        }
        if (wrapper.emailAddress != null) {
            acc.PersonEmail = wrapper.emailAddress;
        }
        if (wrapper.employerName != null) {
            acc.Employer_Name__c = wrapper.employerName;
        }

        if (!INDUSTRY.contains(wrapper.industryCode)) {
            acc.Industry__c = '--None--';
        }else{
            acc.Industry__c = wrapper.industryCode;
        }

        if (!EMPLOYMENT_TYPE.contains(wrapper.employmentType)) {
            acc.Employment_Type__c = '--None--';
        }else{
            acc.Employment_Type__c = wrapper.employmentType;
        }

        if (!OCCUPATION.contains(wrapper.occupationCode)) {
            acc.Occupation__c = '--None--';
        }else{
            acc.Occupation__c = wrapper.occupationCode;
        }

        if (!MAIN_INCOME_SOURCE.contains(wrapper.sourceOfFunds)){
                acc.Main_Income_Source__c = '--None--';
        }else{
                acc.Main_Income_Source__c = wrapper.sourceOfFunds;
        }

        if (!EXPECTED_NET_INCOME.contains(wrapper.incomeRange)) {
            acc.Expected_Net_Income__c = '--None--';
        }else{
            acc.Expected_Net_Income__c = wrapper.incomeRange;
        }

        if (!FREQUENCY_OF_INCOME.contains(wrapper.incomeFrequency)) {
            System.debug(wrapper.incomeFrequency);
            acc.Frequency_of_Main_Income_Source__c = '--None--';
        }else{
            acc.Frequency_of_Main_Income_Source__c = wrapper.incomeFrequency;
        }

        if (wrapper.taxNumber != null) {
            acc.Tax_Number__c = wrapper.taxNumber;
        }
        if (wrapper.age != null) {
            acc.Age__c = wrapper.age;
        }
        if (wrapper.employeeCode != null) {
            acc.Employee_Code__c = wrapper.employeeCode;
        }
    }

    public class ClientDetailsException extends Exception {}
}