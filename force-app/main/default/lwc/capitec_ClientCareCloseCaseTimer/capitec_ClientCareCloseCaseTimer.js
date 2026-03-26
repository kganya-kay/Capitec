import { LightningElement, api, track } from 'lwc';
import closeCase from '@salesforce/apex/capitec_ClientCareController.closeCaseManually';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseCloseTimer extends LightningElement {
    @api recordId;
    @api ccRecordId;
    @api recordCaseNumber;
    @api ccRecordCaseNumber;
    @api timeLeft; // Set in seconds (countdown)
    @track totalTime;
    @track timeLeftFormatted = '00:00'; // Formatted countdown value
    @track showMessage = true; // Flag to show the initial message
    @track showClosedMessage = false; // Flag to show "Closed" message
    @track isLoading = false; // Flag to show/hide loading spinner

    countdownInterval;

    // Getter for the URL to open the case record
    get caseUrl() {
        return `/lightning/r/Case/${this.ccRecordId}/view`; // Salesforce Lightning URL for the Case record
    }

    connectedCallback() {
        this.startCountdown();
    }

    startCountdown() {
        this.totalTime = this.timeLeft;
        this.countdownInterval = setInterval(() => {
            if (this.timeLeft > 0) {
                this.timeLeft -= 1;
                this.updateTimeLeftFormatted();
                this.updateProgress();
            } else {
                clearInterval(this.countdownInterval);
                this.timeLeft = 0; // Ensure time doesn't go negative
                this.showMessage = false;
                this.showClosedMessage = true;
                this.handleCloseCase(); // Close the case once time is up
            }
        }, 1000); // Update every second
    }
    
    updateTimeLeftFormatted() {
        const minutes = Math.floor(this.timeLeft / 60);
        const seconds = this.timeLeft % 60;
        this.timeLeftFormatted = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
    }

    updateProgress() {
        const progressRing = this.template.querySelector('.progress-ring-circle');
        const radius = progressRing.r.baseVal.value;
        const circumference = 2 * Math.PI * radius;
        const offset = (this.timeLeft / this.totalTime) * circumference;

        // Set the stroke-dashoffset to reflect the countdown
        progressRing.style.strokeDashoffset = circumference - offset;
    }

    handleCloseCase() {
        this.isLoading = true; // Show the loading spinner
        closeCase({ caseId: this.ccRecordId })
            .then(() => {
                //console.log('Case closed successfully');
                this.showClosedMessage = true;
                this.showMessage = false;
            })
            .then(() => {
                this.showToast('Saved', 'Case closed successfully.', 'success');
                //console.log('Scheduled job stopped successfully');
            })
            .catch(error => {
                console.error('Error closing case or stopping job: ', error);
                this.showToast('Error', 'Failed to close case or stop job.', 'error');
            })
            .finally(() => {
                this.isLoading = false; // Hide the loading spinner after the action is done
            });
    }

    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(toastEvent);
    }

    disconnectedCallback() {
        // Clear interval when component is destroyed to prevent memory leaks
        if (this.countdownInterval) {
            clearInterval(this.countdownInterval);
        }
    }
}