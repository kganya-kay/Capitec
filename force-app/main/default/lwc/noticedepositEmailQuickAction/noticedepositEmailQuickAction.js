import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { getRecord } from 'lightning/uiRecordApi';
import getEmailTemplateInfo from '@salesforce/apex/EmailTemplateController.getTemplateInfo';

const FIELDS = ['Case.Assignment_Reason__c'];

//CECSF-201 - commented out console logs
export default class NoticedepositEmailQuickAction extends NavigationMixin(LightningElement) {
    @api recordId;
    @api assignmentReason;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCase({ error, data }) {
        if (data) {
            this.assignmentReason = (data.fields.Assignment_Reason__c.value != null) ? data.fields.Assignment_Reason__c.value : this.assignmentReason;
            //console.log('Assignment reason:', this.assignmentReason);
        } else if (error) {
            console.error('Error fetching Case record:', error);
        }
    }

    @api invoke() {
        //console.error('Invoke START');
        if (this.assignmentReason) {
            this.handleAssignmentReason();
        } else {
            console.error('Assignment Reason not fetched yet.');
        }
    }

    async handleAssignmentReason() {
        //console.log('handleAssignmentReason start:', this.assignmentReason);
        let templateApiName;
        let templateSubject;
        let templateBody;

        switch (this.assignmentReason) {
            case 'Technical issue with submitting notice':
                templateApiName = 'Client_Technical_issue_with_submitting_notice_CUSTOMINTERNAL';
                break;
            case 'Technical issue with submitted notice':
                templateApiName = 'Technical_issue_with_submitted_notice_CUSTOMINTERNAL';
                break;
            case 'Unable to submit withdrawal':
                templateApiName = 'Unable_to_submit_withdrawal_CUSTOMINTERNAL';
                break;
            default:
                console.log('Assignment reason does not match any criteria.');
                return;
        }

        try {
            const templateInfo = await getEmailTemplateInfo({ templateApiName });
            const templateSubject = templateInfo.Subject;
            const templateBody = templateInfo.HtmlValue;
            //const templateBody = 'Please see the attached document for details.';
            //console.log('templateSubject:'+templateSubject);
            //console.log('templateBody:'+templateBody);
            //console.log('templateBody:'+templateInfo.Body);
            const pageRef = {
                type: 'standard__quickAction',
                attributes: {
                    apiName: 'Case.SendEmail',
                },
                state: {
                    recordId: this.recordId,
                    defaultFieldValues: encodeDefaultFieldValues({
                        HtmlBody: templateBody,
                        Subject: templateSubject,
                        ToAddress: 'dlsave@capitecbank.co.za',
                    }),
                },
            };

            this[NavigationMixin.Navigate](pageRef);
        } catch (error) {
            console.error('Failed to fetch email template info:', error);
        }
    }
}