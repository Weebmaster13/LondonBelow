# Security Serialization

Security serialization deep-copies public exports and sanitizes diagnostics payloads.

It rejects Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized node counts, and overly deep payloads.

Snapshots and diagnostics are isolated copies. They do not contain service references, executable callbacks, unsafe runtime values, or Roblox Instances.

Serialization is part of the no-execution boundary. Security schemas may describe future policy, but they must not contain enforcement adapters, client monitoring loops, remotes, DataStore handles, analytics emitters, telemetry exporters, moderation actions, or punishment commands.
