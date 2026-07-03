# TRIGGER VALIDATION

Trigger validation rejects malformed schemas, duplicate ids, unsupported types, unsupported domains, unsupported event/group/outcome kinds, invalid references, self dependencies, direct cycles, unsafe metadata/context/tags, forbidden execution/dispatch/callback/listener/client/service/content markers, oversized payloads, deep payloads, cycles, Roblox Instances, functions, threads, and userdata.

## Production Hardening

Production hardening: validation scans metadata, context, tags, nested tables, table keys, and string values for trigger/event/callback/listener/condition/rule/scheduler/lifecycle/EventGraph/RuntimeGraph/ConditionRuntime/orchestration/scripting/state/gameplay/service/remote/client/content markers. Duplicate ids reject globally before mutation.
