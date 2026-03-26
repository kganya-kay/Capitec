/**
 * Created by UrvashiRagobur on 2023/09/25.
 */
public class capitec_CaseCashDisputes {
    
    @InvocableMethod(label='Time to resolve' category='Case')
    public static List<Result> getTimeToResolve(List<Id> cashDisputes) {
        Case caseRecord = [SELECT Id, CreatedDate, Quality_Assurance_Timestamp__c, Cash_Investigations_Timestamp__c FROM Case WHERE Id = :cashDisputes.get(0)];
        // Calculate the time difference in milliseconds
        Long timeDifferenceMillis = System.now().getTime() - caseRecord.CreatedDate.getTime();
        Decimal numberOfMinutes = timeDifferenceMillis/(1000 * 60);
        
        Decimal duration60minSLA = 0;
        if(caseRecord.Quality_Assurance_Timestamp__c != null) {
            duration60minSLA = (System.now().getTime() - caseRecord.Quality_Assurance_Timestamp__c.getTime())/(1000 * 60);
        }
        
        Decimal caseInvestigationsTime = 0;
        if(caseRecord.Cash_Investigations_Timestamp__c != null) {
            caseInvestigationsTime = (System.now().getTime() - caseRecord.Cash_Investigations_Timestamp__c.getTime())/(1000 * 60 * 60);
        }
        
        // Calculate days, hours, minutes, and seconds
        Long days = timeDifferenceMillis / (1000 * 60 * 60 * 24);
        timeDifferenceMillis = timeDifferenceMillis - (days * 1000 * 60 * 60 * 24);
        Long hours = (timeDifferenceMillis / (1000 * 60 * 60));
        timeDifferenceMillis = timeDifferenceMillis - (hours * 1000 * 60 * 60);
        Long minutes = (timeDifferenceMillis / (1000 * 60));
        timeDifferenceMillis = timeDifferenceMillis - (minutes * 1000 * 60);
        Long seconds = (timeDifferenceMillis / (1000 * 60));
        
        String duration = '';
        if(days != 0) {
            duration = duration + String.valueOf(days) + 'd:';
        }
        if(hours != 0) {
            duration = duration + String.valueOf(hours) + 'h:';
        }
        if(minutes != 0) {
            duration = duration + String.valueOf(minutes) + 'm:';
        }
        if(seconds != 0) {
            duration = duration + String.valueOf(seconds) + 's:';
        }
        if(duration.length() != 0) {
            duration = duration.substring(0, duration.length() - 1);
        }
        
        result res = new result();
        res.durationText = duration;
        res.durationMinutes = numberOfMinutes;
        res.duration60minSLA = duration60minSLA;
        res.durationCIHour = caseInvestigationsTime;
        
        List<result> resultList = new List<result>();
        resultList.add(res);
        
        return resultList;
    }
    
    public class result{
        @InvocableVariable
        public String durationText;
        
        @InvocableVariable
        public Decimal durationMinutes;
        
        @InvocableVariable
        public Decimal duration60minSLA;
        
        @InvocableVariable
        public Decimal durationCIHour;
    }

}