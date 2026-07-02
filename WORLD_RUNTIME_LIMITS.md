# World Runtime Limits

World Runtime is bounded by design.

- Districts, regions, buildings, floors, rooms, zones, connections, streaming regions, classifications, and tags are capped.
- Validation failure and snapshot histories are capped.
- Payload depth, node count, string length, tag count, and reference counts are capped.

These limits prevent the world schema layer from becoming unbounded memory growth.
