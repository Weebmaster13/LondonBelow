# Runtime Discovery

Consumers publish public interface identifiers in their contracts.

The Runtime Discovery module indexes those identifiers and returns immutable metadata containing:

- interface id;
- consumer id;
- owner runtime;
- version.

Consumers discover interfaces through registry metadata instead of storing direct runtime references. Unknown interfaces reject deterministically.
