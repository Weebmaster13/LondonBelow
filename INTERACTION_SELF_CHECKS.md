# Interaction Self-Checks

`InteractionSelfChecks` certifies Phase 23 behavior.

Self-checks prove malformed interactions reject, duplicate interactions reject, unsupported types reject, valid interactions register, missing physical object ids reject, unsafe eligibility rejects, unsafe metadata rejects, unsafe context rejects, invalid cooldowns reject, valid cooldowns record, invalid locks reject, valid locks record, interaction intents record safely, client and remote fields reject, Workspace and Instance values reject, animation/audio/UI/lighting/physics/movement fields reject, inventory/door/drawer/pickup/puzzle execution fields reject, MonsterAI/Narrative/Save/Horror/Chapter/story/dialogue/cutscene fields reject, serialization rejects cycles and unsafe runtime values, oversized payloads reject, deep payloads reject, snapshots are isolated, diagnostics are read-only, histories are bounded, and shutdown clears state.
