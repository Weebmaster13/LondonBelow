# Asset Execution Implementation Contract Self-Checks

Self-checks run before startup and verify the runtime remains schema-only.

Coverage includes provider name consistency, schema terminology consistency, nil and non-table rejection, id validation, contract kind and status validation, responsibility kind validation, boundary kind validation, audit kind and status validation, child contract references, missing contract references, unsafe payload rejection, duplicate global id rejection, bounded limits, failed validation without mutation, snapshot isolation, diagnostics health-only copies, diagnostics analytics and telemetry absence, lowerCamelCase posture keys, shutdown cleanup, namespace reset, and banned runtime surface absence.

Forbidden marker checks cover asset loading, preloading, streaming, spawning, application, playback, UI, VFX, Workspace and storage mutation, remotes, client authority, DataStore, HTTP, MessagingService, analytics, telemetry, gameplay execution, Presentation execution, Save execution, Chapter content, maps, rooms, dialogue, cutscenes, callbacks, listeners, module references, execution adapters, dispatch, publish, and subscribe.
