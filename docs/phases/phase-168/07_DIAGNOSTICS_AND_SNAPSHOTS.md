# Diagnostics And Snapshots

Diagnostics use provider `runtimeWorkflowOrchestration` and lowerCamelCase posture key `workflowOrchestrationPosture`.

Diagnostics expose:

- workflow definitions;
- workflow instances;
- lifecycle state;
- schedule;
- pending waits;
- retries;
- timeouts;
- compensation records;
- evidence;
- metrics;
- profiler metadata;
- budgets;
- certification posture.

Snapshots expose isolated deep copies through snapshot provider `runtimeWorkflowOrchestration`.

Diagnostics explicitly report no direct subsystem coupling, no gameplay authority, no command execution, no event publication, no query mutation, no networking, no persistence execution, no Workspace mutation, and no client authority.
