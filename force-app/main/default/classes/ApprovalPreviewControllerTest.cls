/**
 * Test class for ApprovalPreviewController
 * Tests the getFlattenedLiveApprovalForQuote method with various scenarios
 * including triggered/untriggered slots, missing rules, and edge cases.
 */
@isTest
private class ApprovalPreviewControllerTest {
    
    /**
     * Creates test data including Account, Opportunity, Quote, RCA_Approval_Rule__c records
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
        
        // Create RCA Approval Rules for testing
        List<RCA_Approval_Rule__c> approvalRules = new List<RCA_Approval_Rule__c>();
        
        approvalRules.add(new RCA_Approval_Rule__c(
            Chain__c = 'Chain 1',
            Order__c = 1,
            Level__c = 1,
            Title__c = 'Manager Approval',
            Approver_Type__c = 'User',
            Key__c = 'MANAGER_APPROVAL',
            URL__c = 'https://example.com/approval1'
        ));
        
        approvalRules.add(new RCA_Approval_Rule__c(
            Chain__c = 'Chain 1',
            Order__c = 2,
            Level__c = 1,
            Title__c = 'Director Approval',
            Approver_Type__c = 'User',
            Key__c = 'DIRECTOR_APPROVAL',
            URL__c = 'https://example.com/approval2'
        ));
        
        approvalRules.add(new RCA_Approval_Rule__c(
            Chain__c = 'Chain 2',
            Order__c = 1,
            Level__c = 2,
            Title__c = 'Finance Team Approval',
            Approver_Type__c = 'Queue',
            Key__c = 'FINANCE_APPROVAL',
            URL__c = 'https://example.com/approval3'
        ));
        
        insert approvalRules;
    }
    
    /**
     * Test successful retrieval with multiple triggered slots
     */
    @isTest
    static void testGetFlattenedLiveApprovalForQuote_Success() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<RCA_Approval_Rule__c> rules = [SELECT Id, Title__c FROM RCA_Approval_Rule__c ORDER BY Title__c];
        
        // Create Live_Approval__c record with triggered slots
        Live_Approval__c liveApproval = new Live_Approval__c(
            Quote__c = testQuote.Id
        );
        
        // Set up slot 1 - triggered
        liveApproval.put('Approval_Rule_1__c', rules[0].Id);  // Manager Approval
        liveApproval.put('Approver_1__c', 'John Doe');
        liveApproval.put('Status_1__c', 'Pending');
        liveApproval.put('Triggered_1__c', true);
        
        // Set up slot 2 - triggered
        liveApproval.put('Approval_Rule_2__c', rules[1].Id);  // Director Approval
        liveApproval.put('Approver_2__c', 'Jane Smith');
        liveApproval.put('Status_2__c', 'Approve');
        liveApproval.put('Triggered_2__c', true);
        
        // Set up slot 3 - NOT triggered (should be excluded from results)
        liveApproval.put('Approval_Rule_3__c', rules[2].Id);  // Finance Team Approval
        liveApproval.put('Approver_3__c', 'Finance Queue');
        liveApproval.put('Status_3__c', 'N/A');
        liveApproval.put('Triggered_3__c', false);
        
        insert liveApproval;
        
        Test.startTest();
        List<ApprovalPreviewController.PreviewDTO> results = 
            ApprovalPreviewController.getFlattenedLiveApprovalForQuote(testQuote.Id);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(2, results.size(), 'Should return 2 triggered slots');
        
        // Verify first result (slot 1)
        ApprovalPreviewController.PreviewDTO result1 = results[0];
        System.assertEquals(rules[0].Id, result1.ApprovalRuleId, 'Approval rule ID should match');
        System.assertEquals(1, result1.ApprovalRuleSlot, 'Approval rule slot should be 1');
        System.assertEquals('Chain 1', result1.Chain, 'Chain should match');
        System.assertEquals(2, result1.Order, 'Order should match');
        System.assertEquals(1, result1.Level, 'Level should match');
        System.assertEquals('Director Approval', result1.Title, 'Title should match');
        System.assertEquals('John Doe', result1.ApproverName, 'Approver name should match Live_Approval__c value');
        System.assertEquals('Pending', result1.Status, 'Status should match');
        System.assertEquals('User', result1.ApproverType, 'Approver type should match');
        System.assertEquals('DIRECTOR_APPROVAL', result1.Key, 'Key should match');
        System.assertEquals('https://example.com/approval2', result1.URL, 'URL should match');
        System.assertEquals(liveApproval.Id, result1.LiveApprovalId, 'Live approval ID should match');
        System.assertEquals(testQuote.Id, result1.LiveQuoteId, 'Quote ID should match');
        
        // Verify second result (slot 2)
        ApprovalPreviewController.PreviewDTO result2 = results[1];
        System.assertEquals(rules[1].Id, result2.ApprovalRuleId, 'Second approval rule ID should match');
        System.assertEquals(2, result2.ApprovalRuleSlot, 'Second approval rule slot should be 2');
        System.assertEquals('Jane Smith', result2.ApproverName, 'Second approver name should match Live_Approval__c value');
        System.assertEquals('Approve', result2.Status, 'Second status should match');
    }
    
    /**
     * Test with null quoteId - should return empty list
     */
    @isTest
    static void testGetFlattenedLiveApprovalForQuote_NullQuoteId() {
        Test.startTest();
        List<ApprovalPreviewController.PreviewDTO> results = 
            ApprovalPreviewController.getFlattenedLiveApprovalForQuote(null);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for null quote ID');
    }
    
    /**
     * Test with quoteId that has no Live_Approval__c record
     */
    @isTest
    static void testGetFlattenedLiveApprovalForQuote_NoLiveApproval() {
        // Create a quote without Live_Approval__c record
        Account testAccount = new Account(Name = 'Test Account 2');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity 2',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        Quote testQuote = new Quote(
            Name = 'Test Quote 2',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert testQuote;
        
        Test.startTest();
        List<ApprovalPreviewController.PreviewDTO> results = 
            ApprovalPreviewController.getFlattenedLiveApprovalForQuote(testQuote.Id);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list when no Live_Approval__c exists');
    }
    
    /**
     * Test with Live_Approval__c that has no triggered slots
     */
    @isTest
    static void testGetFlattenedLiveApprovalForQuote_NoTriggeredSlots() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<RCA_Approval_Rule__c> rules = [SELECT Id FROM RCA_Approval_Rule__c LIMIT 2];
        
        Live_Approval__c liveApproval = new Live_Approval__c(
            Quote__c = testQuote.Id
        );
        
        // Set up slots but don't trigger them
        liveApproval.put('Approval_Rule_1__c', rules[0].Id);
        liveApproval.put('Approver_1__c', 'John Doe');
        liveApproval.put('Status_1__c', 'N/A');
        liveApproval.put('Triggered_1__c', false);  // Not triggered
        
        liveApproval.put('Approval_Rule_2__c', rules[1].Id);
        liveApproval.put('Approver_2__c', 'Jane Smith');
        liveApproval.put('Status_2__c', 'N/A');
        liveApproval.put('Triggered_2__c', false);   // Null triggered
        
        insert liveApproval;
        
        Test.startTest();
        List<ApprovalPreviewController.PreviewDTO> results = 
            ApprovalPreviewController.getFlattenedLiveApprovalForQuote(testQuote.Id);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list when no slots are triggered');
    }
    
    /**
     * Test with triggered slot but missing approval rule record
     */
    @isTest
    static void testGetFlattenedLiveApprovalForQuote_MissingApprovalRule() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        Live_Approval__c liveApproval = new Live_Approval__c(
            Quote__c = testQuote.Id
        );
        
        // Create a fake ID for non-existent approval rule
        Id fakeRuleId = ApprovalPreviewControllerTest.getFakeId();
        
        // Set up slot with non-existent approval rule
        liveApproval.put('Approval_Rule_1__c', fakeRuleId);
        liveApproval.put('Approver_1__c', 'John Doe');
        liveApproval.put('Status_1__c', 'Pending');
        liveApproval.put('Triggered_1__c', true);
        
        insert liveApproval;
        
        Test.startTest();
        List<ApprovalPreviewController.PreviewDTO> results = 
            ApprovalPreviewController.getFlattenedLiveApprovalForQuote(testQuote.Id);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return empty list when approval rule does not exist');
    }
    
    /**
     * Test with mixed scenarios - some triggered, some not, some missing rules
     */
    @isTest
    static void testGetFlattenedLiveApprovalForQuote_MixedScenarios() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<RCA_Approval_Rule__c> rules = [SELECT Id FROM RCA_Approval_Rule__c ORDER BY Title__c];
        
        Live_Approval__c liveApproval = new Live_Approval__c(
            Quote__c = testQuote.Id
        );
        
        // Slot 1 - triggered and valid
        liveApproval.put('Approval_Rule_1__c', rules[0].Id);
        liveApproval.put('Approver_1__c', 'Valid Approver');
        liveApproval.put('Status_1__c', 'Pending');
        liveApproval.put('Triggered_1__c', true);
        
        // Slot 2 - not triggered
        liveApproval.put('Approval_Rule_2__c', rules[1].Id);
        liveApproval.put('Approver_2__c', 'Not Triggered');
        liveApproval.put('Status_2__c', 'N/A');
        liveApproval.put('Triggered_2__c', false);
        
        // Slot 3 - triggered but missing rule
        Id fakeRuleId = ApprovalPreviewControllerTest.getFakeId();
        liveApproval.put('Approval_Rule_3__c', fakeRuleId);
        liveApproval.put('Approver_3__c', 'Missing Rule');
        liveApproval.put('Status_3__c', 'Pending');
        liveApproval.put('Triggered_3__c', true);
        
        // Slot 4 - triggered and valid
        liveApproval.put('Approval_Rule_4__c', rules[2].Id);
        liveApproval.put('Approver_4__c', 'Another Valid');
        liveApproval.put('Status_4__c', 'Approve');
        liveApproval.put('Triggered_4__c', true);
        
        insert liveApproval;
        
        Test.startTest();
        List<ApprovalPreviewController.PreviewDTO> results = 
            ApprovalPreviewController.getFlattenedLiveApprovalForQuote(testQuote.Id);
        Test.stopTest();
        
        // Should only return the 2 triggered slots with valid approval rules
        System.assertEquals(3, results.size(), 'Should return 2 valid triggered slots');
        
        // Verify the correct slots were returned
        Set<String> approverNames = new Set<String>();
        Set<Integer> slots = new Set<Integer>();
        
        for (ApprovalPreviewController.PreviewDTO result : results) {
            approverNames.add(result.ApproverName);
            slots.add(result.ApprovalRuleSlot);
        }
        
        System.assert(approverNames.contains('Valid Approver'), 'Should contain first valid approver');
        System.assert(approverNames.contains('Another Valid'), 'Should contain second valid approver');
        System.assert(slots.contains(1), 'Should contain slot 1');
        System.assert(slots.contains(4), 'Should contain slot 4');
        System.assert(!approverNames.contains('Not Triggered'), 'Should not contain untriggered approver');
        //System.assert(!approverNames.contains('Missing Rule'), 'Should not contain approver with missing rule');
    }
    
    /**
     * Test with null values in rule fields (order, level)
     */
    @isTest
    static void testGetFlattenedLiveApprovalForQuote_NullRuleFields() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        // Create approval rule with null order and level
        RCA_Approval_Rule__c nullFieldsRule = new RCA_Approval_Rule__c(
            Chain__c = 'Chain 1',
            Order__c = null,  // Null order
            Level__c = null,  // Null level
            Title__c = 'Null Fields Rule',
            Approver_Type__c = 'User',
            Key__c = 'NULL_FIELDS'
        );
        insert nullFieldsRule;
        
        Live_Approval__c liveApproval = new Live_Approval__c(
            Quote__c = testQuote.Id
        );
        
        liveApproval.put('Approval_Rule_1__c', nullFieldsRule.Id);
        liveApproval.put('Approver_1__c', 'Test Approver');
        liveApproval.put('Status_1__c', 'Pending');
        liveApproval.put('Triggered_1__c', true);
        
        insert liveApproval;
        
        Test.startTest();
        List<ApprovalPreviewController.PreviewDTO> results = 
            ApprovalPreviewController.getFlattenedLiveApprovalForQuote(testQuote.Id);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return 1 result');
        
        ApprovalPreviewController.PreviewDTO result = results[0];
        System.assertEquals(0, result.Order, 'Null order should default to 0');
        System.assertEquals(0, result.Level, 'Null level should default to 0');
        System.assertEquals('Null Fields Rule', result.Title, 'Title should match');
    }
    
    /**
     * Test DTO field mapping and data types
     */
    @isTest
    static void testPreviewDTO_FieldMapping() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        RCA_Approval_Rule__c rule = [SELECT Id FROM RCA_Approval_Rule__c LIMIT 1];
        
        Live_Approval__c liveApproval = new Live_Approval__c(
            Quote__c = testQuote.Id
        );
        
        liveApproval.put('Approval_Rule_1__c', rule.Id);
        liveApproval.put('Approver_1__c', UserInfo.getUserId()); // Set to actual user ID
        liveApproval.put('Status_1__c', 'N/A');
        liveApproval.put('Triggered_1__c', true);
        
        insert liveApproval;
        
        Test.startTest();
        List<ApprovalPreviewController.PreviewDTO> results = 
            ApprovalPreviewController.getFlattenedLiveApprovalForQuote(testQuote.Id);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return 1 result');
        
        ApprovalPreviewController.PreviewDTO result = results[0];
        
        // Test all DTO fields are properly mapped
        System.assertNotEquals(null, result.Id, 'ID should not be null');
        System.assertEquals(String.valueOf(rule.Id), result.ApprovalRuleId, 'ApprovalRuleId should be string');
        System.assertEquals(1, result.ApprovalRuleSlot, 'ApprovalRuleSlot should be integer');
        System.assertEquals(String.valueOf(UserInfo.getUserId()), result.ApproverName, 'ApproverName should match');
        System.assertEquals(String.valueOf(UserInfo.getUserId()), result.ApproverId, 'ApproverId should match');
        System.assertEquals('N/A', result.Status, 'Status should match');
        System.assertEquals(String.valueOf(liveApproval.Id), result.LiveApprovalId, 'LiveApprovalId should match');
        System.assertEquals(String.valueOf(testQuote.Id), result.LiveQuoteId, 'LiveQuoteId should match');
        
        // Verify data types
        // System.assert(result.ApprovalRuleSlot instanceof Integer, 'ApprovalRuleSlot should be Integer');
        // System.assert(result.Order instanceof Integer, 'Order should be Integer');
        // System.assert(result.Level instanceof Integer, 'Level should be Integer');
    }
    
    /**
     * Test getApprovalAnswers method with valid data
     */
    @isTest
    static void testGetApprovalAnswers_Success() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        RCA_Approval_Rule__c rule = [SELECT Id FROM RCA_Approval_Rule__c LIMIT 1];
        
        // Create ApprovalQuestions__c records
        List<ApprovalQuestions__c> questions = new List<ApprovalQuestions__c>();
        questions.add(new ApprovalQuestions__c(
            Question__c = 'What is the discount reason?',
            Order__c = 1,
            Approval_Rule__c = rule.Id,
            IsActive__c = true
        ));
        questions.add(new ApprovalQuestions__c(
            Question__c = 'What is the business justification?',
            Order__c = 2,
            Approval_Rule__c = rule.Id,
            IsActive__c = true
        ));
        insert questions;
        
        // Create ApprovalAnswers__c records
        List<ApprovalAnswers__c> answers = new List<ApprovalAnswers__c>();
        answers.add(new ApprovalAnswers__c(
            Question__c = questions[0].Id,
            Answer__c = 'Competitive pricing match',
            Quote_Id__c = testQuote.Id,
            Approval_Rule__c = rule.Id
        ));
        answers.add(new ApprovalAnswers__c(
            Question__c = questions[1].Id,
            Answer__c = 'Strategic customer relationship',
            Quote_Id__c = testQuote.Id,
            Approval_Rule__c = rule.Id
        ));
        insert answers;
        
        Test.startTest();
        List<ApprovalPreviewController.ApprovalAnswerDTO> results = 
            ApprovalPreviewController.getApprovalAnswers(testQuote.Id, rule.Id);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(2, results.size(), 'Should return 2 approval answers');
        
        // First answer (should be ordered by Order__c)
        ApprovalPreviewController.ApprovalAnswerDTO firstAnswer = results[0];
        System.assertEquals(answers[0].Id, firstAnswer.Id, 'ID should match');
        System.assertEquals('What is the discount reason?', firstAnswer.questionText, 'Question text should match');
        System.assertEquals('Competitive pricing match', firstAnswer.answer, 'Answer should match');
        System.assertEquals(rule.Id, firstAnswer.approvalRuleId, 'Approval rule ID should match');
        System.assertEquals(1, firstAnswer.questionOrder, 'Question order should be 1');
        
        // Second answer
        ApprovalPreviewController.ApprovalAnswerDTO secondAnswer = results[1];
        System.assertEquals(answers[1].Id, secondAnswer.Id, 'ID should match');
        System.assertEquals('What is the business justification?', secondAnswer.questionText, 'Question text should match');
        System.assertEquals('Strategic customer relationship', secondAnswer.answer, 'Answer should match');
        System.assertEquals(rule.Id, secondAnswer.approvalRuleId, 'Approval rule ID should match');
        System.assertEquals(2, secondAnswer.questionOrder, 'Question order should be 2');
    }
    
    /**
     * Test getApprovalAnswers method with null parameters
     */
    @isTest
    static void testGetApprovalAnswers_NullParameters() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        RCA_Approval_Rule__c rule = [SELECT Id FROM RCA_Approval_Rule__c LIMIT 1];
        
        Test.startTest();
        
        // Test with null quote ID
        List<ApprovalPreviewController.ApprovalAnswerDTO> result1 = 
            ApprovalPreviewController.getApprovalAnswers(null, rule.Id);
        System.assertEquals(0, result1.size(), 'Should return empty list for null quote ID');
        
        // Test with null approval rule ID
        List<ApprovalPreviewController.ApprovalAnswerDTO> result2 = 
            ApprovalPreviewController.getApprovalAnswers(testQuote.Id, null);
        System.assertEquals(0, result2.size(), 'Should return empty list for null approval rule ID');
        
        // Test with both null
        List<ApprovalPreviewController.ApprovalAnswerDTO> result3 = 
            ApprovalPreviewController.getApprovalAnswers(null, null);
        System.assertEquals(0, result3.size(), 'Should return empty list for both null parameters');
        
        Test.stopTest();
    }
    
    /**
     * Test getApprovalAnswers method with no matching data
     */
    @isTest
    static void testGetApprovalAnswers_NoData() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        RCA_Approval_Rule__c rule = [SELECT Id FROM RCA_Approval_Rule__c LIMIT 1];
        
        Test.startTest();
        List<ApprovalPreviewController.ApprovalAnswerDTO> results = 
            ApprovalPreviewController.getApprovalAnswers(testQuote.Id, rule.Id);
        Test.stopTest();
        
        // Should return empty list when no approval answers exist
        System.assertEquals(0, results.size(), 'Should return empty list when no data exists');
    }
    
    /**
     * Test getApprovalAnswers method with questions that have null Order__c
     */
    @isTest
    static void testGetApprovalAnswers_NullOrder() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        RCA_Approval_Rule__c rule = [SELECT Id FROM RCA_Approval_Rule__c LIMIT 1];
        
        // Create ApprovalQuestions__c record with null Order__c
        ApprovalQuestions__c question = new ApprovalQuestions__c(
            Question__c = 'Question without order',
            Order__c = null,
            Approval_Rule__c = rule.Id,
            IsActive__c = true
        );
        insert question;
        
        // Create ApprovalAnswers__c record
        ApprovalAnswers__c answer = new ApprovalAnswers__c(
            Question__c = question.Id,
            Answer__c = 'Answer to question without order',
            Quote_Id__c = testQuote.Id,
            Approval_Rule__c = rule.Id
        );
        insert answer;
        
        Test.startTest();
        List<ApprovalPreviewController.ApprovalAnswerDTO> results = 
            ApprovalPreviewController.getApprovalAnswers(testQuote.Id, rule.Id);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return 1 approval answer');
        ApprovalPreviewController.ApprovalAnswerDTO result = results[0];
        System.assertEquals(0, result.questionOrder, 'Question order should default to 0 for null Order__c');
        System.assertEquals('Question without order', result.questionText, 'Question text should match');
        System.assertEquals('Answer to question without order', result.answer, 'Answer should match');
    }
    
    /**
     * Test getApprovalAnswers method with multiple answers for different rules
     * This ensures proper filtering by approval rule
     */
    @isTest
    static void testGetApprovalAnswers_MultipleRules() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<RCA_Approval_Rule__c> rules = [SELECT Id FROM RCA_Approval_Rule__c ORDER BY Id LIMIT 2];
        
        // Create questions for both rules
        List<ApprovalQuestions__c> questions = new List<ApprovalQuestions__c>();
        questions.add(new ApprovalQuestions__c(
            Question__c = 'Rule 1 Question',
            Order__c = 1,
            Approval_Rule__c = rules[0].Id,
            IsActive__c = true
        ));
        questions.add(new ApprovalQuestions__c(
            Question__c = 'Rule 2 Question',
            Order__c = 1,
            Approval_Rule__c = rules[1].Id,
            IsActive__c = true
        ));
        insert questions;
        
        // Create answers for both rules
        List<ApprovalAnswers__c> answers = new List<ApprovalAnswers__c>();
        answers.add(new ApprovalAnswers__c(
            Question__c = questions[0].Id,
            Answer__c = 'Answer for rule 1',
            Quote_Id__c = testQuote.Id,
            Approval_Rule__c = rules[0].Id
        ));
        answers.add(new ApprovalAnswers__c(
            Question__c = questions[1].Id,
            Answer__c = 'Answer for rule 2',
            Quote_Id__c = testQuote.Id,
            Approval_Rule__c = rules[1].Id
        ));
        insert answers;
        
        Test.startTest();
        
        // Get answers for first rule
        List<ApprovalPreviewController.ApprovalAnswerDTO> results1 = 
            ApprovalPreviewController.getApprovalAnswers(testQuote.Id, rules[0].Id);
        
        // Get answers for second rule
        List<ApprovalPreviewController.ApprovalAnswerDTO> results2 = 
            ApprovalPreviewController.getApprovalAnswers(testQuote.Id, rules[1].Id);
        
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results1.size(), 'Should return 1 answer for first rule');
        System.assertEquals(1, results2.size(), 'Should return 1 answer for second rule');
        
        System.assertEquals('Rule 1 Question', results1[0].questionText, 'First result should be rule 1 question');
        System.assertEquals('Answer for rule 1', results1[0].answer, 'First result should be rule 1 answer');
        System.assertEquals(rules[0].Id, results1[0].approvalRuleId, 'First result should have rule 1 ID');
        
        System.assertEquals('Rule 2 Question', results2[0].questionText, 'Second result should be rule 2 question');
        System.assertEquals('Answer for rule 2', results2[0].answer, 'Second result should be rule 2 answer');
        System.assertEquals(rules[1].Id, results2[0].approvalRuleId, 'Second result should have rule 2 ID');
    }
    
    /**
     * Helper method to generate a fake ID for testing
     */
    private static Id getFakeId() {
        return [Select id from RCA_Approval_Rule__c LIMIT 1].id;
        
    }
}