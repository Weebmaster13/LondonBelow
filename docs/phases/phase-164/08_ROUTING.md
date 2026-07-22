# Routing

`EventRouter.lua` resolves matching subscriptions and produces an immutable delivery plan.

Routing does not execute subscriber logic and does not mutate domain state. Subscriber order is deterministic by runtime and subscription identity after event priority has selected the queued envelope.
