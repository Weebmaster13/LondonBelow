# Session Serialization

Session serialization deep-copies public exports and sanitizes diagnostics payloads.

It rejects Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized node counts, and overly deep payloads. Diagnostics and snapshots are isolated copies.

Diagnostic copies sanitize unsafe values instead of returning live runtime objects. Snapshot exports use deep copies and preserve session schema records only.
