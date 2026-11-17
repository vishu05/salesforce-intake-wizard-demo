import { LightningElement, api } from 'lwc';

export default class IntakeReviewSubmit extends LightningElement {
    @api intake = {};
    @api participants = [];

    get participantRows() {
        return this.participants.map((p, i) => ({
            key: p.Id || `row-${i}`,
            label: `${p.Role__c || 'Participant'}: ${(p.First_Name__c || '')} ${(p.Last_Name__c || '')}`.trim()
        }));
    }
}
