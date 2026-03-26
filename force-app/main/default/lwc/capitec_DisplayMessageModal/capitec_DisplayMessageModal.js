/**
 * Created by dawid on 16.04.2023.
 */

import {api, LightningElement} from 'lwc';
// import LightningModal from 'lightning/modal';


export default class CapitecDisplayMessageModal extends LightningElement {
    @api header;
    @api content;
    @api showModal;

    connectedCallback() {
        this.showModal = true;
    }

    handleClose(){
        this.showModal = false;
    }

}