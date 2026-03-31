/**
 * @description       : Invocable Class to get schedule checks after a certain number of days
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 11-05-2025
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class Conversions_ScheduleAutoClose {

    public class inputReq {
        @InvocableVariable(required=true)
        public Id caseId;

        @InvocableVariable(required=true)
        public Integer days;
    }

    @InvocableMethod(label='Schedule Checks Based On Business Hours' IconName='slds:utility:automate')
    public static void ScheduleAutoClose(List<inputReq> lstInputs) {
        Case caseRecord = new Case();
        inputReq request = lstInputs[0];

        if(request != null){
            Id businessHoursId = getConversionBH();
            Datetime deadlineSet = getDaysInBusinessHours(request.days, businessHoursId);
            System.debug('## Business hour fetched: ' +businessHoursId);

            caseRecord.Id = request.caseId;
            caseRecord.SLA_Time__c = (deadlineSet != null) ? deadlineSet : null;

            System.debug('## caseRecord to update: ' +caseRecord);

            if(deadlineSet != null){
                update caseRecord;
            }

        }

    }


    public static Datetime getDaysInBusinessHours(Integer numDays, Id businessHoursId){
         Datetime deadline;

        if(numDays != null && numDays > 0){
            Datetime satNow = System.now().addHours(2);
            System.debug('## Current time in SAT: ' + satNow);

            Long daysInMilliSec = numDays* 32400000;

            deadline = BusinessHours.add(businessHoursId, satNow, daysInMilliSec);
            System.debug('## getDaysInBusinessHours deadline: ' + deadline);
        }

        return deadline;
    }

    public static Id getConversionBH(){
        return [SELECT Id FROM BusinessHours WHERE Name = 'Conversions Business Hours' LIMIT 1].Id;

    }
}