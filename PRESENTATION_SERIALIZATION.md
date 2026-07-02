# Presentation Serialization

`PresentationSerialization` deep-copies public state and rejects unsafe runtime values.

Rejected values include Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, overly deep payloads, and oversized node counts.

Diagnostics store sanitized payloads only and never retain raw unsafe runtime references.
