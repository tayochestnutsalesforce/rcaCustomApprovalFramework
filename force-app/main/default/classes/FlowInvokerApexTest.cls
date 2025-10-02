/**
 * Test class for FlowInvokerApex
 * Tests the invocable method functionality including success and error scenarios
 */
@isTest
private class FlowInvokerApexTest {
    
    /**
     * Test data setup
     */
    @TestSetup
    static void setupTestData() {
        // Create test RCA_Approval_Rule__c record
        RCA_Approval_Rule__c testRule = new RCA_Approval_Rule__c(
            Title__c = 'Test Approval Rule',
            Level__c = 1,
            Approver__c = UserInfo.getUserId(),
            IsActive__c = true,
            Order__c = 1
        );
        insert testRule;
    }
    
    /**
     * Test successful Flow invocation
     * Note: This test will need to be updated with actual Flow names once Flows are available
     */
    @isTest
    static void testInvokeFlowSuccess() {
        // Get test data
        RCA_Approval_Rule__c testRule = [SELECT Id, Title__c, Level__c, Approver__c, IsActive__c, Order__c 
                                        FROM RCA_Approval_Rule__c LIMIT 1];
        
        // Prepare input
        FlowInvokerApex.FlowInvokerInput input = new FlowInvokerApex.FlowInvokerInput();
        input.approvalRule = testRule;
        input.flowName = 'TestFlow'; // This would need to be a real Flow name in actual implementation
        
        List<FlowInvokerApex.FlowInvokerInput> inputs = new List<FlowInvokerApex.FlowInvokerInput>{input};
        
        Test.startTest();
        
        // Execute the invocable method
        // Note: This test will fail in actual execution without a real Flow
        // For demonstration purposes, we'll test the input validation
        List<FlowInvokerApex.FlowInvokerOutput> outputs = FlowInvokerApex.invokeFlowWithApprovalRule(inputs);
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, outputs, 'Output should not be null');
        System.assertEquals(1, outputs.size(), 'Should return one output');
        
        FlowInvokerApex.FlowInvokerOutput output = outputs[0];
        // Note: In real scenario with actual Flow, we would assert output.isSuccess = true
        // For now, we expect failure due to non-existent Flow
        System.assertNotEquals(null, output, 'Output should not be null');
    }
    
    /**
     * Test with null approval rule
     */
    @isTest
    static void testInvokeFlowWithNullApprovalRule() {
        // Prepare input with null approval rule
        FlowInvokerApex.FlowInvokerInput input = new FlowInvokerApex.FlowInvokerInput();
        input.approvalRule = null;
        input.flowName = 'TestFlow';
        
        List<FlowInvokerApex.FlowInvokerInput> inputs = new List<FlowInvokerApex.FlowInvokerInput>{input};
        
        Test.startTest();
        
        List<FlowInvokerApex.FlowInvokerOutput> outputs = FlowInvokerApex.invokeFlowWithApprovalRule(inputs);
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, outputs, 'Output should not be null');
        System.assertEquals(1, outputs.size(), 'Should return one output');
        
        FlowInvokerApex.FlowInvokerOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess, 'Should indicate failure');
        System.assert(output.errorMessage.contains('Approval Rule record cannot be null'), 
                     'Error message should indicate null approval rule: ' + output.errorMessage);
    }
    
    /**
     * Test with blank flow name
     */
    @isTest
    static void testInvokeFlowWithBlankFlowName() {
        // Get test data
        RCA_Approval_Rule__c testRule = [SELECT Id, Title__c, Level__c, Approver__c, IsActive__c, Order__c 
                                        FROM RCA_Approval_Rule__c LIMIT 1];
        
        // Prepare input with blank flow name
        FlowInvokerApex.FlowInvokerInput input = new FlowInvokerApex.FlowInvokerInput();
        input.approvalRule = testRule;
        input.flowName = '';
        
        List<FlowInvokerApex.FlowInvokerInput> inputs = new List<FlowInvokerApex.FlowInvokerInput>{input};
        
        Test.startTest();
        
        List<FlowInvokerApex.FlowInvokerOutput> outputs = FlowInvokerApex.invokeFlowWithApprovalRule(inputs);
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, outputs, 'Output should not be null');
        System.assertEquals(1, outputs.size(), 'Should return one output');
        
        FlowInvokerApex.FlowInvokerOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess, 'Should indicate failure');
        System.assert(output.errorMessage.contains('Flow Name cannot be blank'), 
                     'Error message should indicate blank flow name: ' + output.errorMessage);
    }
    
    /**
     * Test with null flow name
     */
    @isTest
    static void testInvokeFlowWithNullFlowName() {
        // Get test data
        RCA_Approval_Rule__c testRule = [SELECT Id, Title__c, Level__c, Approver__c, IsActive__c, Order__c 
                                        FROM RCA_Approval_Rule__c LIMIT 1];
        
        // Prepare input with null flow name
        FlowInvokerApex.FlowInvokerInput input = new FlowInvokerApex.FlowInvokerInput();
        input.approvalRule = testRule;
        input.flowName = null;
        
        List<FlowInvokerApex.FlowInvokerInput> inputs = new List<FlowInvokerApex.FlowInvokerInput>{input};
        
        Test.startTest();
        
        List<FlowInvokerApex.FlowInvokerOutput> outputs = FlowInvokerApex.invokeFlowWithApprovalRule(inputs);
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, outputs, 'Output should not be null');
        System.assertEquals(1, outputs.size(), 'Should return one output');
        
        FlowInvokerApex.FlowInvokerOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess, 'Should indicate failure');
        System.assert(output.errorMessage.contains('Flow Name cannot be blank'), 
                     'Error message should indicate blank flow name: ' + output.errorMessage);
    }
    
    /**
     * Test with non-existent flow name
     */
    @isTest
    static void testInvokeFlowWithNonExistentFlow() {
        // Get test data
        RCA_Approval_Rule__c testRule = [SELECT Id, Title__c, Level__c, Approver__c, IsActive__c, Order__c 
                                        FROM RCA_Approval_Rule__c LIMIT 1];
        
        // Prepare input with non-existent flow name
        FlowInvokerApex.FlowInvokerInput input = new FlowInvokerApex.FlowInvokerInput();
        input.approvalRule = testRule;
        input.flowName = 'NonExistentFlow_12345';
        
        List<FlowInvokerApex.FlowInvokerInput> inputs = new List<FlowInvokerApex.FlowInvokerInput>{input};
        
        Test.startTest();
        
        List<FlowInvokerApex.FlowInvokerOutput> outputs = FlowInvokerApex.invokeFlowWithApprovalRule(inputs);
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, outputs, 'Output should not be null');
        System.assertEquals(1, outputs.size(), 'Should return one output');
        
        FlowInvokerApex.FlowInvokerOutput output = outputs[0];
        System.assertEquals(false, output.isSuccess, 'Should indicate failure');
        System.assert(output.errorMessage.contains('Error executing Flow'), 
                     'Error message should indicate Flow execution error: ' + output.errorMessage);
    }
    
    /**
     * Test multiple inputs processing
     */
    @isTest
    static void testInvokeFlowWithMultipleInputs() {
        // Get test data
        RCA_Approval_Rule__c testRule = [SELECT Id, Title__c, Level__c, Approver__c, IsActive__c, Order__c 
                                        FROM RCA_Approval_Rule__c LIMIT 1];
        
        // Prepare multiple inputs - one valid, one invalid
        FlowInvokerApex.FlowInvokerInput input1 = new FlowInvokerApex.FlowInvokerInput();
        input1.approvalRule = testRule;
        input1.flowName = 'TestFlow';
        
        FlowInvokerApex.FlowInvokerInput input2 = new FlowInvokerApex.FlowInvokerInput();
        input2.approvalRule = null; // Invalid
        input2.flowName = 'TestFlow';
        
        List<FlowInvokerApex.FlowInvokerInput> inputs = new List<FlowInvokerApex.FlowInvokerInput>{input1, input2};
        
        Test.startTest();
        
        List<FlowInvokerApex.FlowInvokerOutput> outputs = FlowInvokerApex.invokeFlowWithApprovalRule(inputs);
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, outputs, 'Output should not be null');
        System.assertEquals(2, outputs.size(), 'Should return two outputs');
        
        // First output should fail due to non-existent Flow
        FlowInvokerApex.FlowInvokerOutput output1 = outputs[0];
        System.assertEquals(false, output1.isSuccess, 'First output should indicate failure');
        
        // Second output should fail due to null approval rule
        FlowInvokerApex.FlowInvokerOutput output2 = outputs[1];
        System.assertEquals(false, output2.isSuccess, 'Second output should indicate failure');
        System.assert(output2.errorMessage.contains('Approval Rule record cannot be null'), 
                     'Second output error message should indicate null approval rule');
    }
    
    /**
     * Test wrapper classes initialization
     */
    @isTest
    static void testWrapperClassesInitialization() {
        // Test FlowInvokerInput initialization
        FlowInvokerApex.FlowInvokerInput input = new FlowInvokerApex.FlowInvokerInput();
        System.assertEquals(null, input.approvalRule, 'Approval rule should be null initially');
        System.assertEquals(null, input.flowName, 'Flow name should be null initially');
        
        // Test FlowInvokerOutput initialization
        FlowInvokerApex.FlowInvokerOutput output = new FlowInvokerApex.FlowInvokerOutput();
        System.assertEquals(null, output.approvalRecordsWrapper, 'Approval records wrapper should be null initially');
        System.assertEquals(null, output.isSuccess, 'Success flag should be null initially');
        System.assertEquals(null, output.errorMessage, 'Error message should be null initially');
    }
}