# Journal Runtime

`JournalRuntime` owns server-authoritative journal entry unlock truth.

Journal entries are schema records only. They are unlockable, inspectable, serializable, and safe. They do not include final UI, final prose, final story dialogue, cutscenes, or Chapter content.

## Rules

- Server owns journal truth.
- Duplicate entry IDs reject per profile.
- Unsafe metadata rejects.
- Client-like payloads reject.
- Entries are exported through diagnostics and snapshots as copied data.

## Future Work

A later UI phase may present entries. A later writing/content phase may author final text. Those systems must consume server-approved journal state instead of inventing client truth.