# Analytics Serialization

Analytics serialization deep-copies public exports and sanitizes diagnostics payloads.

It rejects Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized node counts, and overly deep payloads.

Diagnostics and snapshots are isolated copies. Serialization is not analytics collection and does not send data anywhere.
