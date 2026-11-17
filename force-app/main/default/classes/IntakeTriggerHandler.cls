/** Trigger handler for Service_Intake__c — status lifecycle rules. */
public with sharing class IntakeTriggerHandler {
    private static final Set<String> LOCKED_STATUSES =
        new Set<String>{ 'Submitted', 'In Review', 'Assigned' };

    public static void beforeUpdate(
        List<Service_Intake__c> newList, Map<Id, Service_Intake__c> oldMap
    ) {
        for (Service_Intake__c intake : newList) {
            Service_Intake__c old = oldMap.get(intake.Id);
            if (old.Status__c == 'Assigned' && intake.Status__c != old.Status__c
                && intake.Status__c != 'Returned for Edits') {
                intake.addError('An Assigned intake can only be Returned for Edits.');
            }
            if (intake.Status__c == 'Submitted' && String.isBlank(intake.Referral_Number__c)) {
                intake.Referral_Number__c =
                    'REF-' + String.valueOf(1000 + Math.abs(Crypto.getRandomInteger())).left(10);
            }
        }
    }

    public static Boolean isLocked(Service_Intake__c intake) {
        return intake != null && LOCKED_STATUSES.contains(intake.Status__c);
    }
}
