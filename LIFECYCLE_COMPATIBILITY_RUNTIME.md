# Lifecycle Compatibility Runtime

Compatibility records are metadata, not migrations or adapter loading.

Compatibility records describe compatibility against lifecycle state or transition kind. They do not migrate, patch, load adapters, call runtime APIs, or mutate live systems.

## Hardening Rules

Compatibility records reject unsupported compatibility kinds, unsupported optional lifecycle states, unsupported optional transition kinds, migration execution payloads, adapter loading payloads, runtime patch payloads, runtime API payloads, callbacks, and execution adapters. They are metadata only, not migration tools.
