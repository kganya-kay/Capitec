@IsTest
public class capitec_ClientDetailsMockResponse implements HttpCalloutMock{

    public static HttpResponse respond(HttpRequest req) {    
        
        if(req.getEndpoint().contains('987654321')){
            return clientDetailsNull();
        } 
        return clientDetailsSuccess();

    }

    private static HttpResponse clientDetailsSuccess() {

        // Response containing values that map to valid picklist options in the Org
        String body = '{"cifNumber":"123456789","title":"MS","firstName":"DEV","middleName":"test", "employerName": "The Test Factory","lastName":"SURNAME","idNumber":"7101180046087","dateOfBirth":"1971-01-18","countryOfBirth":"ZA","countryOfResidence":"ZA","nationalityCode":"ZA","sex":"F","workPermitNumber":"123456789","residentialAddress":{"address1":"10QUNTUMSTR","address2":"X","suburb":"TEST","city":"Rustenburg","postalCode":"0300"},"mobilePhoneNumber":"0606384308","homePhoneNumber":"0215550000","workPhoneNumber":"0215560000","emailAddress":"test@test.com","employmentIndustryCode":"01","employmentIndustryName":"test" , "industryCode":"01", "occupationCode":"01","sourceOfFunds":"09","employmentTypeCode":"14","employmentTypeName":"Grant","occupation":"TEST","sourceOfIncome":"Test","incomeRange":null,"incomeFrequency":null,"taxNumber":"123456789"}';
        HttpResponse response = new HttpResponse();
        response.setBody(body);
        response.setStatusCode(200);
        return response;
    }

    private static HttpResponse clientDetailsNull() {

        // Response containing values that map to invalid picklist options Org
        String body = '{"cifNumber":"987654321","title":"MS","firstName":"DEV","middleName":"test","lastName":"SURNAME","idNumber":"7101180046087","dateOfBirth":"1971-01-18","countryOfBirth":"XX","countryOfResidence":"XX","nationalityCode":"XX","sex":"G","workPermitNumber":"123456789","residentialAddress":{"address1":"10QUNTUMSTR","address2":"X","suburb":"TEST","city":"Rustenburg","postalCode":"0300"},"mobilePhoneNumber":"0606384308","homePhoneNumber":"0215550000","workPhoneNumber":"0215560000","emailAddress":"test@test.com","employerName":"The Test Factory","employmentIndustryCode":"21","employmentIndustryName":"test" , "industryCode":"00", "occupationCode":"00","sourceOfFunds":"09","employmentTypeCode":"014","employmentTypeName":"Grant","occupation":"TEST","sourceOfIncome":"Test","incomeRange":null,"incomeFrequency":null,"taxNumber":"123456789"}';
        HttpResponse response = new HttpResponse();
        response.setBody(body);
        response.setStatusCode(200);
        return response;
    }
}