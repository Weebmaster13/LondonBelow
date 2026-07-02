# Session Self-Checks

Session self-checks are destructive and should run before runtime start.

They prove malformed schemas reject, unsupported session types reject, duplicate session/player session/party/readiness/lifecycle/join-leave ids reject, unknown session references reject, valid schemas register, malformed readiness/lifecycle/join-leave records reject, unsafe readiness/lifecycle/join-leave payloads reject, unsafe metadata/context/tags reject, forbidden execution fields reject, serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads, snapshots are isolated, diagnostics are read-only, histories are bounded, shutdown clears state, and no matchmaking execution, teleport execution, lobby UI, party gameplay, save persistence, Workspace mutation, remotes, client authority, or Chapter content exists.
