/**
 * Created by Marinus Jansen van Vuren on 16.04.2024.
 */

@IsTest
public class Capitec_LogEmailEventTest {
    
    static final String COMPLAINTS_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Retail_Complaints').getRecordTypeId();
        
    @IsTest
    static void LogEmailEventWorking() {
        Test.setMock(HttpCalloutMock.class, new Capitec_LogEmailEventMock());
        
        capitec_LogSFEmailEvent.LogEmailEventInput input = new capitec_LogSFEmailEvent.LogEmailEventInput();

        input.ParentId = '500Fg000009BTb6IAG';
        input.CreatedById = '0052600000BuF7IAAV';
        input.CreatedDate = '6/04/2024, 10:43';
        input.FromAddress = 'intcomplaintmanage@capitecbank.co.za)';
        input.HasAttachment = 'false';
        input.Subject = 'mmmmhkey 555';
        input.TextBody = 'mmmmhkey 555 thread::SNKW3HAuejqj3D9JbUTnxSY::';
        input.ToAddress = 'angelahobbs@capitecbank.co.za';
        Boolean gotError = false;
       
        Test.startTest();
        
        try {
            capitec_LogSFEmailEvent.logEmail(new List<capitec_LogSFEmailEvent.LogEmailEventInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_LogSFEmailEvent.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_LogSFEmailEvent.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        
        Test.stopTest();

        System.assertEquals(false, gotError, 'Exception not thrown.');
    }
    
    @IsTest
    static void LogEmailEventNotWorking() {
        Test.setMock(HttpCalloutMock.class, new Capitec_LogEmailEventMock());
                
        capitec_LogSFEmailEvent.LogEmailEventInput input = new capitec_LogSFEmailEvent.LogEmailEventInput();

        input.ParentId = '';
        input.CreatedById = '0052600000BuF7IAAV';
        input.CreatedDate = '6/04/2024, 10:43';
        input.FromAddress = 'intcomplaintmanage@capitecbank.co.za)';
        input.HasAttachment = 'false';
        input.Subject = 'mmmmhkey 555';
        input.TextBody = 'mmmmhkey 555 thread::SNKW3HAuejqj3D9JbUTnxSY::';
        input.ToAddress = 'angelahobbs@capitecbank.co.za';
        Boolean gotError = false;

        Test.startTest();
        try {
            capitec_LogSFEmailEvent.logEmail(new List<capitec_LogSFEmailEvent.LogEmailEventInput>{input});
        } catch(Exception ex) {
            if (ex.getMessage().contains(capitec_LogSFEmailEvent.API_ISSUE_MSG) ||
                    ex.getMessage().contains(capitec_LogSFEmailEvent.BAD_REQUEST_MSG)) {
                gotError = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, gotError, 'Exception has been thrown.');
    }
}