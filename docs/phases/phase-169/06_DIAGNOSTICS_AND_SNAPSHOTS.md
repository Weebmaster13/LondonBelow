# Diagnostics And Snapshots

Diagnostics expose:

- `workflowIntegrationPosture`;
- `workflowIntegration.correlationRecords`;
- `workflowIntegration.causationRecords`;
- `workflowIntegration.routingRecords`;
- `workflowIntegration.executionPipeline`;
- `workflowIntegration.activationRecords`;
- `workflowIntegration.suspensionRecords`;
- `workflowIntegration.resumptionRecords`;
- `workflowIntegration.completionRecords`;
- `workflowIntegration.schedulerHardening`;
- `noDirectCommandBusExecution`;
- `noDirectEventBusPublication`;
- `noDirectQueryBusExecution`.

Snapshots include the same integration records through `workflowOrchestrationSnapshot.integration`.

All diagnostic and snapshot data is deep copied before publication.
