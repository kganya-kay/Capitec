/**
 * Created by Sebastian on 13.04.2023.
 * Updated by Barend on 07.12.2023.
 */

 public class capitec_ClientDetailsWrapper {

    public String cifNumber;
    public String title;
    public String firstName;
    public String middleName;
    public String lastName;
    public String idNumber;
    public String birthDate;
    public String countryOfBirth;
    public String countryOfResidence;
    public String nationalityCode;
    public String sex;
    public String workPermitNumber;
    public ResidentialAddress residentialAddress;
    public String mobileNumber;
    public String residentialPhoneNumber;
    public String businessPhoneNumber;
    public String emailAddress;
    public String employerName;
    public String employmentType;
    public String sourceOfIncome;
    public String incomeRange;
    public String incomeFrequency;
    public string industryCode;
    public string occupationCode;
    public string sourceOfFunds;
    public String taxNumber;
    public Integer age;
    public String employeeCode;


    public class ResidentialAddress {
        public String address1;
        public String address2;
        public String suburb;
        public String city;
        public String postalCode;
    }



    public static capitec_ClientDetailsWrapper parse(String json) {
        return (capitec_ClientDetailsWrapper) System.JSON.deserialize(json, capitec_ClientDetailsWrapper.class);
        
    }
}