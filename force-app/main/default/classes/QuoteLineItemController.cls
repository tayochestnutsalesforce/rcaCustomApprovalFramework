/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-25-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QuoteLineItemController {
    
    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> getQuoteLineItems(Id recordId, List<String> fields, String familyFilter) {
        try {
            // Validate inputs
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required');
            }
            
            if (fields == null || fields.isEmpty()) {
                throw new AuraHandledException('At least one field must be specified');
            }
            
            // Clean and validate field names
            Set<String> cleanFields = new Set<String>();
            cleanFields.add('Product2.Name'); // Always include Product2.Name
            for (String field : fields) {
                if (String.isNotBlank(field)) {
                    cleanFields.add(String.escapeSingleQuotes(field.trim()));
                }
            }
            
            if (cleanFields.isEmpty()) {
                throw new AuraHandledException('At least one valid field must be specified');
            }
            
            // Always include Id field if not already present
            cleanFields.add('Id');
            cleanFields.add('QuoteId');
            
            // Build the dynamic SOQL query
            String soqlQuery = 'SELECT Product2.Name, ' + String.join(new List<String>(cleanFields), ', ') + 
                              ' FROM QuoteLineItem WHERE QuoteId = :recordId';
            
            // Add family filter if provided
            if (String.isNotBlank(familyFilter)) {
                soqlQuery += ' AND Product2.Family = :familyFilter';
            }
            
            // Add ordering
            soqlQuery += ' ORDER BY SortOrder, Id';
            
            System.debug('Executing SOQL: ' + soqlQuery);
            System.debug('Record ID: ' + recordId);
            System.debug('Family Filter: ' + familyFilter);
            
            // Execute the query
            return Database.query(soqlQuery);
            
        } catch (QueryException e) {
            System.debug('QueryException: ' + e.getMessage());
            throw new AuraHandledException('Error querying quote line items: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> getQuoteLineItemsWithGroups(String recordId, List<String> fields, String familyFilter) {
        try {
            // Validate inputs
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required');
            }
            
            if (fields == null || fields.isEmpty()) {
                throw new AuraHandledException('At least one field must be specified');
            }
            
            // Clean and validate field names
            Set<String> cleanFields = new Set<String>();
            for (String field : fields) {
                if (String.isNotBlank(field)) {
                    cleanFields.add(String.escapeSingleQuotes(field.trim()));
                }
            }
            
            if (cleanFields.isEmpty()) {
                throw new AuraHandledException('At least one valid field must be specified');
            }
            
            // Always include required fields
            cleanFields.add('Id');
            cleanFields.add('QuoteId');
            cleanFields.add('QuoteLineItemGroupId');
            
            // Build the dynamic SOQL query with QuoteLineItemGroup relationship
            String soqlQuery = 'SELECT ' + String.join(new List<String>(cleanFields), ', ') + 
                              ', QuoteLineItemGroup.Name, QuoteLineItemGroup.SortOrder' +
                              ' FROM QuoteLineItem WHERE QuoteId = :recordId';
            
            // Add family filter if provided
            if (String.isNotBlank(familyFilter)) {
                soqlQuery += ' AND Product2.Family = :familyFilter';
            }
            
            // Add ordering by group first, then by line item
            soqlQuery += ' ORDER BY QuoteLineItemGroup.SortOrder NULLS LAST, SortOrder, Id';
            
            System.debug('Executing SOQL with Groups: ' + soqlQuery);
            System.debug('Record ID: ' + recordId);
            System.debug('Family Filter: ' + familyFilter);
            
            // Execute the query
            return Database.query(soqlQuery);
            
        } catch (QueryException e) {
            System.debug('QueryException: ' + e.getMessage());
            throw new AuraHandledException('Error querying quote line items with groups: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }
}