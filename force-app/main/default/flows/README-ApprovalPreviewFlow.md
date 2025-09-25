Flow example: Passing ApprovalPreview JSON to the LWC

This document describes a simple Screen Flow that gets Approval_Preview__c records, converts them to the JSON shape using the invocable Apex action `ApprovalPreviewController.convertIdsToJson`, and then displays them in the `approvalPreviewTable` LWC on a Flow Screen.

Steps
1. Get Records (ApprovalPreviewRecords)
   - Object: Approval_Preview__c
   - Filter: (optional) set criteria to limit which previews to display
   - Store: Choose to store all records

2. Create a Text Collection (IdsCollection)
   - Use Assignment to create/collect the Ids of the retrieved Approval_Preview__c records into a Collection Variable (Text) or use the Id field directly.

3. Apex Action: ApprovalPreviewController.convertIdsToJson
   - Input: create a request record with the `recordIds` property set to the collection of Ids.
   - Output: The action returns a list of FlowResponse objects; typically take the first entry and its `json` field.

4. Screen: Add the `approvalPreviewTable` LWC to the screen
   - In the component properties, set `flowData` to the Flow variable containing the JSON string (from step 3 output).

Notes
- The invocable method expects the request shape defined in Apex (list of FlowRequest). The Flow builder will show the Apex action and allow mapping a collection of Ids.
- If you prefer the LWC to query directly from Apex (no Flow usage), leave the `flowData` property empty and the component will fetch results itself.
- Ensure the static resource `ApprovalPreviewIcons` is deployed. It must contain `user.svg` and `group.svg` at the root of the zip.

If you'd like, I can also create an unmanaged Flow XML export that can be deployed, or a simple screenshot step-by-step guide with Flow screenshots.