# Physical Transform Runtime

`PhysicalTransformRuntime` stores transform schemas for registered physical objects.

## Transform Schemas

Transform schemas may describe future placement metadata such as:

- zone ids
- anchor ids
- logical positions
- chapter-neutral grouping

They must not contain Roblox Instances, CFrames intended for immediate application, movement commands, pathfinding data, physics commands, Workspace references, or execution instructions.

## Boundary

Physical Transform Runtime does not move parts. It records data only.
