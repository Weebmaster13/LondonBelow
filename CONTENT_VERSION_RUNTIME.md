# Content Version Runtime

Version records describe future version metadata for registered content definitions.

A version requires:

- `versionId`
- `ownerSystem`
- `contentId`

The target content id must exist before a version can register. Version records are catalog metadata only; they do not migrate saves, load packages, patch content, or execute update logic.

## Hardening Notes

Versions are compatibility records, not migrations or patch execution. They cannot mutate saves, load package versions, patch content, call external services, or alter gameplay state.
