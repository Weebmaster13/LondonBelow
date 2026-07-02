# Execution Queue Runtime

`ExecutionQueueRuntime` records pending and dry-run execution request state.

## Queue States

- Pending
- Approved
- Rejected
- Cancelled
- Expired
- Queued
- Scheduled
- DryRun

## Rules

- The queue is bounded.
- Queue overflow rejects safely.
- Old runtime histories are bounded by explicit limits.
- Queue state is diagnostics-only and does not execute gameplay.

## Dry-Run Behavior

Accepted requests are scheduled as records and immediately audited as dry-run plans. No timers, no Workspace mutation, and no physical execution occur.
