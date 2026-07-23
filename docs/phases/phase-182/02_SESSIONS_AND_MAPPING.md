# Sessions And Mapping

Roblox rendering sessions record:

- `robloxRenderingSessionId`
- `renderingExecutionSessionId`
- `renderingSessionId`
- `rendererId`
- `platform`
- `owner`
- `sessionState`
- `reservationState`
- `schedulingState`
- `lifecycleState`
- `runtimePriority`
- `runtimeMetadata`

`RobloxExecutionSessionMapper` enforces one-to-one mapping between a Roblox rendering session and a Presentation Rendering Execution session. Duplicate mappings reject before mutation.
