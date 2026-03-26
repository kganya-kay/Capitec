/**
 * Created by dawid on 15.11.2024.
 */

import {api, LightningElement, track, wire} from 'lwc';
import {getFieldValue, getRecord} from "lightning/uiRecordApi";
import IC_AccountCheckPassed__c from "@salesforce/schema/IC_Policy_Participant__c.IC_AccountCheckPassed__c"
import IC_CDVPassed__c from "@salesforce/schema/IC_Policy_Participant__c.IC_CDVPassed__c"

export default class IcBeneficiaryAvsCdvWarning extends LightningElement {

    @api recordId;
    @track checkMissing = false;


    @wire(getRecord, {
        recordId: "$recordId",
        fields: [IC_AccountCheckPassed__c, IC_CDVPassed__c],
    })
    wiredData({error, data}){
        if(error){
            console.log(error.message);
        }
        else{
            if(getFieldValue(data, IC_CDVPassed__c) === true && getFieldValue(data, IC_AccountCheckPassed__c) === true){
                this.checkMissing = false;
            }
            else{
                this.checkMissing = true;
            }

            console.log(this.checkMissing);
        }

    }
}