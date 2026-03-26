import { LightningElement, api } from 'lwc';

// Static Resources
import CC_INFO_ICON from '@salesforce/resourceUrl/CC_Info_Bubble_Grey';
import CC_MESSAGE_ICON from '@salesforce/resourceUrl/CC_Thought_Bubble_Red';
import CC_WARNING_ICON from '@salesforce/resourceUrl/CC_Warning_Icon';

const VARIANTS = {
    Info: {
        className: 'variant-info',
        icon: CC_INFO_ICON,
        alt: 'Info'
    },
    Message: {
        className: 'variant-message',
        icon: CC_MESSAGE_ICON,
        alt: 'Message'
    },
    Warning: {
        className: 'variant-warning',
        icon: CC_WARNING_ICON,
        alt: 'Warning'

    }
    // You can add Success here if needed
};

export default class CapitecClientCareFlowBanner extends LightningElement {
    /** Raw HTML to render exactly as provided */
    @api htmlContent = '';

    /** 'Info' | 'Message' (defaults to 'Info' if unknown) */
    _variant = 'Info';
    @api
    get variant() {
        return this._variant;
    }
    set variant(v) {
        this._variant = VARIANTS[v] ? v : 'Info';
        this._applyVariantClass();
    }

    _renderedOnce = false;
    _lastHtml = '';

    @api showIcon = false;

    renderedCallback() {
        if (!this._renderedOnce || this._lastHtml !== this.htmlContent) {
            const target = this.template.querySelector('.content');
            if (target) {
                // LWC does not execute <script> tags. Sanitize upstream if needed.
                target.innerHTML = this.htmlContent ?? '';
                this._lastHtml = this.htmlContent ?? '';
            }
            this._applyVariantClass();
            this._renderedOnce = true;
        }
    }

    get wrapperClass() {
        const v = VARIANTS[this._variant] || VARIANTS.Info;
        return `wrap ${v.className}`;
    }

    get iconUrl() {
        return (VARIANTS[this._variant] || VARIANTS.Info).icon;
    }

    get iconAlt() {
        return (VARIANTS[this._variant] || VARIANTS.Info).alt;
    }

    _applyVariantClass() {
        if (!this._renderedOnce) return;
        const el = this.template.querySelector('.wrap');
        if (!el) return;

        // Remove any known variant classes before adding the selected one
        Object.values(VARIANTS).forEach(v => el.classList.remove(v.className));
        el.classList.add((VARIANTS[this._variant] || VARIANTS.Info).className);
    }
}