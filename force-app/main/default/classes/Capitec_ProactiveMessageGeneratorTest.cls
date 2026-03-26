/**
 * @description Unit test class for Capitec_ProactiveMessageGenerator.
 */
@IsTest(SeeAllData=false)
private class Capitec_ProactiveMessageGeneratorTest {

    /**
     * @description Test method for processProactiveMessage with valid JSON and placeholders.
     */
    @IsTest
    static void testProcessProactiveMessage() {
        String jsonString = '{"Account": {"Name": "John Doe"}, "Case": {"CaseNumber": "12345"}}';

        List<String> salesForceVariables = new List<String>{
                'Account.Name', 'Case.CaseNumber'
        };

        String proactiveContent = 'Hello {{1}}, your case number is {{2}}.';

        Test.startTest();

        Capitec_ProactiveMessageGenerator.ProcessedProactiveMessage result =
                Capitec_ProactiveMessageGenerator.processProactiveMessage(jsonString, salesForceVariables, proactiveContent);

        Test.stopTest();

        System.assertEquals('Hello John Doe, your case number is 12345.', result.proactiveContent, 'Proactive message content should be correctly formatted.');
        System.assertEquals(2, result.templateParameters.size(), 'Template parameters list should contain two elements.');
        System.assertEquals('John Doe', result.templateParameters[0], 'First parameter should be John Doe.');
        System.assertEquals('12345', result.templateParameters[1], 'Second parameter should be 12345.');
    }

    /**
     * @description Test method for processProactiveMessage with missing JSON fields.
     */
    @IsTest
    static void testProcessProactiveMessageWithMissingFields() {
        String jsonString = '{"Case": {"CaseNumber": "12345"}}';

        List<String> salesForceVariables = new List<String>{
                'Account.Name', 'Case.CaseNumber'
        };

        String proactiveContent = 'Hello {{1}}, your case number is {{2}}.';

        Test.startTest();

        Capitec_ProactiveMessageGenerator.ProcessedProactiveMessage result =
                Capitec_ProactiveMessageGenerator.processProactiveMessage(jsonString, salesForceVariables, proactiveContent);

        Test.stopTest();

        System.assertEquals('Hello , your case number is 12345.', result.proactiveContent, 'Missing fields should be replaced with an empty string.');
        System.assertEquals(2, result.templateParameters.size(), 'Template parameters list should contain two elements.');
        System.assertEquals('', result.templateParameters[0], 'First parameter should be an empty string.');
        System.assertEquals('12345', result.templateParameters[1], 'Second parameter should be 12345.');
    }
}