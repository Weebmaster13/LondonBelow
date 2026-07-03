# Lifecycle Failure Runtime

Failures are schemas, not active failure handlers.

Failure records describe validation, dependency, configuration, governance, safety, compatibility, Runtime Graph, unknown, or future failure categories. They do not trigger recovery, store secret stack traces, or execute handlers.

## Hardening Rules

Failures reject unsupported failure kinds, invalid related state references, invalid related transition references, live error objects, secret stack traces, runtime objects, callbacks, service handles, and recovery execution fields. They are failure schemas only, not active failure handlers.
