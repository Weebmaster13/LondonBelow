# Narrative Validation

`NarrativeValidation` protects Narrative Runtime from content and execution leakage.

## Rejects

- Missing or invalid beat, gate, reveal, and emotional beat IDs.
- Duplicate beats and gates through runtime checks.
- Final dialogue, story prose, Chapter content, cutscene, UI, client, remote, Workspace, Audio, Lighting, Monster AI, horror pacing, execution, and effect fields.
- Roblox Instances.
- Cyclic tables.
- Functions, threads, userdata, oversized strings, overly deep payloads, and oversized payloads.