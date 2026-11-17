import { LightningElement, api } from 'lwc';

export default class IntakePrimaryIndividual extends LightningElement {
    @api participants = [];

    get primary() {
        return this.participants.find((p) => p.Role__c === 'Primary Individual') || {};
    }
    get firstName() { return this.primary.First_Name__c || ''; }
    get lastName() { return this.primary.Last_Name__c || ''; }
    get dob() { return this.primary.DOB__c || null; }
    get unknown() { return !!this.primary.Unknown_Participant__c; }
    get approxAge() {
        if (!this.primary.DOB__c) return this.primary.Approx_Age__c || null;
        const birth = new Date(this.primary.DOB__c);
        const today = new Date();
        let age = today.getFullYear() - birth.getFullYear();
        if (today < new Date(birth.setFullYear(today.getFullYear()))) age -= 1;
        return age;
    }

    emit(updated) {
        const next = this.participants.filter((p) => p.Role__c !== 'Primary Individual');
        next.push(updated);
        this.dispatchEvent(new CustomEvent('participantchange', {
            detail: { participants: next }
        }));
    }

    handleChange(event) {
        this.emit({ ...this.primary, Role__c: 'Primary Individual',
            [event.target.dataset.field]: event.target.value });
    }

    handleUnknown(event) {
        this.emit({ ...this.primary, Role__c: 'Primary Individual',
            Unknown_Participant__c: event.target.checked });
    }

    handleDuplicateCheck() {
        this.dispatchEvent(new CustomEvent('duplicatecheck', {
            detail: { lastName: this.primary.Last_Name__c, dob: this.primary.DOB__c }
        }));
    }
}
