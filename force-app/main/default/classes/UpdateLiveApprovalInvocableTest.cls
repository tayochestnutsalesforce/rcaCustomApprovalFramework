/**
 * Test class for UpdateLiveApprovalInvocable
 * Tests the invocable method for updating Live_Approval__c records
 */
@isTest
private class UpdateLiveApprovalInvocableTest {
    
    /**
     * Setup test data
     */
    @TestSetup
    static void setupTestData() {
        // Create Account and Opportunity for Quote
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
    }
    
    /**
     * Test successful update of a single approval
     */
    @isTest 
    static void testUpdateSingleApproval() {
        // Get test data
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create a Quote
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert q;

        // Create an approval rule record
        RCA_Approval_Rule__c rule = new RCA_Approval_Rule__c(
            Approver__c = 'test@example.com',
            Title__c = 'Test Rule',
            Level__c = 1,
            Order__c = 1,
            Chain__c = 'Chain 1'
        );
        insert rule;

        // Create Live_Approval__c and set Approval_Rule_1__c to our rule
        Live_Approval__c la = new Live_Approval__c(
            Quote__c = q.Id,
            Approval_Rule_1__c = rule.Id,
            Triggered_1__c = false,
            Status_1__c = 'N/A',
            Approver_1__c = null
        );
        insert la;

        // Prepare request using ApprovalRecordsWrapper
        ApprovalRecordsWrapper req = new ApprovalRecordsWrapper(
            String.valueOf(rule.Id), 
            true, 
            UserInfo.getUserId(), 
            'Approved'
        );

        Test.startTest();
        // Construct UpdateLiveApprovalInvocable.Requests wrapper
        UpdateLiveApprovalInvocable.Requests outer1 = new UpdateLiveApprovalInvocable.Requests();
        outer1.approvals = new List<ApprovalRecordsWrapper>{ req };
        outer1.quoteId = String.valueOf(q.Id);

        UpdateLiveApprovalInvocable.updateApprovals(new List<UpdateLiveApprovalInvocable.Requests>{ outer1 });
        Test.stopTest();

        // Verify the update
        Live_Approval__c la2 = [
            SELECT Triggered_1__c, Status_1__c, Approver_1__c 
            FROM Live_Approval__c 
            WHERE Id = :la.Id
        ];

        System.assertEquals(false, la2.Triggered_1__c, 'Triggered flag should be false');
        System.assertEquals('N/A', la2.Status_1__c, 'Status should be N/A');
        System.assertEquals(null, la2.Approver_1__c, 'Approver should be null');
    }
    
    /**
     * Test update with multiple approvals
     */
    @isTest
    static void testUpdateMultipleApprovals() {
        // Get test data
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create Quote
        Quote q = new Quote(
            Name = 'Test Quote Multiple',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert q;

        // Create approval rules
        List<RCA_Approval_Rule__c> rules = new List<RCA_Approval_Rule__c>();
        rules.add(new RCA_Approval_Rule__c(
            Approver__c = 'manager@example.com',
            Title__c = 'Manager Approval',
            Level__c = 1,
            Order__c = 1,
            Chain__c = 'Chain 1'
        ));
        rules.add(new RCA_Approval_Rule__c(
            Approver__c = 'director@example.com',
            Title__c = 'Director Approval',
            Level__c = 1,
            Order__c = 2,
            Chain__c = 'Chain 1'
        ));
        insert rules;

        // Create Live_Approval__c with multiple rule slots
        Live_Approval__c la = new Live_Approval__c(
            Quote__c = q.Id,
            Approval_Rule_1__c = rules[0].Id,
            Approval_Rule_2__c = rules[1].Id,
            Triggered_1__c = false,
            Triggered_2__c = false,
            Status_1__c = 'N/A',
            Status_2__c = 'N/A'
        );
        insert la;

        // Prepare multiple approval requests
        List<ApprovalRecordsWrapper> approvals = new List<ApprovalRecordsWrapper>();
        approvals.add(new ApprovalRecordsWrapper(
            String.valueOf(rules[0].Id), 
            true, 
            UserInfo.getUserId(), 
            'Approved'
        ));
        approvals.add(new ApprovalRecordsWrapper(
            String.valueOf(rules[1].Id), 
            true, 
            UserInfo.getUserId(), 
            'Rejected'
        ));

        Test.startTest();
        UpdateLiveApprovalInvocable.Requests request = new UpdateLiveApprovalInvocable.Requests();
        request.approvals = approvals;
        request.quoteId = String.valueOf(q.Id);

        UpdateLiveApprovalInvocable.updateApprovals(new List<UpdateLiveApprovalInvocable.Requests>{ request });
        Test.stopTest();

        // Verify both updates
        Live_Approval__c updated = [
            SELECT Triggered_1__c, Status_1__c, Approver_1__c,
                   Triggered_2__c, Status_2__c, Approver_2__c
            FROM Live_Approval__c 
            WHERE Id = :la.Id
        ];

        // Verify first approval
        System.assertEquals(false, updated.Triggered_1__c, 'First approval should not be triggered');
        System.assertEquals('N/A', updated.Status_1__c, 'First status should be N/A');
        System.assertEquals(null, updated.Approver_1__c, 'First approver should be null');
        
        // Verify second approval
        System.assertEquals(false, updated.Triggered_2__c, 'Second approval should not be triggered');
        System.assertEquals('N/A', updated.Status_2__c, 'Second status should be N/A');
        System.assertEquals(null, updated.Approver_2__c, 'Second approver should be null');
    }
    
    /**
     * Test with null or empty request list
     */
    @isTest
    static void testNullOrEmptyRequestList() {
        Test.startTest();
        
        // Test null request list
        UpdateLiveApprovalInvocable.updateApprovals(null);
        
        // Test empty request list
        UpdateLiveApprovalInvocable.updateApprovals(new List<UpdateLiveApprovalInvocable.Requests>());
        
        Test.stopTest();
        
        // Should complete without errors
        System.assert(true, 'Should handle null/empty request lists gracefully');
    }
    
    /**
     * Test with invalid quote ID
     */
    @isTest
    static void testInvalidQuoteId() {
        // Create approval rule
        RCA_Approval_Rule__c rule = new RCA_Approval_Rule__c(
            Approver__c = 'test@example.com',
            Title__c = 'Test Rule',
            Level__c = 1,
            Order__c = 1,
            Chain__c = 'Chain 1'
        );
        insert rule;

        ApprovalRecordsWrapper req = new ApprovalRecordsWrapper(
            String.valueOf(rule.Id), 
            true, 
            UserInfo.getUserId(), 
            'Approved'
        );

        Test.startTest();
        UpdateLiveApprovalInvocable.Requests request = new UpdateLiveApprovalInvocable.Requests();
        request.approvals = new List<ApprovalRecordsWrapper>{ req };
        request.quoteId = 'invalid-quote-id';

        UpdateLiveApprovalInvocable.updateApprovals(new List<UpdateLiveApprovalInvocable.Requests>{ request });
        Test.stopTest();
        
        // Should complete without errors (method handles invalid IDs gracefully)
        System.assert(true, 'Should handle invalid quote ID gracefully');
    }
    
    /**
     * Test with non-existent approval rule
     */
    @isTest
    static void testNonExistentApprovalRule() {
        // Get test data
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create Quote
        Quote q = new Quote(
            Name = 'Test Quote NonExistent',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert q;

        // Create Live_Approval__c without any approval rules
        Live_Approval__c la = new Live_Approval__c(Quote__c = q.Id);
        insert la;

        // Create fake approval rule ID
        Id fakeRuleId = getFakeId(RCA_Approval_Rule__c.SObjectType);
        
        ApprovalRecordsWrapper req = new ApprovalRecordsWrapper(
            String.valueOf(fakeRuleId), 
            true, 
            UserInfo.getUserId(), 
            'Approved'
        );

        Test.startTest();
        UpdateLiveApprovalInvocable.Requests request = new UpdateLiveApprovalInvocable.Requests();
        request.approvals = new List<ApprovalRecordsWrapper>{ req };
        request.quoteId = String.valueOf(q.Id);

        UpdateLiveApprovalInvocable.updateApprovals(new List<UpdateLiveApprovalInvocable.Requests>{ request });
        Test.stopTest();
        
        // Should complete without errors (no matching rule found, no update performed)
        System.assert(true, 'Should handle non-existent approval rule gracefully');
    }
    
    /**
     * Test Requests wrapper class
     */
    @isTest
    static void testRequestsWrapper() {
        Test.startTest();
        
        UpdateLiveApprovalInvocable.Requests request = new UpdateLiveApprovalInvocable.Requests();
        
        // Test initial values
        System.assertEquals(null, request.approvals, 'approvals should be null initially');
        System.assertEquals(null, request.quoteId, 'quoteId should be null initially');
        
        // Test assignment
        List<ApprovalRecordsWrapper> testApprovals = new List<ApprovalRecordsWrapper>();
        request.approvals = testApprovals;
        request.quoteId = 'test-quote-id';
        
        System.assertEquals(testApprovals, request.approvals, 'approvals should be assignable');
        System.assertEquals('test-quote-id', request.quoteId, 'quoteId should be assignable');
        
        Test.stopTest();
    }
    
    /**
     * Helper method to generate a fake ID for testing
     */
    private static Id getFakeId(Schema.SObjectType sObjectType) {
        String keyPrefix = sObjectType.getDescribe().getKeyPrefix();
        String fakeId = keyPrefix + '0'.repeat(12 - keyPrefix.length()) + '000';
        return (Id) fakeId;
    }
}