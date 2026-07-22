# Consumer Lifecycle

Legal consumer lifecycle:

```text
Created -> Registered -> Validated -> Initialized -> Ready -> Running -> Suspended -> Running -> Shutdown
```

Running and suspended consumers may also transition to `Shutdown`.

Skipped transitions, backward transitions, repeated terminal transitions, and unknown consumers reject. Lifecycle state is integration metadata only; it does not execute domain behavior.
