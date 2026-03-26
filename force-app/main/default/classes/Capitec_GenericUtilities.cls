/*
********************************************************************************************
Apex Class Name    : Capitec_GenericUtilities
Created Date       : December 19, 2024
@description       : Houses generic utility methods, including a left to right Luhn checksum
                     used to verify South African ID numbers
@author            : Cornelia Smit
********************************************************************************************
*/

public with sharing class Capitec_GenericUtilities {

    /**
     * @description  : Determines if a number passes the left to right Luhn checksum algorithm
     * @param        : inputNumber number to verify
     * @return       : True if the number is valid
     */
    public static Boolean calculateLeftToRightLuhnChecksum(String inputNumber) {
            if (String.isBlank(inputNumber)) {
                return false;
            }
    
            Integer sum = 0;
    
            for (Integer i = 0; i < inputNumber.length(); i++) {
                // Parse the current digit
                Integer currentNumber = Integer.valueOf(inputNumber.substring(i, i + 1));
    
                // Apply Luhn doubling rule for every second digit
                if (Math.Mod((i + 1), 2) == 0) {
                    currentNumber *= 2;
                    if (currentNumber > 9) {
                        currentNumber -= 9;
                    }
                }
                sum += currentNumber;
            }
            // Check if the sum is divisible by 10
            return Math.mod(sum, 10) == 0;
        }    
}