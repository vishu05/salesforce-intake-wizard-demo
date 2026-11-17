trigger ServiceIntakeTrigger on Service_Intake__c (before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        IntakeTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
}
