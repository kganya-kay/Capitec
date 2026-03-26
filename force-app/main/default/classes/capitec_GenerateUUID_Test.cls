//RCS-3517 Termination and Restrictions EDD Workflow - Salesforce (Lazola)

@IsTest
public class capitec_GenerateUUID_Test {
    @IsTest
    static void testGenerateUUID() {
        // Call the method to be tested
        List<String> inputs = new List<String>(); // Empty list as placeholder for future inputs
        List<String> result = capitec_GenerateUUID.capitec_GenerateUUID(inputs);

        // Assert the expected results
        System.assertEquals(1, result.size(), 'Expected a single UUID in the result list');
        System.assert(result[0].length() == 36, 'The generated UUID should have 36 characters');
        
        // Additional check for the format of the UUID (8-4-4-4-12)
        String[] parts = result[0].split('-');
        System.assertEquals(5, parts.size(), 'The UUID should be in the format of 8-4-4-4-12');
        System.assertEquals(8, parts[0].length(), 'The first part of UUID should have 8 characters');
        System.assertEquals(4, parts[1].length(), 'The second part of UUID should have 4 characters');
        System.assertEquals(4, parts[2].length(), 'The third part of UUID should have 4 characters');
        System.assertEquals(4, parts[3].length(), 'The fourth part of UUID should have 4 characters');
        System.assertEquals(12, parts[4].length(), 'The fifth part of UUID should have 12 characters');
    }
}