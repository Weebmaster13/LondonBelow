# Security Review

Phase 183 is default-deny. It rejects functions, coroutines, userdata, cyclic
tables, excessive depth, excessive payload nodes, unsupported fields, invalid
enums, and malformed references.

The runtime contains no executable Roblox GUI creation path, no remotes, no
client authority, no networking, no persistence, no Workspace mutation, no
asset loading, no camera manipulation, no animation playback, no sound
playback, no analytics, and no telemetry.

Forbidden executable-source scans must target invocation patterns rather than
documentation strings that intentionally document prohibited surfaces.
