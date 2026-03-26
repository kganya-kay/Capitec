/**
 * Created by dawid on 29.08.2024.
 */

import {api, LightningElement} from 'lwc';

export default class IcRecordBanner extends LightningElement {
    @api iconName;
    @api recordTitle;
}