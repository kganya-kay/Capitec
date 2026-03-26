public with sharing class capitec_AWS_CTI {
	
    public String getCurrentUserId(){
        String userId = System.UserInfo.getUserId();
        return userId;
    }
}