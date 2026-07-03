# Content Reference Runtime

References describe safe relationships between two registered content definitions.

A reference requires:

- `referenceId`
- `ownerSystem`
- `sourceContentId`
- `targetContentId`

Both endpoints must already exist. The runtime rejects missing endpoint references, duplicates, unsupported schema types, and unsafe payloads.

References are descriptive links only. They do not load, stream, spawn, render, execute, or complete anything.

## Hardening Notes

References require existing source and target content definitions. Missing endpoints reject. Self-references reject. Reference records must remain schema links; they must not store Roblox Instances, Workspace paths, asset handles, service references, remote references, callbacks, or execution adapters.
