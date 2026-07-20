# Binary Mechanisms

Binary mechanisms support `OPEN`, `CLOSE`, `TOGGLE`, and `ACTIVATE`-style transitions across normalized states such as `CLOSED`, `OPEN`, `OFF`, and `ON`.

Invalid repeated `OPEN` from `OPEN` rejects without mutation.
