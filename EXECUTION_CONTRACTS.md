# Execution Contracts

Execution contracts define how future systems plug into physical or presentation changes without stealing gameplay ownership.

## Gameplay Systems

Gameplay systems may submit execution requests after server truth changes. They may not move Workspace parts directly.

Examples:

- Door truth changes to `Open`, then a future door adapter animates the model.
- Puzzle node completes, then a future panel adapter shows feedback.
- Key is collected, then a future pickup adapter hides or presents the key model.

## Directors

Directors approve pressure or presentation where required. They do not execute physical behavior.

Major environmental, puzzle, or objective presentation requests must include approval metadata.

## Execution Bridge

The bridge validates, queues, expires, locks, routes, diagnoses, and snapshots execution requests.

It does not invent gameplay truth, change objectives, complete puzzles, grant keys, or own horror pacing.

## Adapters

Adapters are the only future place where physical or presentation behavior should happen. They must fail safely, expose diagnostics, support rollback, and describe themselves.

Phase 14 creates the adapter registry but no real adapters.
