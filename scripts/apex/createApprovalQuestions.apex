// Anonymous Apex: Create one ApprovalQuestions__c record per RCA_Approval_Rule__c if none exist
// Usage: sfdx force:apex:execute -f scripts/apex/createApprovalQuestions.apex -u <orgAlias>

List<RCA_Approval_Rule__c> rules = [SELECT Id, Name FROM RCA_Approval_Rule__c];
System.debug('Found ' + rules.size() + ' approval rules.');

// Map rule Id to existing question count
Map<Id, Integer> existingCounts = new Map<Id, Integer>();
for (AggregateResult ar : [SELECT Approval_Rule__c ruleId, COUNT(Id) cnt FROM ApprovalQuestions__c WHERE Approval_Rule__c IN :rules GROUP BY Approval_Rule__c]) {
    existingCounts.put((Id)ar.get('ruleId'), Integer.valueOf(ar.get('cnt')));
}

List<ApprovalQuestions__c> toInsert = new List<ApprovalQuestions__c>();
Integer orderDefault = 1;
for (RCA_Approval_Rule__c r : rules) {
    Integer cnt = existingCounts.containsKey(r.Id) ? existingCounts.get(r.Id) : 0;
    if (cnt == 0) {
        ApprovalQuestions__c q = new ApprovalQuestions__c();
        q.Approval_Rule__c = r.Id;
        q.Question__c = 'Please confirm the criteria for: ' + r.Name;
        q.IsActive__c = true;
        q.Order__c = orderDefault;
        toInsert.add(q);
    }
}

if (!toInsert.isEmpty()) {
    insert toInsert;
    System.debug('Inserted ' + toInsert.size() + ' ApprovalQuestions__c records.');
} else {
    System.debug('No missing ApprovalQuestions found.');
}
