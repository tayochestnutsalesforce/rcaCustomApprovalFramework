// Apex anonymous script to create sample Approval_Preview__c records for testing
// Run with: sfdx force:apex:execute -f scripts/apex/seedApprovalPreviews.apex -u <yourOrgAlias>

List<Approval_Preview__c> samples = new List<Approval_Preview__c>();

// Create 4 chains with levels 1..5
List<String> chains = new List<String>{'Chain A','Chain B','Chain C','Chain D'};
for (String chainName : chains) {
    for (Integer order = 1; order <= 5; order++) {
        Approval_Preview__c ap = new Approval_Preview__c();
        ap.Name = 'PA-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        ap.Chain__c = chainName;
        ap.Order__c = order;
        ap.Level__c = order; // same as order for testing
        ap.Title__c = chainName + ' - Step ' + String.valueOf(order);
        ap.Approver__c = 'Approver ' + String.valueOf(order);
        // Optional: set Quote__c to a sample Quote Id if you have one
        samples.add(ap);
    }
}

insert samples;
System.debug('Inserted ' + samples.size() + ' Approval_Preview__c sample records.');