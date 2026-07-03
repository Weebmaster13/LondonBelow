# Content Version Runtime

Version records describe future version metadata for registered content definitions.

A version requires:

- `versionId`
- `ownerSystem`
- `contentId`

The target content id must exist before a version can register. Version records are catalog metadata only; they do not migrate saves, load packages, patch content, or execute update logic.
