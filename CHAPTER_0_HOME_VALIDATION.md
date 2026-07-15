# Chapter 0 Home Validation

Phase 109 validation is performed by `Chapter0HomeValidation`.

Validation rejects:

- non-table definitions;
- invalid `chapterId`;
- missing display name or spawn;
- duplicate room ids;
- duplicate interaction ids;
- sparse or dictionary-shaped room, interaction, connection, and completion arrays;
- unknown room references;
- unknown room-connection references;
- unsupported room or interaction kinds;
- missing prompts;
- over-limit room or interaction counts;
- unsafe metadata keys related to DataStore, HTTP, MessagingService, telemetry, analytics, remotes, or client authority;
- completion requirements that reference missing interactions.
- completion requirements that reference optional interactions;
- required interactions missing from the completion list.

Validation runs before `Chapter0HomeCoordinator` creates Workspace content.
