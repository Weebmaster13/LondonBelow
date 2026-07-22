# Transactions

Transactions support begin, commit, rollback, and cancel.

Only one active transaction may exist per session. Nested transactions, double commits, rollback without transaction, and commits on cancelled sessions reject.
