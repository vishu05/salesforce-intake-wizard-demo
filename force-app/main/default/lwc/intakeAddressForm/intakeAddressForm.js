import { LightningElement, api, track } from 'lwc';
import validateAddress from '@salesforce/apex/IntakeWizardController.validateAddress';

/** Reusable address block with mock validation (demo — no API key needed). */
export default class IntakeAddressForm extends LightningElement {
    @api address = {};
    @track line1 = '';
    @track city = '';
    @track stateCode = '';
    @track zip = '';
    message;

    handleChange(event) {
        this[event.target.dataset.field] = event.target.value;
    }

    async handleValidate() {
        try {
            const r = await validateAddress({
                line1: this.line1, city: this.city,
                stateCode: this.stateCode, zip: this.zip
            });
            this.message = r.message;
        } catch (e) {
            this.message = 'Validation is unavailable right now.';
        }
    }
}
