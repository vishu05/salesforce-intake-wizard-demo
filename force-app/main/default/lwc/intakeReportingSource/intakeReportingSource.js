import { LightningElement, api } from 'lwc';

export default class IntakeReportingSource extends LightningElement {
    @api participants = [];
    @api addresses = [];

    get reporter() {
        return this.participants.find((p) => p.Role__c === 'Reporting Person') || {};
    }
    get firstName() { return this.reporter.First_Name__c || ''; }
    get lastName() { return this.reporter.Last_Name__c || ''; }
    get phone() { return this.reporter.Phone__c || ''; }
    get email() { return this.reporter.Email__c || ''; }

    handleChange(event) {
        const field = event.target.dataset.field;
        const next = this.participants.filter((p) => p.Role__c !== 'Reporting Person');
        next.push({ ...this.reporter, Role__c: 'Reporting Person', [field]: event.target.value });
        this.dispatchEvent(new CustomEvent('participantchange', {
            detail: { participants: next }
        }));
    }
}
