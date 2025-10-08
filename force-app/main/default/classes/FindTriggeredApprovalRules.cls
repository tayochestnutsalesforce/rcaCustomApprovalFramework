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
        
        @InvocableVariable(required=false)
        public Integer totalLevels;
    }

    public class Response {
        @InvocableVariable
        public List<String> approvalRuleIds;
    }

    @InvocableMethod(label='Find Triggered Approval Rules' description='Given a Quote Id and optional total number of levels, returns Approval_Rule_x__c values when the corresponding Triggered_x__c (or Status_x__c) indicates a trigger')
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
        // Updated patterns to be more specific and handle edge cases
        Pattern pApproval = Pattern.compile('(?i)^Approval_Rule_\\d+__c$');
        Pattern pTriggered = Pattern.compile('(?i)^Triggered_\\d+__c$');
        Pattern pStatus = Pattern.compile('(?i)^Status_\\d+__c$');

        for (String fn : fldMap.keySet()) {
            if (pApproval.matcher(fn).matches()) {
                approvalRuleFields.add(fn);
                System.debug('Found approval rule field: ' + fn);
            }
            if (pTriggered.matcher(fn).matches()) {
                triggeredFields.add(fn);
                System.debug('Found triggered field: ' + fn);
            }
            if (pStatus.matcher(fn).matches()) {
                triggeredFields.add(fn);
                System.debug('Found status field: ' + fn);
            }
        }

        // Always include Quote__c, Level__c and Id
        Set<String> selectSet = new Set<String>{'Id','Quote__c','Level__c'};
        selectSet.addAll(approvalRuleFields);
        selectSet.addAll(triggeredFields);

        String soql = 'SELECT ' + String.join(new List<String>(selectSet), ',') + ' FROM Live_Approval__c WHERE Quote__c IN :quoteIds';
        System.debug('SOQL Query: ' + soql);
        System.debug('Approval Rule Fields found: ' + approvalRuleFields);
        System.debug('Triggered/Status Fields found: ' + triggeredFields);
        
        List<SObject> liveApprovals = Database.query(soql);

        // Map quoteId + level -> Live_Approval__c to handle multiple records per quote
        Map<String,SObject> byQuoteAndLevel = new Map<String,SObject>();
        for (SObject la : liveApprovals) {
            Object q = la.get('Quote__c');
            Object lvl = la.get('Level__c');
            if (q instanceof Id) {
                String key = String.valueOf(q) + '_' + (lvl != null ? String.valueOf(lvl) : 'null');
                byQuoteAndLevel.put(key, la);
                System.debug('Mapped Live_Approval record: Quote=' + q + ', Level=' + lvl + ', Key=' + key);
            }
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

            // Determine which Live_Approval records to process
            List<SObject> recordsToProcess = new List<SObject>();
            
            if (r.totalLevels != null && r.totalLevels > 0) {
                // Process levels 1 through totalLevels
                for (Integer currentLevel = 1; currentLevel <= r.totalLevels; currentLevel++) {
                    String key = String.valueOf(qid) + '_' + String.valueOf(currentLevel);
                    SObject la = byQuoteAndLevel.get(key);
                    if (la != null) {
                        recordsToProcess.add(la);
                        System.debug('Added level ' + currentLevel + ' for processing (quote ' + qid + ')');
                    } else {
                        System.debug('No Live_Approval record found for quote ' + qid + ' level ' + currentLevel);
                    }
                }
                System.debug('Processing levels 1 through ' + r.totalLevels + ' for quote ' + qid + ', found ' + recordsToProcess.size() + ' records');
            } else {
                // Process all levels for this quote (when totalLevels is null or 0)
                for (String key : byQuoteAndLevel.keySet()) {
                    if (key.startsWith(String.valueOf(qid) + '_')) {
                        recordsToProcess.add(byQuoteAndLevel.get(key));
                    }
                }
                System.debug('Processing all levels for quote ' + qid + ', found ' + recordsToProcess.size() + ' records');
            }
            
            if (recordsToProcess.isEmpty()) { 
                outputs.add(resp); 
                continue; 
            }

            // Process each Live_Approval record
            for (SObject la : recordsToProcess) {
                Object currentLevel = la.get('Level__c');
                System.debug('Processing Live_Approval record for quote ' + qid + ', level: ' + currentLevel);

            // Iterate approval rule fields, extract index and inspect corresponding triggered/status field
            for (String arField : approvalRuleFields) {
                // Remove __c suffix to work with cleaner field name
                String tempField = arField.replace('__c', '');
                System.debug('Processing field: ' + arField + ', temp field: ' + tempField);
                
                // Extract the numeric index from field name like "Approval_Rule_10"
                // Find the position after the last underscore
                Integer start = tempField.lastIndexOf('_') + 1;
                
                // Validate the position to ensure proper extraction
                if (start <= 0 || start >= tempField.length()) {
                    System.debug('Invalid field format: ' + arField + ', start: ' + start + ', tempField length: ' + tempField.length());
                    continue;
                }
                
                String idx = tempField.substring(start);
                System.debug('Extracted index: "' + idx + '" from field: ' + arField);
                
                // Validate that idx is numeric
                if (!idx.isNumeric()) {
                    System.debug('Non-numeric index extracted: ' + idx + ' from field: ' + arField);
                    continue;
                }
                
                String trigF = 'Triggered_' + idx + '__c';
                String statusF = 'Status_' + idx + '__c';

                Object trigVal = null;
                String usedField = null;
                
                // Check if the corresponding triggered or status field exists and get its value
                if (fldMap.containsKey(trigF)) {
                    try {
                        trigVal = la.get(trigF);
                        usedField = trigF;
                    } catch (Exception e) {
                        System.debug('Error accessing field ' + trigF + ': ' + e.getMessage());
                    }
                } else if (fldMap.containsKey(statusF)) {
                    try {
                        trigVal = la.get(statusF);
                        usedField = statusF;
                    } catch (Exception e) {
                        System.debug('Error accessing field ' + statusF + ': ' + e.getMessage());
                    }
                } else {
                    System.debug('Neither ' + trigF + ' nor ' + statusF + ' exists in the field map');
                    continue;
                }

                Boolean isTriggered = false;
                if (trigVal instanceof Boolean) {
                    isTriggered = (Boolean)trigVal;
                } else if (trigVal instanceof String) {
                    String s = ((String)trigVal).toLowerCase();
                    if (s == 'true' || s == 'triggered' || s == 'yes') isTriggered = true;
                }

                if (isTriggered) {
                    Object arVal = la.get(arField);
                    if (arVal != null) {
                        resp.approvalRuleIds.add(String.valueOf(arVal));
                        System.debug('Added approval rule ID: ' + String.valueOf(arVal) + ' from field: ' + arField + ' (triggered by: ' + usedField + ' = ' + trigVal + ')');
                    } else {
                        System.debug('Approval rule field ' + arField + ' was null despite being triggered by ' + usedField);
                    }
                } else {
                    System.debug('Field ' + arField + ' not triggered. ' + usedField + ' = ' + trigVal);
                }
            }
            } // End of processing for this Live_Approval record

            outputs.add(resp);
        }

        return outputs;
    }
}