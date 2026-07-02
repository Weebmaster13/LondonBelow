# Localization Runtime

Phase 35 defines the server-authoritative Localization Runtime Foundation for London Engine.

This runtime is localization schema infrastructure only. It records language definitions, text key records, translation package schemas, fallback policies, subtitle schemas, caption schemas, and text safety schemas.

It does not create final translated text, write dialogue, write story, render UI, display subtitles, render captions, play voiceover, call external translation services, mutate Workspace, create remotes, read or write DataStores, or add Chapter content.

Future translation, subtitle rendering, caption rendering, UI, voiceover, and content writing must be separate governed systems. Consumers must treat localization schemas as constraints and identifiers, not commands.
