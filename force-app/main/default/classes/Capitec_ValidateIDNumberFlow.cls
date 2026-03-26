/*
********************************************************************************************
Apex Class Name    : Capitec_ValidateIDNumberFlow
Created Date       : December 19, 2024
@description       : Validates a South African ID number - invocable via flow
@author            : Cornelia Smit
********************************************************************************************
*/

public with sharing class Capitec_ValidateIDNumberFlow {
    
    /**
     * @description  : Determines if a 13-digit South African ID number is valid
     * @param        : inputNumbers List of ID numbers to verify
     * @return       : List of boolean results - true if ID number is valid
     */
    @InvocableMethod(label='Validate ID Number' description='Validates whether a South African ID number is valid.')
    public static List<Boolean> validateIDNumber(List<String> inputNumbers) {

        if (inputNumbers == null || inputNumbers.isEmpty()) {
            throw new EmptyListException('Input list cannot be empty. Please provide at least one ID number.');
        }

        List<Boolean> results = new List<Boolean>();

        for (String inputNumber : inputNumbers) {
            Boolean result = Capitec_GenericUtilities.calculateLeftToRightLuhnChecksum(inputNumber);
            results.add(result);
        }

        return results;
    }

    public class EmptyListException extends Exception {}
}