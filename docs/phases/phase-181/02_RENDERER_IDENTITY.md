# Renderer Identity

Roblox renderers declare:

- `rendererId`
- `platform`
- `provider`
- `version`
- `capabilityVersion`
- `supportedContractVersions`
- `supportedRenderingKinds`
- `supportedDescriptorVersions`
- `supportedSynchronizationPolicies`
- `rendererPriority`
- `status`
- `configuration`
- `runtimeMetadata`

Registration rejects duplicate ids, unsupported platforms, unsupported rendering kinds, malformed arrays, unsupported statuses, unsafe metadata, and limit overflow before mutation.
