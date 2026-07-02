# Tool Self-Checks

Developer Tooling self-checks are destructive and should run before runtime start.

They prove malformed records reject, unsupported schema types reject, duplicate tool/inspection/command/report/permission/audit ids reject across a global schema-id namespace, valid schema records register, unsafe report and audit payloads reject, unsafe metadata/context/tags reject, forbidden execution fields reject, serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads, snapshots are isolated, diagnostics are read-only, histories are bounded, shutdown clears state, and no command execution, live admin tools, remote console, player-facing UI, moderation, analytics collection, exploit/backdoor tooling, DataStore reads/writes, Workspace mutation, remotes, client authority, or Chapter content exists.

Self-checks are destructive because they intentionally exercise duplicate and shutdown paths. Run them before `DeveloperToolsCoordinator.start()`, never as live tooling logic.
