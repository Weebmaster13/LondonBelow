# Authored Instance Binding

Fixture definitions include `authoringMetadata.authoredInstanceId` and `authoringMetadata.authoredInstanceRequired`.

Binding validation distinguishes:
- required authored references, which block if unavailable;
- optional authored references, which produce warnings but do not block;
- catalog-backed authored references, used by Bootstrap without mutating Workspace.

No Roblox Instance is stored inside diagnostic state or evidence.
