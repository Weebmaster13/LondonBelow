# Inventory Item Runtime

Inventory items are server-owned schemas for future objects that may later become keys, notes, tools, fragments, or chapter-specific items.

An item schema contains:

- `itemId`
- `itemType`
- `ownerSystem`
- `slotId`
- optional `state`
- optional `eligibility`
- optional metadata, context, and tags

The runtime does not spawn items, pick up items, use items, equip items, consume items, unlock doors, solve puzzles, or mutate gameplay truth.
