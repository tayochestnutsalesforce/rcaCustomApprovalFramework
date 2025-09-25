/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class FindTriggeredApprovalRules {

    public class Request {
        @InvocableVariable(required=true)
        public String quoteId;
    }

    public class Response {
        @InvocableVariable
        public List<String> approvalRuleIds;
    }

    @InvocableMethod(label='Find Triggered Approval Rules' description='Given a Quote Id returns Approval_Rule_x__c values when the corresponding Triggered_x__c (or Status_x__c) indicates a trigger')
    public static List<Response> find(List<Request> requests) {
        List<Response> outputs = new List<Response>();
        if (requests == null || requests.isEmpty()) return outputs;

        // collect quote ids
        Set<Id> quoteIds = new Set<Id>();
        for (Request r : requests) {
            if (r == null || String.isBlank(r.quoteId)) continue;
            try {
                quoteIds.add((Id)r.quoteId);
            } catch (Exception e) {
                // ignore invalid ids; will result in empty response for that entry
            }
        }

        if (quoteIds.isEmpty()) {
            // return empty responses per input order
            for (Request r : requests) outputs.add(new Response());
            return outputs;
        }

        // Describe Live_Approval__c to find matching dynamic fields
        Map<String, Schema.SObjectField> fldMap = Schema.SObjectType.Live_Approval__c.fields.getMap();
        List<String> approvalRuleFields = new List<String>();
        Set<String> triggeredFields = new Set<String>();

        // Precompile regex patterns (Apex Pattern/Matcher usage)
        Pattern pApproval = Pattern.compile('(?i)Approval_Rule_\\d+__c');
        Pattern pTriggered = Pattern.compile('(?i)Triggered_\\d+__c');
        Pattern pStatus = Pattern.compile('(?i)Status_\\d+__c');

        for (String fn : fldMap.keySet()) {
            if (pApproval.matcher(fn).matches()) approvalRuleFields.add(fn);
            if (pTriggered.matcher(fn).matches()) triggeredFields.add(fn);
            if (pStatus.matcher(fn).matches()) triggeredFields.add(fn);
        }

        // Always include Quote__c and Id
        Set<String> selectSet = new Set<String>{'Id','Quote__c'};
        selectSet.addAll(approvalRuleFields);
        selectSet.addAll(triggeredFields);

        String soql = 'SELECT ' + String.join(new List<String>(selectSet), ',') + ' FROM Live_Approval__c WHERE Quote__c IN :quoteIds';
        List<SObject> liveApprovals = Database.query(soql);

        // Map quoteId -> Live_Approval__c
        Map<Id,SObject> byQuote = new Map<Id,SObject>();
        for (SObject la : liveApprovals) {
            Object q = la.get('Quote__c');
            if (q instanceof Id) byQuote.put((Id)q, la);
        }

        // For each request, compute matched approval rule ids
        for (Request r : requests) {
            Response resp = new Response();
            resp.approvalRuleIds = new List<String>();
            if (r == null || String.isBlank(r.quoteId)) {
                outputs.add(resp);
                continue;
            }
            Id qid;
            try { qid = (Id)r.quoteId; } catch (Exception e) { outputs.add(resp); continue; }

            SObject la = byQuote.get(qid);
            if (la == null) { outputs.add(resp); continue; }

            // Iterate approval rule fields, extract index and inspect corresponding triggered/status field
            for (String arField : approvalRuleFields) {
                Integer start = arField.lastIndexOf('_') + 1;
                Integer endding = arField.indexOf('__c');
                if (start <= 0 || endding <= start) continue;
                String idx = arField.substring(start, endding);
                String trigF = 'Triggered_' + idx + '__c';
                String statusF = 'Status_' + idx + '__c';

                Object trigVal = null;
                if (fldMap.containsKey(trigF)) trigVal = la.get(trigF);
                else if (fldMap.containsKey(statusF)) trigVal = la.get(statusF);

                Boolean isTriggered = false;
                if (trigVal instanceof Boolean) {
                    isTriggered = (Boolean)trigVal;
                } else if (trigVal instanceof String) {
                    String s = ((String)trigVal).toLowerCase();
                    if (s == 'true' || s == 'triggered' || s == 'yes') isTriggered = true;
                }

                if (isTriggered) {
                    Object arVal = la.get(arField);
                    if (arVal != null) resp.approvalRuleIds.add(String.valueOf(arVal));
                }
            }

            outputs.add(resp);
        }

        return outputs;
    }
}