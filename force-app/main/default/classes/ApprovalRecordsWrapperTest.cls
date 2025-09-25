/**
 * Test class for ApprovalRecordsWrapper
 * Tests the wrapper class properties, constructors, and serialization behavior
 */
@isTest
private class ApprovalRecordsWrapperTest {
    
    /**
     * Test the no-arg constructor
     */
    @isTest
    static void testNoArgConstructor() {
        Test.startTest();
        ApprovalRecordsWrapper wrapper = new ApprovalRecordsWrapper();
        Test.stopTest();
        
        // Verify all fields are null after using no-arg constructor
        System.assertEquals(null, wrapper.approvalRuleId, 'approvalRuleId should be null');
        System.assertEquals(null, wrapper.triggeringStatus, 'triggeringStatus should be null');
        System.assertEquals(null, wrapper.approver, 'approver should be null');
        System.assertEquals(null, wrapper.approvalStatus, 'approvalStatus should be null');
    }
    
    /**
     * Test the convenience constructor with all parameters
     */
    @isTest
    static void testConvenienceConstructor() {
        String testApprovalRuleId = 'a001234567890ABC';
        Boolean testTriggeringStatus = true;
        String testApprover = UserInfo.getUserId();
        String testApprovalStatus = 'Pending';
        
        Test.startTest();
        ApprovalRecordsWrapper wrapper = new ApprovalRecordsWrapper(
            testApprovalRuleId, 
            testTriggeringStatus, 
            testApprover, 
            testApprovalStatus
        );
        Test.stopTest();
        
        // Verify all fields are set correctly
        System.assertEquals(testApprovalRuleId, wrapper.approvalRuleId, 'approvalRuleId should match constructor parameter');
        System.assertEquals(testTriggeringStatus, wrapper.triggeringStatus, 'triggeringStatus should match constructor parameter');
        System.assertEquals(testApprover, wrapper.approver, 'approver should match constructor parameter');
        System.assertEquals(testApprovalStatus, wrapper.approvalStatus, 'approvalStatus should match constructor parameter');
    }
    
    /**
     * Test convenience constructor with null values
     */
    @isTest
    static void testConvenienceConstructorWithNulls() {
        Test.startTest();
        ApprovalRecordsWrapper wrapper = new ApprovalRecordsWrapper(null, null, null, null);
        Test.stopTest();
        
        // Verify all fields are null
        System.assertEquals(null, wrapper.approvalRuleId, 'approvalRuleId should be null');
        System.assertEquals(null, wrapper.triggeringStatus, 'triggeringStatus should be null');
        System.assertEquals(null, wrapper.approver, 'approver should be null');
        System.assertEquals(null, wrapper.approvalStatus, 'approvalStatus should be null');
    }
    
    /**
     * Test field assignment after construction
     */
    @isTest
    static void testFieldAssignment() {
        ApprovalRecordsWrapper wrapper = new ApprovalRecordsWrapper();
        
        String testApprovalRuleId = 'a001234567890XYZ';
        Boolean testTriggeringStatus = false;
        String testApprover = '0051234567890ABC';
        String testApprovalStatus = 'Approved';
        
        Test.startTest();
        wrapper.approvalRuleId = testApprovalRuleId;
        wrapper.triggeringStatus = testTriggeringStatus;
        wrapper.approver = testApprover;
        wrapper.approvalStatus = testApprovalStatus;
        Test.stopTest();
        
        // Verify fields can be assigned and retrieved
        System.assertEquals(testApprovalRuleId, wrapper.approvalRuleId, 'approvalRuleId should be assignable');
        System.assertEquals(testTriggeringStatus, wrapper.triggeringStatus, 'triggeringStatus should be assignable');
        System.assertEquals(testApprover, wrapper.approver, 'approver should be assignable');
        System.assertEquals(testApprovalStatus, wrapper.approvalStatus, 'approvalStatus should be assignable');
    }
    
    /**
     * Test different approval status values
     */
    @isTest
    static void testDifferentApprovalStatusValues() {
        List<String> statusValues = new List<String>{'Pending', 'Approved', 'Rejected', 'N/A', 'In Progress'};
        
        Test.startTest();
        for (String status : statusValues) {
            ApprovalRecordsWrapper wrapper = new ApprovalRecordsWrapper(
                'testRuleId', 
                true, 
                'testApprover', 
                status
            );
            System.assertEquals(status, wrapper.approvalStatus, 'Should handle status: ' + status);
        }
        Test.stopTest();
    }
    
    /**
     * Test boolean values for triggeringStatus
     */
    @isTest
    static void testTriggeringStatusBooleanValues() {
        Test.startTest();
        
        // Test true value
        ApprovalRecordsWrapper wrapper1 = new ApprovalRecordsWrapper('rule1', true, 'approver1', 'status1');
        System.assertEquals(true, wrapper1.triggeringStatus, 'Should handle true value');
        
        // Test false value
        ApprovalRecordsWrapper wrapper2 = new ApprovalRecordsWrapper('rule2', false, 'approver2', 'status2');
        System.assertEquals(false, wrapper2.triggeringStatus, 'Should handle false value');
        
        // Test null value
        ApprovalRecordsWrapper wrapper3 = new ApprovalRecordsWrapper('rule3', null, 'approver3', 'status3');
        System.assertEquals(null, wrapper3.triggeringStatus, 'Should handle null value');
        
        Test.stopTest();
    }
    
    /**
     * Test JSON serialization/deserialization (important for Flow integration)
     */
    @isTest
    static void testJSONSerialization() {
        String testApprovalRuleId = 'a001234567890DEF';
        Boolean testTriggeringStatus = true;
        String testApprover = UserInfo.getUserId();
        String testApprovalStatus = 'Pending Review';
        
        ApprovalRecordsWrapper originalWrapper = new ApprovalRecordsWrapper(
            testApprovalRuleId, 
            testTriggeringStatus, 
            testApprover, 
            testApprovalStatus
        );
        
        Test.startTest();
        
        // Serialize to JSON
        String jsonString = JSON.serialize(originalWrapper);
        System.assertNotEquals(null, jsonString, 'JSON serialization should not be null');
        System.assert(jsonString.contains(testApprovalRuleId), 'JSON should contain approvalRuleId');
        System.assert(jsonString.contains(testApprovalStatus), 'JSON should contain approvalStatus');
        
        // Deserialize from JSON
        ApprovalRecordsWrapper deserializedWrapper = 
            (ApprovalRecordsWrapper) JSON.deserialize(jsonString, ApprovalRecordsWrapper.class);
        
        Test.stopTest();
        
        // Verify deserialized object matches original
        System.assertEquals(originalWrapper.approvalRuleId, deserializedWrapper.approvalRuleId, 
            'Deserialized approvalRuleId should match original');
        System.assertEquals(originalWrapper.triggeringStatus, deserializedWrapper.triggeringStatus, 
            'Deserialized triggeringStatus should match original');
        System.assertEquals(originalWrapper.approver, deserializedWrapper.approver, 
            'Deserialized approver should match original');
        System.assertEquals(originalWrapper.approvalStatus, deserializedWrapper.approvalStatus, 
            'Deserialized approvalStatus should match original');
    }
    
    /**
     * Test wrapper in a collection (List) context
     */
    @isTest
    static void testWrapperInCollection() {
        List<ApprovalRecordsWrapper> wrapperList = new List<ApprovalRecordsWrapper>();
        
        Test.startTest();
        
        // Add multiple wrappers to list
        wrapperList.add(new ApprovalRecordsWrapper('rule1', true, 'approver1', 'Pending'));
        wrapperList.add(new ApprovalRecordsWrapper('rule2', false, 'approver2', 'Approved'));
        wrapperList.add(new ApprovalRecordsWrapper('rule3', null, null, null));
        
        Test.stopTest();
        
        // Verify collection operations
        System.assertEquals(3, wrapperList.size(), 'List should contain 3 wrappers');
        
        // Verify first wrapper
        System.assertEquals('rule1', wrapperList[0].approvalRuleId, 'First wrapper approvalRuleId should match');
        System.assertEquals(true, wrapperList[0].triggeringStatus, 'First wrapper triggeringStatus should match');
        System.assertEquals('approver1', wrapperList[0].approver, 'First wrapper approver should match');
        System.assertEquals('Pending', wrapperList[0].approvalStatus, 'First wrapper approvalStatus should match');
        
        // Verify third wrapper (with nulls)
        System.assertEquals('rule3', wrapperList[2].approvalRuleId, 'Third wrapper approvalRuleId should match');
        System.assertEquals(null, wrapperList[2].triggeringStatus, 'Third wrapper triggeringStatus should be null');
        System.assertEquals(null, wrapperList[2].approver, 'Third wrapper approver should be null');
        System.assertEquals(null, wrapperList[2].approvalStatus, 'Third wrapper approvalStatus should be null');
    }
    
    /**
     * Test wrapper with realistic Salesforce ID values
     */
    @isTest
    static void testWithRealisticSalesforceIds() {
        // Create test data for realistic IDs
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Test.startTest();
        
        ApprovalRecordsWrapper wrapper = new ApprovalRecordsWrapper();
        wrapper.approvalRuleId = String.valueOf(testAccount.Id); // Using Account ID as mock approval rule ID
        wrapper.triggeringStatus = true;
        wrapper.approver = String.valueOf(currentUser.Id);
        wrapper.approvalStatus = 'Awaiting Manager Approval';
        
        Test.stopTest();
        
        // Verify Salesforce ID format handling
        System.assertEquals(18, wrapper.approvalRuleId.length(), 'Salesforce ID should be 18 characters');
        System.assertEquals(18, wrapper.approver.length(), 'User ID should be 18 characters');
        System.assert(wrapper.approvalRuleId.startsWith(testAccount.Id.getSObjectType().getDescribe().getKeyPrefix()), 
            'Should start with Account key prefix');
        System.assert(wrapper.approver.startsWith('005'), 'User ID should start with 005');
    }
    
    /**
     * Test wrapper field data types and annotations
     */
    @isTest
    static void testFieldDataTypesAndAnnotations() {
        ApprovalRecordsWrapper wrapper = new ApprovalRecordsWrapper();
        
        Test.startTest();
        
        // Test String fields can handle various string lengths
        wrapper.approvalRuleId = 'a'.repeat(255); // Long string
        wrapper.approver = ''; // Empty string
        wrapper.approvalStatus = 'Single'; // Short string
        
        // Test Boolean field
        wrapper.triggeringStatus = true;
        
        Test.stopTest();
        
        // // Verify data types are maintained
        // System.assert(wrapper.approvalRuleId instanceof String, 'approvalRuleId should be String type');
        // System.assert(wrapper.triggeringStatus instanceof Boolean, 'triggeringStatus should be Boolean type');
        // System.assert(wrapper.approver instanceof String, 'approver should be String type');
        // System.assert(wrapper.approvalStatus instanceof String, 'approvalStatus should be String type');
        
        // Verify values
        System.assertEquals(255, wrapper.approvalRuleId.length(), 'Should handle long strings');
        System.assertEquals('', wrapper.approver, 'Should handle empty strings');
        System.assertEquals('Single', wrapper.approvalStatus, 'Should handle regular strings');
        System.assertEquals(true, wrapper.triggeringStatus, 'Should handle boolean values');
    }
}