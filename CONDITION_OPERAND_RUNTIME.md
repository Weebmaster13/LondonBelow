# Condition Operand Runtime

Condition operands are schema values that describe the shape of future inputs. They are not live values, player facts, world facts, or function arguments.

Operands may describe a future source, expected value kind, or schema metadata. They must not contain Roblox Instances, callbacks, service references, remotes, runtime objects, client-owned values, or execution handles.

Operand records are deep copied on registration and in snapshots.

## Production Hardening

Operands reject unsupported schema types, unsafe payloads, live value markers, player state markers, runtime object markers, Roblox Instances, callbacks, functions, threads, userdata, service references, remote references, and Workspace references. Operands are schema values only.
