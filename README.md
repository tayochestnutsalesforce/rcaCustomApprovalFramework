# RCA Custom Approval Framework

## Overview

The RCA (Revenue Cloud Approval) Custom Approval Framework is a comprehensive Salesforce solution for managing complex multi-level approval processes on Quote records. The framework provides a flexible, configurable system that supports:

- **Multi-level approval hierarchies** with configurable chains
- **Dynamic approval rule evaluation** based on Quote criteria
- **Visual approval preview components** for real-time status monitoring
- **Automated approval orchestration** via Salesforce Flows
- **Flexible approver assignment** (Users, Queues, or dynamic assignment)
- **Interactive approval questionnaires** with custom questions and answers

## Architecture

### Core Data Model

#### Custom Objects

1. **RCA_Approval_Rule__c** - Master approval rule configuration
   - **Chain__c**: Groups rules into logical approval chains
   - **Level__c**: Defines the approval hierarchy level (1, 2, 3, etc.)
   - **Order__c**: Sequence within the same level
   - **Title__c**: Human-readable rule description
   - **Approver_Type__c**: User, Queue, or dynamic assignment
   - **Key__c**: Unique identifier for rule referencing
   - **URL__c**: Optional link to additional resources

2. **Live_Approval__c** - Runtime approval state for each Quote
   - **Quote__c**: Lookup to the Quote record
   - **Approval_Rule_1__c** through **Approval_Rule_20__c**: References to active approval rules
   - **Triggered_1__c** through **Triggered_20__c**: Boolean flags indicating if rule is triggered
   - **Status_1__c** through **Status_20__c**: Current approval status (N/A, Pending, Approved, Rejected)
   - **Approver_1__c** through **Approver_20__c**: Assigned approver for each slot

3. **ApprovalQuestions__c** - Custom questions per approval rule
   - **Approval_Rule__c**: Lookup to RCA_Approval_Rule__c
   - **Question_Text__c**: The question content
   - **Order__c**: Display sequence

4. **ApprovalAnswers__c** - Responses to approval questions
   - **Approval_Rule__c**: Lookup to RCA_Approval_Rule__c
   - **Question_Text__c**: Question being answered
   - **Answer__c**: The provided answer

### Apex Classes

#### Core Processing Classes

**ApprovalPreviewController**
- Primary controller for approval data visualization
- `getFlattenedLiveApprovalForQuote(String quoteId)`: Returns flattened approval data for LWC consumption
- `getApprovalAnswers(List<String> approvalRuleIds)`: Retrieves questions and answers for approval rules
- Converts Live_Approval__c slot-based data into structured DTOs

**LiveApprovalCreator**
- Creates Live_Approval__c records for new quotes
- `createLiveApprovals(List<Requests> requests)`: Invocable method for Flow integration
- Populates up to 20 approval rule slots based on triggered rules
- Orders rules by Level__c and Order__c for consistent slot assignment

**FindTriggeredApprovalRules**
- Identifies which approval rules are currently triggered for a quote
- `find(List<Request> requests)`: Returns approval rule IDs where Triggered_X__c = true
- Uses dynamic SOQL to handle variable field patterns
- Supports both Boolean and String trigger indicators

**UpdateLiveApprovalInvocable**
- Updates Live_Approval__c records with new approval statuses
- `updateApprovals(List<Requests> requestGroups)`: Invocable method for bulk updates
- Handles approver assignment, status changes, and trigger state updates
- Supports processing multiple approval records per quote

#### Supporting Classes

**ApprovalRecordsWrapper**
- Data transfer object for Flow integration
- Contains `approvalRuleId`, `triggeringStatus`, `approver`, `approvalStatus`
- Annotated with `@InvocableVariable` for Flow compatibility

**QuoteLineItemController**
- Manages Quote Line Item data access and manipulation
- Supports configurable field display in Lightning components
- Provides filtering capabilities by product family

### Lightning Web Components

#### ApprovalPreviewMosaic
**Purpose**: Visual mosaic display of approval status organized by chains and levels

**Key Features**:
- Groups approvals by Chain for columnar display
- Displays approval cards with status colors and approver avatars
- Supports tooltip hover information with approval questions/answers
- Configurable status color mapping via component properties
- Responsive design adapting to different chain configurations

**Usage**:
```html
<c-approval-preview-mosaic 
    record-id={quoteId}
    status-color-map='{"Approved":"#2ecc71","Rejected":"#e74c3c","Pending":"#f39c12","N/A":"#95a5a6"}'
    approved-color="#2ecc71"
    rejected-color="#e74c3c">
</c-approval-preview-mosaic>
```

#### ApprovalPreviewTable
**Purpose**: Tabular view of approval data with grid/table toggle

**Key Features**:
- Dual view modes: visual grid and data table
- Sorting and filtering capabilities
- Supports direct Flow data injection via `flowData` property
- Configurable level display and divider placement
- Lightning datatable integration for advanced data operations

**Usage**:
```html
<c-approval-preview-table 
    quote-id={quoteId}
    max-level="5"
    divider-level="2">
</c-approval-preview-table>
```

#### QuoteLineItemTable
**Purpose**: Configurable display of Quote Line Items with dynamic field selection

**Key Features**:
- Dynamic field configuration (field1 through field5)
- Product family filtering
- Real-time data updates
- Customizable column headers and display formats

### Flow Orchestration

The framework includes several key Flows for approval process automation:

#### RCA_Approval_Orch
Main orchestration flow managing the complete approval lifecycle:
- **Level-based progression**: Moves through approval levels sequentially
- **Status evaluation**: Checks approval/rejection at each stage
- **Automatic transitions**: Progresses to next level on approval
- **Rejection handling**: Manages rejection scenarios and notifications

#### RCA_Stage_Evaluation / RCA_Evaluate_Stage
Evaluates approval requirements at each stage:
- Determines which approval rules should be triggered
- Assigns appropriate approvers based on rule configuration
- Updates Live_Approval__c trigger flags

#### RCA_Subflow_Create_Live_Approval_Record
Creates and initializes Live_Approval__c records:
- Links approval rules to specific quote contexts
- Sets initial status values
- Establishes approval rule slot assignments

#### RCA_Summary_Variable_Flow
Populates context variables for approval evaluation:
- Calculates quote totals and quantities
- Extracts product family information
- Sets up variables for rule trigger evaluation

#### Supporting Flows
- **RCA_Approval_Preview**: Manages approval preview data
- **RCA_Prepare_Approval_Questions_for_Answers**: Sets up questionnaire data
- **RCA_Screen_Approval_Answers**: Handles approval question responses
- **RCA_Set_Approve_or_Rejected**: Processes approval decisions

## Implementation Guide

### Initial Setup

1. **Deploy Custom Objects**
   ```bash
   sfdx force:source:deploy -p force-app/main/default/objects/
   ```

2. **Deploy Apex Classes**
   ```bash
   sfdx force:source:deploy -p force-app/main/default/classes/
   ```

3. **Deploy Lightning Web Components**
   ```bash
   sfdx force:source:deploy -p force-app/main/default/lwc/
   ```

4. **Deploy Flows**
   ```bash
   sfdx force:source:deploy -p force-app/main/default/flows/
   ```

### Configuration Steps

#### 1. Create Approval Rules
```apex
// Create approval rules for your organization
RCA_Approval_Rule__c managerRule = new RCA_Approval_Rule__c(
    Chain__c = 'Sales Chain',
    Level__c = 1,
    Order__c = 1,
    Title__c = 'Sales Manager Approval',
    Approver_Type__c = 'User',
    Key__c = 'SALES_MANAGER'
);
insert managerRule;
```

#### 2. Configure Static Resources
Deploy the `ApprovalPreviewIcons` static resource containing:
- `user.svg` - Default user avatar
- `group.svg` - Queue/group avatar
- Custom approver images as needed

#### 3. Setup Quote Page Layouts
Add the approval preview components to Quote record pages:
- **ApprovalPreviewMosaic** for visual status overview
- **ApprovalPreviewTable** for detailed data analysis

#### 4. Configure Flow Triggers
Set up Process Builder or Flow triggers to initiate approval processes:
- Trigger on Quote status changes
- Trigger on Quote field value changes
- Manual approval initiation

### Usage Patterns

#### Creating Live Approvals
```apex
// Using the LiveApprovalCreator
LiveApprovalCreator.Requests request = new LiveApprovalCreator.Requests();
request.quoteId = 'a0XX000000XXXXX';
request.approvalRuleIds = new List<String>{'a0YX000000XXXXX'};

LiveApprovalCreator.createLiveApprovals(new List<LiveApprovalCreator.Requests>{request});
```

#### Updating Approval Status
```apex
// Using the UpdateLiveApprovalInvocable
ApprovalRecordsWrapper approval = new ApprovalRecordsWrapper();
approval.approvalRuleId = 'a0YX000000XXXXX';
approval.triggeringStatus = true;
approval.approver = '005X000000XXXXX';
approval.approvalStatus = 'Approved';

UpdateLiveApprovalInvocable.Requests request = new UpdateLiveApprovalInvocable.Requests();
request.quoteId = 'a0XX000000XXXXX';
request.approvals = new List<ApprovalRecordsWrapper>{approval};

UpdateLiveApprovalInvocable.updateApprovals(new List<UpdateLiveApprovalInvocable.Requests>{request});
```

#### Finding Triggered Rules
```apex
// Using FindTriggeredApprovalRules
FindTriggeredApprovalRules.Request request = new FindTriggeredApprovalRules.Request();
request.quoteId = 'a0XX000000XXXXX';

List<FindTriggeredApprovalRules.Response> responses = 
    FindTriggeredApprovalRules.find(new List<FindTriggeredApprovalRules.Request>{request});
```

## Customization Options

### Status Color Configuration
Configure approval status colors in the LWC components:
```javascript
// JSON format
statusColorMap = '{"Approved":"#2ecc71","Rejected":"#e74c3c","Pending":"#f39c12","N/A":"#95a5a6"}';

// Individual property override
approvedColor = "#2ecc71";
rejectedColor = "#e74c3c";
```

### Custom Approval Rules
Extend approval rule evaluation by:
1. Adding custom fields to `RCA_Approval_Rule__c`
2. Modifying the trigger evaluation logic in Flows
3. Creating custom Apex classes for complex rule evaluation

### UI Customization
- Modify LWC templates for different visual layouts
- Add custom CSS for organization branding
- Extend component properties for additional configuration options

### Flow Customization
- Add custom approval notification logic
- Implement escalation rules for delayed approvals
- Create custom approval routing based on business rules

## Testing

The framework includes comprehensive test coverage:

- **ApprovalPreviewControllerTest**: Tests data retrieval and DTO conversion
- **LiveApprovalCreatorTest**: Tests Live_Approval__c record creation
- **FindTriggeredApprovalRulesTest**: Tests rule trigger identification
- **UpdateLiveApprovalInvocableTest**: Tests approval status updates
- **ApprovalRecordsWrapperTest**: Tests data wrapper functionality
- **QuoteLineItemControllerTest**: Tests quote line item functionality

### Running Tests
```bash
# Run all tests
sfdx force:apex:test:run

# Run specific test class
sfdx force:apex:test:run -n "ApprovalPreviewControllerTest"

# Run with code coverage
sfdx force:apex:test:run --code-coverage
```

## Support Scripts

The framework includes utility scripts in the `scripts/` directory:

### Apex Scripts
- **createApprovalQuestions.apex**: Creates default approval questions for all rules
- **seedApprovalPreviews.apex**: Seeds sample approval data for testing

### Usage
```bash
# Execute apex scripts
sfdx force:apex:execute -f scripts/apex/createApprovalQuestions.apex
```

## Troubleshooting

### Common Issues

**Live_Approval__c records not created**
- Verify approval rules exist and are properly configured
- Check that the LiveApprovalCreator is being called with valid data
- Ensure proper field-level security on Live_Approval__c fields

**Approval preview components not displaying data**
- Confirm `recordId` is properly passed to the component
- Verify Live_Approval__c record exists for the Quote
- Check that approval rules have `Triggered_X__c = true`

**Flow execution errors**
- Review Flow error logs in Setup > Process Automation > Flow
- Verify all required fields are populated on input records
- Check user permissions for all referenced objects

### Debug Mode

Enable debug logging for approval framework components:
```apex
// Add to Anonymous Apex
System.debug(LoggingLevel.DEBUG, 'Approval Debug Information');
```

## Performance Considerations

- **Live_Approval__c slots**: Limited to 20 approval rule slots per quote
- **SOQL Limits**: Bulk operations handle multiple quotes efficiently
- **View State**: LWC components use `@track` for optimal rendering
- **Flow Bulkification**: All invocable methods support bulk processing

## Future Enhancements

Potential framework extensions:
- **Mobile-optimized approval interface**
- **Advanced approval analytics and reporting**
- **Integration with third-party approval systems**
- **Automated approval routing based on workload**
- **Approval template management**

## License

This framework is provided as-is for educational and development purposes. Please ensure compliance with your organization's Salesforce licensing agreements.

---

For additional support or feature requests, please contact your Salesforce administrator or development team.
