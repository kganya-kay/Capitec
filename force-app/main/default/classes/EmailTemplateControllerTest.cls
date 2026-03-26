/**
 * @description       : Test Class for Email Template Controller
 * @author            : Rajesh Yandrathi
 * @group             : 
 * @last modified on  : 05-16-2024
**/
@isTest
private class EmailTemplateControllerTest {
    @testSetup
    static void setup() {
        System.runAs(new User(Id=UserInfo.getUserId())){
            EmailTemplate et = new EmailTemplate(); 
            et.isActive = true; 
            et.Name = 'Test Template'; 
            et.DeveloperName = 'Test_Template'; 
            et.TemplateType = 'text';
            et.Subject = 'Test Subject';
            et.FolderId = UserInfo.getUserId(); 
            et.Body = 'Test Body'; 

            insert et;
        }
    }

    @isTest
    static void testGetTemplateInfo() {

        String templateApiName = 'Test_Template';

        Test.startTest();
        EmailTemplate templateInfo = EmailTemplateController.getTemplateInfo(templateApiName);
        Test.stopTest();
    }
}