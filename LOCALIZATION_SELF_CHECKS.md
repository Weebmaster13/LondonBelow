# Localization Self-Checks

Localization self-checks are destructive and must run before runtime start.

They prove malformed, duplicate, unsupported-type, unsafe, and valid registration paths for language, text key, package, fallback, subtitle, caption, and text safety schemas.

They also prove global id rejection across every localization category, forbidden field rejection, serialization rejection of cycles, Roblox Instances, functions, threads, oversized strings, oversized node counts, and deep payloads, diagnostic sanitization, isolated snapshots, read-only diagnostics, bounded histories, bounded snapshots, runtime category limit rejection, shutdown cleanup, global namespace reset on shutdown, and post-start self-check refusal.

No-execution checks prove no final translated text, final dialogue, story writing, Chapter content, automatic translation, external service calls, HTTP, messaging, DataStore reads/writes, subtitle/caption rendering, voiceover/audio execution, UI rendering, client presentation, remotes, client authority, or Workspace mutation exists.

## Hardened Proof List

The self-check suite proves malformed, duplicate, unsupported-type, unsafe, and valid paths for all seven schema categories. It proves global id rejection across the category chain, unsafe metadata/context/tags rejection, nested forbidden field rejection, forbidden table key rejection, forbidden string value rejection, individual forbidden content/translation/rendering/ownership field rejection, serialization safety, diagnostic sanitization, isolated snapshots, read-only diagnostics, bounded histories, bounded snapshots, runtime category limit rejection, shutdown state cleanup, shutdown namespace cleanup, and post-start self-check refusal.

No-execution proof includes no Narrative ownership, no Save ownership, no Analytics ownership, no moderation, no censorship execution, and no content rewriting.
