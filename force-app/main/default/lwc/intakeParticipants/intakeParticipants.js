import { LightningElement, api } from 'lwc';

const FIXED_ROLES = ['Reporting Person', 'Primary Individual'];

export default class IntakeParticipants extends LightningElement {
    @api participants = [];

    get others() {
        return this.participants
            .map((p, index) => ({ ...p, index, key: p.Id || `new-${index}` }))
            .filter((p) => !FIXED_ROLES.includes(p.Role__c));
    }

    emit(next) {
        this.dispatchEvent(new CustomEvent('participantchange', {
            detail: { participants: next }
        }));
    }

    handleAdd() {
        this.emit([...this.participants, { Role__c: 'Household Member' }]);
    }

    handleRemove(event) {
        const idx = Number(event.target.dataset.index);
        this.emit(this.participants.filter((_, i) => i !== idx));
    }

    handleChange(event) {
        const idx = Number(event.target.dataset.index);
        const next = this.participants.map((p, i) =>
            i === idx ? { ...p, [event.target.dataset.field]: event.target.value } : p);
        this.emit(next);
    }
}
