# Performance Self-Checks

Performance self-checks are destructive and should run before runtime start.

They prove malformed budget/category/threshold/report records reject, unsupported schema types reject, duplicate ids reject across one global performance schema namespace, valid schemas register, unsafe metadata/context/tags reject, forbidden execution fields reject, serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads, snapshots are isolated, diagnostics are read-only, histories are bounded, shutdown clears state, and no live profiling, optimization execution, automatic throttling, analytics collection, telemetry sending, memory/network/render mutation, client monitoring, remotes, Workspace mutation, or Chapter content exists.

These checks use synthetic schemas only. They must not become live profiling, client monitoring, analytics collection, or runtime optimization.

## Hardened Proof List

The current self-check suite explicitly proves:

- malformed budget rejects, duplicate budget rejects, unsafe budget rejects, and valid budget registers;
- malformed category rejects, duplicate category rejects, unsafe category rejects, and valid category registers;
- malformed threshold rejects, duplicate threshold rejects, unsafe threshold rejects, and valid threshold registers;
- malformed report rejects, duplicate report rejects, unsafe report rejects, and valid report registers;
- duplicate ids reject globally across budget, category, threshold, and report categories;
- unsupported schema types reject;
- unsafe metadata, unsafe context, and unsafe tags reject;
- profiling execution, optimization execution, throttling execution, analytics collection, telemetry, memory mutation, network mutation, render mutation, client/remote, Workspace/gameplay, and Chapter/story/dialogue/cutscene fields reject;
- serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads;
- snapshots are isolated, diagnostics are read-only, histories are bounded, and shutdown clears state;
- no live profiling, optimization execution, automatic throttling, analytics collection, telemetry sending, memory/network/render mutation, client monitoring, remotes, Workspace mutation, gameplay execution, or Chapter content exists.

Self-checks remain pre-start certification tools. They do not collect measurements, export telemetry, or tune runtime behavior.
