# World Runtime Limits

World Runtime is bounded by design.

- Districts, regions, buildings, floors, rooms, zones, connections, streaming regions, classifications, and tags are capped.
- Validation failure and snapshot histories are capped.
- Payload depth, node count, string length, tag count, and reference counts are capped.

These limits prevent the world schema layer from becoming unbounded memory growth.

## Limit Behavior

World schema category limits reject new registrations once the category is full. They do not silently evict live world schemas. Diagnostic and snapshot histories remain bounded rolling histories because they are observability records, not source-of-truth schemas.
