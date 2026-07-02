# Localization Package Runtime

Packages are schema bundles, not translation files.

Package schemas require `packageId`, `ownerSystem`, optional `schemaType = LocalizationPackageSchema`, safe metadata, safe context, and safe tags.

Packages describe future grouping only. They do not call external services, store production translations, export final content, or perform automatic translation.
