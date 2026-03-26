@IsTest
public class capitec_GetEnrolmentImage_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create Account and Case records
        Account testAccount = new Account(Name = 'Test Account', CIF_Number__c = '12345');
        insert testAccount;
        
        Case testCase = new Case(AccountId = testAccount.Id, Status = 'New');
        insert testCase;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = '12345',
            PathOnClient = 'testimage.jpg',
            VersionData = Blob.valueOf('Test data')
        );
        insert contentVersion;

        ContentVersion cV = [SELECT Id, ContentDocumentId FROM ContentVersion
        WHERE Id = :contentVersion.Id];

        ContentDocumentLink contentLink = new ContentDocumentLink(
            LinkedEntityId = testAccount.Id,
            ContentDocumentId = cV.ContentDocumentId, // Use the ID directly
            ShareType = 'V'
        );
        insert contentLink;
    }
    
    @IsTest
    static void testGetAccountImage() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        // Call getAccountImage method
        String imageUrl = capitec_GetEnrolmentImage.getAccountImage(testCase.Id);
        
        // Verify that the image URL is not null and has the correct path
        System.assertNotEquals(null, imageUrl, 'Expected non-null image URL');
        System.assert(imageUrl.startsWith('/sfc/servlet.shepherd/version/download/'), 'URL should start with the expected path');
    }
    

    
    @IsTest
    static void testGetAccountImage_NoContentDocument() {
        // Create a Case without a matching ContentDocument
        Account account = new Account(Name = 'Account Without Document', CIF_Number__c = '67890');
        insert account;
        
        Case caseWithoutDoc = new Case(AccountId = account.Id, Status = 'New');
        insert caseWithoutDoc;
        
        // Test getAccountImage method - expecting null return
        String result = capitec_GetEnrolmentImage.getAccountImage(caseWithoutDoc.Id);
        System.assertEquals(null, result, 'Expected null when no matching ContentDocument is found');
        

}
}