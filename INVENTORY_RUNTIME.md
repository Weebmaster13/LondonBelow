# Inventory Runtime

Inventory Runtime owns server-side inventory truth.

It supports personal inventory now and party inventory hooks for later. Item kinds include keys, quest items, artifacts, puzzle pieces, tools, documents, lantern fuel hooks, and custom items.

Per-player inventory growth is bounded by runtime configuration. Future save and party systems should serialize through the runtime snapshot instead of reading internal containers directly.

Clients cannot create items, remove items, claim keys, or decide inventory truth. Future UI can only present server-owned state.

Persistence, final UI, item placement, and Chapter 1 rewards are future systems.
