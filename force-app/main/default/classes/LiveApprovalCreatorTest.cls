/**
 * Test class for LiveApprovalCreator
 * Tests the invocable method for creating Live_Approval__c records from approval rules
 */
@isTest
private class LiveApprovalCreatorTest {
    
    /**
     * Create test data including Account, Opportunity, Quote, and RCA_Approval_Rule__c records
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
        
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert testQuote;
        
        // Create RCA Approval Rules with different levels and orders
        List<RCA_Approval_Rule__c> approvalRules = new List<RCA_Approval_Rule__c>();
        
        // Level 1, Order 1
        approvalRules.add(new RCA_Approval_Rule__c(
            Chain__c = 'Chain 1',
            Order__c = 1,
            Level__c = 1,
            Title__c = 'Manager Approval',
            Approver_Type__c = 'User',
            Key__c = 'MANAGER_APPROVAL'
        ));
        
        // Level 1, Order 2
        approvalRules.add(new RCA_Approval_Rule__c(
            Chain__c = 'Chain 1',
            Order__c = 2,
            Level__c = 1,
            Title__c = 'Director Approval',
            Approver_Type__c = 'User',
            Key__c = 'DIRECTOR_APPROVAL'
        ));
        
        // Level 2, Order 1
        approvalRules.add(new RCA_Approval_Rule__c(
            Chain__c = 'Chain 2',
            Order__c = 1,
            Level__c = 2,
            Title__c = 'Finance Team Approval',
            Approver_Type__c = 'Queue',
            Key__c = 'FINANCE_APPROVAL'
        ));
        
        // Level 2, Order 3 - for testing ordering
        approvalRules.add(new RCA_Approval_Rule__c(
            Chain__c = 'Chain 2',
            Order__c = 3,
            Level__c = 2,
            Title__c = 'VP Approval',
            Approver_Type__c = 'User',
            Key__c = 'VP_APPROVAL'
        ));
        
        // Level 3, Order 1
        approvalRules.add(new RCA_Approval_Rule__c(
            Chain__c = 'Chain 1',
            Order__c = 1,
            Level__c = 3,
            Title__c = 'Executive Approval',
            Approver_Type__c = 'User',
            Key__c = 'EXECUTIVE_APPROVAL'
        ));
        
        insert approvalRules;
    }
    
    /**
     * Test successful creation of Live_Approval__c with multiple approval rules
     */
    @isTest
    static void testCreateLiveApprovals_Success() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<RCA_Approval_Rule__c> rules = [SELECT Id FROM RCA_Approval_Rule__c ORDER BY Level__c, Order__c];
        
        // Prepare request with multiple approval rule IDs
        LiveApprovalCreator.Requests request = new LiveApprovalCreator.Requests();
        request.quoteId = String.valueOf(testQuote.Id);
        request.approvalRuleIds = new List<String>();
        
        for (RCA_Approval_Rule__c rule : rules) {
            request.approvalRuleIds.add(String.valueOf(rule.Id));
        }
        
        Test.startTest();
        LiveApprovalCreator.createLiveApprovals(new List<LiveApprovalCreator.Requests>{request});
        Test.stopTest();
        
        // Verify Live_Approval__c record was created
        List<Live_Approval__c> liveApprovals = [SELECT Id, Quote__c FROM Live_Approval__c WHERE Quote__c = :testQuote.Id];
        System.assertEquals(1, liveApprovals.size(), 'Should create one Live_Approval__c record');
        System.assertEquals(testQuote.Id, liveApprovals[0].Quote__c, 'Quote__c should match request');
        
        // Verify approval rule fields were populated correctly (ordered by Level__c, Order__c)
        Live_Approval__c la = [
            SELECT Id, 
                   Approval_Rule_1__c, Approval_Rule_2__c, Approval_Rule_3__c, Approval_Rule_4__c, Approval_Rule_5__c,
                   Triggered_1__c, Triggered_2__c, Triggered_3__c, Triggered_4__c, Triggered_5__c,
                   Status_1__c, Status_2__c, Status_3__c, Status_4__c, Status_5__c,
                   Approver_1__c, Approver_2__c, Approver_3__c, Approver_4__c, Approver_5__c
            FROM Live_Approval__c 
            WHERE Quote__c = :testQuote.Id 
            LIMIT 1
        ];
        
        // Should have 5 approval rules populated in slots 1-5
        System.assertNotEquals(null, la.Approval_Rule_1__c, 'Slot 1 should have approval rule');
        System.assertNotEquals(null, la.Approval_Rule_2__c, 'Slot 2 should have approval rule');
        System.assertNotEquals(null, la.Approval_Rule_3__c, 'Slot 3 should have approval rule');
        System.assertNotEquals(null, la.Approval_Rule_4__c, 'Slot 4 should have approval rule');
        System.assertNotEquals(null, la.Approval_Rule_5__c, 'Slot 5 should have approval rule');
        
        // Verify initial field values
        System.assertEquals(false, la.Triggered_1__c, 'Triggered should default to false');
        System.assertEquals(false, la.Triggered_2__c, 'Triggered should default to false');
        System.assertEquals('N/A', la.Status_1__c, 'Status should default to N/A');
        System.assertEquals('N/A', la.Status_2__c, 'Status should default to N/A');
        System.assertEquals(null, la.Approver_1__c, 'Approver should default to null');
        System.assertEquals(null, la.Approver_2__c, 'Approver should default to null');
    }
    
    /**
     * Test creation with null or empty request list
     */
    @isTest
    static void testCreateLiveApprovals_NullOrEmptyRequestList() {
        Test.startTest();
        
        // Test with null request list
        LiveApprovalCreator.createLiveApprovals(null);
        
        // Test with empty request list
        LiveApprovalCreator.createLiveApprovals(new List<LiveApprovalCreator.Requests>());
        
        Test.stopTest();
        
        // Should not create any Live_Approval__c records
        List<Live_Approval__c> liveApprovals = [SELECT Id FROM Live_Approval__c];
        System.assertEquals(0, liveApprovals.size(), 'Should not create any Live_Approval__c records');
    }
    
    /**
     * Test creation with null request object
     */
    @isTest
    static void testCreateLiveApprovals_NullRequest() {
        List<LiveApprovalCreator.Requests> requestList = new List<LiveApprovalCreator.Requests>();
        requestList.add(null);
        
        Test.startTest();
        LiveApprovalCreator.createLiveApprovals(requestList);
        Test.stopTest();
        
        // Should not create any Live_Approval__c records
        List<Live_Approval__c> liveApprovals = [SELECT Id FROM Live_Approval__c];
        System.assertEquals(0, liveApprovals.size(), 'Should not create any Live_Approval__c records for null request');
    }
    
    /**
     * Test creation with null quoteId
     */
    @isTest
    static void testCreateLiveApprovals_NullQuoteId() {
        RCA_Approval_Rule__c rule = [SELECT Id FROM RCA_Approval_Rule__c LIMIT 1];
        
        LiveApprovalCreator.Requests request = new LiveApprovalCreator.Requests();
        request.quoteId = null;
        request.approvalRuleIds = new List<String>{String.valueOf(rule.Id)};
        
        Test.startTest();
        LiveApprovalCreator.createLiveApprovals(new List<LiveApprovalCreator.Requests>{request});
        Test.stopTest();
        
        // Should not create any Live_Approval__c records
        List<Live_Approval__c> liveApprovals = [SELECT Id FROM Live_Approval__c];
        System.assertEquals(0, liveApprovals.size(), 'Should not create any Live_Approval__c records for null quoteId');
    }
    
    /**
     * Test creation with invalid quoteId
     */
    @isTest
    static void testCreateLiveApprovals_InvalidQuoteId() {
        RCA_Approval_Rule__c rule = [SELECT Id FROM RCA_Approval_Rule__c LIMIT 1];
        
        LiveApprovalCreator.Requests request = new LiveApprovalCreator.Requests();
        request.quoteId = 'invalid-id-string';
        request.approvalRuleIds = new List<String>{String.valueOf(rule.Id)};
        
        Test.startTest();
        LiveApprovalCreator.createLiveApprovals(new List<LiveApprovalCreator.Requests>{request});
        Test.stopTest();
        
        // Should not create any Live_Approval__c records
        List<Live_Approval__c> liveApprovals = [SELECT Id FROM Live_Approval__c];
        System.assertEquals(0, liveApprovals.size(), 'Should not create any Live_Approval__c records for invalid quoteId');
    }
    
    /**
     * Test creation with null or empty approval rule IDs
     */
    @isTest
    static void testCreateLiveApprovals_NullOrEmptyApprovalRuleIds() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        // Test with null approvalRuleIds
        LiveApprovalCreator.Requests request1 = new LiveApprovalCreator.Requests();
        request1.quoteId = String.valueOf(testQuote.Id);
        request1.approvalRuleIds = null;
        
        // Test with empty approvalRuleIds
        LiveApprovalCreator.Requests request2 = new LiveApprovalCreator.Requests();
        request2.quoteId = String.valueOf(testQuote.Id);
        request2.approvalRuleIds = new List<String>();
        
        Test.startTest();
        LiveApprovalCreator.createLiveApprovals(new List<LiveApprovalCreator.Requests>{request1, request2});
        Test.stopTest();
        
        // Should create 2 Live_Approval__c records with no approval rule fields populated
        List<Live_Approval__c> liveApprovals = [SELECT Id, Quote__c FROM Live_Approval__c WHERE Quote__c = :testQuote.Id];
        System.assertEquals(2, liveApprovals.size(), 'Should create 2 Live_Approval__c records');
        
        // Verify no approval rule fields are populated
        Live_Approval__c la = [
            SELECT Approval_Rule_1__c, Approval_Rule_2__c 
            FROM Live_Approval__c 
            WHERE Quote__c = :testQuote.Id 
            LIMIT 1
        ];
        System.assertEquals(null, la.Approval_Rule_1__c, 'Should not populate approval rule fields');
        System.assertEquals(null, la.Approval_Rule_2__c, 'Should not populate approval rule fields');
    }
    
    /**
     * Test creation with invalid approval rule IDs
     */
    @isTest
    static void testCreateLiveApprovals_InvalidApprovalRuleIds() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        LiveApprovalCreator.Requests request = new LiveApprovalCreator.Requests();
        request.quoteId = String.valueOf(testQuote.Id);
        request.approvalRuleIds = new List<String>{
            'invalid-id-1',
            null,
            'invalid-id-2',
            ''
        };
        
        Test.startTest();
        LiveApprovalCreator.createLiveApprovals(new List<LiveApprovalCreator.Requests>{request});
        Test.stopTest();
        
        // Should create 1 Live_Approval__c record with no approval rule fields populated
        List<Live_Approval__c> liveApprovals = [SELECT Id, Quote__c FROM Live_Approval__c WHERE Quote__c = :testQuote.Id];
        System.assertEquals(1, liveApprovals.size(), 'Should create 1 Live_Approval__c record');
        
        // Verify no approval rule fields are populated (because all IDs were invalid)
        Live_Approval__c la = [
            SELECT Approval_Rule_1__c, Approval_Rule_2__c 
            FROM Live_Approval__c 
            WHERE Quote__c = :testQuote.Id 
            LIMIT 1
        ];
        System.assertEquals(null, la.Approval_Rule_1__c, 'Should not populate approval rule fields for invalid IDs');
        System.assertEquals(null, la.Approval_Rule_2__c, 'Should not populate approval rule fields for invalid IDs');
    }
    
    /**
     * Test creation with more than 20 approval rules (should only process first 20)
     */
    @isTest
    static void testCreateLiveApprovals_MoreThan20Rules() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        // Create 25 approval rules
        List<RCA_Approval_Rule__c> extraRules = new List<RCA_Approval_Rule__c>();
        for (Integer i = 6; i <= 25; i++) {
            extraRules.add(new RCA_Approval_Rule__c(
                Chain__c = 'Chain 1',
                Order__c = i,
                Level__c = 1,
                Title__c = 'Extra Rule ' + i,
                Approver_Type__c = 'User',
                Key__c = 'EXTRA_RULE_' + i
            ));
        }
        insert extraRules;
        
        // Get all approval rules (should be 25 total: 5 from setup + 20 new)
        List<RCA_Approval_Rule__c> allRules = [SELECT Id FROM RCA_Approval_Rule__c ORDER BY Level__c, Order__c];
        
        LiveApprovalCreator.Requests request = new LiveApprovalCreator.Requests();
        request.quoteId = String.valueOf(testQuote.Id);
        request.approvalRuleIds = new List<String>();
        
        for (RCA_Approval_Rule__c rule : allRules) {
            request.approvalRuleIds.add(String.valueOf(rule.Id));
        }
        
        Test.startTest();
        LiveApprovalCreator.createLiveApprovals(new List<LiveApprovalCreator.Requests>{request});
        Test.stopTest();
        
        // Verify only 20 approval rule slots are populated
        Live_Approval__c la = [
            SELECT Id,
                   Approval_Rule_1__c, Approval_Rule_2__c, Approval_Rule_3__c, Approval_Rule_4__c, Approval_Rule_5__c,
                   Approval_Rule_6__c, Approval_Rule_7__c, Approval_Rule_8__c, Approval_Rule_9__c, Approval_Rule_10__c,
                   Approval_Rule_11__c, Approval_Rule_12__c, Approval_Rule_13__c, Approval_Rule_14__c, Approval_Rule_15__c,
                   Approval_Rule_16__c, Approval_Rule_17__c, Approval_Rule_18__c, Approval_Rule_19__c, Approval_Rule_20__c
            FROM Live_Approval__c 
            WHERE Quote__c = :testQuote.Id 
            LIMIT 1
        ];
        
        // Verify first 20 slots are populated
        System.assertNotEquals(null, la.Approval_Rule_1__c, 'Slot 1 should be populated');
        System.assertNotEquals(null, la.Approval_Rule_20__c, 'Slot 20 should be populated');
        
        // Note: Can't easily test that 21st rule is not processed without creating 21+ fields in the object
    }
    
    /**
     * Test creation with mixed valid and invalid approval rule IDs
     */
    @isTest
    static void testCreateLiveApprovals_MixedValidInvalidIds() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<RCA_Approval_Rule__c> rules = [SELECT Id FROM RCA_Approval_Rule__c ORDER BY Level__c, Order__c LIMIT 2];
        
        LiveApprovalCreator.Requests request = new LiveApprovalCreator.Requests();
        request.quoteId = String.valueOf(testQuote.Id);
        request.approvalRuleIds = new List<String>{
            String.valueOf(rules[0].Id),  // Valid
            'invalid-id',                  // Invalid
            null,                         // Null
            String.valueOf(rules[1].Id)   // Valid
        };
        
        Test.startTest();
        LiveApprovalCreator.createLiveApprovals(new List<LiveApprovalCreator.Requests>{request});
        Test.stopTest();
        
        // Should create Live_Approval__c with only the 2 valid rules
        Live_Approval__c la = [
            SELECT Approval_Rule_1__c, Approval_Rule_2__c, Approval_Rule_3__c
            FROM Live_Approval__c 
            WHERE Quote__c = :testQuote.Id 
            LIMIT 1
        ];
        
        System.assertNotEquals(null, la.Approval_Rule_1__c, 'Slot 1 should have valid rule');
        System.assertNotEquals(null, la.Approval_Rule_2__c, 'Slot 2 should have valid rule');
        System.assertEquals(null, la.Approval_Rule_3__c, 'Slot 3 should be null');
    }
    
    /**
     * Test multiple requests in single invocation
     */
    @isTest
    static void testCreateLiveApprovals_MultipleRequests() {
        // Create additional test data
        Account testAccount2 = new Account(Name = 'Test Account 2');
        insert testAccount2;
        
        Opportunity testOpp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            AccountId = testAccount2.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp2;
        
        Quote testQuote2 = new Quote(
            Name = 'Test Quote 2',
            OpportunityId = testOpp2.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert testQuote2;
        
        Quote testQuote1 = [SELECT Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        List<RCA_Approval_Rule__c> rules = [SELECT Id FROM RCA_Approval_Rule__c LIMIT 3];
        
        // Create two requests
        LiveApprovalCreator.Requests request1 = new LiveApprovalCreator.Requests();
        request1.quoteId = String.valueOf(testQuote1.Id);
        request1.approvalRuleIds = new List<String>{String.valueOf(rules[0].Id), String.valueOf(rules[1].Id)};
        
        LiveApprovalCreator.Requests request2 = new LiveApprovalCreator.Requests();
        request2.quoteId = String.valueOf(testQuote2.Id);
        request2.approvalRuleIds = new List<String>{String.valueOf(rules[2].Id)};
        
        Test.startTest();
        LiveApprovalCreator.createLiveApprovals(new List<LiveApprovalCreator.Requests>{request1, request2});
        Test.stopTest();
        
        // Verify 2 Live_Approval__c records were created
        List<Live_Approval__c> liveApprovals = [SELECT Id, Quote__c FROM Live_Approval__c];
        System.assertEquals(2, liveApprovals.size(), 'Should create 2 Live_Approval__c records');
        
        // Verify each quote has its own Live_Approval__c
        Set<Id> quoteIds = new Set<Id>();
        for (Live_Approval__c la : liveApprovals) {
            quoteIds.add(la.Quote__c);
        }
        System.assert(quoteIds.contains(testQuote1.Id), 'Should contain first quote');
        System.assert(quoteIds.contains(testQuote2.Id), 'Should contain second quote');
    }
    
    /**
     * Test Requests wrapper class constructor and properties
     */
    @isTest
    static void testRequestsWrapper() {
        Test.startTest();
        
        LiveApprovalCreator.Requests request = new LiveApprovalCreator.Requests();
        
        // Test initial values
        System.assertEquals(null, request.quoteId, 'quoteId should be null initially');
        System.assertEquals(null, request.approvalRuleIds, 'approvalRuleIds should be null initially');
        
        // Test assignment
        request.quoteId = 'test-quote-id';
        request.approvalRuleIds = new List<String>{'rule1', 'rule2'};
        
        System.assertEquals('test-quote-id', request.quoteId, 'quoteId should be assignable');
        System.assertEquals(2, request.approvalRuleIds.size(), 'approvalRuleIds should be assignable');
        
        Test.stopTest();
    }
}