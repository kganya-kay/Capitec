/*
********************************************************************************************
Apex Class Name    : Capitec_ValidateIDNumberAura
Created Date       : December 19, 2024
@description       : Validates a South African ID number - invocable via LWC
@author            : Cornelia Smit
********************************************************************************************
*/

public with sharing class Capitec_ValidateIDNumberAura {
    /**
     * @description  : Determines if a 13-digit South African ID number is valid
     * @param        : inputNumbers List of ID numbers to verify
     * @return       : Boolean result - true if ID number is valid
     */
    @AuraEnabled
    public static Boolean validateIDNumber(String inputNumber) {
        
        if (String.isBlank(inputNumber)) {
            throw new AuraHandledException('Input cannot be empty. Please provide an ID number.');
        }
        
        try {
           Boolean result = Capitec_GenericUtilities.calculateLeftToRightLuhnChecksum(inputNumber); 
           return result;
        } catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}