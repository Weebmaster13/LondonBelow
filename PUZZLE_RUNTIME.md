# Puzzle Runtime

Puzzle Runtime requires graph-based puzzles.

Puzzle definitions contain nodes, dependencies, required items, required object states, co-op flags, fail states, completion nodes, hints, fairness protection, Director hooks, and metadata.

The graph validator rejects duplicate nodes, missing dependencies, missing completion nodes, completion nodes that do not exist, dependency cycles, oversized graphs, and orphan nodes outside the completion path. Wrong inputs and missing dependency attempts are recorded without creating one-off puzzle scripts.

This runtime does not create Chapter 1 puzzles, copied puzzles, final UI, final art, final scares, Monster AI, or physical Workspace mutation.
