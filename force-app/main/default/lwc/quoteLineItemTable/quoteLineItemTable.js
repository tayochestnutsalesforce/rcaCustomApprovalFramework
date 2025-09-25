import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getQuoteLineItems from '@salesforce/apex/QuoteLineItemController.getQuoteLineItems';

export default class QuoteLineItemTable extends LightningElement {
    @api recordId;
    @api field1;
    @api field2;
    @api field3;
    @api field4;
    @api field5;
    @api familyFilter;

    @track quoteLineItems = [];
    @track error;
    @track isLoading = false;

    // Get the fields that are configured
    get configuredFields() {
        const fields = [];
        if (this.field1) fields.push(this.field1);
        if (this.field2) fields.push(this.field2);
        if (this.field3) fields.push(this.field3);
        if (this.field4) fields.push(this.field4);
        if (this.field5) fields.push(this.field5);
        return fields;
    }

    // Get column headers for the table
    get tableHeaders() {
        return this.configuredFields.map(field => ({
            label: this.formatFieldLabel(field),
            fieldName: field
        }));
    }

    // Get the table title with family filter
    get tableTitle() {
        return this.familyFilter ? `Quote Line Items - ${this.familyFilter}` : 'Quote Line Items';
    }

    // Check if we have data to display
    get hasData() {
        return this.quoteLineItems && this.quoteLineItems.length > 0;
    }

    // Wire to get quote line items when recordId or other properties change
    @wire(getQuoteLineItems, { 
        quoteId: '$recordId', 
        fields: '$configuredFields', 
        familyFilter: '$familyFilter' 
    })
    wiredQuoteLineItems({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.quoteLineItems = this.processQuoteLineItems(data);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.quoteLineItems = [];
        }
    }

    // Process the data to ensure proper field access
    processQuoteLineItems(data) {
        if (!data || !Array.isArray(data)) return [];
        
        return data.map(item => {
            const processedItem = { ...item };
            // Ensure all configured fields are accessible
            this.configuredFields.forEach(field => {
                if (!(field in processedItem)) {
                    processedItem[field] = this.getFieldValue(item, field);
                }
            });
            return processedItem;
        });
    }

    // Format field names for display
    formatFieldLabel(fieldName) {
        if (!fieldName) return '';
        
        // Handle common field patterns
        if (fieldName.includes('.')) {
            const parts = fieldName.split('.');
            fieldName = parts[parts.length - 1];
        }
        
        // Remove __c suffix for custom fields
        if (fieldName.endsWith('__c')) {
            fieldName = fieldName.substring(0, fieldName.length - 3);
        }
        
        // Convert camelCase or underscore to readable format
        return fieldName
            .replace(/([A-Z])/g, ' $1')
            .replace(/_/g, ' ')
            .replace(/\b\w/g, l => l.toUpperCase())
            .trim();
    }

    // Get field value from record
    getFieldValue(record, fieldName) {
        if (!record || !fieldName) return '';
        
        // Handle nested field references (e.g., Account.Name)
        if (fieldName.includes('.')) {
            const parts = fieldName.split('.');
            let value = record;
            for (const part of parts) {
                value = value && value[part];
                if (value === undefined || value === null) break;
            }
            return value || '';
        }
        
        return record[fieldName] || '';
    }

    connectedCallback() {
        // Set loading state when component initializes
        if (this.recordId && this.configuredFields.length > 0) {
            this.isLoading = true;
        }
    }
}