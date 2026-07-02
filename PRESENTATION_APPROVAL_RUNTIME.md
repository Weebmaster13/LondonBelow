# Presentation Approval Runtime

`PresentationApprovalRuntime` verifies approval evidence for presentation plans.

## Rules

- At least one approved approval is required.
- Duplicate approval ids reject.
- Rejected, expired, missing, or malformed approvals reject.
- Approval records are schemas only.

Approvals do not execute presentation.
