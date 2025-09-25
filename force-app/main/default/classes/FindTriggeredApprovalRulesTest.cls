@isTest
private class FindTriggeredApprovalRulesTest {
    @isTest static void testFindTriggeredRules() {
        // Create minimal test data: Account -> Opportunity -> Quote
        Account a = new Account(Name='TestAcct');
        insert a;

        Opportunity opp = new Opportunity(Name='Opp', StageName='Prospecting', CloseDate=Date.today().addDays(30), AccountId=a.Id);
        insert opp;

        Quote q = new Quote(Name='Q1', OpportunityId=opp.Id, Pricebook2Id=Test.getStandardPricebookId(), Status='Draft');
        insert q;

        // Create Live_Approval__c record and set Status_1__c = 'Triggered' and Approval_Rule_1__c to a sample key
        Live_Approval__c la = new Live_Approval__c(Quote__c = q.Id);
        // Use dynamic field setting in case fields don't exist in different orgs
        // Set Status_1__c to 'Triggered'
        la.put('Status_1__c','Triggered');
        la.put('Approval_Rule_1__c','Rule_One');
        insert la;

        // Call invocable method
        FindTriggeredApprovalRules.Request req = new FindTriggeredApprovalRules.Request();
        req.quoteId = String.valueOf(q.Id);
        Test.startTest();
        List<FindTriggeredApprovalRules.Response> res = FindTriggeredApprovalRules.find(new List<FindTriggeredApprovalRules.Request>{req});
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertNotEquals(null, res[0].approvalRuleIds);
        System.assertEquals(1, res[0].approvalRuleIds.size());
        System.assertEquals('Rule_One', res[0].approvalRuleIds[0]);
    }

    @isTest static void testNoTriggered() {
        Account a = new Account(Name='TestAcct2');
        insert a;
        Opportunity opp = new Opportunity(Name='Opp2', StageName='Prospecting', CloseDate=Date.today().addDays(30), AccountId=a.Id);
        insert opp;
        Quote q = new Quote(Name='Q2', OpportunityId=opp.Id, Pricebook2Id=Test.getStandardPricebookId(), Status='Draft');
        insert q;

        Live_Approval__c la = new Live_Approval__c(Quote__c = q.Id);
        la.put('Status_1__c','Not Triggered');
        la.put('Approval_Rule_1__c','Rule_One');
        insert la;

        FindTriggeredApprovalRules.Request req = new FindTriggeredApprovalRules.Request();
        req.quoteId = String.valueOf(q.Id);
        Test.startTest();
        List<FindTriggeredApprovalRules.Response> res = FindTriggeredApprovalRules.find(new List<FindTriggeredApprovalRules.Request>{req});
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(0, res[0].approvalRuleIds.size());
    }
}
