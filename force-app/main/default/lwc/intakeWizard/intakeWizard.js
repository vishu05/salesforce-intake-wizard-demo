import { LightningElement, api, track } from 'lwc';
import getWizardState from '@salesforce/apex/IntakeWizardController.getWizardState';
import saveWizard from '@salesforce/apex/IntakeWizardController.saveWizard';
import findPossibleDuplicates from '@salesforce/apex/IntakeDuplicateService.findPossibleDuplicates';

const STEPS = [
    { label: 'Reporting Source', value: 'step1' },
    { label: 'Primary Individual', value: 'step2' },
    { label: 'Participants', value: 'step3' },
    { label: 'Request Details', value: 'step4' },
    { label: 'Attachments & Review', value: 'step5' }
];

export default class IntakeWizard extends LightningElement {
    @api recordId;
    steps = STEPS;
    @track currentStepIndex = 0;
    @track intake = { Status__c: 'New' };
    @track participants = [];
    @track addresses = [];
    errorMessage;
    savedMessage;
    duplicateWarning;

    get currentStepValue() { return this.steps[this.currentStepIndex].value; }
    get isFirstStep() { return this.currentStepIndex === 0; }
    get isLastStep() { return this.currentStepIndex === this.steps.length - 1; }
    get isStep1() { return this.currentStepIndex === 0; }
    get isStep2() { return this.currentStepIndex === 1; }
    get isStep3() { return this.currentStepIndex === 2; }
    get isStep4() { return this.currentStepIndex === 3; }
    get isStep5() { return this.currentStepIndex === 4; }
    get primaryParticipantId() {
        const p = this.participants.find((x) => x.Role__c === 'Primary Individual');
        return p ? p.Id : null;
    }

    async connectedCallback() {
        try {
            const state = await getWizardState({ intakeId: this.recordId || null });
            this.intake = state.intake || this.intake;
            this.participants = state.participants || [];
            this.addresses = state.addresses || [];
        } catch (e) {
            this.errorMessage = this.reduceError(e);
        }
    }

    handleParticipantChange(event) { this.participants = event.detail.participants; }
    handleIntakeChange(event) { this.intake = { ...this.intake, ...event.detail.intake }; }

    async handleDuplicateCheck(event) {
        const { lastName, dob } = event.detail;
        this.duplicateWarning = null;
        if (!lastName || !dob) return;
        try {
            const matches = await findPossibleDuplicates({
                lastName, dob, excludeIntakeId: this.intake.Id || null
            });
            if (matches.length) {
                this.duplicateWarning =
                    `${matches.length} possible match(es) found — this may be a duplicate referral. ` +
                    'You can still continue; the prior referral(s) are shown on the Review step.';
            }
        } catch (e) {
            this.errorMessage = this.reduceError(e);
        }
    }

    validateCurrentStep() {
        this.errorMessage = null;
        if (this.isStep1) {
            const reporter = this.participants.find((p) => p.Role__c === 'Reporting Person');
            if (!reporter || !reporter.Last_Name__c) {
                this.errorMessage = 'Step 1: enter the Reporting Person last name.';
                return false;
            }
            if (!reporter.Phone__c && !reporter.Email__c) {
                this.errorMessage = 'Step 1: Reporting Person needs a phone or an email.';
                return false;
            }
        }
        if (this.isStep2) {
            const primary = this.participants.find((p) => p.Role__c === 'Primary Individual');
            if (!primary || (!primary.Unknown_Participant__c && !primary.Last_Name__c)) {
                this.errorMessage = 'Step 2: enter the Primary Individual (or mark Name Unknown).';
                return false;
            }
        }
        return true;
    }

    handleNext() { if (this.validateCurrentStep()) this.currentStepIndex += 1; }
    handlePrevious() { if (!this.isFirstStep) this.currentStepIndex -= 1; }

    async persist(submit) {
        this.errorMessage = null;
        try {
            const state = await saveWizard({
                intake: this.intake,
                participants: this.participants,
                addresses: this.addresses,
                submitForReview: submit
            });
            this.intake = state.intake;
            this.participants = state.participants;
            this.addresses = state.addresses;
            this.savedMessage = submit
                ? `Submitted. Referral number: ${this.intake.Referral_Number__c}`
                : 'Draft saved.';
        } catch (e) {
            this.errorMessage = this.reduceError(e);
        }
    }

    handleSaveDraft() { this.persist(false); }
    handleSubmit() { if (this.validateCurrentStep()) this.persist(true); }

    reduceError(error) {
        if (!error) return 'Unknown error';
        if (error.body && error.body.message) return error.body.message;
        return error.message || 'Unknown error';
    }
}
