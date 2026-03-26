import { LightningElement, api, wire } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { CurrentPageReference } from 'lightning/navigation';

export default class Ic_GetQuickActionAPINameForFlows extends LightningElement {

    @api quickActionAPIName = '';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {        
        //if the page is a quick action, get quick action API name
        if(currentPageReference.type === 'standard__quickAction') {
            this.quickActionAPIName = currentPageReference.attributes.apiName;
            console.log(this.quickActionAPIName); //Account.Flow_Test

        }
        //progress to next element in flow
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }
}