# Accessibility Self-Checks

Accessibility self-checks are destructive and should run before runtime start.

They prove malformed records reject, unsupported schema types reject, duplicate setting/visual/audio/input/motion/readability/content warning ids reject, valid schema records register, unsafe metadata/context/tags reject, forbidden execution fields reject, serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads, snapshots are isolated, diagnostics are read-only, histories are bounded, shutdown clears state, and no final accessibility UI, client settings execution, input remapping execution, audio/lighting/camera/VFX execution, Workspace mutation, remotes, client authority, or Chapter content exists.
