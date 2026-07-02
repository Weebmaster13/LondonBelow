# Analytics Self-Checks

Analytics self-checks are destructive and should run before runtime start.

They prove malformed records reject, unsupported schema types reject, duplicate event/metric/aggregation/consent/retention/report ids reject, valid schema records register, unsafe metadata/context/tags reject, forbidden collection and transport fields reject, serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads, snapshots are isolated, diagnostics are read-only, histories are bounded, shutdown clears state, and no analytics collection, telemetry sending, player tracking, external reporting, moderation, live metrics, HTTP calls, DataStore writes, MessagingService usage, remotes, client authority, Workspace mutation, or Chapter content exists.
