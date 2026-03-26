import { LightningElement, api } from 'lwc';

export default class CapitecTabSetLWC extends LightningElement {
    @api tab1Label = 'Tab 1';
    @api tab2Label = 'Tab 2';
    @api tab3Label = 'Tab 3';
}