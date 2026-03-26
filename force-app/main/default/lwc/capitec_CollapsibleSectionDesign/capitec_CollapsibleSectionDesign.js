import { LightningElement } from 'lwc';

export default class CollapsibleSections extends LightningElement {
    connectedCallback() {
        
    }

    renderedCallback(){
        this.applyCollapsibleSectionStyle();
    }

    applyCollapsibleSectionStyle() {
        const recordPageContainer = this.template.host.parentNode;
        let accordionSummary = recordPageContainer.parentNode;
        let accordionSummaryChildren = accordionSummary.childNodes[0].childNodes[0].childNodes;
        let accordionSummaryFirstChild = accordionSummaryChildren[0];
        const style = document.createElement('style');
        style.innerText = `.slds-accordion__summary { background-color: #F3F3F3; } .slds-section__title { display: none; }`;

        // Check if the style has already been added to avoid duplicates
        if (!this.template.querySelector('style')) {
            accordionSummary.appendChild(style);
        }
    }
}