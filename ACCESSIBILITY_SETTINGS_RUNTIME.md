# Accessibility Settings Runtime

Accessibility setting schemas describe future setting records as data.

Each setting must include:

- `settingId`
- `ownerSystem`
- optional `schemaType = "AccessibilitySettingsSchema"`
- safe `metadata`
- safe `context`
- safe `tags`

Registering a setting schema does not apply client settings, create UI, create remotes, or mutate gameplay.
