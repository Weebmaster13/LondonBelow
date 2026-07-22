# Locks

Locks support acquire, release, locked-state checks, and owner checks.

Only one owner may hold a session lock. Stale lock releases and concurrent owners reject.
