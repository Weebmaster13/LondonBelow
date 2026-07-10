# Asset Governance Certification Decision Serialization

Serialization accepts only bounded primitive/table metadata that can be safely deep-copied for diagnostics and snapshots.

Serialization rejects:

- functions
- threads
- userdata
- Instances and Instance-shaped tables
- cycles
- oversized strings
- deep payloads
- oversized node counts
- runtime handles
- asset handles
- loaded asset handles
- callbacks
- listeners
- services
- module references
- execution adapters
- decision engines
- decision trees
- decision graphs
- approval logic
- approval handlers
- rejection handlers
- authorization handlers
- repair handlers
- orchestration handlers
- scheduling handlers
- routing handlers
- dispatch handlers
- routing tables
- dispatch graphs
- message buses
- event routing markers
- runtime dispatch markers
- runtime dispatchers
- runtime schedulers
- scheduler queues
- execution queues
- repair queues
- approval routing markers
- authorization routing markers
- execution routing markers
- authority tokens
- future execution markers
- live subsystem handles
- networking markers
- persistence markers
- DataStore markers
- HTTP markers
- Messaging markers
- analytics markers
- telemetry markers
- client authority markers
- Workspace mutation markers
- Chapter content markers

Diagnostics use `diagnosticCopy`, which deep-copies safe payloads and replaces unsafe payloads with `<unsafe-payload>`.

Phase 76 hardens serialization rejection for future integration surfaces while preserving deep-copy-only metadata. Serialization does not load, preload, stream, spawn, apply, display, play, authorize, approve, reject, repair, execute, dispatch, route execution, orchestrate, schedule, persist, network, create remotes, grant client authority, mutate Workspace, mutate storage, execute gameplay, execute Presentation, execute Save, or add Chapter content.
