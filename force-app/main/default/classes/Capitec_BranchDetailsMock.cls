/*
* Author : Oumesh Jhundoo
* Date : 23/11/2023
* Description : Mock class for Capitec_BranchDetails
* Last Modified by
*/
@isTest
global class Capitec_BranchDetailsMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"firstName":"Ian","lastName":"Test","email":"test@yopmail.coms","loginId":"cp360052"}');
        res.setStatusCode(200);
        return res;
    }
}