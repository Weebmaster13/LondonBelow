# Environment Execution

`EnvironmentExecutionBridge` is the only bridge from Environment Director approval into future physical systems.

It supports these execution request kinds:

- `ApplyFogPressure`
- `ApplyRainPressure`
- `ApplyWindPressure`
- `RequestDoorReaction`
- `RequestPropShift`
- `RequestRoomPressure`
- `RequestBuildingAttention`
- `RequestCarriageAtmosphere`

The bridge validates payloads, records diagnostics, and publishes `EnvironmentDirector.ExecutionRequested` through EventBus. It does not mutate Workspace, Lighting, SoundService, maps, props, doors, particles, or client UI.

Future execution systems must listen for approved bridge requests and still fail safely if chapter objects are missing. Clients may present approved results later, but clients never create trusted environment truth.

Payload validation rejects invalid execution kinds, invalid categories, invalid zone kinds, out-of-range intensity, missing reasons, oversized metadata, overly deep payloads, Instances, callbacks, and threads. This keeps the bridge as a data contract rather than an object mutation path.
