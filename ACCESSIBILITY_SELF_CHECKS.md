# Accessibility Self-Checks

Accessibility self-checks are destructive and should run before runtime start.

They prove malformed records reject, unsupported schema types reject, duplicate setting/visual/audio/input/motion/readability/content warning ids reject, valid schema records register, unsafe metadata/context/tags reject, forbidden execution fields reject, serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads, snapshots are isolated, diagnostics are read-only, histories are bounded, shutdown clears state, and no final accessibility UI, client settings execution, input remapping execution, audio/lighting/camera/VFX execution, Workspace mutation, remotes, client authority, or Chapter content exists.

## Hardened Proof List

The current self-check suite explicitly proves:

- malformed setting rejects, duplicate setting rejects, and valid setting registers;
- unsupported schema type rejects;
- duplicate schema id across categories rejects;
- malformed visual rule rejects, duplicate visual rule rejects, and unsafe visual rejects;
- malformed audio rule rejects, duplicate audio rule rejects, and unsafe audio rejects;
- malformed input assist rejects, duplicate input assist rejects, and unsafe input rejects;
- malformed motion rule rejects, duplicate motion rule rejects, and unsafe motion rejects;
- malformed readability rule rejects, duplicate readability rule rejects, and unsafe readability rejects;
- malformed content warning rejects, duplicate content warning rejects, and unsafe content warning rejects;
- unsafe metadata, unsafe context, and unsafe tags reject;
- client/remote, final UI, input remapping, sensory execution, world/gameplay, and Chapter/story/dialogue/cutscene fields reject;
- serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads;
- snapshots are isolated, diagnostics are read-only, histories are bounded, and shutdown clears state.

These checks are intentionally destructive because they register and reject synthetic schemas. They must run before runtime start and must never become live player-facing validation UI.
