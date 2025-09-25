/**
 * Helper class to create Live_Approval__c records from approval rules.
 * Contains a global wrapper so Flow can reference the type.
 */



public with sharing class LiveApprovalCreator {

        public class Requests {
        @InvocableVariable(label='Approvals Ids' description='List of approval record Ids to apply')
        public List<String> approvalRuleIds;

        @InvocableVariable(label='Quote Id' description='Quote Id to target')
        public String quoteId;

        public Requests() {}
    }

    @InvocableMethod(label='Create Live Approval' description='Creates Live Approval Record fields for given approval rules (groups)')
    public static void createLiveApprovals(List<Requests> requestList) {
        if (requestList == null || requestList.isEmpty()) return;

        List<Live_Approval__c> toInsert = new List<Live_Approval__c>();

        for (Requests req : requestList) {
            if (req == null || req.quoteId == null) continue;
            Id qId = null;
            try { qId = (Id)req.quoteId; } catch (Exception e) { qId = null; }
            if (qId == null) continue;

            // collect rule ids
            Set<Id> ruleIdSet = new Set<Id>();
            if (req.approvalRuleIds != null) {
                for (String s : req.approvalRuleIds) {
                    if (s == null) continue;
                    try { ruleIdSet.add((Id)s); } catch (Exception e) { /* ignore invalid */ }
                }
            }

            List<RCA_Approval_Rule__c> rules = new List<RCA_Approval_Rule__c>();
            if (!ruleIdSet.isEmpty()) {
                rules = [SELECT Id, Level__c, Order__c FROM RCA_Approval_Rule__c WHERE Id IN :ruleIdSet ORDER BY Level__c, Order__c];
            }

            Live_Approval__c la = new Live_Approval__c();
            la.Quote__c = qId;

            Integer idx = 1;
            for (RCA_Approval_Rule__c rr : rules) {
                if (idx > 20) break;
                String ruleField = 'Approval_Rule_' + idx + '__c';
                String trigField = 'Triggered_' + idx + '__c';
                String statusField = 'Status_' + idx + '__c';
                String approverField = 'Approver_' + idx + '__c';

                la.put(ruleField, rr.Id);
                la.put(trigField, false);
                la.put(statusField, 'N/A');
                la.put(approverField, null);

                idx++;
            }

            toInsert.add(la);
        }

        if (!toInsert.isEmpty()) {
            try {
                insert toInsert;
            } catch (DmlException de) {
                // swallow for now; consider logging or returning results
            }
        }
    }
}