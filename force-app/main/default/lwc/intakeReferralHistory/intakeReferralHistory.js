import { LightningElement, api, wire } from 'lwc';
import getReferralHistory from '@salesforce/apex/IntakeDuplicateService.getReferralHistory';

export default class IntakeReferralHistory extends LightningElement {
    @api participantId;
    history = [];
    columns = [
        { label: 'Referral #', fieldName: 'referralNumber' },
        { label: 'Status', fieldName: 'status' },
        { label: 'Request Type', fieldName: 'requestType' },
        { label: 'Request Date', fieldName: 'requestDate', type: 'date' }
    ];

    get hasHistory() { return this.history.length > 0; }

    @wire(getReferralHistory, { participantId: '$participantId' })
    wiredHistory({ data }) {
        if (data) this.history = data;
    }
}
