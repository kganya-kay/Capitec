/**
 * Created by dawid on 28.03.2023.
 */

import {api, LightningElement} from 'lwc';


export default class CapitecDisplayOutcome extends LightningElement {
    @api contentList;

    renderedCallback() {
        let mainContainer = this.template.querySelector('[data-id="main-container"]');
        this.contentList.forEach(newRow =>{
            if(newRow.includes(':')){
                let headerAndParagraph = newRow.split(':');
                mainContainer.appendChild(this.createRow(headerAndParagraph[0], headerAndParagraph[1]));
            }
            else{
                mainContainer.appendChild(this.createRow(newRow));
            }
        })
    }

    createRow(headline, paragraph){

        let newRowSection = document.createElement('div');
        newRowSection.classList.add('headline-section');
        newRowSection.setAttribute('c-capitec_displayoutcome_capitec_displayoutcome', "");



        // Header Creation

        let newHeaderCol = document.createElement('div');
        newHeaderCol.setAttribute('c-capitec_displayoutcome_capitec_displayoutcome', "");
        newHeaderCol.classList.add('headline-col');

        let newHeaderText = document.createElement('p');
        newHeaderText.classList.add('headline-text');
        newHeaderText.innerHTML = headline;
        newHeaderText.setAttribute('c-capitec_displayoutcome_capitec_displayoutcome', "");
        newHeaderCol.appendChild(newHeaderText);

        newRowSection.appendChild(newHeaderCol);



        // Paragraph Creation

        if(typeof paragraph !== 'undefined'){
            let newParagraphCol = document.createElement('div');
            newParagraphCol.classList.add('paragraph-col');
            newParagraphCol.setAttribute('c-capitec_displayoutcome_capitec_displayoutcome', "");

            let newParagraphText = document.createElement('p');
            newParagraphText.classList.add('paragraph-text');
            newParagraphText.innerHTML = paragraph.replaceAll(';',', ');
            newParagraphText.setAttribute('c-capitec_displayoutcome_capitec_displayoutcome', "");
            newParagraphCol.appendChild(newParagraphText);

            newRowSection.appendChild(newParagraphCol);
        }

        return newRowSection;
    }



}