# Presentation Self-Checks

`PresentationSelfChecks` certifies Phase 22 behavior.

Self-checks prove malformed requests reject, duplicates reject, unsupported types reject, valid requests record, missing approvals reject, duplicate approvals reject, missing channels reject, invalid channels reject, expired requests reject, unsafe metadata/context reject, client and remote fields reject, Workspace and Instance values reject, final UI/audio/lighting/camera/cutscene fields reject, gameplay/MonsterAI/Narrative/Save/Horror/Chapter fields reject, serialization rejects cycles and unsafe runtime values, oversized payloads reject, snapshots are isolated, diagnostics are read-only, histories are bounded, and shutdown clears state.

They also prove no final UI, audio execution, lighting execution, camera execution, cutscenes, animations, particle/VFX execution, Workspace mutation, client authority, remotes, gameplay execution, Monster AI ownership, Narrative ownership, Save ownership, Horror pacing ownership, or Chapter content exists.
