/**
 * New ApprovalPreviewController implementation (2025-09-23)
 * - Ignores the legacy Approval_Preview__c object.
 * - Reads the Live_Approval__c row for a Quote and uses the Approver_N__c values
 *   and Triggered_N__c checkboxes to determine which slots to return.
 * - Joins Approval_Rule_N__c lookups to RCA_Approval_Rule__c for rule metadata.
 */
public with sharing class ApprovalPreviewController {
    // Simple DTO for LWC consumption
    public class PreviewDTO {
        @AuraEnabled public String Id;
        @AuraEnabled public String Chain;
        @AuraEnabled public Integer Order;
        @AuraEnabled public Integer Level;
        @AuraEnabled public String Title;
        @AuraEnabled public String ApproverName;
        @AuraEnabled public String ApproverId;
        @AuraEnabled public String AvatarUrl;
        @AuraEnabled public String Key;
        @AuraEnabled public String URL;
        @AuraEnabled public String ApproverType;
        @AuraEnabled public String LiveApprovalId;
        @AuraEnabled public String LiveQuoteId;
        @AuraEnabled public String ApprovalRuleId;
        @AuraEnabled public Integer ApprovalRuleSlot;
        @AuraEnabled public String Status;

        public PreviewDTO() {}
    }

    /**
     * Flatten the Live_Approval__c record for a Quote into per-slot DTOs. Uses the
     * Approver_N__c values from Live_Approval__c (not the Approver on the rule) and
     * only returns slots where the corresponding Triggered_N__c == true.
     */
    @AuraEnabled(cacheable=true)
    public static List<PreviewDTO> getFlattenedLiveApprovalForQuote(Id quoteId) {
        List<PreviewDTO> results = new List<PreviewDTO>();
        if (quoteId == null) return results;

        // Query the single Live_Approval__c row for this quote and include all slot fields
        List<Live_Approval__c> liveList = [
            SELECT Id, Quote__c,
                Approval_Rule_1__c, Approval_Rule_2__c, Approval_Rule_3__c, Approval_Rule_4__c, Approval_Rule_5__c,
                Approval_Rule_6__c, Approval_Rule_7__c, Approval_Rule_8__c, Approval_Rule_9__c, Approval_Rule_10__c,
                Approval_Rule_11__c, Approval_Rule_12__c, Approval_Rule_13__c, Approval_Rule_14__c, Approval_Rule_15__c,
                Approval_Rule_16__c, Approval_Rule_17__c, Approval_Rule_18__c, Approval_Rule_19__c, Approval_Rule_20__c,
                Approver_1__c, Approver_2__c, Approver_3__c, Approver_4__c, Approver_5__c,
                Approver_6__c, Approver_7__c, Approver_8__c, Approver_9__c, Approver_10__c,
                Approver_11__c, Approver_12__c, Approver_13__c, Approver_14__c, Approver_15__c,
                Approver_16__c, Approver_17__c, Approver_18__c, Approver_19__c, Approver_20__c,
                Status_1__c, Status_2__c, Status_3__c, Status_4__c, Status_5__c,
                Status_6__c, Status_7__c, Status_8__c, Status_9__c, Status_10__c,
                Status_11__c, Status_12__c, Status_13__c, Status_14__c, Status_15__c,
                Status_16__c, Status_17__c, Status_18__c, Status_19__c, Status_20__c,
                Triggered_1__c, Triggered_2__c, Triggered_3__c, Triggered_4__c, Triggered_5__c,
                Triggered_6__c, Triggered_7__c, Triggered_8__c, Triggered_9__c, Triggered_10__c,
                Triggered_11__c, Triggered_12__c, Triggered_13__c, Triggered_14__c, Triggered_15__c,
                Triggered_16__c, Triggered_17__c, Triggered_18__c, Triggered_19__c, Triggered_20__c
            FROM Live_Approval__c
            WHERE Quote__c = :quoteId
            LIMIT 1
        ];

        if (liveList.isEmpty()) return results;
        Live_Approval__c live = liveList[0];

        // Collect approval rule ids from slots and prepare per-slot arrays
        Id[] slotRuleIds = new Id[20];
        String[] approverVals = new String[20];
        String[] statuses = new String[20];
        Boolean[] triggered = new Boolean[20];

        slotRuleIds[0] = (Id)live.get('Approval_Rule_1__c');
        slotRuleIds[1] = (Id)live.get('Approval_Rule_2__c');
        slotRuleIds[2] = (Id)live.get('Approval_Rule_3__c');
        slotRuleIds[3] = (Id)live.get('Approval_Rule_4__c');
        slotRuleIds[4] = (Id)live.get('Approval_Rule_5__c');
        slotRuleIds[5] = (Id)live.get('Approval_Rule_6__c');
        slotRuleIds[6] = (Id)live.get('Approval_Rule_7__c');
        slotRuleIds[7] = (Id)live.get('Approval_Rule_8__c');
        slotRuleIds[8] = (Id)live.get('Approval_Rule_9__c');
        slotRuleIds[9] = (Id)live.get('Approval_Rule_10__c');
        slotRuleIds[10] = (Id)live.get('Approval_Rule_11__c');
        slotRuleIds[11] = (Id)live.get('Approval_Rule_12__c');
        slotRuleIds[12] = (Id)live.get('Approval_Rule_13__c');
        slotRuleIds[13] = (Id)live.get('Approval_Rule_14__c');
        slotRuleIds[14] = (Id)live.get('Approval_Rule_15__c');
        slotRuleIds[15] = (Id)live.get('Approval_Rule_16__c');
        slotRuleIds[16] = (Id)live.get('Approval_Rule_17__c');
        slotRuleIds[17] = (Id)live.get('Approval_Rule_18__c');
        slotRuleIds[18] = (Id)live.get('Approval_Rule_19__c');
        slotRuleIds[19] = (Id)live.get('Approval_Rule_20__c');

        approverVals[0] = (String)live.get('Approver_1__c');
        approverVals[1] = (String)live.get('Approver_2__c');
        approverVals[2] = (String)live.get('Approver_3__c');
        approverVals[3] = (String)live.get('Approver_4__c');
        approverVals[4] = (String)live.get('Approver_5__c');
        approverVals[5] = (String)live.get('Approver_6__c');
        approverVals[6] = (String)live.get('Approver_7__c');
        approverVals[7] = (String)live.get('Approver_8__c');
        approverVals[8] = (String)live.get('Approver_9__c');
        approverVals[9] = (String)live.get('Approver_10__c');
        approverVals[10] = (String)live.get('Approver_11__c');
        approverVals[11] = (String)live.get('Approver_12__c');
        approverVals[12] = (String)live.get('Approver_13__c');
        approverVals[13] = (String)live.get('Approver_14__c');
        approverVals[14] = (String)live.get('Approver_15__c');
        approverVals[15] = (String)live.get('Approver_16__c');
        approverVals[16] = (String)live.get('Approver_17__c');
        approverVals[17] = (String)live.get('Approver_18__c');
        approverVals[18] = (String)live.get('Approver_19__c');
        approverVals[19] = (String)live.get('Approver_20__c');

        statuses[0] = (String)live.get('Status_1__c');
        statuses[1] = (String)live.get('Status_2__c');
        statuses[2] = (String)live.get('Status_3__c');
        statuses[3] = (String)live.get('Status_4__c');
        statuses[4] = (String)live.get('Status_5__c');
        statuses[5] = (String)live.get('Status_6__c');
        statuses[6] = (String)live.get('Status_7__c');
        statuses[7] = (String)live.get('Status_8__c');
        statuses[8] = (String)live.get('Status_9__c');
        statuses[9] = (String)live.get('Status_10__c');
        statuses[10] = (String)live.get('Status_11__c');
        statuses[11] = (String)live.get('Status_12__c');
        statuses[12] = (String)live.get('Status_13__c');
        statuses[13] = (String)live.get('Status_14__c');
        statuses[14] = (String)live.get('Status_15__c');
        statuses[15] = (String)live.get('Status_16__c');
        statuses[16] = (String)live.get('Status_17__c');
        statuses[17] = (String)live.get('Status_18__c');
        statuses[18] = (String)live.get('Status_19__c');
        statuses[19] = (String)live.get('Status_20__c');

        triggered[0] = (Boolean)live.get('Triggered_1__c');
        triggered[1] = (Boolean)live.get('Triggered_2__c');
        triggered[2] = (Boolean)live.get('Triggered_3__c');
        triggered[3] = (Boolean)live.get('Triggered_4__c');
        triggered[4] = (Boolean)live.get('Triggered_5__c');
        triggered[5] = (Boolean)live.get('Triggered_6__c');
        triggered[6] = (Boolean)live.get('Triggered_7__c');
        triggered[7] = (Boolean)live.get('Triggered_8__c');
        triggered[8] = (Boolean)live.get('Triggered_9__c');
        triggered[9] = (Boolean)live.get('Triggered_10__c');
        triggered[10] = (Boolean)live.get('Triggered_11__c');
        triggered[11] = (Boolean)live.get('Triggered_12__c');
        triggered[12] = (Boolean)live.get('Triggered_13__c');
        triggered[13] = (Boolean)live.get('Triggered_14__c');
        triggered[14] = (Boolean)live.get('Triggered_15__c');
        triggered[15] = (Boolean)live.get('Triggered_16__c');
        triggered[16] = (Boolean)live.get('Triggered_17__c');
        triggered[17] = (Boolean)live.get('Triggered_18__c');
        triggered[18] = (Boolean)live.get('Triggered_19__c');
        triggered[19] = (Boolean)live.get('Triggered_20__c');

        // Build a list of unique rule ids to query
        List<Id> ruleIds = new List<Id>();
        for (Integer i = 0; i < 20; i++) {
            if (slotRuleIds[i] != null) ruleIds.add(slotRuleIds[i]);
        }

        // Query RCA rules in bulk
        Map<Id, RCA_Approval_Rule__c> ruleMap = new Map<Id, RCA_Approval_Rule__c>();
        if (!ruleIds.isEmpty()) {
            for (RCA_Approval_Rule__c r : [SELECT Id, Chain__c, Key__c, Order__c, Level__c, Approver_Image__c, Approver_Type__c, Title__c, URL__c FROM RCA_Approval_Rule__c WHERE Id IN :ruleIds]) {
                ruleMap.put(r.Id, r);
            }
        }

        // Build DTOs per populated & triggered slot
        for (Integer i = 0; i < 20; i++) {
            Id rid = slotRuleIds[i];
            if (rid == null) continue;
            // only include if the corresponding Triggered_N__c is true
            if (triggered[i] == null || !triggered[i]) continue;
            if (!ruleMap.containsKey(rid)) continue;
            RCA_Approval_Rule__c rule = ruleMap.get(rid);
            PreviewDTO d = new PreviewDTO();
            d.Id = String.valueOf(rule.Id);
            d.ApprovalRuleId = String.valueOf(rule.Id);
            d.ApprovalRuleSlot = i + 1;
            d.Chain = rule.Chain__c;
            d.Order = (rule.Order__c == null ? 0 : Integer.valueOf(rule.Order__c));
            d.Level = (rule.Level__c == null ? 0 : Integer.valueOf(rule.Level__c));
            d.Title = rule.Title__c;
            // Use the Approver value from the Live_Approval__c row instead of the rule's approver
            d.ApproverName = approverVals[i];
            d.ApproverId = (live.get('Approver_' + String.valueOf(i+1) + '__c') == null ? null : String.valueOf(live.get('Approver_' + String.valueOf(i+1) + '__c')));
            d.AvatarUrl = rule.Approver_Image__c;
            d.Key = rule.Key__c;
            d.URL = rule.URL__c;
            d.ApproverType = rule.Approver_Type__c;
            d.Status = statuses[i];
            d.LiveApprovalId = String.valueOf(live.Id);
            d.LiveQuoteId = (live.Quote__c == null ? null : String.valueOf(live.Quote__c));

            system.debug('--- ApprovalPreviewController.getFlattenedLiveApprovalForQuote results ---');
            system.debug(d);
        
            results.add(d);
        }
        
        // return results as-is; sorting/grouping is handled client-side
        return results;
        
    }

    /**
     * DTO for Approval Answer data
     */
    public class ApprovalAnswerDTO {
        @AuraEnabled public String Id;
        @AuraEnabled public String questionText;
        @AuraEnabled public String answer;
        @AuraEnabled public String approvalRuleId;
        @AuraEnabled public Integer questionOrder;

        public ApprovalAnswerDTO() {}
    }

    /**
     * Get approval answers for a specific quote and approval rule
     */
    @AuraEnabled(cacheable=true)
    public static List<ApprovalAnswerDTO> getApprovalAnswers(Id quoteId, Id approvalRuleId) {
        List<ApprovalAnswerDTO> results = new List<ApprovalAnswerDTO>();
        if (quoteId == null || approvalRuleId == null) return results;

        List<ApprovalAnswers__c> answers = [
            SELECT Id, Answer__c, Question__r.Question__c, Question__r.Order__c, Approval_Rule__c
            FROM ApprovalAnswers__c 
            WHERE Quote_Id__c = :quoteId 
            AND Approval_Rule__c = :approvalRuleId
            ORDER BY Question__r.Order__c ASC NULLS LAST
        ];

        for (ApprovalAnswers__c answer : answers) {
            ApprovalAnswerDTO dto = new ApprovalAnswerDTO();
            dto.Id = answer.Id;
            dto.questionText = answer.Question__r.Question__c;
            dto.answer = answer.Answer__c;
            dto.approvalRuleId = answer.Approval_Rule__c;
            dto.questionOrder = answer.Question__r.Order__c != null ? 
                Integer.valueOf(answer.Question__r.Order__c) : 0;
            results.add(dto);
        }

        return results;
    }

}
