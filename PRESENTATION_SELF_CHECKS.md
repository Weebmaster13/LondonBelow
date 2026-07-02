# Presentation Self-Checks

`PresentationSelfChecks` certifies Phase 22 behavior.

Self-checks prove malformed requests reject, duplicates reject, unsupported types reject, valid requests record, missing approvals reject, duplicate approvals reject, malformed approvals reject, missing channels reject, duplicate channels reject, invalid channels reject, expired requests reject, unsafe metadata/context reject, client and remote fields reject, Workspace and Instance values reject, final UI fields reject, audio execution fields reject, lighting execution fields reject, camera execution fields reject, cutscene fields reject, animation fields reject, particle/VFX execution fields reject, gameplay/MonsterAI/Narrative/Save/Horror/Chapter/story/dialogue fields reject, serialization rejects cycles and unsafe runtime values, oversized payloads reject, deep payloads reject, snapshots are isolated, diagnostics are read-only, histories are bounded, and shutdown clears state.

They also prove no final UI, audio execution, lighting execution, camera execution, cutscenes, animations, particle/VFX execution, Workspace mutation, client authority, remotes, gameplay execution, Monster AI ownership, Narrative ownership, Save ownership, Horror pacing ownership, or Chapter content exists.
