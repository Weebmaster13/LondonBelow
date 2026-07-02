# Objective Validation

Objective validation rejects malformed objectives, unsupported objective types, malformed tasks, duplicate task ids, malformed requirements, duplicate requirement ids, malformed dependencies, duplicate dependency ids, malformed state, malformed progress, duplicate progress ids, unknown objective progress, unsafe progress payloads, unsafe metadata/context/tags, Roblox Instances, unsafe runtime values, cycles, oversized payloads, and deep payloads.

It also rejects client, remote, Workspace, objective completion execution, quest execution, gameplay execution, puzzle execution, interaction execution, inventory execution, UI, Audio, Lighting, Camera, Monster AI, Narrative, Save persistence, Horror pacing, Chapter, story, dialogue, and cutscene fields.

## Registration Rules

- Objective ids must be unique.
- Task ids, requirement ids, and dependency ids must be unique inside one objective.
- Progress ids must be unique globally within the runtime.
- Progress records must reference a known objective id.
- Objective, task, requirement, dependency, state, and progress schema types must be supported when provided.
- Unsafe payloads reject before any state change.
