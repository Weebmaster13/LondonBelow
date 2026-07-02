# Localization Validation

Localization validation rejects malformed records, missing ids, malformed ids, unsupported schema types, duplicate ids across one global localization namespace, unsafe metadata, unsafe context, unsafe tags, Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized payloads, and overly deep payloads.

It also rejects final dialogue, final story, Chapter content, automatic translation, external translation services, HTTP, messaging, DataStore, subtitle rendering, caption rendering, voiceover playback, audio execution, UI rendering, client presentation, remote, client authority, Workspace, Narrative ownership, Save ownership, Analytics ownership, cutscene, service reference, adapter reference, handler reference, and execute fields.

Validation protects schema boundaries only. It does not author content, translate content, render UI, display subtitles, play voiceover, call external services, create remotes, or add Chapter content.

## Hardened Validation

Validation rejects forbidden fields anywhere in metadata, context, tags, nested tables, table keys, and string values where applicable. This includes final translated text, final dialogue, story, Chapter, cutscene, translation execution, external translation, HTTP, messaging, DataStore, subtitle/caption rendering, voiceover, audio, UI, client presentation, remote, client authority, Workspace, Narrative/Save/Analytics ownership, moderation, censorship execution, content rewriting, service reference, adapter reference, handler reference, and execute fields.

All schema ids share one global localization namespace. Duplicate rejection happens before state mutation, is deterministic, and is visible only through sanitized diagnostics.
