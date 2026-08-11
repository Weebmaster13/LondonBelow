# Revision And Supersession

Resolved composition plans use monotonically increasing revisions. Compilation
requires an expected revision. If the expected revision does not match the
current revision, the operation rejects as stale and records evidence.

Stale revision rejection must not partially mutate the active composition or
commit a plan. Self-checks prove stale compile attempts preserve the previous
revision.

Supersession is lifecycle metadata. Superseded plans remain inspectable through
bounded plan history and cannot become active again.
