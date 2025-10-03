/**
 * Invocable Apex class that can dynamically call a Flow and pass/receive approval data.
 * This class accepts an RCA_Approval_Rule__c record and a Flow name, executes the Flow,
 * and returns an ApprovalRecordsWrapper object.
 */
global class FlowInvokerApex {
    
    /**
     * Input parameters for the invocable method
     */
    global class FlowInvokerInput {
        @InvocableVariable(label='Approval Rule Record' description='RCA Approval Rule record to pass to the Flow' required=true)
        global RCA_Approval_Rule__c approvalRule;
        
        @InvocableVariable(label='Flow Name' description='Name of the Flow to execute' required=true)
        global String flowName;
        
        @InvocableVariable(label='Record Id' description='ID of the record being processed' required=true)
        global String recordId;
        
        @InvocableVariable(label='Quote Record' description='Quote record to pass to the Flow' required=false)
        global Quote quoteRecord;
        
        @InvocableVariable(label='Quote Line Items' description='List of QuoteLineItem records to pass to the Flow' required=false)
        global List<QuoteLineItem> quoteLineItems;
        
        @InvocableVariable(label='Quote Line Groups' description='List of QuoteLineGroup records to pass to the Flow' required=false)
        global List<QuoteLineGroup> quoteLineGroups;
    }
    
    /**
     * Output wrapper for the invocable method
     */
    global class FlowInvokerOutput {
        @InvocableVariable(label='Approval Records Wrapper' description='Result from the Flow execution')
        global ApprovalRecordsWrapper approvalRecordsWrapper;
        
        @InvocableVariable(label='Success' description='Whether the Flow execution was successful')
        global Boolean isSuccess;
        
        @InvocableVariable(label='Error Message' description='Error message if execution failed')
        global String errorMessage;
        
        @InvocableVariable(label='Triggered' description='Whether the approval was triggered')
        global Boolean triggered;
        
        @InvocableVariable(label='Approver' description='The approver for the approval')
        global String approver;
    }
    
    /**
     * Invocable method that executes a Flow dynamically with approval rule data
     * @param inputs List of FlowInvokerInput containing approval rule and flow name
     * @return List of FlowInvokerOutput containing the result
     */
    @InvocableMethod(label='Invoke Flow with Approval Rule' description='Dynamically calls a Flow with approval rule data and returns ApprovalRecordsWrapper')
    global static List<FlowInvokerOutput> invokeFlowWithApprovalRule(List<FlowInvokerInput> inputs) {
        List<FlowInvokerOutput> outputs = new List<FlowInvokerOutput>();
        
        for (FlowInvokerInput input : inputs) {
            FlowInvokerOutput output = new FlowInvokerOutput();
            output.isSuccess = false;
            
            try {
                // Validate inputs
                if (input.approvalRule == null) {
                    throw new IllegalArgumentException('Approval Rule record cannot be null');
                }
                
                if (String.isBlank(input.flowName)) {
                    throw new IllegalArgumentException('Flow Name cannot be blank');
                }
                
                if (String.isBlank(input.recordId)) {
                    throw new IllegalArgumentException('Record Id cannot be blank');
                }
                
                // Execute the Flow dynamically
                FlowResult flowResult = executeFlow(input.flowName, input.approvalRule, input.recordId, input.quoteRecord, input.quoteLineItems, input.quoteLineGroups);
                output.approvalRecordsWrapper = flowResult.approvalRecordsWrapper;
                output.triggered = flowResult.triggered;
                output.approver = flowResult.approver;
                output.isSuccess = flowResult.isSuccess;
                output.errorMessage = flowResult.errorMessage;
                
            } catch (Exception e) {
                output.errorMessage = 'Error executing Flow: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'FlowInvokerApex Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            }
            
            outputs.add(output);
        }
        
        return outputs;
    }
    
    /**
     * Private method to execute the Flow and handle the input/output
     * @param flowName Name of the Flow to execute
     * @param approvalRule The approval rule record to pass to the Flow
     * @param recordId The record ID to pass to the Flow
     * @param quoteRecord The Quote record to pass to the Flow
     * @param quoteLineItems The list of QuoteLineItem records to pass to the Flow
     * @param quoteLineGroups The list of QuoteLineGroup records to pass to the Flow
     * @return FlowResult containing all outputs from the Flow
     */
    private static FlowResult executeFlow(String flowName, RCA_Approval_Rule__c approvalRule, String recordId, Quote quoteRecord, List<QuoteLineItem> quoteLineItems, List<QuoteLineGroup> quoteLineGroups) {
        // Prepare input variables for the Flow
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('approvalRule', approvalRule);
        flowInputs.put('recordId', recordId);
        
        // Add the new optional inputs if they are provided
        if (quoteRecord != null) {
            flowInputs.put('quoteRecord', quoteRecord);
        }
        
        if (quoteLineItems != null && !quoteLineItems.isEmpty()) {
            flowInputs.put('quoteLineItems', quoteLineItems);
        }
        
        if (quoteLineGroups != null && !quoteLineGroups.isEmpty()) {
            flowInputs.put('quoteLineGroups', quoteLineGroups);
        }
        
        // Create and start the Flow interview
        Flow.Interview flowInterview = Flow.Interview.createInterview(flowName, flowInputs);
        
        if (flowInterview == null) {
            throw new FlowException('Failed to create Flow interview for: ' + flowName + '. Please verify the Flow name and that it exists.');
        }
        
        // Start the Flow execution
        flowInterview.start();
        
        // Extract the outputs from the Flow
        FlowResult result = new FlowResult();
        
        // Extract ApprovalRecordsWrapper output
        result.approvalRecordsWrapper = (ApprovalRecordsWrapper) flowInterview.getVariableValue('approvalRecordsWrapper');
        
        // Extract Triggered output
        Object triggeredValue = flowInterview.getVariableValue('triggered');
        result.triggered = triggeredValue != null ? (Boolean) triggeredValue : false;
        
        // Extract Approver output
        Object approverValue = flowInterview.getVariableValue('approver');
        result.approver = approverValue != null ? (String) approverValue : null;
        
        // Extract isSuccess output
        Object isSuccessValue = flowInterview.getVariableValue('isSuccess');
        result.isSuccess = isSuccessValue != null ? (Boolean) isSuccessValue : true;
        
        // Extract errorMessage output
        Object errorMessageValue = flowInterview.getVariableValue('errorMessage');
        result.errorMessage = errorMessageValue != null ? (String) errorMessageValue : null;
        
        return result;
    }
    
    /**
     * Helper class to hold Flow execution results
     */
    private class FlowResult {
        public ApprovalRecordsWrapper approvalRecordsWrapper;
        public Boolean triggered;
        public String approver;
        public Boolean isSuccess;
        public String errorMessage;
    }
    
    /**
     * Custom exception for Flow-related errors
     */
    public class FlowException extends Exception {}
}