/**
 * Created by Sebastian on 19.04.2023.
 */

public class Capitec_DataSourceRiskScoreMockResponse implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest httpRequest) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"PepYN":"N","PepDte":"","CRAOutCome":"","CRAScore":"","CRADte":"","CDDOutCome":"Medium","CDDScore":"918.00","CDDDte":"2023-03-1809:50:52.0","RiskFactorList":[{"RF_Label":"AccountType[[ACCTCLASS]]","RF_Value":"04{{31.00}}{{31.00}}@|@CorrespondentBank[[BOOL]]","RF_Source":"CDD","RF_Score":"31.00"},{"RF_Label":"Occupation[[OCCUP]]","RF_Value":"06{{36.00}}","RF_Source":"CDD","RF_Score":"36.00"},{"RF_Label":"OngoingSourceofFunds[[FUND]]","RF_Value":"7{{28.00}}{{28.00}}","RF_Source":"CDD","RF_Score":"28.00"},{"RF_Label":"ClientNetWorth[[NUM]]","RF_Value":"36000.0{{30.00}}","RF_Source":"CDD","RF_Score":"30.00"},{"RF_Label":"CitizenshipCountry[[CTRY]]","RF_Value":"ZA{{31.00}}","RF_Source":"CDD","RF_Score":"31.00"},{"RF_Label":"NumOfSARs[[NUM]]","RF_Value":"0{{30.00}}","RF_Source":"CDD","RF_Score":"30.00"},{"RF_Label":"BehaviouralRiskModel","RF_Value":"TRUE","RF_Source":"CDD","RF_Score":"525.00"},{"RF_Label":"IsPEP","RF_Value":"FALSE","RF_Source":"CDD","RF_Score":"36.00"},{"RF_Label":"Tenure","RF_Value":"11Months","RF_Source":"CDD","RF_Score":"47.00"},{"RF_Label":"Industry","RF_Value":"[01]Government","RF_Source":"CDD","RF_Score":"62.00"},{"RF_Label":"OnboardingChannel","RF_Value":"[B]Branch","RF_Source":"CDD","RF_Score":"31.00"},{"RF_Label":"ClientLocation","RF_Value":"[0404]NorthWest-NorthernPartNorthernRegion","RF_Source":"CDD","RF_Score":"31.00"}]}');
        res.setStatusCode(200);
        return res;
    }
}