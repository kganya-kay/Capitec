/**
 * @description Utility class for merging QuickText with dynamic field values from SObjects.
 * @author     Johan Langenhoven
 * @date       14/10/2024
**/
public with sharing class Capitec_MergeQuickTextUtility {

    /**
    * @description Generates merged text by replacing merge fields in the QuickText message with actual values from the provided records.
    * @param recordIds Set of record IDs to fetch data from.
    * @param quickText QuickText object containing the message with merge fields.
    * @return MergedQuickText object containing the merged fields and the final merged message.
    */
    public static MergedQuickText generateMergedText(Set<Id> recordIds, QuickText quickText) {
        List<SObject> sObjects = new List<SObject>();
        List<String> mergedFields = new List<String>();
        String mergedMessage = quickText.Message;

        // Regular expression pattern to match merge fields like {!Object.Field}
        Pattern pattern = Pattern.compile('\\{!([^}]+)\\}');
        Matcher matcher = pattern.matcher(mergedMessage);

        for (Id recordId : recordIds) {
            if (recordId != null) {
                SObject sObjectRecord = dynamicQueryWithFields(recordId);
                sObjects.add(sObjectRecord);
            }
        }

        // Iterate through all matched merge fields in the message
        while (matcher.find()) {
            String mergeField = matcher.group(1).trim();
            // Split the merge field to get the object and field parts (e.g., Case.Subject)
            List<String> parts = mergeField.split('\\.');

            if (parts.size() == 2) {
                for (SObject sObjectRecord : sObjects) {
                    String objectName = parts[0];
                    String fieldName = parts[1];

                    Map<String, Object> fieldMap = sObjectRecord.getPopulatedFieldsAsMap();

                    // Check if the SObject type matches and if the field is present in the record's field map
                    if (sObjectRecord.getSObjectType().getDescribe().getName() == objectName && fieldMap.containsKey(fieldName)) {
                        Object fieldValue = fieldMap.get(fieldName);
                        String valueToReplace = fieldValue != null ? String.valueOf(fieldValue) : '';
                        mergedFields.add(valueToReplace);
                        // Replace the merge field in the message
                        mergedMessage = mergedMessage.replace('{!' + mergeField + '}', valueToReplace);
                    }
                }
            }
        }

        MergedQuickText mergedQuickText = new MergedQuickText(mergedFields, mergedMessage);

        return mergedQuickText;
    }

    /**
    * @description Executes a dynamic SOQL query to fetch all fields of a record by its ID.
    * @param recordId ID of the record to fetch.
    * @return SObject containing all fields of the record.
    */
    private static SObject dynamicQueryWithFields(Id recordId) {
        Schema.SObjectType sObjectType = recordId.getSobjectType();
        String sObjectName = sObjectType.getDescribe().getName();

        String query = 'SELECT ' + getAllFieldNames(sObjectName) + ' FROM ' + sObjectName + ' WHERE Id = :recordId';
        SObject sObjectRecord = Database.query(String.escapeSingleQuotes(query));

        return sObjectRecord;
    }

    /**
    * @description Helper method to get all field names of an SObject type.
    * @param sObjectType Name of the SObject type.
    * @return Comma-separated string of all field names.
    */
    private static String getAllFieldNames(String sObjectType) {
        List<String> fieldNames = new List<String>();

        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sObjectType);
        Map<String, Schema.SObjectField> fieldsMap = objectType.getDescribe().fields.getMap();

        for (String fieldName : fieldsMap.keySet()) {
            fieldNames.add(fieldName);
        }
        String fields = String.join(fieldNames, ', ');

        return fields;
    }

    /**
    * @description Inner class representing the result of the merged QuickText.
    */
    public class MergedQuickText {
        public List<String> mergedFields;
        public String message;

        /**
        * @description Constructor for MergedQuickText.
        * @param mergedFields List of merged field values.
        * @param message Final merged message.
        */
        public MergedQuickText(List<String> mergedFields, String message) {
            this.mergedFields = mergedFields;
            this.message = message;
        }
    }
}