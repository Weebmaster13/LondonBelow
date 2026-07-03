# Lifecycle Policy Runtime

Policies are constraints, not enforcement.

Policy records describe required states, forbidden states, allowed transitions, forbidden transitions, preconditions, postconditions, recovery policy, failure policy, compatibility policy, or future policy. They do not call guards, perform service lookup, enforce runtime state, or mutate systems.

## Hardening Rules

Policies reject unsupported policy kinds, unsupported optional lifecycle states, unsupported optional transition kinds, enforcement payloads, service lookup payloads, live guard execution payloads, callbacks, adapters, runtime object fields, and remediation fields. They are constraints for future review only, not policy engines.
