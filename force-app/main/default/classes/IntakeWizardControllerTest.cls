@isTest
private class IntakeWizardControllerTest {
    @isTest
    static void saveDraftCreatesIntakeAndParticipants() {
        Service_Intake__c intake = new Service_Intake__c(
            Status__c = 'New', Request_Date__c = Date.today());
        Intake_Participant__c reporter = new Intake_Participant__c(
            Role__c = 'Reporting Person', First_Name__c = 'Jamie',
            Last_Name__c = 'Rivera', Phone__c = '555-0100');

        Test.startTest();
        IntakeWizardController.WizardState state = IntakeWizardController.saveWizard(
            intake, new List<Intake_Participant__c>{ reporter },
            new List<Intake_Address__c>(), false);
        Test.stopTest();

        System.assertNotEquals(null, state.intake.Id);
        System.assertEquals('Draft', state.intake.Status__c);
        System.assertEquals(1, state.participants.size());
    }

    @isTest
    static void submitGeneratesReferralNumber() {
        Service_Intake__c intake = IntakeTestDataFactory.createNorthstarScenario();
        IntakeWizardController.WizardState loaded =
            IntakeWizardController.getWizardState(intake.Id);

        Test.startTest();
        IntakeWizardController.WizardState submitted = IntakeWizardController.saveWizard(
            loaded.intake, loaded.participants, loaded.addresses, true);
        Test.stopTest();

        System.assertEquals('Submitted', submitted.intake.Status__c);
        System.assert(submitted.intake.Referral_Number__c.startsWith('REF-'));
    }

    @isTest
    static void submitWithoutReporterIsRejected() {
        Service_Intake__c intake = new Service_Intake__c(
            Status__c = 'New', Request_Date__c = Date.today());
        Boolean rejected = false;
        Test.startTest();
        try {
            IntakeWizardController.saveWizard(
                intake, new List<Intake_Participant__c>(),
                new List<Intake_Address__c>(), true);
        } catch (AuraHandledException ex) {
            rejected = true;
        }
        Test.stopTest();
        System.assert(rejected, 'Submit without a Reporting Person should fail');
    }

    @isTest
    static void duplicateDetectionFindsPriorReferral() {
        Service_Intake__c prior = IntakeTestDataFactory.createNorthstarScenario();
        Date dob = Date.today().addYears(-11);

        Test.startTest();
        List<IntakeDuplicateService.DuplicateMatch> matches =
            IntakeDuplicateService.findPossibleDuplicates('Morgan', dob, null);
        Test.stopTest();

        System.assertEquals(1, matches.size());
        System.assertEquals(prior.Id, matches[0].intakeId);
    }

    @isTest
    static void validateAddressMockVerifiesCompleteAddress() {
        IntakeWizardController.AddressValidationResult r =
            IntakeWizardController.validateAddress('1 Main St', 'Atlanta', 'GA', '30301');
        System.assertEquals(true, r.verified);
    }

    @isTest
    static void bulkSaveHandles200Participants() {
        List<Intake_Participant__c> bulk = new List<Intake_Participant__c>();
        for (Integer i = 0; i < 200; i++) {
            bulk.add(new Intake_Participant__c(
                Role__c = 'Household Member', First_Name__c = 'Demo',
                Last_Name__c = 'Person' + i));
        }
        Test.startTest();
        IntakeWizardController.WizardState state = IntakeWizardController.saveWizard(
            new Service_Intake__c(Status__c = 'New', Request_Date__c = Date.today()),
            bulk, new List<Intake_Address__c>(), false);
        Test.stopTest();
        System.assertEquals(200, state.participants.size());
    }
}
