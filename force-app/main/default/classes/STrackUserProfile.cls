public with sharing class STrackUserProfile {
    @AuraEnabled(cacheable = true)
     /**
     * This method is for retrieving the current user's profile name
     * @return string : Returns the profile name of the current logged-in user
     * @author : Nonny Mahao
     * @date : 12.02.2025
     */
    public static string getCurrentUserProfile(){
        return [SELECT Profile.Name FROM User WHERE Id=:UserInfo.getUserId() LIMIT 1].Profile.Name;
    }
}