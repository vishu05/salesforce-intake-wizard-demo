/** Reusable fictional test data for the intake demo. */
@isTest
public class IntakeTestDataFactory {
    public static Service_Intake__c createIntake(String status) {
        Service_Intake__c intake = new Service_Intake__c(
            Status__c = status,
            Priority__c = 'High',
            Request_Type__c = 'Mentoring',
            Request_Date__c = Date.today(),
            Narrative__c = 'Fictional demo referral.',
            Services_Needed__c = 'Mentoring;Food Assistance'
        );
        insert intake;
        return intake;
    }

    public static Intake_Participant__c createParticipant(
        Id intakeId, String role, String firstName, String lastName, Date dob
    ) {
        Intake_Participant__c p = new Intake_Participant__c(
            Name = (firstName + ' ' + lastName).trim(),
            Service_Intake__c = intakeId,
            Role__c = role,
            First_Name__c = firstName,
            Last_Name__c = lastName,
            DOB__c = dob,
            Phone__c = '555-0100',
            Email__c = 'demo@example.com'
        );
        insert p;
        return p;
    }

    /** Seed: Jamie Rivera (reporter) -> Alex Morgan (primary) + Taylor Morgan (caregiver). */
    public static Service_Intake__c createNorthstarScenario() {
        Service_Intake__c intake = createIntake('Draft');
        createParticipant(intake.Id, 'Reporting Person', 'Jamie', 'Rivera', null);
        createParticipant(intake.Id, 'Primary Individual', 'Alex', 'Morgan',
            Date.today().addYears(-11));
        createParticipant(intake.Id, 'Caregiver', 'Taylor', 'Morgan', null);
        return intake;
    }
}
