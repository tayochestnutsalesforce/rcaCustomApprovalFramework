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

### Level-Based Approval Architecture

The RCA Custom Approval Framework implements a sophisticated **4-Level Hierarchical Approval System** that provides granular control over complex approval processes:

#### Level Structure Overview
- **Level 1**: Initial approval tier (Stage 1) - typically line managers, team leads
- **Level 2**: Secondary approval tier (Stage 2) - department managers, senior staff  
- **Level 3**: Executive approval tier (Stage 3) - directors, VPs
- **Level 4**: Final approval tier (Stage 4) - C-level executives, ultimate authority

#### Key Architectural Components

**1. Hierarchical Flow Progression**
- Sequential level processing with mandatory progression through each active level
- Each level can contain multiple parallel approval chains
- Up to 6 individual approvals per level (Approval_1 through Approval_6)
- Automatic progression to next level only after current level completion

**2. Dynamic Level Assignment**
- Live_Approval__c records support Level__c field for level-based filtering
- Approval rules are organized by Level__c (1-4) and Order__c within each level
- Dynamic slot assignment based on triggered rules within each level
- Support for up to 20 total approval slots across all levels

**3. Stage-Based Orchestration**
- **Stage 1** → **Evaluate Level 1** → **Check Level 1 Status** → **Stage 2**
- **Stage 2** → **Evaluate Level 2** → **Check Level 2 Status** → **Stage 3**  
- **Stage 3** → **Evaluate Level 3** → **Check Level 3 Status** → **Stage 4**
- **Stage 4** → **Evaluate Level 4** → **Check Level 4 Status** → **Approval Stage**

**4. Level-Specific Evaluation Logic**
- Each level has dedicated evaluation flows (Evaluate_Level_1 through Evaluate_Level_4)
- Level-specific status aggregation using RCA_Set_Approve_or_Rejected
- Independent approval tracking per level with consolidated decision making
- Rejection at any level terminates the entire approval process

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
   - **Level__c**: Approval level designation (1-4) for level-based processing
   - **Approval_Rule_1__c** through **Approval_Rule_20__c**: References to active approval rules
   - **Triggered_1__c** through **Triggered_20__c**: Boolean flags indicating if rule is triggered
   - **Status_1__c** through **Status_20__c**: Current approval status (N/A, Pending, Approved, Rejected)
   - **Approver_1__c** through **Approver_20__c**: Assigned approver for each slot
   - **Level-based slot allocation**: Rules automatically assigned to slots based on Level__c and Order__c

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
- Creates Live_Approval__c records for new quotes with level-based organization
- `createLiveApprovals(List<Requests> requests)`: Invocable method for Flow integration
- **Level-aware slot assignment**: Populates up to 20 approval rule slots organized by level
- **Hierarchical ordering**: Orders rules by Level__c first, then Order__c for consistent slot assignment
- **Level field population**: Sets Level__c field on Live_Approval__c for level-based filtering

**FindTriggeredApprovalRules**
- Identifies which approval rules are currently triggered for a quote
- `find(List<Request> requests)`: Returns approval rule IDs where Triggered_X__c = true
- Uses dynamic SOQL to handle variable field patterns
- Supports both Boolean and String trigger indicators

**UpdateLiveApprovalInvocable**
- Updates Live_Approval__c records with new approval statuses using level-aware processing
- `updateApprovals(List<Requests> requestGroups)`: Invocable method for bulk updates
- **Level-based filtering**: Can filter updates by specific levels using Level__c field
- Handles approver assignment, status changes, and trigger state updates
- Supports processing multiple approval records per quote across different levels

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
**Purpose**: Visual mosaic display of approval status organized by chains and levels with level-based matrix layout

**Key Features**:
- **Level-based matrix visualization**: Displays approvals in a grid with levels as rows and chains as columns
- **Multi-level support**: Automatically detects and displays all approval levels (1-4+)
- **Stacked card display**: Shows multiple approvals per level/chain intersection
- Groups approvals by Chain for columnar display with level progression
- Displays approval cards with status colors and approver avatars
- **Level dividers**: Clear visual separation between approval levels
- Supports tooltip hover information with approval questions/answers
- Configurable status color mapping via component properties
- Responsive design adapting to different chain and level configurations

**Level-Based Display Logic**:
- Automatically groups approvals by Level__c field
- Sorts levels numerically (Level 1 → Level 2 → Level 3 → Level 4)
- Shows level labels and dividers for clear hierarchy visualization
- Handles multiple approvals per level with stacked card layout

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
**Purpose**: Tabular view of approval data with grid/table toggle and level-based organization

**Key Features**:
- **Level-based grid layout**: Organizes approvals by level with clear level dividers
- **Configurable level display**: Supports `maxLevel` property to set maximum displayed levels
- **Level divider control**: `dividerLevel` property controls where visual dividers appear
- Dual view modes: visual grid (level-based) and data table (flat)
- Sorting and filtering capabilities with level-aware processing
- Supports direct Flow data injection via `flowData` property
- **Placeholder level slots**: Shows empty slots for unconfigured levels up to maxLevel
- Lightning datatable integration for advanced data operations with level/order columns

**Level-Based Processing**:
- Groups approvals by Chain, then organizes by Level within each chain
- Sorts by Order within each level for consistent display
- Pads levels to ensure consistent slot counts across all chains
- Level-aware placeholder generation for empty approval slots

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

#### RCA_Approval_Orch (Main Orchestration Flow)
**Primary Level-Based Orchestration Flow** managing the complete 4-level approval lifecycle:

**Level-Based Architecture**:
- **4-Level Sequential Processing**: Supports Levels 1-4 with mandatory sequential progression
- **Stage-to-Level Mapping**: Stage 1→Level 1, Stage 2→Level 2, Stage 3→Level 3, Stage 4→Level 4
- **Individual Approval Steps**: Up to 6 parallel approvals per level (Approval_1 through Approval_6)
- **Level-specific triggers**: Each approval step checks corresponding Triggered_X__c flags

**Flow Progression Logic**:
1. **Check Live Stage** → Calls RCA_Approval_Rule_Evaluation_Flow for initial setup
2. **Stage 1** → Processes Level 1 approvals (Approval_1, Approval_2)
3. **Evaluate Level 1** → Calls RCA_Set_Approve_or_Rejected for level status
4. **Check Level 1 Status** → Decision: Approve → Stage 2, Reject → Rejection Stage
5. **Stage 2** → Processes Level 2 approvals (Approval_3, Approval_4)  
6. **Evaluate Level 2** → Level 2 status evaluation
7. **Check Level 2 Status** → Decision: Approve → Stage 3, Reject → Rejection Stage
8. **Stage 3** → Processes Level 3 approvals (Approval_5)
9. **Evaluate Level 3** → Level 3 status evaluation  
10. **Check Level 3 Status** → Decision: Approve → Stage 4, Reject → Rejection Stage
11. **Stage 4** → Processes Level 4 approvals (Approval_6)
12. **Evaluate Level 4** → Level 4 status evaluation
13. **Check Level 4 Status** → Decision: Approve → Approval Stage, Reject → Rejection Stage

**Stage Exit Actions**: Each stage calls RCA_Stage_Evaluation for post-level processing
**Recall Support**: Dedicated Recall Stage for approval process rollback
**Status Management**: Automatic Quote status updates (Draft/Approved) based on final outcome

#### RCA_Approval_Rule_Evaluation_Flow
Evaluates and initializes approval rules for quotes:
- Determines which approval rules should be triggered based on quote criteria
- Creates or updates Live_Approval__c records with appropriate rule assignments
- Populates approval rule slots (1-20) with triggered rules
- Sets up approver assignments based on rule configuration

#### RCA_Approval_Evaluate_Approve_Reject
Individual approval action flow called for each approval step:
- Handles individual approval/rejection decisions
- Processes approval comments and decisions
- Supports custom email notifications with approval chain context
- Integrates with Smart Approval capabilities when available

#### RCA_Set_Approve_or_Rejected
**Level-specific status aggregation flow** that evaluates multiple approval statuses within each level:
- **Multi-approval evaluation**: Processes up to 4 approval statuses per level simultaneously
- **Level-specific logic**: Determines overall level status (Approve/Reject) based on individual approvals within that level
- **Configurable approval requirements**: Supports different approval criteria per level (all required, majority, any, etc.)
- **Stage progression control**: Returns level-level decision for orchestration flow progression
- **Input parameters**: Status1, Status2, Status3, Status4 for flexible level-based evaluation
- **Output**: stageStatus (Approve/Reject) determining next flow action

#### RCA_Stage_Evaluation
**Post-level evaluation and processing flow** called after each approval level completion:
- **Level-specific data updates**: Updates Live_Approval__c records with current approval statuses for the completed level
- **Next-level preparation**: Prepares data for next level progression by setting up subsequent level approvals
- **Level transition logic**: Handles complex level-to-level transition requirements
- **Status synchronization**: Ensures approval statuses are properly recorded before level progression
- **Exit action**: Called as exitAction from each orchestrated stage (Stage 1-4)

#### RCA_Subflow_Create_Live_Approval_Record
**Level-aware Live_Approval__c record creation and initialization**:
- **Level-based record creation**: Creates Live_Approval__c records with appropriate Level__c assignment
- **Level-specific slot assignment**: Links approval rules to specific quote contexts based on Level__c and Order__c
- **Hierarchical status initialization**: Sets initial status values for all approval slots within the specified level
- **Level-scoped rule assignment**: Establishes approval rule slot assignments (1-20) organized by level
- **Level field population**: Properly sets Level__c field for level-based filtering and processing

#### RCA_Summary_Variable_Flow
Populates context variables for approval evaluation:
- Calculates quote totals, quantities, and line item summaries
- Extracts product family and grouping information
- Sets up variables for rule trigger evaluation
- Provides data context for approval rule criteria evaluation

#### RCA_Update_Quote_Status
Quote status management utility flow:
- Updates Quote status field based on approval outcomes
- Called from various stages (approval, rejection, recall)
- Handles status transitions throughout the approval lifecycle
- Supports status values: Draft, Approved, and custom statuses

#### RCA_Approver_Locator
Dynamic approver assignment and lookup:
- Locates appropriate approvers based on approval rule configuration
- Handles user and queue assignment logic
- Manages fallback approver scenarios
- Outputs approver information for Live_Approval__c assignment

#### Supporting Flows

**RCA_Approval_Preview**
- Manages approval preview data for UI components
- Formats approval data for Lightning Web Component consumption

**RCA_Prepare_Approval_Questions_for_Answers**
- Sets up questionnaire data for approval rules
- Retrieves approval questions associated with triggered rules
- Prepares question/answer context for approvers

**RCA_Screen_Approval_Answers**
- Handles approval question responses and data collection
- Processes approver input for approval questions
- Stores answers in ApprovalAnswers__c records

**RCA_Recall_Live_Approval_Statuses**
- Manages approval recall scenarios
- Resets Live_Approval__c statuses when approvals are recalled
- Synchronizes approval states during recall processes

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

#### 1. Create Level-Based Approval Rules
```apex
// Create approval rules with proper level hierarchy
// Level 1 - Initial Approvals
RCA_Approval_Rule__c managerRule = new RCA_Approval_Rule__c(
    Chain__c = 'Sales Chain',
    Level__c = 1,
    Order__c = 1,
    Title__c = 'Sales Manager Approval',
    Approver_Type__c = 'User',
    Key__c = 'SALES_MANAGER'
);

// Level 2 - Department Approvals  
RCA_Approval_Rule__c directorRule = new RCA_Approval_Rule__c(
    Chain__c = 'Sales Chain',
    Level__c = 2,
    Order__c = 1,
    Title__c = 'Sales Director Approval',
    Approver_Type__c = 'User',
    Key__c = 'SALES_DIRECTOR'
);

// Level 3 - Executive Approvals
RCA_Approval_Rule__c vpRule = new RCA_Approval_Rule__c(
    Chain__c = 'Sales Chain',
    Level__c = 3,
    Order__c = 1,
    Title__c = 'VP Sales Approval',
    Approver_Type__c = 'User',
    Key__c = 'VP_SALES'
);

// Level 4 - Final Authority
RCA_Approval_Rule__c ceoRule = new RCA_Approval_Rule__c(
    Chain__c = 'Sales Chain',
    Level__c = 4,
    Order__c = 1,
    Title__c = 'CEO Final Approval',
    Approver_Type__c = 'User',
    Key__c = 'CEO_APPROVAL'
);

insert new List<RCA_Approval_Rule__c>{managerRule, directorRule, vpRule, ceoRule};
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

#### Creating Level-Based Live Approvals
```apex
// Using the LiveApprovalCreator with level specification
LiveApprovalCreator.Requests request = new LiveApprovalCreator.Requests();
request.quoteId = 'a0XX000000XXXXX';
request.level = 1; // Specify the approval level
request.approvalRuleIds = new List<String>{'a0YX000000XXXXX'};

LiveApprovalCreator.createLiveApprovals(new List<LiveApprovalCreator.Requests>{request});
```

#### Level-Specific Approval Updates
```apex
// Using the UpdateLiveApprovalInvocable with level filtering
ApprovalRecordsWrapper approval = new ApprovalRecordsWrapper();
approval.approvalRuleId = 'a0YX000000XXXXX';
approval.triggeringStatus = true;
approval.approver = '005X000000XXXXX';
approval.approvalStatus = 'Approved';

UpdateLiveApprovalInvocable.Requests request = new UpdateLiveApprovalInvocable.Requests();
request.quoteId = 'a0XX000000XXXXX';
request.approvals = new List<ApprovalRecordsWrapper>{approval};
// Level filtering handled automatically based on approval rule configuration

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
Extend approval rule evaluation with level-based logic by:
1. Adding custom fields to `RCA_Approval_Rule__c` with level-specific criteria
2. Modifying the trigger evaluation logic in Flows to respect level hierarchies
3. Creating custom Apex classes for complex level-based rule evaluation
4. Implementing level-specific approval thresholds and requirements

### UI Customization for Level-Based Display
- **Level-aware LWC templates**: Modify templates to emphasize level progression
- **Level-specific styling**: Add custom CSS for level-based visual hierarchy
- **Level progression indicators**: Extend component properties for level status visualization
- **Multi-level responsive design**: Optimize for varying numbers of active levels

### Flow Customization for Level Architecture
- **Level-specific notification logic**: Add custom approval notifications per level
- **Level-based escalation rules**: Implement escalation within levels for delayed approvals
- **Custom level routing**: Create business rules for skipping levels based on criteria
- **Level-parallel processing**: Enable parallel approvals within specific levels

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

- **Live_Approval__c level organization**: Limited to 20 approval rule slots total, organized across 4 levels
- **Level-based SOQL optimization**: Bulk operations filter by Level__c for efficient processing
- **Multi-level view state**: LWC components use `@track` for optimal rendering across level hierarchies
- **Flow bulkification**: All invocable methods support bulk processing with level-aware batching
- **Level progression efficiency**: Sequential level processing minimizes unnecessary evaluations
- **Memory optimization**: Level-based slot allocation reduces data footprint per approval context

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
