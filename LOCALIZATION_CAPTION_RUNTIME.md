# Localization Caption Runtime

Captions are schemas, not rendered captions.

Caption schemas require `captionId`, `ownerSystem`, optional `schemaType = LocalizationCaptionSchema`, safe metadata, safe context, and safe tags.

This runtime does not render captions, present UI, play audio, or create final caption text.

Future caption rendering must be a separate governed presentation system that consumes approved schema identifiers only.
