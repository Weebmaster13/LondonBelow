# Read Models and Cache

Queries read from projections, read models, immutable snapshots, and cache metadata.

The Query Bus owns cache policy metadata, not cache mutation authority. Cache invalidation remains event-driven in future integrations; queries do not invalidate caches directly.
