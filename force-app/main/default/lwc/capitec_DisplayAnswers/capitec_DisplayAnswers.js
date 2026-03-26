/**
 * Created by dawid on 20.03.2023.
 */

import {LightningElement, api} from 'lwc';
import getAnswers from '@salesforce/apex/Capitec_DisplayAnswersController.getAnswers';

export default class CapitecDisplayAnswers extends LightningElement {

    @api userId;
    @api caseId;
    @api questionType;


    renderedCallback() {

        getAnswers({
            
            caseId: this.caseId,
            questionType: this.questionType

        }).then(response => {

            let mainContainer = this.template.querySelector('[data-id="main-container"]');
            response.forEach(answerRec => {
                if(answerRec.Answer__c !== '-'){
                    let newQuestionSection = this.createQuestionSection(answerRec);
                    mainContainer.appendChild(newQuestionSection);
                }
            })

        }).catch(error =>{
            console.log(error);
        })
    }


    createQuestionSection(answerRec){
        let newQuestionSection = document.createElement('div');
        newQuestionSection.classList.add('question-section');
        newQuestionSection.setAttribute('c-capitec_DisplayAnswers_capitec_DisplayAnswers', "");

        let newQuestionCol = document.createElement('div');
        newQuestionCol.setAttribute('c-capitec_DisplayAnswers_capitec_DisplayAnswers', "");
        newQuestionCol.classList.add('question-col');


        let newQuestionText = document.createElement('p');
        newQuestionText.classList.add('question-text');
        newQuestionText.innerHTML = (answerRec.Question__c + ': ');
        newQuestionText.setAttribute('c-capitec_DisplayAnswers_capitec_DisplayAnswers', "");
        newQuestionCol.appendChild(newQuestionText);

        let newAnswerCol = document.createElement('div');
        newAnswerCol.classList.add('answer-col');
        newAnswerCol.setAttribute('c-capitec_DisplayAnswers_capitec_DisplayAnswers', "");

        let newAnswerText = document.createElement('p');
        newAnswerText.classList.add('answer-text');
        newAnswerText.innerHTML = answerRec.Answer__c.replaceAll(';',', ');
        newAnswerText.setAttribute('c-capitec_DisplayAnswers_capitec_DisplayAnswers', "");


        newAnswerCol.appendChild(newAnswerText);

        newQuestionSection.appendChild(newQuestionCol);
        newQuestionSection.appendChild(newAnswerCol);
        // newQuestionSection.appendChild(newAnswerText);

        return newQuestionSection;
    }
}