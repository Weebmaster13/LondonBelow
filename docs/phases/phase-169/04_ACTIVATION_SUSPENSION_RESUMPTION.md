# Activation Suspension Resumption

`RuntimeWorkflowOrchestration.activateWorkflow()` performs the integrated activation sequence:

1. Validate duplicate correlation absence.
2. Create the workflow instance through the existing Phase 168 path.
3. Create correlation metadata.
4. Record causation metadata.
5. Record activation metadata.
6. Record scheduler admission evidence.
7. Schedule the workflow through the existing scheduler.

`suspendWorkflow()` uses the existing wait path and records suspension metadata.

`resumeWorkflow()` routes an incoming message, transitions lifecycle back to `Running`, and records resumption metadata.

These operations coordinate workflow state only. They do not claim authority over domain runtime state.
