/**
 * Wrapper class for passing approval record data into Flows / Invocable methods.
 * Fields are annotated with @InvocableVariable so they are available to Flow.
 */
global class ApprovalRecordsWrapper {

    /** ID of the approval rule (as string) */
    @InvocableVariable(label='Approval Rule Id' description='Id of the approval rule')
    @AuraEnabled
    public String approvalRuleId;

    /** Status that triggered the approval (boolean for Flow) */
    @InvocableVariable(label='Triggering Status' description='Status that triggered the approval')
    @AuraEnabled
    public Boolean triggeringStatus;

    /** Approver (User Id or queue id as string) */
    @InvocableVariable(label='Approver' description='User or Queue Id who will approve')
    @AuraEnabled
    public String approver;

    /** Current approval status */
    @InvocableVariable(label='Approval Status' description='Current approval status')
    @AuraEnabled
    public String approvalStatus;

    // No-arg constructor for platform serialization
    public ApprovalRecordsWrapper() {}

    // Convenience constructor
    public ApprovalRecordsWrapper(String approvalRuleId, Boolean triggeringStatus, String approver, String approvalStatus) {
        this.approvalRuleId = approvalRuleId;
        this.triggeringStatus = triggeringStatus;
        this.approver = approver;
        this.approvalStatus = approvalStatus;
    }
}
