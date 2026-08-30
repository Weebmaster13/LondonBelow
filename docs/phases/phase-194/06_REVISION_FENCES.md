# Revision Fences
## Ownership
Contract ID, render revision, theme ID, and theme revision must exactly match active registered state.
## Non-Ownership
The runtime cannot advance the render tree or infer a newer theme.
## Certification Boundary
Stale and conflicting revisions reject without visual mutation.
