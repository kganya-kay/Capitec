/**
 * Created by dawid on 13.11.2023.
 */

import { api } from 'lwc';
import LightningModal from 'lightning/modal';


export default class CapitecFraudModal extends LightningModal  {
    @api content
    @api header

    handleOkay(){
        this.close('okay');
    }
    handleCancel(){
        this.close(null);
    }
}