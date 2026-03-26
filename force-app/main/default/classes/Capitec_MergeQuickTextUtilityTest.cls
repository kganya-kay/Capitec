/**
 * @description Unit test class for Capitec_MergeQuickTextUtility.
 * @author      Johan Langenhoven
 * @date        2024/10/15
 */
@IsTest(SeeAllData=false)
private class Capitec_MergeQuickTextUtilityTest {

    /**
    * @description Tests the generateMergedText method of Capitec_MergeQuickTextUtility.
    */
    @IsTest
    static void testGenerateMergedText() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        QuickText testQuickText = new QuickText(
                Name = 'Test QuickText',
                Message = 'Hello {!Account.Name}, welcome to our service!'
        );
        insert testQuickText;

        Set<Id> recordIds = new Set<Id>{
                testAccount.Id
        };

        Test.startTest();

        Capitec_MergeQuickTextUtility.MergedQuickText result = Capitec_MergeQuickTextUtility.generateMergedText(recordIds, testQuickText);

        Test.stopTest();

        Assert.areEqual(1, result.mergedFields.size());
        Assert.areEqual('Test Account', result.mergedFields[0]);
        Assert.areEqual('Hello Test Account, welcome to our service!', result.message);
    }
}