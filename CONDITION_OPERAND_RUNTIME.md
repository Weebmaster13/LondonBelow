# Condition Operand Runtime

Condition operands are schema values that describe the shape of future inputs. They are not live values, player facts, world facts, or function arguments.

Operands may describe a future source, expected value kind, or schema metadata. They must not contain Roblox Instances, callbacks, service references, remotes, runtime objects, client-owned values, or execution handles.

Operand records are deep copied on registration and in snapshots.
