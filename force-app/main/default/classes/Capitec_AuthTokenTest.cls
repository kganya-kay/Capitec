/**
 * Created by CalebGovender on 2023/07/20.
 */
@isTest
private class Capitec_AuthTokenTest {

    @IsTest
    static void GetTokenWorking() {
        Test.setMock(HttpCalloutMock.class, new capitec_AuthTokenMockResponse());
        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_AuthToken.getToken();
        } catch(Exception ex) {
            gotError = true;
        }
        Test.stopTest();

        System.assertEquals(false, gotError, 'Exception has not been throw.');
    }

    @IsTest
    static void GetTokenNotWorking() {
       /* Test.setMock(HttpCalloutMock.class, new capitec_AuthTokenMockResponse());
        Boolean gotError = false;
        Test.startTest();
        try {
            capitec_AuthToken.getToken();
        } catch(Exception ex) {
                gotError = true;
        }
        Test.stopTest();

        System.assertEquals(true, gotError, 'Exception has been throw.');
*/
    }
}