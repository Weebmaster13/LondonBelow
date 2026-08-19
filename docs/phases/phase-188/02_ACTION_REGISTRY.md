# Phase 188 - Action Registry

Consumers register bounded, unique string action identities with local callback functions. A rendered control references an action through validated `accessibility.actionId`. Activation produces a frozen context containing action, node, contract, revision, and explicit client-presentation posture. Unknown actions fail visibly; callback exceptions are contained with `pcall` and recorded.

Action registration intentionally survives visual revision replacement, while control event connections are rebuilt for the new Instances. Shutdown clears every action.

## Ownership

Phase 188 owns local action lookup and protected callback dispatch.

## Non-Ownership

Callbacks are not server approvals, trusted observations, RemoteEvent sends, or gameplay decisions.

## Certification Boundary

Registry behavior must pass activation and failure tests in Studio before certification.
