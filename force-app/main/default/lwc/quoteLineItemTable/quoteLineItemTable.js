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
    
    // Add property change detection
    @track _previousField1;
    @track _previousField2;
    @track _previousField3;
    @track _previousField4;
    @track _previousField5;

    // Method to manually set fields for testing (can be called from console)
    @api
    setTestFields(field1, field2, field3, field4, field5) {
        console.log('XXXXManually setting test fields:', { field1, field2, field3, field4, field5 });
        this.field1 = field1 || 'Product2.Name';
        this.field2 = field2 || 'Quantity';
        this.field3 = field3 || 'UnitPrice';
        this.field4 = field4 || 'TotalPrice';
        this.field5 = field5;
        
        // Force re-evaluation
        this.requestUpdate();
    }

    // Detect property changes
    checkForPropertyChanges() {
        let hasChanges = false;
        
        if (this._previousField1 !== this.field1) {
            console.log('XXXXField1 changed:', { from: this._previousField1, to: this.field1 });
            this._previousField1 = this.field1;
            hasChanges = true;
        }
        if (this._previousField2 !== this.field2) {
            console.log('XXXXField2 changed:', { from: this._previousField2, to: this.field2 });
            this._previousField2 = this.field2;
            hasChanges = true;
        }
        if (this._previousField3 !== this.field3) {
            console.log('XXXXField3 changed:', { from: this._previousField3, to: this.field3 });
            this._previousField3 = this.field3;
            hasChanges = true;
        }
        if (this._previousField4 !== this.field4) {
            console.log('XXXXField4 changed:', { from: this._previousField4, to: this.field4 });
            this._previousField4 = this.field4;
            hasChanges = true;
        }
        if (this._previousField5 !== this.field5) {
            console.log('XXXXField5 changed:', { from: this._previousField5, to: this.field5 });
            this._previousField5 = this.field5;
            hasChanges = true;
        }
        
        return hasChanges;
    }





    // Get the fields that are configured
    get configuredFields() {
        console.log('xxxx',this.recordId);
        console.log('XXXXConfigured fields getter called');
        console.log('XXXXRaw field properties:', {
            field1: this.field1,
            field2: this.field2,
            field3: this.field3,
            field4: this.field4,
            field5: this.field5,
            field1Type: typeof this.field1,
            field2Type: typeof this.field2,
            field3Type: typeof this.field3,
            field4Type: typeof this.field4,
            field5Type: typeof this.field5
        });
        
        const fields = [];
        if (this.field1 && this.field1.trim()) fields.push(this.field1.trim());
        if (this.field2 && this.field2.trim()) fields.push(this.field2.trim());
        if (this.field3 && this.field3.trim()) fields.push(this.field3.trim());
        if (this.field4 && this.field4.trim()) fields.push(this.field4.trim());
        if (this.field5 && this.field5.trim()) fields.push(this.field5.trim());
        
        console.log('XXXXProcessed fields array:', fields);
        
        // For testing in Document Builder - temporarily hardcode some fields
        // TODO: Remove this after testing
        if (fields.length === 0 && this.recordId) {
            console.log('XXXXNo fields configured, using hardcoded test fields');
            // Use commonly available QuoteLineItem fields
            fields.push('Product2.Name', 'Quantity', 'UnitPrice', 'TotalPrice');
            console.log('XXXXUsing hardcoded fields for Document Builder testing:', fields);
        }
        
        console.log('XXXXFinal configured fields:', fields);
        
        return fields;
    }

    // Get column headers for the table with processed data
    get tableHeaders() {
        return this.configuredFields.map((field, index) => ({
            label: this.formatFieldLabel(field),
            fieldName: field,
            fieldKey: `field${index}`,
            titleKey: `fieldTitle${index}`,
            key: `header_${index}`
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

    // Helper method to get field value safely for templates
    getFieldValueForTemplate(item, fieldKey) {
        return item && item.fieldValues && item.fieldValues[fieldKey] || '';
    }

    // Wire to get quote line items when recordId or other properties change
    @wire(getQuoteLineItems, { 
        recordId: '$recordId', 
        fields: '$configuredFields', 
        familyFilter: '$familyFilter' 
    })
    wiredQuoteLineItems({ error, data }) {
        console.log('XXXXWire method called', { 
            recordId: this.recordId, 
            fields: this.configuredFields, 
            familyFilter: this.familyFilter 
        });
        console.log('XXXXWire data:', data);
        console.log('XXXXWire error:', error);
        
        if (data) {
            this.quoteLineItems = this.processQuoteLineItems(data);
            this.error = undefined;
            this.isLoading = false;
            console.log('XXXXProcessed items:', this.quoteLineItems);
        } else if (error) {
            this.error = error;
            this.quoteLineItems = [];
            this.isLoading = false;
            console.log('XXXXError occurred:', error);
        } else {
            // No data and no error – still loading or waiting for parameters
            this.quoteLineItems = [];
            this.error = undefined;
            // Don't set loading to false here - let connectedCallback handle it
            console.log('XXXXNo data and no error – wire method waiting');
        }
    }

    // Process the data to ensure proper field access
    processQuoteLineItems(data) {
        if (!data || !Array.isArray(data)) return [];
        
        return data.map(item => {
            const processedItem = { ...item };
            
            // Create direct field properties to avoid computed property access
            this.configuredFields.forEach((field, index) => {
                const value = this.getFieldValue(item, field);
                // Add as direct properties that can be accessed in template
                processedItem[`field${index}`] = value;
                processedItem[`fieldTitle${index}`] = value; // For title attribute
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
        console.log('XXXXComponent connected', { 
            recordId: this.recordId,
            effectiveRecordId: this.effectiveRecordId,
            field1: this.field1,
            field2: this.field2,
            configuredFields: this.configuredFields 
        });
        
        // Initialize property tracking
        this._previousField1 = this.field1;
        this._previousField2 = this.field2;
        this._previousField3 = this.field3;
        this._previousField4 = this.field4;
        this._previousField5 = this.field5;
        
        // Debug all available properties on this component
        console.log('XXXXAll component properties:', {
            recordId: this.recordId,
            contextRecordId: this.contextRecordId,
            effectiveRecordId: this.effectiveRecordId,
            field1: this.field1,
            field2: this.field2,
            field3: this.field3,
            field4: this.field4,
            field5: this.field5,
            familyFilter: this.familyFilter
        });
        
        // Introspect all properties on this object
        console.log('XXXXAll enumerable properties on this:', Object.keys(this));
        console.log('XXXXAll properties with values:', Object.getOwnPropertyNames(this).filter(prop => this[prop] !== undefined));
        
        // Check if we're in a specific context
        console.log('XXXXWindow location:', window.location.href);
        console.log('XXXXPage reference:', this.pageRef);
        
        // Set loading state when component initializes
        if (this.effectiveRecordId && this.configuredFields.length > 0) {
            this.isLoading = true;
            console.log('XXXXSetting loading to true');
        } else {
            console.log('XXXXNot setting loading - missing recordId or fields', { 
                hasRecordId: !!this.effectiveRecordId, 
                fieldsCount: this.configuredFields.length 
            });
        }
    }

    renderedCallback() {
        // Check for property changes
        const hasChanges = this.checkForPropertyChanges();
        if (hasChanges) {
            console.log('XXXXProperty changes detected in renderedCallback');
        }
    }
}