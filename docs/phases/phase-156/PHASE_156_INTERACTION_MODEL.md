# Interaction Model

An interaction is a server-owned definition with `interactionId`, `definitionId`, `targetId`, `physicalObjectId`, type, owner, status, eligibility, required state, cooldown, lock state, tags, metadata, and context.

Requests are not execution. A request becomes a session only after validation, eligibility, replay resistance, rate limiting, contention checks, and authorization pass.
