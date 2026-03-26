/*
  @description       : CEDT-2946 - SendCashVoucher Controller to handle voucher operations
  @author            : Kevin Nundran
  @last modified on  : 10-09-2024
  @last modified by  : Kevin Nundran
*/
public class capitec_SendCashVoucherController {

    /*
      @description       : Wrapper class to hold SendCashVoucher data structure
      @author            : Kevin Nundran
      @created on        : 10-09-2024
    */
    public class SendCashVoucherWrapper{
        public String Id{get;set;}
        public String ExternalId{get;set;}
        public String VoucherNumber{get;set;}
        public String SentFrom{get;set;}
        public Double SendAmount{get;set;}
        public String Status{get;set;}
        public DateTime DateCreated{get;set;}
        public DateTime DateModified{get;set;}
        public Boolean isRedeemable{get;set;}
        public Boolean isRedeemed{get;set;}
        public Boolean isHold{get;set;}
        public Boolean isOther{get;set;}
        public Boolean showHoldButton{get;set;}
        public Boolean showReleaseButton{get;set;}
    }
    
    /*
      @description       : Method to return a hardcoded list of dummy vouchers if real data is not available
      @author            : Kevin Nundran
      @created on        : 10-09-2024
      @last modified on  : 10-09-2024
      @param accountId   : ID of the related account for which to fetch dummy vouchers
      @return            : Serialized JSON string containing a list of dummy voucher data
    */
    @AuraEnabled(cacheable=true)
    public static String getVoucherListDummy(Id accountId, String actionType) {
        List<SendCashVoucherWrapper> lstSendCashVoucherWrap = new List<SendCashVoucherWrapper>();
        
        // Create the first voucher object
        SendCashVoucherWrapper voucher1 = new SendCashVoucherWrapper();
        voucher1.Id = '1';
        voucher1.ExternalId = 'EXT-001';
        voucher1.VoucherNumber = 'VCH001';
        voucher1.SentFrom = 'Capitec Branch A';
        voucher1.SendAmount = 2500.0;
        voucher1.Status = 'REDEEMED';
        voucher1.DateCreated = DateTime.newInstance(2024, 9, 8, 0, 0, 0);
        voucher1.DateModified = DateTime.newInstance(2024, 9, 8, 0, 0, 0);
        voucher1.isRedeemable = false;
        voucher1.isRedeemed = true;
        voucher1.isHold = false;
        voucher1.showHoldButton = false;
        voucher1.showReleaseButton = false;
        lstSendCashVoucherWrap.add(voucher1);
        
        // Create the second voucher object
        SendCashVoucherWrapper voucher2 = new SendCashVoucherWrapper();
        voucher2.Id = '2';
        voucher2.ExternalId = 'EXT-002';
        voucher2.VoucherNumber = 'VCH002';
        voucher2.SentFrom = 'Capitec Branch B';
        voucher2.SendAmount = 2000.0;
        voucher2.Status = 'REDEEMABLE';
        voucher2.DateCreated = DateTime.newInstance(2024, 9, 8, 0, 0, 0);
        voucher2.DateModified = DateTime.newInstance(2024, 9, 8, 0, 0, 0);
        voucher2.isRedeemable = true;
        voucher2.isRedeemed = false;
        voucher2.isHold = false;
        voucher2.showHoldButton = (voucher2.Status == 'REDEEMABLE' && actionType=='Hold');
        voucher2.showReleaseButton = (voucher2.Status == 'HOLD' && actionType=='Release');
        lstSendCashVoucherWrap.add(voucher2);
        
        // Create the second voucher object
        SendCashVoucherWrapper voucher3 = new SendCashVoucherWrapper();
        voucher3.Id = '3';
        voucher3.ExternalId = 'EXT-003';
        voucher3.VoucherNumber = 'VCH003';
        voucher3.SentFrom = 'Capitec Branch C';
        voucher3.SendAmount = 2000.0;
        voucher3.Status = 'HOLD';
        voucher3.DateCreated = DateTime.newInstance(2024, 9, 8, 0, 0, 0);
        voucher3.DateModified = DateTime.newInstance(2024, 9, 8, 0, 0, 0);
        voucher3.isRedeemable = false;
        voucher3.isRedeemed = false;
        voucher3.isHold = true;
        voucher3.showHoldButton = (voucher3.Status == 'REDEEMABLE' && actionType=='Hold');
        voucher3.showReleaseButton = (voucher3.Status == 'HOLD' && actionType=='Release');
        lstSendCashVoucherWrap.add(voucher3);
        
        System.debug(JSON.serialize(lstSendCashVoucherWrap));
        
        return JSON.serialize(lstSendCashVoucherWrap);
    }

    /*
      @description       : Method to fetch vouchers from the external object based on the accountId parameter. If the call fails, returns dummy voucher data.
      @author            : Kevin Nundran
      @created on        : 10-09-2024
      @last modified on  : 10-09-2024
      @param accountId   : ID of the related account for which to fetch vouchers
      @return            : Serialized JSON string containing a list of voucher data
    */
    @AuraEnabled(cacheable=true)
    public static String getVoucherList(String recordId, String actionType) {
        String result = '';
        
        try{
            // Querying external object Send_Cash_Voucher__x
            List<Send_Cash_Voucher__x> lstSendCashVoucher = [SELECT Id, ExternalId, Voucher_Number__c, Sent_From__c, 
                                                             Send_Amount__c, Status__c, Date_Created__c, 
                                                             Date_Modified__c
                                                             FROM Send_Cash_Voucher__x 
                                                             WHERE Related_Account__r.Id = :recordId];
            
            // List of wrapper objects to return
            List<SendCashVoucherWrapper> lstSendCashVoucherWrap = new List<SendCashVoucherWrapper>();
            
            // Loop over external object records and map them to the wrapper class
            for (Send_Cash_Voucher__x scv : lstSendCashVoucher) {
                System.debug(scv.Status__c);
                SendCashVoucherWrapper scvw = new SendCashVoucherWrapper();
                scvw.Id = scv.Id;
                scvw.ExternalId = scv.ExternalId;
                scvw.VoucherNumber = scv.Voucher_Number__c;
                scvw.SentFrom = scv.Sent_From__c;
                scvw.SendAmount = scv.Send_Amount__c;
                scvw.Status = scv.Status__c;
                scvw.DateCreated = scv.Date_Created__c;
                scvw.DateModified = scv.Date_Modified__c;
                scvw.isRedeemable = (scv.Status__c == 'REDEEMABLE');
                scvw.isRedeemed = (scv.Status__c == 'REDEEMED');
                scvw.isHold = (scv.Status__c == 'ON_HOLD');
                scvw.isOther = (!scvw.isRedeemable && !scvw.isRedeemed && !scvw.isHold);
        		scvw.showHoldButton = (scv.Status__c == 'REDEEMABLE' && actionType == 'Hold');
                scvw.showReleaseButton = (scv.Status__c == 'ON_HOLD' && actionType == 'Release');
                
                // Add each wrapper to the list
                lstSendCashVoucherWrap.add(scvw);
            }
            
            result = JSON.serialize(lstSendCashVoucherWrap);
        }catch(Exception ex){
            //return getVoucherListDummy(accountId, actionType);
            throw ex;
        }
        
        return result;
    }

    /*
      @description       : Method to hold (block) a specific voucher based on the order reference and accountId parameters by calling an invocable method
      @author            : Kevin Nundran
      @created on        : 10-09-2024
      @last modified on  : 10-09-2024
      @param accountId   : ID of the account related to the voucher to be held
      @param orderReference : Unique reference for the order associated with the voucher
    */
    @AuraEnabled
    public static void callHoldVoucher(String accountId, String orderReference) {
        System.debug(accountId);
        System.debug(orderReference);
        List<Account> lstAccount = [SELECT Id, CIF_Number__c FROM Account WHERE Id=:accountId];
        System.debug(lstAccount);
        
        // Prepare input for Invocable Method
        capitec_HoldCashVoucher.HoldCashVoucherInput input = new capitec_HoldCashVoucher.HoldCashVoucherInput();
        input.senderId = lstAccount[0].CIF_Number__c;
        input.orderReference = orderReference;
        input.onHold = 'true';

        List<capitec_HoldCashVoucher.HoldCashVoucherInput> inputs = new List<capitec_HoldCashVoucher.HoldCashVoucherInput>();
        inputs.add(input);

        // Call the invocable method
        capitec_HoldCashVoucher.HoldCashVoucher(inputs);
    }

    /*
      @description       : Method to Release a specific voucher based on the order reference and accountId parameters by calling an invocable method
      @author            : Kevin Nundran
      @created on        : 27-09-2024
      @last modified on  : 30-09-2024
      @param accountId   : ID of the account related to the voucher to be held
      @param orderReference : Unique reference for the order associated with the voucher
    */
    @AuraEnabled
    public static void callReleaseVoucher(String accountId, String orderReference) {
        System.debug(accountId);
        System.debug(orderReference);
        List<Account> lstAccount = [SELECT Id, CIF_Number__c FROM Account WHERE Id=:accountId];
        System.debug(lstAccount);
        
        // Prepare input for Invocable Method
        capitec_ReleaseCashVoucher.ReleaseCashVoucherInput input = new capitec_ReleaseCashVoucher.ReleaseCashVoucherInput();
        input.senderId = lstAccount[0].CIF_Number__c;
        input.orderReference = orderReference;
        input.onHold = 'false';

        List<capitec_ReleaseCashVoucher.ReleaseCashVoucherInput> inputs = new List<capitec_ReleaseCashVoucher.ReleaseCashVoucherInput>();
        inputs.add(input);

        // Call the invocable method
        capitec_ReleaseCashVoucher.ReleaseCashVoucher(inputs);
    }
}