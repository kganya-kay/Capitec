import { LightningElement, api, track } from 'lwc';

export default class CapitecFilesPreviewer extends LightningElement {
    @track _ids = [];
    @track currentIndex = 0;

    @api
    get contentDocumentIds() {
        return this._ids.join(',');
    }

    set contentDocumentIds(value) {
        if (typeof value === 'string') {
            this._ids = value
                .replace(/[\[\]"']/g, '')
                .split(',')
                .map(id => id.trim())
                .filter(id => id.length >= 15);
        } else {
            this._ids = [];
        }

        this.currentIndex = 0;
    }

    get currentFileId() {
        return this._ids.length > 0 ? this._ids[this.currentIndex] : null;
    }

    get hasFiles() {
        return this._ids.length > 0;
    }

    get fileCountLabel() {
        return `File ${this.currentIndex + 1} of ${this._ids.length}`;
    }

    get isFirst() {
        return this.currentIndex === 0;
    }

    get isLast() {
        return this.currentIndex === this._ids.length - 1;
    }

    // ✅ ONLY preview method that works in Flow
    handlePreview() {
        if (!this.currentFileId) return;

        const previewUrl =
            `/sfc/servlet.shepherd/document/download/${this.currentFileId}` +
            `?operationContext=CHATTER`;

        window.open(previewUrl, '_blank');
    }

    handleNext() {
        if (!this.isLast) {
            this.currentIndex++;
        }
    }

    handlePrevious() {
        if (!this.isFirst) {
            this.currentIndex--;
        }
    }
}