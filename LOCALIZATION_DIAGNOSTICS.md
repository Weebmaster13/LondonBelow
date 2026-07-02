# Localization Diagnostics

Localization diagnostics expose initialized, started, lifecycle state, health, validation posture, language count, text key count, package count, fallback count, subtitle count, caption count, text safety count, validation failure count, snapshot count, per-category limit usage, runtime limits, serialization posture, snapshot isolation proof, diagnostics isolation proof, no-execution posture, recent sanitized validation failures, and last self-check result.

Diagnostics are health-only, not localization analytics. They do not render UI, monitor clients, export final content, call translation services, or display subtitles/captions.

Diagnostics must not contain final story text, final dialogue text, translation files, subtitle/caption presentation payloads, service references, remote references, raw unsafe payload references, localization analytics, player-facing UI, or content exports.
