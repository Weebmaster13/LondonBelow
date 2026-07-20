# Runtime Integrations

Interaction integration:

Gameplay Flow can consume `InteractionCompleted` and `InspectionCompleted` event records after Interaction Runtime accepts the player action.

Environmental integration:

Gameplay Flow can consume authored object state records such as breaker `ON` and front door `OPEN`.

Presentation integration:

Gameplay Flow publishes objective change and progress events. Presentation Runtime remains the owner of command queueing and dispatch.

Observation integration:

Objective facts remain server-authoritative and are suitable for Observation ingestion. Gameplay Flow does not bypass Observation ownership for broader horror interpretation.
