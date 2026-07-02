# Interaction Object Runtime

`InteractionObjectRuntime` stores bounded interaction schemas and related records.

Each interaction schema includes:

- `interactionId`
- `physicalObjectId`
- `interactionType`
- `ownerSystem`
- `eligibility`
- `requiredState`
- `cooldown`
- `lockState`
- `metadata`
- `context`
- `tags`

Public state is deep-copied and contains no Roblox Instances.
