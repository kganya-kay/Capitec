/**
 * @description This class processes proactive messages by extracting values from JSON data
 * and replacing placeholders in message templates.
 */
public with sharing class Capitec_ProactiveMessageGenerator {

    /**
     * @description Extracts values from JSON and replaces placeholders in proactiveContent.
     *
     * @param jsonString The JSON string containing Salesforce record data.
     * @param salesForceVariables A list of fields to extract values from the JSON.
     * @param proactiveContent The message template with placeholders (e.g., "Hello {{1}}, case {{2}}").
     * @return The final proactiveContent string with placeholders replaced.
     */
    public static ProcessedProactiveMessage processProactiveMessage(String jsonString, List<String> salesForceVariables, String proactiveContent) {
        // Parse the JSON into a Map
        Map<String, Object> recordData = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        List<String> extractedValuesList = new List<String>();

        // Extract values based on requested fields
        for (String field : salesForceVariables) {
            Object fieldValue = getNestedValue(recordData, field);
            String value = fieldValue != null ? String.valueOf(fieldValue) : '';
            extractedValuesList.add(value);
        }

        // Replace placeholders in proactiveContent using extractedValuesList
        Integer placeholderIndex = 1;
        for (String value : extractedValuesList) {
            String placeholder = '{{' + String.valueOf(placeholderIndex) + '}}';
            proactiveContent = proactiveContent.replace(placeholder, value);
            placeholderIndex++;
        }

        // Return as ProcessedProactiveMessage wrapper
        return new ProcessedProactiveMessage(extractedValuesList, proactiveContent);
    }

    /**
     * @description Retrieves a nested value from a JSON structure using dot notation.
     *
     * @param jsonData The JSON data as a Map<String, Object>.
     * @param fieldPath The field path in dot notation (e.g., "Account.Name").
     * @return The extracted value or null if not found.
     */
    private static Object getNestedValue(Map<String, Object> jsonData, String fieldPath) {
        if (jsonData == null || fieldPath == null) return null;

        String[] fieldLevels = fieldPath.split('\\.');
        Map<String, Object> currentData = jsonData;

        // Traverse the JSON structure dynamically
        for (Integer i = 0; i < fieldLevels.size() - 1; i++) {
            String currentLevel = fieldLevels[i];

            // Move to the next level if exists
            if (currentData.containsKey(currentLevel) && currentData.get(currentLevel) instanceof Map<String, Object>) {
                currentData = (Map<String, Object>) currentData.get(currentLevel);
            } else {
                return null; // Stop if the path does not exist
            }
        }

        // Return the final field value
        String finalField = fieldLevels[fieldLevels.size() - 1];
        return currentData.containsKey(finalField) ? currentData.get(finalField) : null;
    }

    /**
     * @description Wrapper class for storing processed proactive messages.
     */
    public class ProcessedProactiveMessage {

        /**
         * @description List of extracted template parameters.
         */
        public List<String> templateParameters;

        /**
         * @description The final proactive content with placeholders replaced.
         */
        public String proactiveContent;

        /**
         * @description Constructor to initialize ProcessedProactiveMessage.
         *
         * @param templateParameters The extracted template parameters.
         * @param proactiveContent The processed proactive message content.
         */
        public ProcessedProactiveMessage(List<String> templateParameters, String proactiveContent) {
            this.templateParameters = templateParameters;
            this.proactiveContent = proactiveContent;
        }
    }
}