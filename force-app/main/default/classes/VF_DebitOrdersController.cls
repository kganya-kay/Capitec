/**
 * @description       : Controller for VF Email Template
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 09-22-2025
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class VF_DebitOrdersController {
    public String noActionDebitOrdersText { get; set; }
    public String clientActionDebitOrdersText { get; set; }

    public VF_DebitOrdersController(ApexPages.StandardController stdController) {
        Case c = (Case)stdController.getRecord();
        Id caseId = c.Id;

        // Call your existing method
        List<Conversions_AnalyseDebitOrders.debitOrderInput> inputList = new List<Conversions_AnalyseDebitOrders.debitOrderInput>();
        Conversions_AnalyseDebitOrders.debitOrderInput inputVar = new Conversions_AnalyseDebitOrders.debitOrderInput();
        inputVar.caseId = caseId;
        inputList.add(inputVar);

        List<Conversions_AnalyseDebitOrders.debitOrderOutput> results =
            Conversions_AnalyseDebitOrders.generateEmailBodyForDebitOrders(inputList);

        if(!results.isEmpty()) {
            noActionDebitOrdersText = results[0].noActionDebitOrdersText;
            clientActionDebitOrdersText = results[0].clientActionDebitOrdersText;
        }
    }
}