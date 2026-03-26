/*
********************************************************************************************
Apex Class Name    : Capitec_ValidateIDNumberTest
Created Date       : December 20, 2024
@description       : Test class for the ValidateIDNumber classes
@author            : Cornelia Smit
********************************************************************************************
*/

@IsTest
private with sharing class Capitec_ValidateIDNumberTest {
    private static final String emptyIDNumber = '';
    private static final String invalidIDNumber1 = '9009010062087';
    private static final String invalidIDNumber2 = '9605240053081';
    private static final String validIDNumber1 = '9309010062087';
    private static final String validIDNumber2 = '9500240053082';

    @IsTest
    static void testFlowEmptyIDNumber() {

        List<String> inputNumbers = new List<String>();
        List<Boolean> results = new List<Boolean>();

        Boolean exceptionCaught = false;
        
        try {
            results = Capitec_ValidateIDNumberFlow.validateIDNumber(inputNumbers);
        } catch (Capitec_ValidateIDNumberFlow.EmptyListException ex) {
            exceptionCaught = true;
            System.assertEquals('Input list cannot be empty. Please provide at least one ID number.', ex.getMessage(), 'Incorrect exception message.');
        }

        System.assert(exceptionCaught, 'Expected empty list exception was not thrown.');
    }

    @IsTest
    static void testFlowInvalidIDNumber() {

        List<String> inputNumbers = new List<String>();
        inputNumbers.add(invalidIDNumber1);
        inputNumbers.add(invalidIDNumber2);
        
        List<Boolean> results = new List<Boolean>();
        
        results = Capitec_ValidateIDNumberFlow.validateIDNumber(inputNumbers);

        for (Boolean result : results) {
            System.assertEquals(false, result, 'ID number should be invalid.');
        }
    }

    @IsTest
    static void testFlowValidIDNumber() {

        List<String> inputNumbers = new List<String>();
        inputNumbers.add(validIDNumber1);
        inputNumbers.add(validIDNumber2);

        List<Boolean> results = new List<Boolean>();
        
        results = Capitec_ValidateIDNumberFlow.validateIDNumber(inputNumbers);

        for (Boolean result : results) {
            System.assertEquals(true, result, 'ID number should be valid.');
        }
    }

    @IsTest
    static void testAuraEmptyIDNumber() {

        Boolean result;
        Boolean exceptionCaught = false;
        
        try {
            result = Capitec_ValidateIDNumberAura.validateIDNumber(emptyIDNumber);
        } catch (Exception ex) {
            exceptionCaught = true;
        }

        System.assert(exceptionCaught, 'Expected blank string exception was not thrown.');
    }

    @IsTest
    static void testAuraInvalidIDNumber() {

        Boolean result;

        result = Capitec_ValidateIDNumberAura.validateIDNumber(invalidIDNumber1);

        System.assertEquals(false, result, 'ID number should be invalid.');

    }

    @IsTest
    static void testAuraValidIDNumber() {

        Boolean result;

        result = Capitec_ValidateIDNumberAura.validateIDNumber(validIDNumber1);

        System.assertEquals(true, result, 'ID number should invalid.');

    }

    @IsTest
    static void testOmniNoIDNumber() {

        Map<String, Object> input = new Map<String, Object>();  
        Map<String, Object> output = new Map<String, Object>();  
    
        Capitec_ValidateIDNumberOmni classInstance = new Capitec_ValidateIDNumberOmni();
        Boolean result = classInstance.invokeMethod('', input, output, new Map<String, Object>());

        System.assertEquals(true, result, 'Class should not have thrown an exception.');
        System.assertEquals('No input number provided.', output.get('Error'), 'Incorrect error message.');
    }

    @IsTest
    static void testOmniEmptyIDNumber() {

        Map<String, Object> input = new Map<String, Object>{
            'inputNumber' => ''
            };   
        Map<String, Object> output = new Map<String, Object>();   
    
        Capitec_ValidateIDNumberOmni classInstance = new Capitec_ValidateIDNumberOmni();
        Boolean result = classInstance.invokeMethod('', input, output, new Map<String, Object>());

        System.assertEquals(true, result, 'Class should not have thrown an exception.');
        System.assertEquals('Input cannot be empty. Please provide an ID number.', output.get('Error'), 'Incorrect error message.');
    }

    @IsTest
    static void testOmniInvalidIDNumber() {

        Map<String, Object> input = new Map<String, Object>{
            'inputNumber' => invalidIDNumber1
            };      
        Map<String, Object> output = new Map<String, Object>();
    
        Capitec_ValidateIDNumberOmni classInstance = new Capitec_ValidateIDNumberOmni();
        Boolean result = classInstance.invokeMethod('', input, output, new Map<String, Object>());

        System.assertEquals(true, result, 'Class should not have thrown an exception.');
        System.assertEquals(false, output.get('ValidIDNumber'), 'ID number should be invalid.');
    }

    @IsTest
    static void testOmniValidIDNumber() {

        Map<String, Object> input = new Map<String, Object>{
            'inputNumber' => validIDNumber1
            };      
        Map<String, Object> output = new Map<String, Object>();
    
        Capitec_ValidateIDNumberOmni classInstance = new Capitec_ValidateIDNumberOmni();
        Boolean result = classInstance.invokeMethod('', input, output, new Map<String, Object>());

        System.assertEquals(true, result, 'Class should not have thrown an exception.');
        System.assertEquals(true, output.get('ValidIDNumber'), 'ID number should be valid.');
    }

}