# Content Reference Runtime

References describe safe relationships between two registered content definitions.

A reference requires:

- `referenceId`
- `ownerSystem`
- `sourceContentId`
- `targetContentId`

Both endpoints must already exist. The runtime rejects missing endpoint references, duplicates, unsupported schema types, and unsafe payloads.

References are descriptive links only. They do not load, stream, spawn, render, execute, or complete anything.
