# Asset Execution Design Contract Self-Checks

Self-checks are deterministic and prove valid registration, duplicate rejection, invalid id rejection, unsupported contract kind/status rejection, unsupported responsibility kind rejection, unsupported boundary kind rejection, missing contract reference rejection, unsafe payload rejection, oversized payload rejection, failed-validation no-mutation, bounded validation failures, bounded snapshots, snapshot isolation, diagnostics isolation, provider name consistency, schema name consistency, shutdown cleanup, global namespace reset, and banned runtime surface absence.

Self-checks do not perform asset operations and are not gameplay tests.
