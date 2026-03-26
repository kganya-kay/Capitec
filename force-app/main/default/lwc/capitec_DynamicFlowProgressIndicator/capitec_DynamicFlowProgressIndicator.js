import { LightningElement, api } from 'lwc';

export default class Capitec_DynamicFlowProgressIndicator extends LightningElement {
    @api stages = [];
    @api currentStage;
    @api varient;
    @api type;

    connectedCallback() {
        this.stages = this.stages.map((stage) => ({ label: stage, value: stage }));
    }
}