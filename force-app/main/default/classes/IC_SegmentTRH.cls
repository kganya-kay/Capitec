/**
 * Created by dawid on 09.07.2024.
 * Updated by Samiirah Aujub on 23.09.2024 [ICS_892]
 * Updated by Ridwan Moosuddee on 27.10.2024 [ICS-1750]
 */

public with sharing class IC_SegmentTRH extends TriggerHandler {

    private Map<Id, IC_Segment__c> oldSegmentMap;
    private Map<Id, IC_Segment__c> newSegmentMap;
    private List<IC_Segment__c> oldSegmentList;
    private List<IC_Segment__c> newSegmentList;
    
    public IC_SegmentTRH() {
        oldSegmentMap = (Map<Id, IC_Segment__c>)Trigger.oldMap;
        newSegmentMap = (Map<Id, IC_Segment__c>)Trigger.newMap;
        oldSegmentList = (List<IC_Segment__c>)Trigger.old;
        newSegmentList = (List<IC_Segment__c>)Trigger.new;
    }

    public override void beforeUpdate() {
		IC_SegmentDMN.pushRecommendToPaySegment(newSegmentList, Trigger.isInsert); //ICS-1750        
    }

    public override void beforeInsert() {
        IC_SegmentDMN.pushRecommendToPaySegment(newSegmentList, Trigger.isInsert); //ICS-1750
    }

    public override void afterUpdate() {
        IC_SegmentDMN.recommendedOutcome(newSegmentList);
        IC_SegmentDMN.calculateAssuredAmount(oldSegmentMap, newSegmentList);
        IC_SegmentDMN.recalculateSegments(newSegmentList, Trigger.isInsert); //Moved to afterUpdate for ticket ICS-1750
    }
    
    public override void afterInsert() {
        IC_SegmentDMN.recommendedOutcome(newSegmentList);
        IC_SegmentDMN.calculateAssuredAmount(oldSegmentMap, newSegmentList);
        IC_SegmentDMN.recalculateSegments(newSegmentList, Trigger.isInsert); //ICS-1750
    }
}