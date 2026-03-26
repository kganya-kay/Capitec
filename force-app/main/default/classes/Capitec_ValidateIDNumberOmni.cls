/*
********************************************************************************************
Apex Class Name    : Capitec_ValidateIDNumberOmni
Created Date       : December 19, 2024
@description       : Validates a South African ID number - invocable via Omnistudio
@author            : Cornelia Smit
********************************************************************************************
*/

global with sharing class Capitec_ValidateIDNumberOmni implements Omnistudio.VlocityOpenInterface {
    /**
     * @description       : Invokes the specified method to proc
     * @param methodName  : Name of the method to be invoked
     * @param input       : Map containing input data
     * @param output      : Map to store output data
     * @param option      : Map to store additional options
     * @return            : Boolean indicating whether the operation succeeded or not
     */
    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> option) {
        
        try {
            validateIDNumber(input, output);
            return true;
        } catch (Exception ex) {
            output.put('Error', ex.getMessage());
            return false;
        }
    }

    /**
     * @description       : Determines if a 13-digit South African ID number is valid
     * @param input       : Map containing input data
     * @param output      : Map to store output data
     * @return            : Boolean result - true if ID number is valid
     */
    private static void validateIDNumber(Map<String, Object> input, Map<String, Object> output) {

        String inputNumber = '';
        Boolean result;

        if (input.containsKey('inputNumber')) {
            inputNumber = (String) input.get('inputNumber');
        } else {
            output.put('Error', 'No input number provided.');
            return;
        }

        if (String.isBlank(inputNumber)) {
            output.put('Error', 'Input cannot be empty. Please provide an ID number.');
            return;
        }
    
        result = Capitec_GenericUtilities.calculateLeftToRightLuhnChecksum(inputNumber);
        output.put('ValidIDNumber', result);
    }
}