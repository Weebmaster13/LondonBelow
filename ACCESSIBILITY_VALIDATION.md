# Accessibility Validation

Accessibility validation rejects malformed records, unsupported schema types, duplicate ids across one global accessibility schema namespace, unsafe payloads, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized payloads, and deep payloads.

It also rejects:

- Client and remote fields
- Final UI fields
- Input remapping execution fields
- Audio, lighting, camera, and VFX execution fields
- Workspace and gameplay fields
- Chapter, story, dialogue, and cutscene fields

Validation never creates UI, applies client settings, remaps input, executes audio, mutates lighting, moves cameras, plays VFX, mutates Workspace, creates remotes, trusts clients, executes gameplay, or adds Chapter content.

## Category Rules

- Accessibility settings require a stable `settingId`, an `ownerSystem`, and an optional matching settings schema type.
- Visual safety rules require a stable `visualId`, an `ownerSystem`, and an optional matching visual schema type.
- Audio safety rules require a stable `audioId`, an `ownerSystem`, and an optional matching audio schema type.
- Input assist schemas require a stable `inputId`, an `ownerSystem`, and an optional matching input schema type.
- Motion comfort schemas require a stable `motionId`, an `ownerSystem`, and an optional matching motion schema type.
- Readability schemas require a stable `readabilityId`, an `ownerSystem`, and an optional matching readability schema type.
- Content warning schemas require a stable `contentWarningId`, an `ownerSystem`, and an optional matching content warning schema type.

Every category rejects unsafe metadata, unsafe context, unsafe tags, unsupported schema types, and forbidden ownership or execution fields. Duplicate ids reject across the entire accessibility namespace so one category cannot shadow another category's schema.

## Safe Failure

Validation failures are normal, bounded, and non-destructive. A rejected schema does not create partial state, does not create a fallback rule, does not execute anything, and does not grant client authority.
