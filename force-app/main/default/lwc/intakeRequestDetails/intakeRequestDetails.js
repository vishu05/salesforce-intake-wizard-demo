import { LightningElement, api } from 'lwc';

export default class IntakeRequestDetails extends LightningElement {
    @api intake = {};

    requestTypeOptions = [
        { label: 'Housing Support', value: 'Housing Support' },
        { label: 'Food Assistance', value: 'Food Assistance' },
        { label: 'Counseling', value: 'Counseling' },
        { label: 'Mentoring', value: 'Mentoring' },
        { label: 'Other', value: 'Other' }
    ];
    priorityOptions = [
        { label: 'Low', value: 'Low' },
        { label: 'Medium', value: 'Medium' },
        { label: 'High', value: 'High' }
    ];

    get requestType() { return this.intake.Request_Type__c || ''; }
    get priority() { return this.intake.Priority__c || 'Medium'; }
    get requestDate() { return this.intake.Request_Date__c || null; }
    get narrative() { return this.intake.Narrative__c || ''; }

    handleChange(event) {
        this.dispatchEvent(new CustomEvent('intakechange', {
            detail: { intake: { [event.target.dataset.field]: event.target.value } }
        }));
    }
}
