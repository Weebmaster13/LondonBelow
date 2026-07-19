# Runner Invocation Contract

Phase 152 adds `RunnerInvocation.mjs`.

Fields:

- schema version
- runner ID
- session ID
- phase
- repository commit
- execution mode
- requested capabilities
- assertion set
- evidence output
- timeout
- participant count
- certification requested
- metadata

`certificationRequested` defaults to false. Runner invocation is source-bound and session-bound.
