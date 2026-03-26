import { LightningElement, api, wire } from "lwc";

export default class Capitec_ClickableComponent extends LightningElement {
    @api label;
    @api fieldType;
    @api value;
    @api formattedValue;
    isPhone = false;
    isEmail = false;

    connectedCallback() {
        if(this.fieldType == "Phone"){
            this.isPhone = true;
            this.formattedValue = 'tel:' + this.value;
        }else{
            this.isEmail = true;
            this.formattedValue = 'mailto:' + this.value;
        }
    }
}