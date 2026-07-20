# Security Review

The runtime rejects unsafe payloads, Roblox Instances in schema payloads, functions, threads, userdata, cycles, oversized strings, excessive depth, excessive nodes, duplicate ids, invalid request ids, duplicate request ids, rate-limit excess, and target mismatches.

It adds no DataStore, HTTP, MessagingService, analytics, telemetry, remotes, client authority, or Workspace mutation.
