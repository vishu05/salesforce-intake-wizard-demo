/**
 * Controller for the multi-step Intake Wizard LWC.
 * One transactional save per step; participant + address saved together.
 * Demo only — fictional organization and data.
 */
public with sharing class IntakeWizardController {
    public class WizardState {
        @AuraEnabled public Service_Intake__c intake;
        @AuraEnabled public List<Intake_Participant__c> participants;
        @AuraEnabled public List<Intake_Address__c> addresses;
    }

    public class AddressValidationResult {
        @AuraEnabled public Boolean verified;
        @AuraEnabled public String message;
        @AuraEnabled public String suggestedCity;
        @AuraEnabled public String suggestedZip;
    }

    /** Load an existing intake (or return a blank state for a new wizard). */
    @AuraEnabled
    public static WizardState getWizardState(Id intakeId) {
        WizardState state = new WizardState();
        state.participants = new List<Intake_Participant__c>();
        state.addresses = new List<Intake_Address__c>();
        if (intakeId == null) {
            state.intake = new Service_Intake__c(Status__c = 'New', Request_Date__c = Date.today());
            return state;
        }
        state.intake = [
            SELECT Id, Name, Status__c, Priority__c, Request_Type__c, Request_Date__c,
                   Narrative__c, Services_Needed__c, Referral_Number__c
            FROM Service_Intake__c WHERE Id = :intakeId LIMIT 1
        ];
        state.participants = [
            SELECT Id, Role__c, First_Name__c, Last_Name__c, DOB__c, Approx_Age__c,
                   Phone__c, Email__c, Relationship__c, Unknown_Participant__c
            FROM Intake_Participant__c WHERE Service_Intake__c = :intakeId ORDER BY CreatedDate
        ];
        state.addresses = [
            SELECT Id, Address_Line_1__c, Address_Line_2__c, City__c, State__c, Zip__c,
                   County__c, Address_Type__c, Validation_Status__c
            FROM Intake_Address__c WHERE Service_Intake__c = :intakeId ORDER BY CreatedDate
        ];
        return state;
    }

    /**
     * Save the whole wizard in one transaction (used by Save Draft and by each
     * step's Next). Participants and addresses are upserted with the intake so
     * a failure anywhere rolls everything back.
     */
    @AuraEnabled
    public static WizardState saveWizard(
        Service_Intake__c intake,
        List<Intake_Participant__c> participants,
        List<Intake_Address__c> addresses,
        Boolean submitForReview
    ) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (submitForReview == true) {
                validateForSubmit(intake, participants);
                intake.Status__c = 'Submitted';
                if (String.isBlank(intake.Referral_Number__c)) {
                    intake.Referral_Number__c = generateReferralNumber();
                }
            } else if (intake.Status__c == 'New') {
                intake.Status__c = 'Draft';
            }
            upsert intake;

            if (participants != null) {
                for (Intake_Participant__c p : participants) {
                    p.Service_Intake__c = intake.Id;
                    if (p.DOB__c != null) {
                        p.Approx_Age__c = IntakeDuplicateService.calculateAge(p.DOB__c);
                    }
                    p.Name = buildParticipantName(p);
                }
                upsert participants;
            }
            if (addresses != null) {
                for (Intake_Address__c a : addresses) {
                    a.Service_Intake__c = intake.Id;
                    a.Name = buildAddressName(a);
                }
                upsert addresses;
            }
            return getWizardState(intake.Id);
        } catch (Exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /** Mock address validation (demo — no external API key needed). */
    @AuraEnabled
    public static AddressValidationResult validateAddress(
        String line1, String city, String stateCode, String zip
    ) {
        AddressValidationResult r = new AddressValidationResult();
        if (String.isBlank(line1) || String.isBlank(city) || String.isBlank(zip)) {
            r.verified = false;
            r.message = 'Enter street, city and ZIP to validate.';
            return r;
        }
        r.verified = true;
        r.suggestedCity = city;
        r.suggestedZip = zip;
        r.message = 'Address verified (demo validation).';
        return r;
    }

    private static void validateForSubmit(
        Service_Intake__c intake, List<Intake_Participant__c> participants
    ) {
        Boolean hasReporter = false;
        Boolean hasPrimary = false;
        if (participants != null) {
            for (Intake_Participant__c p : participants) {
                if (p.Role__c == 'Reporting Person') {
                    hasReporter = true;
                    if (String.isBlank(p.Phone__c) && String.isBlank(p.Email__c)) {
                        throw new AuraHandledException(
                            'Reporting Person needs a phone or an email before submit.');
                    }
                }
                if (p.Role__c == 'Primary Individual') {
                    hasPrimary = true;
                }
            }
        }
        if (!hasReporter) {
            throw new AuraHandledException('Add a Reporting Person before submit.');
        }
        if (!hasPrimary) {
            throw new AuraHandledException('Add a Primary Individual before submit.');
        }
    }

    private static String buildParticipantName(Intake_Participant__c p) {
        if (p.Unknown_Participant__c == true) {
            return 'Unknown Participant';
        }
        return ((p.First_Name__c == null ? '' : p.First_Name__c) + ' ' +
                (p.Last_Name__c == null ? '' : p.Last_Name__c)).trim();
    }

    private static String buildAddressName(Intake_Address__c a) {
        return ((a.Address_Line_1__c == null ? 'Address' : a.Address_Line_1__c) + ' ' +
                (a.City__c == null ? '' : a.City__c)).trim();
    }

    private static String generateReferralNumber() {
        Integer count = [SELECT COUNT() FROM Service_Intake__c];
        return 'REF-' + String.valueOf(1000 + count + 1);
    }
}
