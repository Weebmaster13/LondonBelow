# Artifact And History Management

Per-session runtime artifacts are stored under:

`automation/local-state/runtime-execution/<session-id>/`

Committed artifacts are limited to schemas, backend modules, generated catalog, and docs. Binary place artifacts and local runtime result files are not committed.

History is represented by session ID, phase, commit, backend, status, artifacts, cleanup, and summary metadata.
