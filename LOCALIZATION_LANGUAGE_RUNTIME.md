# Localization Language Runtime

Language records are schemas, not player locale execution.

Language schemas define future locale definitions and require `languageId`, `ownerSystem`, optional `schemaType = LocalizationLanguageSchema`, safe metadata, safe context, and safe tags.

This runtime does not choose player locale truth, render UI, translate content, or expose client authority.

Language records cannot contain final text, translation handles, service references, remotes, client authority, or player locale execution commands.
