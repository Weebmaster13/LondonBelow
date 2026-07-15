# Chapter 0 Home Validation

Phase 109 validation is performed by `Chapter0HomeValidation`. Phase 110 expands the
same validator with closed schema checks, bounded Vector3 checks, and deeper unsafe
payload rejection.

Validation rejects:

- non-table definitions;
- invalid `chapterId`;
- missing display name or spawn;
- unsupported definition, room, or interaction fields;
- duplicate room ids;
- duplicate interaction ids;
- sparse or dictionary-shaped room, interaction, connection, and completion arrays;
- unknown room references;
- unknown room-connection references;
- self-referential room connections;
- duplicate room connections;
- unsupported room or interaction kinds;
- missing prompts;
- over-limit room or interaction counts;
- unbounded, NaN-like, or infinite positions;
- zero, negative, oversized, NaN-like, or infinite room and interaction dimensions;
- unsafe metadata keys related to DataStore, HTTP, MessagingService, telemetry, analytics, remotes, or client authority;
- unsafe metadata payloads containing callbacks, Roblox runtime objects, cycles, or excessive nesting;
- completion requirements that reference missing interactions.
- completion requirements that reference optional interactions;
- required interactions missing from the completion list.

Validation runs before `Chapter0HomeCoordinator` creates Workspace content.
