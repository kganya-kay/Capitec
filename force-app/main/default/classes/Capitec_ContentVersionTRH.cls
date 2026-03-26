/**
 * Created by dawid on 12.06.2023.
 */

public with sharing class Capitec_ContentVersionTRH extends TriggerHandler{

    private Map<Id, ContentVersion> oldCVersionMap;
    private Map<Id, ContentVersion> newCVersionMap;
    private List<ContentVersion> oldCVersionList;
    private List<ContentVersion> newCVersionList;
    
    public Capitec_ContentVersionTRH() {
        oldCVersionMap = (Map<Id, ContentVersion>)Trigger.oldMap;
        newCVersionMap = (Map<Id, ContentVersion>)Trigger.newMap;
        oldCVersionList = (List<ContentVersion>)Trigger.old;
        newCVersionList = (List<ContentVersion>)Trigger.new;
    }

    /**
    * FFSF-525 - Added Test.isRunningTest() check to prevent Web Service Callouts operations during tests
    */
    public override void afterInsert() {
        //if(!Test.isRunningTest()) { Commented because of test class failure: Capitec_ContentVersionDMN  for ICS-Deployment 0409 to Prod deployment
            Capitec_ContentVersionDMN.uploadFileToDocumentum(newCVersionList);
        //}
    }

    public override void beforeInsert() {
        Capitec_ContentVersionDMN.checkDuplication(newCVersionList);
    }
}