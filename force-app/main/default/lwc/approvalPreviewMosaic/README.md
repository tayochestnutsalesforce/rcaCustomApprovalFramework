Approval Preview Mosaic LWC

Usage:
- Deploy the `approvalPreviewMosaic` LWC and the existing `ApprovalPreviewController` Apex class.
- Place the component on a Quote record page or call it from a Flow screen.
- If used on a record page the component expects `recordId` to be the Quote Id.

Notes:
- The component calls `ApprovalPreviewController.getFlattenedLiveApprovalForQuote` to retrieve per-slot DTOs and groups them by `Chain`.
- Avatars are loaded from the `ApprovalPreviewIcons` static resource (user.svg/group.svg).

Next steps / improvements:
- Add click actions to open the rule or approver record.
- Add loading skeletons and better error formatting.
