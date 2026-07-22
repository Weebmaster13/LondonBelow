# Event Bus Runtime

`src/ServerScriptService/Core/Events/RuntimeEventBus.lua` owns typed publication, batch publication, cancellation, dispatch, inspection, snapshots, validation, shutdown cleanup, and legacy EventBus compatibility.

The runtime is server-local and bounded. It does not provide durable delivery, cross-server delivery, external broker integration, networking, client subscription, or gameplay authority.
