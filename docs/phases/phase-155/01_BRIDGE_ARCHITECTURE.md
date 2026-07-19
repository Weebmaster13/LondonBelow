# Phase 155 Bridge Architecture

Runtime Execution Framework remains the consumer. Studio Runtime Execution Bridge is the Studio-side producer boundary. The bridge is inert unless Studio mode and the explicit DataModel attribute are present.

| file | exists | bytes |
| --- | --- | --- |
| Bootstrap.server.lua | true | 618 |
| Core/BridgeCoordinator.lua | true | 4494 |
| Core/Diagnostics.lua | true | 1358 |
| Core/RuntimeAssertions.lua | true | 1503 |
| Core/RuntimeCapture.lua | true | 1712 |
| Core/RuntimeCleanup.lua | true | 243 |
| Core/RuntimeDiagnostics.lua | true | 808 |
| Core/RuntimeEvidence.lua | true | 2011 |
| Core/RuntimeLifecycle.lua | true | 936 |
| Core/RuntimeSession.lua | true | 890 |
| Core/RuntimeWriter.lua | true | 695 |
| Core/SelfChecks.lua | true | 7388 |
| Core/Serialization.lua | true | 2184 |
| Core/Snapshots.lua | true | 937 |
| Core/State.lua | true | 2151 |
| Core/Types.lua | true | 2453 |
| Core/Validation.lua | true | 3311 |
