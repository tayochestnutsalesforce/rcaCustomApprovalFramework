@isTest
public class QuoteLineItemControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        // Create test quote
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testQuote;
        
        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            Family = 'Hardware',
            IsActive = true
        );
        insert testProduct;
        
        // Create pricebook entry
        PricebookEntry testPbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPbe;
        
        // Create quote line items
        List<QuoteLineItem> testQuoteLineItems = new List<QuoteLineItem>();
        
        testQuoteLineItems.add(new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = testPbe.Id,
            Product2Id = testProduct.Id,
            Quantity = 2,
            UnitPrice = 100.00,
            Description = 'Test Description 1'
        ));
        
        testQuoteLineItems.add(new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = testPbe.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 200.00,
            Description = 'Test Description 2'
        ));
        
        insert testQuoteLineItems;
    }
    
    @isTest
    static void testGetQuoteLineItems_Success() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<String> fields = new List<String>{'Description', 'Quantity', 'UnitPrice'};
        String familyFilter = 'Hardware';
        
        Test.startTest();
        List<QuoteLineItem> result = QuoteLineItemController.getQuoteLineItems(
            testQuote.Id, fields, familyFilter
        );
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should return 2 quote line items');
        
        // Verify fields are populated
        for (QuoteLineItem qli : result) {
            System.assertNotEquals(null, qli.Id, 'Id should be populated');
            System.assertNotEquals(null, qli.Description, 'Description should be populated');
            System.assertNotEquals(null, qli.Quantity, 'Quantity should be populated');
            System.assertNotEquals(null, qli.UnitPrice, 'UnitPrice should be populated');
        }
    }
    
    @isTest
    static void testGetQuoteLineItems_WithoutFamilyFilter() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<String> fields = new List<String>{'Description', 'Quantity'};
        
        Test.startTest();
        List<QuoteLineItem> result = QuoteLineItemController.getQuoteLineItems(
            testQuote.Id, fields, null
        );
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should return 2 quote line items');
    }
    
    @isTest
    static void testGetQuoteLineItems_EmptyQuoteId() {
        List<String> fields = new List<String>{'Description'};
        
        Test.startTest();
        try {
            QuoteLineItemController.getQuoteLineItems('', fields, null);
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertEquals('Quote ID is required', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetQuoteLineItems_EmptyFields() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<String> fields = new List<String>();
        
        Test.startTest();
        try {
            QuoteLineItemController.getQuoteLineItems(testQuote.Id, fields, null);
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertEquals('At least one field must be specified', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetQuoteLineItems_NullFields() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        try {
            QuoteLineItemController.getQuoteLineItems(testQuote.Id, null, null);
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertEquals('At least one field must be specified', e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetQuoteLineItemsWithGroups_Success() {
        // Get test data
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<String> fields = new List<String>{'Description', 'Quantity', 'UnitPrice'};
        String familyFilter = 'Hardware';
        
        Test.startTest();
        List<QuoteLineItem> result = QuoteLineItemController.getQuoteLineItemsWithGroups(
            testQuote.Id, fields, familyFilter
        );
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.size(), 'Should return 2 quote line items');
        
        // Verify fields are populated
        for (QuoteLineItem qli : result) {
            System.assertNotEquals(null, qli.Id, 'Id should be populated');
            System.assertNotEquals(null, qli.Description, 'Description should be populated');
            System.assertNotEquals(null, qli.Quantity, 'Quantity should be populated');
            System.assertNotEquals(null, qli.UnitPrice, 'UnitPrice should be populated');
        }
    }
    
    @isTest
    static void testGetQuoteLineItems_InvalidField() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<String> fields = new List<String>{'InvalidField__c'};
        
        Test.startTest();
        try {
            QuoteLineItemController.getQuoteLineItems(testQuote.Id, fields, null);
            System.assert(false, 'Should have thrown an exception for invalid field');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error querying quote line items'), 
                         'Should contain error message about querying');
        }
        Test.stopTest();
    }
}