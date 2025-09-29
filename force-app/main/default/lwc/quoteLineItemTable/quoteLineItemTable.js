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
    @api field1Header;
    @api field2Header;
    @api field3Header;
    @api field4Header;
    @api field5Header;
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
            field1Header: this.field1Header,
            field2Header: this.field2Header,
            field3Header: this.field3Header,
            field4Header: this.field4Header,
            field5Header: this.field5Header,
            field1Type: typeof this.field1,
            field2Type: typeof this.field2,
            field3Type: typeof this.field3,
            field4Type: typeof this.field4,
            field5Type: typeof this.field5,
            field1Length: this.field1?.length,
            field2Length: this.field2?.length,
            field1Value: JSON.stringify(this.field1),
            field2Value: JSON.stringify(this.field2)
        });
        
        const fields = [];
        if (this.field1 && String(this.field1).trim()) {
            console.log('XXXXAdding field1:', this.field1);
            fields.push(String(this.field1).trim());
        }
        if (this.field2 && String(this.field2).trim()) {
            console.log('XXXXAdding field2:', this.field2);
            fields.push(String(this.field2).trim());
        }
        if (this.field3 && String(this.field3).trim()) {
            console.log('XXXXAdding field3:', this.field3);
            fields.push(String(this.field3).trim());
        }
        if (this.field4 && String(this.field4).trim()) {
            console.log('XXXXAdding field4:', this.field4);
            fields.push(String(this.field4).trim());
        }
        if (this.field5 && String(this.field5).trim()) {
            console.log('XXXXAdding field5:', this.field5);
            fields.push(String(this.field5).trim());
        }
        
        console.log('XXXXProcessed fields array:', fields);
        
        // For testing - always use some fields if we have a recordId but no configured fields
        if (fields.length === 0 && this.recordId) {
            console.log('XXXXNo fields configured, using hardcoded test fields');
            // Use commonly available QuoteLineItem fields that match your preview with proper formatting
            fields.push('Product2.Name', 'Quantity', 'UnitPrice', 'TotalPrice', 'Discount');
            console.log('XXXXUsing hardcoded fields:', fields);
        }
        
        console.log('XXXXFinal configured fields:', fields);
        
        return fields;
    }

    // Get column headers for the table with processed data
    get tableHeaders() {
        const customHeaders = [this.field1Header, this.field2Header, this.field3Header, this.field4Header, this.field5Header];
        
        const headers = this.configuredFields.map((field, index) => {
            const fieldType = this.getFieldType(field);
            const customHeader = customHeaders[index];
            
            return {
                label: customHeader && customHeader.trim() ? customHeader.trim() : this.formatFieldLabel(field),
                fieldName: field,
                fieldKey: `field${index}`,
                titleKey: `fieldTitle${index}`,
                key: `header_${index}`,
                isCurrency: fieldType === 'currency',
                isPercent: fieldType === 'percent',
                isNumber: fieldType === 'number',
                isDate: fieldType === 'date',
                isText: fieldType === 'text'
            };
        });
        
        // Ensure we always have 5 headers for template safety, but only for the fields that exist
        // This allows safe access to tableHeaders[0] through tableHeaders[4] in templates
        const allFields = [this.field1, this.field2, this.field3, this.field4, this.field5];
        const allHeaders = [];
        
        for (let i = 0; i < 5; i++) {
            if (i < headers.length) {
                allHeaders.push(headers[i]);
            } else {
                const customHeader = customHeaders[i];
                allHeaders.push({
                    label: customHeader && customHeader.trim() ? customHeader.trim() : '',
                    fieldName: allFields[i] || '',
                    fieldKey: `field${i}`,
                    titleKey: `fieldTitle${i}`,
                    key: `header_${i}`,
                    isCurrency: false,
                    isPercent: false,
                    isNumber: false,
                    isDate: false,
                    isText: true
                });
            }
        }
        
        return allHeaders;
    }

    // Individual field type getters for template use
    get field1IsCurrency() { return this.tableHeaders[0]?.isCurrency || false; }
    get field1IsPercent() { return this.tableHeaders[0]?.isPercent || false; }
    get field1IsNumber() { return this.tableHeaders[0]?.isNumber || false; }
    get field1IsDate() { return this.tableHeaders[0]?.isDate || false; }

    get field2IsCurrency() { return this.tableHeaders[1]?.isCurrency || false; }
    get field2IsPercent() { return this.tableHeaders[1]?.isPercent || false; }
    get field2IsNumber() { return this.tableHeaders[1]?.isNumber || false; }
    get field2IsDate() { return this.tableHeaders[1]?.isDate || false; }

    get field3IsCurrency() { return this.tableHeaders[2]?.isCurrency || false; }
    get field3IsPercent() { return this.tableHeaders[2]?.isPercent || false; }
    get field3IsNumber() { return this.tableHeaders[2]?.isNumber || false; }
    get field3IsDate() { return this.tableHeaders[2]?.isDate || false; }

    get field4IsCurrency() { return this.tableHeaders[3]?.isCurrency || false; }
    get field4IsPercent() { return this.tableHeaders[3]?.isPercent || false; }
    get field4IsNumber() { return this.tableHeaders[3]?.isNumber || false; }
    get field4IsDate() { return this.tableHeaders[3]?.isDate || false; }

    get field5IsCurrency() { return this.tableHeaders[4]?.isCurrency || false; }
    get field5IsPercent() { return this.tableHeaders[4]?.isPercent || false; }
    get field5IsNumber() { return this.tableHeaders[4]?.isNumber || false; }
    get field5IsDate() { return this.tableHeaders[4]?.isDate || false; }

    // Individual header label getters for template use
    get field1Label() { return this.tableHeaders[0]?.label || ''; }
    get field2Label() { return this.tableHeaders[1]?.label || ''; }
    get field3Label() { return this.tableHeaders[2]?.label || ''; }
    get field4Label() { return this.tableHeaders[3]?.label || ''; }
    get field5Label() { return this.tableHeaders[4]?.label || ''; }

    // Determine field type for proper formatting
    getFieldType(fieldName) {
        if (!fieldName) return 'text';
        
        const lowerField = fieldName.toLowerCase();
        
        // Currency fields
        if (lowerField.includes('price') || lowerField.includes('cost') || lowerField === 'subtotal') {
            return 'currency';
        }
        
        // Percentage fields
        if (lowerField.includes('discount') || lowerField.includes('percent')) {
            return 'percent';
        }
        
        // Number fields
        if (lowerField === 'quantity' || lowerField === 'linenumber' || lowerField === 'sortorder') {
            return 'number';
        }
        
        // Date fields
        if (lowerField.includes('date') || lowerField.includes('time')) {
            return 'date';
        }
        
        // Default to text
        return 'text';
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
        console.log('XXXXWire method called with parameters:', { 
            recordId: this.recordId, 
            recordIdType: typeof this.recordId,
            fields: this.configuredFields, 
            familyFilter: this.familyFilter,
            hasRecordId: !!this.recordId,
            hasFields: this.configuredFields && this.configuredFields.length > 0,
            fieldsLength: this.configuredFields?.length,
            parametersForWire: {
                recordId: this.recordId, 
                fields: this.configuredFields, 
                familyFilter: this.familyFilter
            }
        });
        console.log('XXXXWire data received:', data);
        console.log('XXXXWire error received:', error);
        
        if (data) {
            console.log('XXXXReceived data from Apex:', data);
            this.quoteLineItems = this.processQuoteLineItems(data);
            this.error = undefined;
            this.isLoading = false;
            console.log('XXXXProcessed items:', this.quoteLineItems);
        } else if (error) {
            this.error = error;
            this.quoteLineItems = [];
            this.isLoading = false;
            console.log('XXXXError occurred:', error);
            console.log('XXXXError body:', error.body);
            console.log('XXXXError message:', error.body?.message);
            console.log('XXXXFull error object:', JSON.stringify(error, null, 2));
        } else {
            // No data and no error – still loading or waiting for parameters
            this.quoteLineItems = [];
            this.error = undefined;
            console.log('XXXXNo data and no error – wire method waiting for parameters');
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

        // Test imperative call after a short delay to let properties settle
        setTimeout(() => {
            this.testImperativeCall();
        }, 2000);
    }

    // Test method to call Apex imperatively
    @api
    testImperativeCall() {
        console.log('XXXXTesting imperative call to Apex');
        if (this.recordId && this.configuredFields.length > 0) {
            console.log('XXXXCalling Apex imperatively with:', {
                recordId: this.recordId,
                fields: this.configuredFields,
                familyFilter: this.familyFilter
            });
            
            getQuoteLineItems({
                recordId: this.recordId,
                fields: this.configuredFields,
                familyFilter: this.familyFilter
            })
            .then(result => {
                console.log('XXXXImperative call SUCCESS:', result);
                this.quoteLineItems = this.processQuoteLineItems(result);
                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                console.log('XXXXImperative call ERROR:', error);
                this.error = error;
                this.quoteLineItems = [];
                this.isLoading = false;
            });
        } else {
            console.log('XXXXSkipping imperative call - missing recordId or fields');
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