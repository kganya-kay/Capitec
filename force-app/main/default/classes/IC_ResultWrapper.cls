/**
 * Created by dawid on 24.09.2024.
 */

public with sharing class IC_ResultWrapper {
    public Boolean success;
    public String message;
    public Integer statusCode;
    public String relatedId;
    public String relatedParentId;

    public IC_ResultWrapper(Boolean success, String message, Integer statusCode, String relatedId) {
        this.success = success;
        this.message = message;
        this.statusCode = statusCode;
        this.relatedId = relatedId;
        this.relatedParentId = null;
    }

    public IC_ResultWrapper(Boolean success, String message, Integer statusCode, String relatedId, String relatedParentId) {
        this.success = success;
        this.message = message;
        this.statusCode = statusCode;
        this.relatedId = relatedId;
        this.relatedParentId = relatedParentId;
    }

    public IC_ResultWrapper() {
    }
}