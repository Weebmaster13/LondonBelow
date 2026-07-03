# Condition Operator Runtime

Condition operators are metadata records for supported operator kinds such as Equals, NotEquals, GreaterThan, Exists, Boolean, Logical, and FutureOperator.

Operators are not functions. They do not execute comparisons or boolean logic. Future evaluation must implement operator behavior in a separate governed runtime.

Operator registration is bounded, globally unique, and restricted to supported operator kinds.

## Production Hardening

Operators reject unsupported schema types, unsupported operator kinds, executable function markers, comparison execution markers, callbacks, modules, runtime objects, service references, and unsafe payloads. Operators remain metadata only.
