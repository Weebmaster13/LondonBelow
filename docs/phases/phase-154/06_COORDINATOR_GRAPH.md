# Phase 154 Coordinator Graph

| coordinator | owner | initializationOrder | dependencies | dependents | failureState | verified | blocked |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CoreBootstrap | RuntimeExecutionFramework | 1 |  | Governance, Diagnostics | NOT_EXECUTED | false | true |
| Governance | Core | 2 | CoreBootstrap | Contracts, Observation, Presentation | NOT_EXECUTED | false | true |
| Contracts | Governance | 3 | Governance |  | NOT_EXECUTED | false | true |
| Diagnostics | Core | 4 | CoreBootstrap | Snapshots, Observation, Presentation | NOT_EXECUTED | false | true |
| Snapshots | Core | 5 | Diagnostics |  | NOT_EXECUTED | false | true |
| Observation | Observation | 6 | Governance, Diagnostics | Interaction, Chapter0HomeCoordinator | NOT_EXECUTED | false | true |
| Interaction | Interaction | 7 | Observation | Chapter0HomeCoordinator | NOT_EXECUTED | false | true |
| Presentation | Presentation | 8 | Governance, Diagnostics | Chapter0HomeCoordinator | NOT_EXECUTED | false | true |
| Chapter0HomeCoordinator | Chapter0Home | 9 | Observation, Interaction, Presentation |  | NOT_EXECUTED | false | true |
