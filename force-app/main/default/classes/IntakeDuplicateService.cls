/**
 * Finds possible duplicate individuals / prior referrals for the intake wizard.
 * Demo only — fictional data, selective SOQL, bulk-safe.
 */
public with sharing class IntakeDuplicateService {
    public class DuplicateMatch {
        @AuraEnabled public Id participantId;
        @AuraEnabled public Id intakeId;
        @AuraEnabled public String referralNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String requestType;
        @AuraEnabled public Date requestDate;
        @AuraEnabled public String displayName;
    }

    /** Possible duplicates: same last name + DOB, excluding the current intake. */
    @AuraEnabled(cacheable=true)
    public static List<DuplicateMatch> findPossibleDuplicates(
        String lastName, Date dob, Id excludeIntakeId
    ) {
        List<DuplicateMatch> matches = new List<DuplicateMatch>();
        if (String.isBlank(lastName) || dob == null) {
            return matches;
        }
        for (Intake_Participant__c p : [
            SELECT Id, First_Name__c, Last_Name__c, Service_Intake__c,
                   Service_Intake__r.Referral_Number__c, Service_Intake__r.Status__c,
                   Service_Intake__r.Request_Type__c, Service_Intake__r.Request_Date__c
            FROM Intake_Participant__c
            WHERE Last_Name__c = :lastName
              AND DOB__c = :dob
              AND Role__c = 'Primary Individual'
              AND Service_Intake__c != :excludeIntakeId
            ORDER BY CreatedDate DESC
            LIMIT 10
        ]) {
            DuplicateMatch m = new DuplicateMatch();
            m.participantId = p.Id;
            m.intakeId = p.Service_Intake__c;
            m.referralNumber = p.Service_Intake__r.Referral_Number__c;
            m.status = p.Service_Intake__r.Status__c;
            m.requestType = p.Service_Intake__r.Request_Type__c;
            m.requestDate = p.Service_Intake__r.Request_Date__c;
            m.displayName = (p.First_Name__c + ' ' + p.Last_Name__c).trim();
            matches.add(m);
        }
        return matches;
    }

    /** Prior referrals for the referral-history table (by participant). */
    @AuraEnabled(cacheable=true)
    public static List<DuplicateMatch> getReferralHistory(Id participantId) {
        List<DuplicateMatch> history = new List<DuplicateMatch>();
        if (participantId == null) {
            return history;
        }
        Intake_Participant__c self = [
            SELECT Last_Name__c, DOB__c FROM Intake_Participant__c WHERE Id = :participantId LIMIT 1
        ];
        return findPossibleDuplicates(self.Last_Name__c, self.DOB__c, self.Service_Intake__c);
    }

    /** Age in whole years from a date of birth (null-safe). */
    public static Integer calculateAge(Date dob) {
        if (dob == null) {
            return null;
        }
        Integer age = Date.today().year() - dob.year();
        if (Date.today() < dob.addYears(age)) {
            age--;
        }
        return age;
    }
}
