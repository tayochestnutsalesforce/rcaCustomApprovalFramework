/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class UpdateLiveApprovalInvocable {

    // Outer wrapper for Flow: contains a list of approval wrappers and a quoteId (string)
    public class Requests {
        @InvocableVariable(label='Approvals' description='List of approval records to apply')
        public List<ApprovalRecordsWrapper> approvals;

        @InvocableVariable(label='Quote Id' description='Quote Id to target')
        public String quoteId;

        public Requests() {}
    }

    

    @InvocableMethod(label='Update Live Approval' description='Update Live_Approval__c fields for given approval rules (groups)')
    public static void updateApprovals(List<Requests> requestGroups) {
        if (requestGroups == null || requestGroups.isEmpty()) return;

        // Build a map of quoteId -> list of approval wrappers
    Map<Id, List<ApprovalRecordsWrapper>> approvalsByQuote = new Map<Id, List<ApprovalRecordsWrapper>>();
    Set<Id> quoteIds = new Set<Id>();
    Set<String> ruleIds = new Set<String>();

        for (Requests rg : requestGroups) {
            if (rg == null) continue;
            Id qId = null;
            if (rg.quoteId != null) {
                try { qId = (Id)rg.quoteId; } catch (Exception e) { qId = null; }
            }
                if (qId == null) continue;

            quoteIds.add(qId);
            if (!approvalsByQuote.containsKey(qId)) approvalsByQuote.put(qId, new List<ApprovalRecordsWrapper>());
            if (rg.approvals != null) {
                approvalsByQuote.get(qId).addAll(rg.approvals);
                for (ApprovalRecordsWrapper ar : rg.approvals) {
                    if (ar != null && ar.approvalRuleId != null) ruleIds.add(ar.approvalRuleId);
                }
            }
        }

        if (quoteIds.isEmpty() || ruleIds.isEmpty()) return;

        // Build WHERE clause to find any Live_Approval__c that references any of these ruleIds
        String whereClause = '';
        List<String> ors = new List<String>();
        for (Integer i = 1; i <= 20; i++) {
            ors.add('Approval_Rule_' + i + '__c IN :ruleIds');
        }

        whereClause = String.join(ors, ' OR ');

    String soql = 'SELECT Id, Quote__c,' +
            ' Approval_Rule_1__c, Approval_Rule_2__c, Approval_Rule_3__c, Approval_Rule_4__c, Approval_Rule_5__c,' +
            ' Approval_Rule_6__c, Approval_Rule_7__c, Approval_Rule_8__c, Approval_Rule_9__c, Approval_Rule_10__c,' +
            ' Approval_Rule_11__c, Approval_Rule_12__c, Approval_Rule_13__c, Approval_Rule_14__c, Approval_Rule_15__c,' +
            ' Approval_Rule_16__c, Approval_Rule_17__c, Approval_Rule_18__c, Approval_Rule_19__c, Approval_Rule_20__c,' +
            ' Triggered_1__c, Triggered_2__c, Triggered_3__c, Triggered_4__c, Triggered_5__c,' +
            ' Triggered_6__c, Triggered_7__c, Triggered_8__c, Triggered_9__c, Triggered_10__c,' +
            ' Triggered_11__c, Triggered_12__c, Triggered_13__c, Triggered_14__c, Triggered_15__c,' +
            ' Triggered_16__c, Triggered_17__c, Triggered_18__c, Triggered_19__c, Triggered_20__c,' +
            ' Status_1__c, Status_2__c, Status_3__c, Status_4__c, Status_5__c,' +
            ' Status_6__c, Status_7__c, Status_8__c, Status_9__c, Status_10__c,' +
            ' Status_11__c, Status_12__c, Status_13__c, Status_14__c, Status_15__c,' +
            ' Status_16__c, Status_17__c, Status_18__c, Status_19__c, Status_20__c,' +
            ' Approver_1__c, Approver_2__c, Approver_3__c, Approver_4__c, Approver_5__c,' +
            ' Approver_6__c, Approver_7__c, Approver_8__c, Approver_9__c, Approver_10__c,' +
            ' Approver_11__c, Approver_12__c, Approver_13__c, Approver_14__c, Approver_15__c,' +
            ' Approver_16__c, Approver_17__c, Approver_18__c, Approver_19__c, Approver_20__c' +
            ' FROM Live_Approval__c WHERE (' + whereClause + ') AND Quote__c IN :quoteIds';

    List<Live_Approval__c> lives = Database.query(soql);

        Map<Id, Live_Approval__c> toUpdateMap = new Map<Id, Live_Approval__c>();

        for (Live_Approval__c la : lives) {
            // Get approvals targeted for this quote
            List<ApprovalRecordsWrapper> approvals = approvalsByQuote.get(la.Quote__c);
            if (approvals == null || approvals.isEmpty()) continue;

            for (ApprovalRecordsWrapper req : approvals) {
                if (req == null || req.approvalRuleId == null) continue;
                Integer foundIndex = null;
                for (Integer i = 1; i <= 20; i++) {
                    String fieldName = 'Approval_Rule_' + i + '__c';
                    Object ruleObj = la.get(fieldName);
                    if (ruleObj != null && String.valueOf(ruleObj) == req.approvalRuleId) {
                        foundIndex = i;
                        break;
                    }
                }
                if (foundIndex != null) {
                    String trigField = 'Triggered_' + foundIndex + '__c';
                    String statusField = 'Status_' + foundIndex + '__c';
                    String approverField = 'Approver_' + foundIndex + '__c';

                    // Convert triggeringStatus string to boolean: accept 'true' (case-insensitive), else false

                    Boolean trigVal = (req.triggeringStatus == true);
                    if(req.triggeringStatus!=null){
                        la.put(trigField, trigVal);
                    }
                    if(req.approvalStatus!=null){
                        la.put(statusField, req.approvalStatus);
                    }

                    if(req.approver!=null){
                        la.put(approverField, req.approver);
                    }

                    toUpdateMap.put(la.Id, la);
                }
            }
        }

        if (!toUpdateMap.isEmpty()) {
            try {
                update toUpdateMap.values();
            } catch (DmlException de) {
                // swallow - Flow can't handle exceptions here; consider logging
            }
        }
    }
}