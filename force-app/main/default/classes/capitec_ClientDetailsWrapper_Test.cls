/**
 * Created by Sebastian on 20.04.2023.
 */

 @IsTest
 public with sharing class capitec_ClientDetailsWrapper_Test {
 
     @IsTest
     static void testParse() {
         String json = '{'+
                 '  \"cifNumber\": \"369733096\",'+
                 '  \"title\": \"MS\",'+
                 '  \"firstName\": \"DEV\",'+
                 '  \"middleName\": null,'+
                 '  \"lastName\": \"SURNAME\",'+
                 '  \"idNumber\": \"7101180046087\",'+
                 '  \"dateOfBirth\": \"1971-01-18\",'+
                 '  \"countryOfBirth\": null,'+
                 '  \"countryOfResidence\": null,'+
                 '  \"nationality\": \"ZA\",'+
                 '  \"sex\": \"F\",'+
                 '  \"workPermitNumber\": null,'+
                 '  \"residentialAddress\": {'+
                 '    \"address1\": \"10 QUNTUM STR\",'+
                 '    \"address2\": \"X\",'+
                 '    \"suburb\": \"TEST\",'+
                 '    \"city\": \"Rustenburg\",'+
                 '    \"postalCode\": \"0300\"'+
                 '  },'+
                 '  \"mobilePhoneNumber\": \"0606384308\",'+
                 '  \"homePhoneNumber\": \"0215550000\",'+
                 '  \"workPhoneNumber\": \"0215560000\",'+
                 '  \"emailAddress\": \"test@test.com\",'+
                 '  \"employerName\": null,'+
                 '  \"employmentIndustryCode\": \"\",'+
                 '  \"employmentIndustryName\": null,'+
                 '  \"employmentTypeCode\": \"14\",'+
                 '  \"employmentTypeName\": \"Grant\",'+
                 '  \"occupation\": \"\",'+
                 '  \"occupationCode\": \"\",'+
                 '  \"industryCode\": \"\",'+
                 '  \"sourceOFFunds\": \"\",'+
                 '  \"sourceOfIncome\": null,'+
                 '  \"incomeRange\": null,'+
                 '  \"incomeFrequency\": null,'+
                 '  \"taxNumber\": null'+
                 '}';
         capitec_ClientDetailsWrapper obj = capitec_ClientDetailsWrapper.parse(json);
         System.assert(obj != null);
     }
 }