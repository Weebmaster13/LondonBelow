# Content Package Runtime

Packages group registered content ids into bounded package records.

Packages may describe future chapter packages, room bundles, item packs, puzzle packs, localization packages, presentation packages, or system packages. They do not load assets, stream rooms, spawn objects, or ship final content.

Every package member must reference an existing content definition. Package member counts are bounded to keep future tooling predictable and diagnostics readable.

## Hardening Notes

Packages are groups, not asset bundles. They cannot contain asset handles, loader configuration, streaming configuration, package loading adapters, final Chapter content, final room layouts, story, dialogue, execution hooks, or client presentation instructions.
