/**
 * @description       : Extends the OOTB StepChartItem functionality of Omniscripts
 *                      CEDT-3346 - disable StepChart buttons
 * @author            : Cornelia Smit
 * @group             :
 * @last modified on  : 19-11-2024
 * @last modified by  : Cornelia Smit
 * Modifications Log
 * Ver   Date         Author                    Modification
 * 1.0   19-11-2024   Cornelia Smit             Initial Version
 **/

import {  LightningElement, api } from 'lwc';
import omniscriptStepChartItems from 'omnistudio/omniscriptStepChartItems';
import {OmniscriptBaseMixin} from 'omnistudio/omniscriptBaseMixin';
import tmpl from './capitecStepChartItemOverride.html';

export default class CapitecStepChartItemOverride extends OmniscriptBaseMixin(omniscriptStepChartItems, LightningElement) {

    render() {
        return tmpl;
    }
}