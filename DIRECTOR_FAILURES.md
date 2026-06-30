# Director Failures

The Director Ecosystem must degrade safely.

If one Director fails:

- The Coordinator isolates the failure.
- Other Directors continue.
- The engine does not crash.
- Failure is published through EventBus diagnostics.
- The request is rejected or deferred with a reason.

Failure handling exists so a broken future Audio Director does not take down Save, Performance, Narrative, or Monster permission logic.

