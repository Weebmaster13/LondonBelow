# Inventory Capacity Runtime

Capacity schemas define conservative limits such as `maxSlots`. Capacity prevents future systems from building unbounded inventory records.

Capacity does not enforce final UI, item pickup, item use, or physical containment. It is a schema policy, not gameplay execution.

Unknown or malformed capacity records reject. Capacity values are clamped by validation limits and must remain finite numeric values.
