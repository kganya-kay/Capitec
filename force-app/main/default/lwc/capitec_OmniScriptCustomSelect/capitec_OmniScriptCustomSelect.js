import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
    import { LightningElement,wire, api, track  } from 'lwc';
    import {getObjectInfo} from 'lightning/uiObjectInfoApi';
    import CASE_OBJECT from '@salesforce/schema/Case';
    import {getPicklistValues} from 'lightning/uiObjectInfoApi';
    import CHANNEL_FIELD from '@salesforce/schema/Case.Channel__c';
    import SPECIFIC_FIELD from '@salesforce/schema/Case.Capitec_Specific_Need__c';
    import PRIMARY_FIELD from '@salesforce/schema/Case.Capitec_Primary_Need__c';

    export default class Capitec_OmniScriptCustomSelect extends OmniscriptBaseMixin(LightningElement) {

        @wire(getObjectInfo, {objectApiName: CASE_OBJECT })
        caseInfo;
        recId;
        recType;
        async connectedCallback(){
            this.recId = this.omniJsonData.ContextId;
            this.recType = this.omniJsonData.RT_Case;
            console.log(this.recId);
            console.log(this.recType);

        }
        @track specificOptions;
        @track primaryOptions;
        @track channelOptions;
        @wire(getPicklistValues, {recordTypeId: '$recType', fieldApiName: CHANNEL_FIELD })
        channelFieldInfo({ data, error }) {
            if (data) this.channelOptions = data.values;
        }
        @wire(getPicklistValues, {recordTypeId: '$recType', fieldApiName: SPECIFIC_FIELD })
        specificFieldInfo({ data, error }) {
            if (data) this.specificFieldData = data;
        }

        @wire(getPicklistValues, {recordTypeId:'$recType', fieldApiName: PRIMARY_FIELD })
        primaryFieldInfo({ data, error }) {
            if (data) this.primaryOptions = data.values;
        }

        handlePrimaryChange(event) {
            console.log('handlePrimaryChange ',event.target.value);
            let key = this.specificFieldData.controllerValues[event.target.value];
            this.specificOptions = this.specificFieldData.values.filter(opt => opt.validFor.includes(key));
            var data = {
                primaryData:event.target.value
            }
            this.omniApplyCallResp(data);
        }
        handleChannelChange(event) {
            var data = {
                channelData:event.target.value
            }
            this.omniApplyCallResp(data);
        }
        handleSpecificChange(event) {
            var data = {
                specificData:event.target.value
            }
            this.omniApplyCallResp(data);
        }   
}