# Inventory Slot Runtime

Slots describe where future inventory records may be arranged. They are not UI slots, Roblox Instances, backpack containers, hotbar entries, or client-owned state.

Slot schemas must have stable `slotId` values. Duplicate slot ids in a profile reject. Slot counts are bounded by Inventory Runtime limits.

Future UI may present slots, but UI must consume approved presentation data from a later presentation layer, not this schema runtime directly.
