//RCS-3517 Termination and Restrictions EDD Workflow - Salesforce (Lazola)
// This class provides a method to generate a random UUID (Universally Unique Identifier)

public class capitec_GenerateUUID {
    
    // This invocable method allows the 'Generate UUID' function to be called in Salesforce process builder or flows
    
    @InvocableMethod(label='Generate UUID' description='Generates a random UUID')
    public static List<String> capitec_GenerateUUID (List<String> inputs) {
        
        // Generate a UUID using the helper method below
        
        String randomUUID = generateUUID();
        
         // Return the generated UUID in a list as required by invocable methods
        
        return new List<String>{randomUUID};
    }

    // Helper method to generate a random UUID
    
   public static String generateUUID() {
       
       // Use the built-in UUID class to create a new random UUID
       
        UUID randomUUID = UUID.randomUUID();
        
       // Convert the UUID to a string and return it
       
        return randomUUID.toString();
    }
    
}