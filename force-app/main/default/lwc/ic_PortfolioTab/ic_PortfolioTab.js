import { LightningElement,api, track } from 'lwc';

export default class Ic_PortfolioTab extends LightningElement {
    @api recordId;

    @track showAll = false;

    handleShowAll() {
        this.showAll = true;
    }
}