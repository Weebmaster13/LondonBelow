# Session Self-Checks

Session self-checks are destructive and should run before runtime start.

They prove malformed schemas reject, duplicate session/player session/party ids reject, valid schemas register, malformed readiness/lifecycle/join-leave records reject, unsafe metadata/context/tags reject, forbidden execution fields reject, serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads, snapshots are isolated, diagnostics are read-only, histories are bounded, shutdown clears state, and no matchmaking execution, teleport execution, lobby UI, party gameplay, save persistence, Workspace mutation, remotes, client authority, or Chapter content exists.
