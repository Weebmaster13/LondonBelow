# Framework API And Migration

Phase 152 exports:

- `createExecutionConfiguration`
- `collectExecutionEnvironment`
- `createBackendRegistry`
- `selectBackend`
- `createExecutionSession`
- `evaluateRuntimeExecution`
- `runRuntimeExecution`
- `importExecutionEvidence`
- `validateExecutionEvidenceFile`
- `createRunnerInvocation`
- `validateRunnerResult`
- Studio discovery helpers

Future phases must consume these APIs instead of adding independent launch, evidence, timeout, cleanup, or reporting pipelines.
