# Performance Threshold Runtime

Threshold schemas define warning levels for future performance budget reports.

Thresholds may describe soft warning, hard warning, certification, and release-blocking boundaries, but they do not sample metrics and do not trigger automatic throttling.

Future systems must treat thresholds as policy data. Any runtime response to a threshold must be implemented in a separate governed system and must remain auditable.
